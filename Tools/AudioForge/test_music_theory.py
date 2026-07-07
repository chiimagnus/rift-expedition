#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rift Expedition — BGM 乐理/技术标准测试。

因为无法“听”，用客观指标检验 `Tools/AudioForge/generate_bgm.py` 生成的三首区域 BGM：

技术规格：
  - 采样率 44100 / 16bit / 立体声；时长在合理区间
  - 不削幅（peak < 1.0）且不过安静（RMS 在健康区间）
  - 无直流偏置（DC ≈ 0）
  - 无“喀塔”喳声（相邻样本无巨跳）
  - 无长时静音
  - 立体声：左右不完全相同且不反相
  - 无缝循环：首尾接缝连续

乐理：
  - 调内能量占主（chroma 中“调外半音”能量占比低于阈值）——即避免刺耳半音
  - 主音突出（tonic pitch class 在 chroma 能量前列）

可复现性：
  - 相同种子 → 渲染结果位一致（确定性）

运行：python3 Tools/AudioForge/test_music_theory.py -v
     或 python3 -m unittest Tools.AudioForge.test_music_theory
依赖：numpy（标准库 unittest）。若 wav 缺失会先自动调用生成器。
"""
from __future__ import annotations
import os
import sys
import wave
import unittest
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
AUDIO = os.path.normpath(os.path.join(HERE, "..", "..", "RiftExpedition",
                                     "Resources", "Assets", "Audio"))
sys.path.insert(0, HERE)

# 每首曲的调内 pitch class 集合（C=0）与主音
SPEC = {
    "village_theme_loop.wav": {
        "scale": {0, 2, 4, 5, 7, 9, 11},   # C 大调
        "tonic": 0,                          # C
        "dur": (12, 26),
    },
    "wilds_theme_loop.wav": {
        "scale": {0, 2, 4, 5, 7, 9, 11},   # A 自然小调（C 大调关系调）
        "tonic": 9,                          # A
        "dur": (14, 30),
    },
    "cave_theme_loop.wav": {
        "scale": {0, 2, 4, 5, 7, 9, 10},   # D 自然小调
        "tonic": 2,                          # D
        "dur": (20, 40),
    },
}

# 阈值（根据实测标定，既能通过当前好结果，又能抓回归）
SR_EXPECTED = 44100
PEAK_MAX = 0.985
RMS_MIN, RMS_MAX = 0.06, 0.35
DC_MAX = 0.01
MAX_JUMP = 0.35            # 相邻样本最大跳变（防喀塔）
SEAM_MAX = 0.05           # 首尾样本接缝差
SILENCE_MAX_S = 1.5        # 最长允许静音
OUT_OF_KEY_MAX = 0.22     # 调外半音能量占比上限
TONIC_TOP_K = 5           # 主音需落在 chroma 能量前 K


def _ensure_audio():
    missing = [f for f in SPEC if not os.path.exists(os.path.join(AUDIO, f))]
    if missing:
        import generate_bgm
        generate_bgm.main()


def _read(path):
    w = wave.open(path)
    ch, sw, sr, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
    raw = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float64) / 32768.0
    w.close()
    if ch == 2:
        L, R = raw[0::2], raw[1::2]
    else:
        L = R = raw
    return {"ch": ch, "sw": sw, "sr": sr, "n": len(L), "L": L, "R": R,
            "mono": (L + R) * 0.5}


def _chroma(x, sr):
    N, hop = 8192, 4096
    win = np.hanning(N)
    freqs = np.fft.rfftfreq(N, 1 / sr)
    pc = np.full(len(freqs), -1, dtype=int)
    valid = freqs > 25
    midi = 69 + 12 * np.log2(freqs[valid] / 440.0)
    pc[valid] = np.mod(np.round(midi).astype(int), 12)
    acc = np.zeros(12)
    for i in range(0, max(1, len(x) - N), hop):
        seg = x[i:i + N] * win
        mag = np.abs(np.fft.rfft(seg)) ** 2
        for c in range(12):
            acc[c] += mag[pc == c].sum()
    s = acc.sum()
    return acc / s if s > 0 else acc


def _max_silence_s(x, sr, win_ms=50, thresh=0.02):
    w = int(sr * win_ms / 1000)
    if w <= 0:
        return 0.0
    run = longest = 0
    for i in range(0, len(x) - w, w):
        if np.sqrt((x[i:i + w] ** 2).mean()) < thresh:
            run += 1
            longest = max(longest, run)
        else:
            run = 0
    return longest * win_ms / 1000


class BGMTheoryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        _ensure_audio()
        cls.data = {f: _read(os.path.join(AUDIO, f)) for f in SPEC}

    # ---------- 技术规格 ----------
    def test_format(self):
        for f, d in self.data.items():
            self.assertEqual(d["sr"], SR_EXPECTED, f"{f} 采样率")
            self.assertEqual(d["sw"], 2, f"{f} 位深应 16bit")
            self.assertEqual(d["ch"], 2, f"{f} 应为立体声")
            dur = d["n"] / d["sr"]
            lo, hi = SPEC[f]["dur"]
            self.assertTrue(lo <= dur <= hi, f"{f} 时长 {dur:.2f}s 不在 [{lo},{hi}]")

    def test_no_clip_and_loudness(self):
        for f, d in self.data.items():
            peak = max(np.max(np.abs(d["L"])), np.max(np.abs(d["R"])))
            rms = np.sqrt((d["mono"] ** 2).mean())
            self.assertLess(peak, PEAK_MAX, f"{f} 削幅 peak={peak:.3f}")
            self.assertTrue(RMS_MIN <= rms <= RMS_MAX, f"{f} RMS={rms:.3f} 超出健康区间")

    def test_no_dc_offset(self):
        for f, d in self.data.items():
            self.assertLess(abs(d["mono"].mean()), DC_MAX, f"{f} 直流偏置过大")

    def test_no_clicks(self):
        for f, d in self.data.items():
            jump = max(np.max(np.abs(np.diff(d["L"]))), np.max(np.abs(np.diff(d["R"]))))
            self.assertLess(jump, MAX_JUMP, f"{f} 存在喳声巨跳 {jump:.3f}")

    def test_no_long_silence(self):
        for f, d in self.data.items():
            sil = _max_silence_s(d["mono"], d["sr"])
            self.assertLess(sil, SILENCE_MAX_S, f"{f} 最长静音 {sil:.2f}s")

    def test_stereo_field(self):
        for f, d in self.data.items():
            L, R = d["L"], d["R"]
            corr = float(np.corrcoef(L, R)[0, 1])
            self.assertGreater(corr, 0.0, f"{f} 左右声道反相")
            self.assertLess(corr, 0.9999, f"{f} 左右声道完全相同（非立体声）")

    def test_seamless_loop(self):
        for f, d in self.data.items():
            seamL = abs(d["L"][0] - d["L"][-1])
            seamR = abs(d["R"][0] - d["R"][-1])
            self.assertLess(seamL, SEAM_MAX, f"{f} 左声道循环接缝 {seamL:.3f}")
            self.assertLess(seamR, SEAM_MAX, f"{f} 右声道循环接缝 {seamR:.3f}")

    # ---------- 乐理 ----------
    def test_in_key_energy(self):
        for f, d in self.data.items():
            ch = _chroma(d["mono"], d["sr"])
            out_of_key = sum(ch[c] for c in range(12) if c not in SPEC[f]["scale"])
            self.assertLess(out_of_key, OUT_OF_KEY_MAX,
                            f"{f} 调外半音能量占比 {out_of_key:.3f} 过高（可能刺耳）")

    def test_tonic_prominent(self):
        for f, d in self.data.items():
            ch = _chroma(d["mono"], d["sr"])
            rank = list(np.argsort(ch)[::-1])
            tonic = SPEC[f]["tonic"]
            self.assertIn(tonic, rank[:TONIC_TOP_K],
                          f"{f} 主音(pc={tonic}) 不在 chroma 能量前 {TONIC_TOP_K}")

    # ---------- 可复现性 ----------
    def test_deterministic_render(self):
        import generate_bgm as g
        spec = {
            'bpm': 100, 'beats_per_bar': 4, 'seed': 123,
            'bars': [('C', 'maj7'), ('A', 'min7'), ('F', 'maj7'), ('G', 'dom7')],
            'key': ('C', 4), 'scale': [0, 2, 4, 7, 9],
            'pad': g.strings_pad, 'arp': g.harp, 'lead': g.lead,
            'pad_oct': 4, 'bass_oct': 2, 'arp_oct': 5, 'lead_oct': 5,
            'gains': {'pad': 0.16, 'bass': 0.5, 'arp': 0.3, 'mel': 0.42},
            'drums': None, 'reverb_len': 1.0, 'reverb_damp': 4.0, 'reverb_mix': 0.2,
        }
        L1, R1, _ = g.render_song(spec)
        L2, R2, _ = g.render_song(spec)
        self.assertTrue(np.array_equal(L1, L2) and np.array_equal(R1, R2),
                        "相同种子渲染结果不一致（非确定性）")


def _report():
    _ensure_audio()
    print(f"{'file':24s} {'sr':>5} {'ch':>2} {'dur':>6} {'peak':>5} {'rms':>5} "
          f"{'DC':>7} {'jump':>5} {'seam':>6} {'silence':>7} {'outkey':>6} tonic_rank")
    for f in SPEC:
        d = _read(os.path.join(AUDIO, f))
        peak = max(np.max(np.abs(d["L"])), np.max(np.abs(d["R"])))
        rms = np.sqrt((d["mono"] ** 2).mean())
        jump = max(np.max(np.abs(np.diff(d["L"]))), np.max(np.abs(np.diff(d["R"]))))
        seam = max(abs(d["L"][0] - d["L"][-1]), abs(d["R"][0] - d["R"][-1]))
        sil = _max_silence_s(d["mono"], d["sr"])
        ch = _chroma(d["mono"], d["sr"])
        outk = sum(ch[c] for c in range(12) if c not in SPEC[f]["scale"])
        rank = list(np.argsort(ch)[::-1])
        tr = rank.index(SPEC[f]["tonic"])
        print(f"{f:24s} {d['sr']:>5} {d['ch']:>2} {d['n']/d['sr']:>6.2f} "
              f"{peak:>5.2f} {rms:>5.3f} {d['mono'].mean():>7.4f} {jump:>5.3f} "
              f"{seam:>6.4f} {sil:>7.2f} {outk:>6.3f} #{tr}")


if __name__ == "__main__":
    if "--report" in sys.argv:
        _report()
    else:
        unittest.main(argv=[sys.argv[0], "-v"])
