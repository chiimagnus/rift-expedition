#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rift Expedition — 程序化背景音乐引擎（self-made / 本地程序化合成）。

一个纯 numpy 实现的小型合成 + 混音引擎，用于生成三个区域的立体声 BGM 循环：
  - village_theme_loop : C 大调、田园明快、有柔和鼓组
  - wilds_theme_loop   : A 自然小调、开阔神秘、带回声
  - cave_theme_loop    : D 小调、阴暗空旷、铟铟钟音 + 长混响

信号链：加法/减法合成振荡器 → windowed-sinc 滤波 → ADSR → 分轨总线
         → 多抽头延迟/合唱 → Schroeder 混响（FFT 卷积）→ 立体声声像
         → tanh 软限幅 → 无缝循环 crossfade → 44100Hz 16bit 立体声 WAV。

用法：python3 Tools/AudioForge/generate_bgm.py
依赖：numpy。输出覆盖 RiftExpedition/Resources/Assets/Audio/*_theme_loop.wav。
"""
from __future__ import annotations
import numpy as np
import wave
import os

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "RiftExpedition",
                                    "Resources", "Assets", "Audio"))

# ---------------------------------------------------------------- 音高
NAMES = {'C': -9, 'C#': -8, 'D': -7, 'D#': -6, 'E': -5, 'F': -4, 'F#': -3,
         'G': -2, 'G#': -1, 'A': 0, 'A#': 1, 'B': 2}


def freq(letter, octave, semi=0):
    return 440.0 * 2 ** ((NAMES[letter] + (octave - 4) * 12 + semi) / 12.0)


def _t(dur):
    return np.arange(int(dur * SR)) / SR

# ---------------------------------------------------------------- DSP 工具


def fftconvolve(a, b):
    n = len(a) + len(b) - 1
    N = 1 << (n - 1).bit_length()
    out = np.fft.irfft(np.fft.rfft(a, N) * np.fft.rfft(b, N), N)[:n]
    return out


def _sinc_kernel(cutoff, taps):
    fc = cutoff / SR
    m = np.arange(taps) - (taps - 1) / 2
    h = np.sinc(2 * fc * m) * np.hamming(taps)
    return h / h.sum()


def lowpass(sig, cutoff, taps=193):
    return fftconvolve(sig, _sinc_kernel(cutoff, taps))[:len(sig)]


def highpass(sig, cutoff, taps=193):
    h = -_sinc_kernel(cutoff, taps)
    h[(taps - 1) // 2] += 1
    return fftconvolve(sig, h)[:len(sig)]


def adsr(n, a, d, s, r):
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(0, n - a_n - d_n - r_n)
    parts = []
    if a_n:
        parts.append(np.linspace(0, 1, a_n, endpoint=False))
    if d_n:
        parts.append(np.linspace(1, s, d_n, endpoint=False))
    parts.append(np.full(s_n, s))
    if r_n:
        parts.append(np.linspace(s, 0, r_n))
    env = np.concatenate(parts) if parts else np.zeros(n)
    if len(env) < n:
        env = np.concatenate([env, np.zeros(n - len(env))])
    return env[:n]

# ---------------------------------------------------------------- 振荡器


def saw(f, dur, nharm=16):
    t = _t(dur)
    out = np.zeros(len(t))
    for k in range(1, nharm + 1):
        out += np.sin(2 * np.pi * f * k * t) / k
    return out * (2 / np.pi)


def square(f, dur, nharm=15):
    t = _t(dur)
    out = np.zeros(len(t))
    for k in range(1, nharm + 1, 2):
        out += np.sin(2 * np.pi * f * k * t) / k
    return out * (4 / np.pi)


def sine(f, dur):
    return np.sin(2 * np.pi * f * _t(dur))


def sine_vib(f, dur, rate=5.2, depth=0.005):
    t = _t(dur)
    inst = f * (1 + depth * np.sin(2 * np.pi * rate * t))
    return np.sin(2 * np.pi * np.cumsum(inst) / SR)

# ---------------------------------------------------------------- 乐器


def strings_pad(f, dur):
    y = (saw(f * 0.994, dur) + saw(f * 1.006, dur) + saw(f, dur)) / 3
    y += 0.5 * sine(f / 2, dur)               # 低八度垫底
    y = lowpass(y, 2600)
    return y * adsr(len(y), 0.35, 0.2, 0.8, 0.5)


def choir_pad(f, dur):
    y = sum(a * sine(f * m, dur) for m, a in
            [(1, 1.0), (2, 0.4), (3, 0.22), (4, 0.12)])
    y = lowpass(y, 3200)
    return y * adsr(len(y), 0.4, 0.25, 0.85, 0.6)


def harp(f, dur):
    y = sum(a * sine(f * m, dur) for m, a in
            [(1, 1.0), (2, 0.5), (3, 0.28), (4, 0.16), (5, 0.08)])
    n = len(y)
    return y * adsr(n, 0.004, 0.10, 0.0, max(0.02, dur - 0.11)) * np.exp(-np.linspace(0, 4.5, n))


def glocken(f, dur):
    y = sum(a * sine(f * m, dur) for m, a in
            [(1, 1.0), (2.76, 0.55), (5.4, 0.28), (8.9, 0.12)])
    n = len(y)
    return y * np.exp(-np.linspace(0, 5.5, n))


def bass(f, dur):
    y = 0.7 * (2 * (np.abs(2 * (_t(dur) * f - np.floor(_t(dur) * f + 0.5))) - 0.5))  # triangle
    y += 0.6 * sine(f, dur) + 0.3 * sine(f / 2, dur)
    y = lowpass(y, 900)
    return y * adsr(len(y), 0.01, 0.1, 0.72, 0.12)


def lead(f, dur):
    y = sine_vib(f, dur) + 0.28 * sine(f * 2, dur) + 0.12 * saw(f, dur)
    y = lowpass(y, 4200)
    return y * adsr(len(y), 0.02, 0.08, 0.7, 0.18)


def kick(dur=0.32):
    t = _t(dur)
    pitch = 110 * np.exp(-t * 26) + 44
    y = np.sin(2 * np.pi * np.cumsum(pitch) / SR)
    return y * np.exp(-t * 9)


def shaker(dur=0.12):
    n = int(dur * SR)
    y = highpass(np.random.default_rng(7).standard_normal(n), 6500)
    return y * np.exp(-np.linspace(0, 7, n))

# ---------------------------------------------------------------- 效果


def schroeder_ir(dur=1.6, seed=1, damp=4.2):
    n = int(dur * SR)
    rng = np.random.default_rng(seed)
    ir = rng.standard_normal(n) * np.exp(-np.linspace(0, damp, n))
    # 早期反射
    for d, g in [(0.011, 0.7), (0.019, 0.55), (0.031, 0.42), (0.047, 0.32)]:
        k = int(d * SR)
        ir[k] += g
    ir[0] = 1.0
    return lowpass(ir, 5200) * 0.6


def reverb(sig, ir):
    return fftconvolve(sig, ir)[:len(sig)]


def delay(sig, time_s, feedback=0.38, mix=0.3, taps=5):
    d = int(time_s * SR)
    out = sig.copy()
    tap = sig.copy()
    for _ in range(taps):
        tap = np.concatenate([np.zeros(d), tap])[:len(out)] * feedback
        out += tap * mix
    return out


def chorus(sig, rate=0.7, depth_ms=6.0, mix=0.35):
    n = len(sig)
    t = np.arange(n) / SR
    mod = (depth_ms / 1000 * SR) * (0.5 + 0.5 * np.sin(2 * np.pi * rate * t))
    idx = np.arange(n) - mod
    idx = np.clip(idx, 0, n - 1)
    wet = np.interp(idx, np.arange(n), sig)
    return sig * (1 - mix) + wet * mix


def soft_clip(sig, drive=1.2):
    return np.tanh(sig * drive)

# ---------------------------------------------------------------- 总线


class Bus:
    def __init__(self, dur_s):
        self.buf = np.zeros(int(dur_s * SR) + SR)

    def add(self, at_s, samples, gain=1.0, pan=0.0):
        i = int(at_s * SR)
        j = i + len(samples)
        if j > len(self.buf):
            self.buf = np.concatenate([self.buf, np.zeros(j - len(self.buf))])
        self.buf[i:j] += samples * gain


def loopify(sig, loop_s, xfade_s=0.09):
    N = int(loop_s * SR)
    x = int(xfade_s * SR)
    core = sig[:N + x].copy()
    fade = np.linspace(0, 1, x)
    core[:x] = core[:x] * fade + core[N:N + x] * (1 - fade)
    return core[:N]


def save_stereo(name, L, R, loop_s, peak=0.89):
    L = loopify(L, loop_s)
    R = loopify(R, loop_s)
    m = max(np.max(np.abs(L)), np.max(np.abs(R))) or 1.0
    L = soft_clip(L / m * peak * 1.05)
    R = soft_clip(R / m * peak * 1.05)
    inter = np.empty(len(L) * 2)
    inter[0::2] = np.clip(L, -1, 1)
    inter[1::2] = np.clip(R, -1, 1)
    data = (inter * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), 'w') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    seam = abs(int((L[0] * 32767)) - int((L[-1] * 32767)))
    print(f"{name:24s} {len(L)/SR:5.2f}s stereo  peak={m:.2f}  seam={seam}")

# ---------------------------------------------------------------- 和声
QUAL = {
    'maj':  [0, 4, 7],
    'min':  [0, 3, 7],
    'maj7': [0, 4, 7, 11],
    'min7': [0, 3, 7, 10],
    'dom7': [0, 4, 7, 10],
    'sus2': [0, 2, 7],
    'add9': [0, 4, 7, 14],
}


def pan_lr(mono, pan):
    # equal-power panning; pan in [-1,1]
    a = (pan + 1) * np.pi / 4
    return mono * np.cos(a), mono * np.sin(a)


def melody_line(rng, bars, scale, beats):
    """为每小节生成旋律：强拍落和弦音，其余走阶。返回 [(bar, beat, semi, dur_beats)]。"""
    notes = []
    for bi, (root, qual) in enumerate(bars):
        tones = QUAL[qual]
        patterns = [[0, 1, 1], [0, 0.5, 0.5, 1], [0, 1.5, 0.5], [0, 2]]
        pat = patterns[rng.integers(len(patterns))]
        beat_cursor = 0.0
        prev = tones[rng.integers(len(tones))]
        for step, dur_b in enumerate(pat):
            if step == 0:
                semi = tones[rng.integers(len(tones))]
            else:
                # 走阶：在音阶里靠近 prev
                cand = [s for s in scale if abs(s - prev) <= 4]
                semi = cand[rng.integers(len(cand))] if cand else prev
            notes.append((bi, beat_cursor, semi, max(0.5, dur_b)))
            prev = semi
            beat_cursor += dur_b
            if beat_cursor >= beats:
                break
    return notes


def render_song(spec):
    bpm = spec['bpm']
    beats = spec.get('beats_per_bar', 4)
    beat = 60.0 / bpm
    bars = spec['bars']
    key = spec['key']            # (letter, octave) 主音
    scale = spec['scale']        # 相对主音的半音集
    rng = np.random.default_rng(spec['seed'])
    bar_dur = beat * beats
    loop_s = len(bars) * bar_dur

    dry = Bus(loop_s + 2.0)
    send = Bus(loop_s + 2.0)   # 混响发送
    dryR = Bus(loop_s + 2.0)
    dryL = Bus(loop_s + 2.0)

    def place(bus_at, samples, gain, pan):
        L, R = pan_lr(samples, pan)
        dryL.add(bus_at, L, gain)
        dryR.add(bus_at, R, gain)

    voice_arp = spec.get('arp', harp)
    padvoice = spec.get('pad', strings_pad)
    g = spec['gains']

    for bi, (root, qual) in enumerate(bars):
        at = bi * bar_dur
        tones = QUAL[qual]
        # --- pad 和声（展开到立体声两侧）---
        for ti, s in enumerate(tones):
            samp = padvoice(freq(root, spec['pad_oct'], s), bar_dur + 0.4)
            pan = -0.5 + ti / max(1, len(tones) - 1)
            place(at, samp, g['pad'], pan * 0.6)
            send.add(at, samp, g['pad'] * 0.4)
        # --- bass：根-五-根-三 走动 ---
        walk = [0, 7, 0, tones[1]]
        for k in range(beats):
            samp = bass(freq(root, spec['bass_oct'], walk[k % len(walk)]), beat * 0.96)
            place(at + k * beat, samp, g['bass'], 0.0)
        # --- arp：上行六联音 ---
        arp_seq = tones + tones[::-1][1:-1]
        steps = beats * 2
        for e in range(steps):
            s = arp_seq[e % len(arp_seq)]
            samp = voice_arp(freq(root, spec['arp_oct'], s), beat / 2 + 0.2)
            pan = 0.35 * np.sin(e * 1.3)
            place(at + e * (beat / 2), samp, g['arp'], pan)
            send.add(at + e * (beat / 2), samp, g['arp'] * 0.5)

    # --- 主旋律 ---
    for (bi, beat_off, semi, dur_b) in melody_line(rng, bars, scale, beats):
        at = bi * bar_dur + beat_off * beat
        samp = spec.get('lead', lead)(freq(key[0], spec['lead_oct'], semi), dur_b * beat + 0.12)
        place(at, samp, g['mel'], 0.12)
        send.add(at, samp, g['mel'] * 0.55)

    # --- 鼓组 ---
    if spec.get('drums'):
        for bi in range(len(bars)):
            at = bi * bar_dur
            for k in spec['drums'].get('kick', []):
                place(at + k * beat, kick(), g.get('kick', 0.5), 0.0)
            for k in spec['drums'].get('shaker', []):
                place(at + k * beat, shaker(), g.get('shaker', 0.25), 0.2)

    # --- 混响总线 ---
    ir = schroeder_ir(dur=spec['reverb_len'], seed=spec['seed'], damp=spec['reverb_damp'])
    wetL = reverb(send.buf, ir) * spec['reverb_mix']
    wetR = reverb(send.buf, ir[::-1] if len(ir) else ir) * spec['reverb_mix']

    L = dryL.buf + wetL[:len(dryL.buf)]
    R = dryR.buf + wetR[:len(dryR.buf)]
    if spec.get('delay'):
        L = delay(L, *spec['delay'])
        R = delay(R, spec['delay'][0] * 1.13, *spec['delay'][1:])
    if spec.get('chorus'):
        L = chorus(L)
        R = chorus(R, rate=0.63)
    L = lowpass(L, spec.get('master_lp', 15000))
    R = lowpass(R, spec.get('master_lp', 15000))
    return L, R, loop_s


def main():
    os.makedirs(OUT, exist_ok=True)

    # ===================== VILLAGE : C 大调、明快田园 =====================
    C = ['C', 'G', 'A', 'F', 'C', 'G', 'F', 'G']
    Q = ['maj7', 'maj', 'min7', 'maj7', 'maj', 'dom7', 'add9', 'maj']
    village = {
        'bpm': 108, 'beats_per_bar': 4, 'seed': 21,
        'bars': list(zip(C, Q)),
        'key': ('C', 4), 'scale': [0, 2, 4, 7, 9, 12, 14],   # C 大五声+
        'pad': strings_pad, 'arp': harp, 'lead': lead,
        'pad_oct': 4, 'bass_oct': 2, 'arp_oct': 5, 'lead_oct': 5,
        'gains': {'pad': 0.16, 'bass': 0.5, 'arp': 0.3, 'mel': 0.42,
                  'kick': 0.55, 'shaker': 0.22},
        'drums': {'kick': [0, 2], 'shaker': [1, 1.5, 3, 3.5]},
        'reverb_len': 1.3, 'reverb_damp': 5.0, 'reverb_mix': 0.22,
        'chorus': True, 'master_lp': 15500,
    }
    save_stereo("village_theme_loop.wav", *render_song(village))

    # ===================== WILDS : A 自然小调、开阔神秘 =====================
    C = ['A', 'F', 'C', 'G', 'A', 'F', 'D', 'E']
    Q = ['min7', 'maj7', 'maj', 'dom7', 'min7', 'add9', 'min7', 'min']
    wilds = {
        'bpm': 96, 'beats_per_bar': 4, 'seed': 44,
        'bars': list(zip(C, Q)),
        'key': ('A', 4), 'scale': [0, 2, 3, 5, 7, 8, 10, 12],  # A 自然小调
        'pad': choir_pad, 'arp': harp, 'lead': lead,
        'pad_oct': 3, 'bass_oct': 2, 'arp_oct': 5, 'lead_oct': 4,
        'gains': {'pad': 0.15, 'bass': 0.46, 'arp': 0.24, 'mel': 0.44,
                  'kick': 0.4, 'shaker': 0.16},
        'drums': {'kick': [0], 'shaker': [2, 3.5]},
        'reverb_len': 1.9, 'reverb_damp': 3.8, 'reverb_mix': 0.32,
        'delay': (0.28, 0.34, 0.26), 'chorus': True, 'master_lp': 14000,
    }
    save_stereo("wilds_theme_loop.wav", *render_song(wilds))

    # ===================== CAVE : D 小调、阴暗空旷 =====================
    C = ['D', 'D', 'A', 'D', 'A#', 'F', 'A', 'D']
    Q = ['min', 'sus2', 'min7', 'min', 'maj7', 'maj', 'min7', 'sus2']
    cave = {
        'bpm': 66, 'beats_per_bar': 4, 'seed': 9,
        'bars': list(zip(C, Q)),
        'key': ('D', 4), 'scale': [0, 2, 3, 5, 7, 8, 10, 12],
        'pad': choir_pad, 'arp': glocken, 'lead': glocken,
        'pad_oct': 3, 'bass_oct': 2, 'arp_oct': 5, 'lead_oct': 4,
        'gains': {'pad': 0.17, 'bass': 0.5, 'arp': 0.2, 'mel': 0.26},
        'drums': None,
        'reverb_len': 2.8, 'reverb_damp': 2.6, 'reverb_mix': 0.5,
        'delay': (0.42, 0.5, 0.42), 'chorus': True, 'master_lp': 9000,
    }
    save_stereo("cave_theme_loop.wav", *render_song(cave))


if __name__ == "__main__":
    main()
