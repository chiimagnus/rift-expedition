#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rift Expedition — BGM 专业级客观测试（按行业标准）。

参照的行业标准/方法（与 GitHub 开源生态一致）：
  - 响度：ITU-R BS.1770-4 / EBU R128 积分响度 LUFS（参考实现 csteinmetz1/pyloudnorm）。
  - 真峰值：ITU-R BS.1770 True Peak（4x 过采样 dBTP）。
  - 调性：Krumhansl-Schmuckler key-finding + 色度特征（参考 librosa.feature.chroma_cqt）。

本测试**优先调用权威开源库**（pyloudnorm / librosa / soundfile）作为独立参考实现；
若未安装，则回退到仓库内 audio_metrics.py 的纯 numpy 标准实现。
本地建议：`pip install librosa pyloudnorm soundfile` 以启用权威参考实现。

运行：python3 Tools/AudioForge/test_music_theory.py
"""
from __future__ import annotations
import os
import sys
import wave
import unittest
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import audio_metrics as M  # noqa: E402

AUDIO = os.path.normpath(os.path.join(
    HERE, "..", "..", "RiftExpedition", "Resources", "Assets", "Audio"))

# 目标规格（与生成器 save_stereo 一致）
SR = 44100
TARGET_LUFS = -16.0
LUFS_TOL = 2.0            # ±2 LU
TP_CEILING_DBTP = -1.0    # 断言上限（生成时目标 -1.5，留余量）

TRACKS = {
    "village_theme_loop.wav": "C major",
    "wilds_theme_loop.wav": "A minor",
    "cave_theme_loop.wav": "D minor",
}

# --------------------------------------------------------------------------
# 后端选择：优先权威开源库，否则回退 audio_metrics
# --------------------------------------------------------------------------
try:
    import pyloudnorm as _pyln  # type: ignore
    LUFS_BACKEND = "pyloudnorm(BS.1770)"

    def measure_lufs(L, R, sr):
        meter = _pyln.Meter(sr)
        return float(meter.integrated_loudness(np.stack([L, R], axis=1)))
except Exception:
    LUFS_BACKEND = "audio_metrics(BS.1770,numpy)"

    def measure_lufs(L, R, sr):
        return float(M.integrated_lufs(L, R, sr))

try:
    import librosa as _librosa  # type: ignore
    KEY_BACKEND = "librosa.chroma_cqt+KS"

    def detect_key(mono, sr):
        ch = _librosa.feature.chroma_cqt(y=mono.astype(np.float32), sr=sr).mean(axis=1)
        return M.detect_key_from_chroma(ch)
except Exception:
    KEY_BACKEND = "audio_metrics(chroma+KS,numpy)"

    def detect_key(mono, sr):
        return M.detect_key(mono, sr)


def load_wav(path):
    with wave.open(path) as w:
        ch, sw, sr, n = (w.getnchannels(), w.getsampwidth(),
                         w.getframerate(), w.getnframes())
        raw = w.readframes(n)
    a = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0
    if ch == 2:
        L, R = a[0::2], a[1::2]
    else:
        L = R = a
    return dict(ch=ch, sw=sw, sr=sr, n=len(L), L=L, R=R, mono=(L + R) / 2)


class BGMProfessionalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = {}
        for f in TRACKS:
            p = os.path.join(AUDIO, f)
            assert os.path.exists(p), f"缺失音频文件: {p}"
            cls.data[f] = load_wav(p)
        print(f"\n[后端] LUFS={LUFS_BACKEND}  KEY={KEY_BACKEND}")

    # ---------- 格式 ----------
    def test_format(self):
        for f, d in self.data.items():
            self.assertEqual(d["sr"], SR, f"{f} 采样率应 {SR}")
            self.assertEqual(d["sw"], 2, f"{f} 应 16-bit")
            self.assertEqual(d["ch"], 2, f"{f} 应立体声")

    # ---------- 响度（EBU R128 / BS.1770）----------
    def test_integrated_loudness(self):
        for f, d in self.data.items():
            lufs = measure_lufs(d["L"], d["R"], d["sr"])
            self.assertTrue(np.isfinite(lufs), f"{f} LUFS 无效")
            self.assertLessEqual(
                abs(lufs - TARGET_LUFS), LUFS_TOL,
                f"{f} 响度 {lufs:.2f} LUFS 超出目标 {TARGET_LUFS}±{LUFS_TOL}")

    def test_loudness_consistency(self):
        vals = [measure_lufs(d["L"], d["R"], d["sr"]) for d in self.data.values()]
        self.assertLessEqual(
            max(vals) - min(vals), 3.0,
            f"三首响度差 {max(vals)-min(vals):.2f} LU 过大（应≤3）")

    # ---------- True Peak（BS.1770 附录2）----------
    def test_true_peak(self):
        for f, d in self.data.items():
            tp = max(M.true_peak_dbtp(d["L"])[0], M.true_peak_dbtp(d["R"])[0])
            self.assertLessEqual(
                tp, TP_CEILING_DBTP,
                f"{f} True Peak {tp:.2f} dBTP 超出上限 {TP_CEILING_DBTP}")

    # ---------- 调性（Krumhansl-Schmuckler）----------
    def test_key_detection(self):
        for f, expected in TRACKS.items():
            key, score = detect_key(self.data[f]["mono"], self.data[f]["sr"])
            self.assertEqual(
                key, expected,
                f"{f} 调性应为 {expected}，实测 {key} (r={score:.2f})")
            self.assertGreater(score, 0.6, f"{f} 调性置信度 {score:.2f} 过低")

    # ---------- 技术质量 ----------
    def test_no_nan_or_inf(self):
        for f, d in self.data.items():
            for ch in ("L", "R"):
                self.assertTrue(np.all(np.isfinite(d[ch])), f"{f}/{ch} 含 NaN/Inf")

    def test_dc_offset(self):
        for f, d in self.data.items():
            for ch in ("L", "R"):
                dc = abs(float(np.mean(d[ch])))
                self.assertLess(dc, 0.01, f"{f}/{ch} 直流偏置 {dc:.4f} 过大")

    def test_no_hard_clipping(self):
        for f, d in self.data.items():
            for ch in ("L", "R"):
                clipped = int(np.sum(np.abs(d[ch]) >= 0.999))
                ratio = clipped / d["n"]
                self.assertLess(ratio, 1e-4,
                                f"{f}/{ch} 削幅样本占比 {ratio:.6f} 过高")

    def test_not_silent(self):
        for f, d in self.data.items():
            rms = float(np.sqrt(np.mean(d["mono"] ** 2)))
            self.assertGreater(rms, 0.02, f"{f} RMS {rms:.4f} 过低（近静音）")

    def test_loop_seam(self):
        # 首尾无缝拼接：首尾样本差应极小，避免循环响点击
        for f, d in self.data.items():
            for ch in ("L", "R"):
                seam = abs(float(d[ch][0] - d[ch][-1]))
                self.assertLess(seam, 0.05, f"{f}/{ch} 循环接缝 {seam:.4f} 过大")

    def test_stereo_width(self):
        # 确保不是伪立体声（左右完全相同）
        for f, d in self.data.items():
            diff = float(np.mean(np.abs(d["L"] - d["R"])))
            self.assertGreater(diff, 1e-4, f"{f} 左右声道几乎相同（伪立体声）")


if __name__ == "__main__":
    unittest.main(verbosity=2)
