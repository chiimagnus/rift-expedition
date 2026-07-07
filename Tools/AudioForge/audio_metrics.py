#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rift Expedition — 音频客观度量（行业标准算法，纯 numpy 实现）。

本模块是生成器（归一化）与测试（验证）的**单一真相源**，所有度量均按公开标准/算法实现，
以便在无法 pip 安装 librosa/pyloudnorm/scipy 的环境里仍能做专业级检验。
测试层会优先调用 pyloudnorm/librosa（若已安装），否则回退到本模块。

标准依据：
  - 响度 LUFS：ITU-R BS.1770-4 / EBU R128（K-weighting 双级滤波 + 门限积分）
      滤波器参数（fc/Q/gain）采用 pyloudnorm 同款常量，用 RBJ Audio-EQ-Cookbook
      双二阶公式按目标采样率现算系数。
  - 真峰值 True Peak（dBTP）：ITU-R BS.1770 附录2，≥ 4x 过采样后取峰。
  - 调性检测：Krumhansl-Schmuckler key-finding（24 调 profile 相关）。

依赖：numpy。
"""
from __future__ import annotations
import numpy as np

__all__ = [
    "k_weight", "integrated_lufs", "true_peak_dbtp", "true_peak_stereo",
    "chroma", "detect_key", "detect_key_from_chroma",
    "KS_MAJOR", "KS_MINOR", "NOTE_NAMES",
]

NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

# ----------------------------------------------------------------------------
# ITU-R BS.1770-4 K-weighting —— RBJ biquad，pyloudnorm 同款 fc/Q/gain 常量
# ----------------------------------------------------------------------------
_SHELF = dict(fc=1681.9744509555319, Q=0.7071752369554193, gaindb=3.999843853973347)
_HPF = dict(fc=38.13547087602444, Q=0.5003270373238773)


def _biquad(x, b, a):
    """Direct-form I 双二阶 IIR（无 scipy 依赖）。"""
    b0, b1, b2 = (c / a[0] for c in b)
    a1, a2 = a[1] / a[0], a[2] / a[0]
    y = np.empty_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i in range(len(x)):
        xi = x[i]
        yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, xi
        y2, y1 = y1, yi
        y[i] = yi
    return y


def _high_shelf(fs, fc, Q, gaindb):
    A = 10 ** (gaindb / 40.0)
    w0 = 2 * np.pi * fc / fs
    c, al = np.cos(w0), np.sin(w0) / (2 * Q)
    sq = 2 * np.sqrt(A) * al
    b = [A * ((A + 1) + (A - 1) * c + sq),
         -2 * A * ((A - 1) + (A + 1) * c),
         A * ((A + 1) + (A - 1) * c - sq)]
    a = [(A + 1) - (A - 1) * c + sq,
         2 * ((A - 1) - (A + 1) * c),
         (A + 1) - (A - 1) * c - sq]
    return b, a


def _high_pass(fs, fc, Q):
    w0 = 2 * np.pi * fc / fs
    c, al = np.cos(w0), np.sin(w0) / (2 * Q)
    b = [(1 + c) / 2, -(1 + c), (1 + c) / 2]
    a = [1 + al, -2 * c, 1 - al]
    return b, a


def k_weight(x, fs):
    """BS.1770 K-weighting：高架预滤波 + RLB 高通。"""
    x = np.asarray(x, dtype=np.float64)
    b1, a1 = _high_shelf(fs, **_SHELF)
    b2, a2 = _high_pass(fs, **_HPF)
    return _biquad(_biquad(x, b1, a1), b2, a2)


def integrated_lufs(L, R, fs):
    """ITU-R BS.1770-4 门限积分响度（LUFS），立体声。

    400ms 块 / 75% 重叠；绝对门限 -70 LUFS；相对门限 -10 LU。
    """
    yL, yR = k_weight(L, fs), k_weight(R, fs)
    T, step = int(0.4 * fs), int(0.1 * fs)
    if len(yL) < T:
        return -np.inf
    zs = np.array([(yL[i:i + T] ** 2).mean() + (yR[i:i + T] ** 2).mean()
                   for i in range(0, len(yL) - T + 1, step)])
    loud = -0.691 + 10 * np.log10(zs + 1e-12)
    g1 = zs[loud >= -70.0]                       # 绝对门限
    if len(g1) == 0:
        return -np.inf
    Lg = -0.691 + 10 * np.log10(g1.mean())
    g2 = g1[(-0.691 + 10 * np.log10(g1 + 1e-12)) >= Lg - 10.0]  # 相对门限
    if len(g2) == 0:
        return Lg
    return -0.691 + 10 * np.log10(g2.mean())


def true_peak_dbtp(x, oversample=4):
    """True Peak（dBTP）：FFT sinc 过采样后取峰（BS.1770 附录2）。

    返回 (dBTP, 线性真峰)。
    """
    x = np.asarray(x, dtype=np.float64)
    N = len(x)
    if N == 0:
        return -np.inf, 0.0
    X = np.fft.rfft(x)
    Y = np.zeros(N * oversample // 2 + 1, dtype=complex)
    Y[:len(X)] = X
    up = np.fft.irfft(Y, n=N * oversample) * oversample
    pk = float(np.max(np.abs(up)))
    return 20 * np.log10(pk + 1e-12), pk


def true_peak_stereo(L, R, oversample=4):
    return max(true_peak_dbtp(L, oversample)[0], true_peak_dbtp(R, oversample)[0])


# ----------------------------------------------------------------------------
# Krumhansl-Schmuckler 调性检测
# ----------------------------------------------------------------------------
KS_MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
                     2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
KS_MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
                     2.54, 4.75, 3.98, 2.69, 3.34, 3.17])


def chroma(mono, fs, N=8192, hop=4096, fmin=55.0, fmax=2000.0):
    """12 维 pitch-class 分布（C=0），Hann 窗 STFT 映射到半音。

    用**幅度谱**（非能量）并限制到基频段，降低泛音（五度/三度）泄漏
    对调性判定的干扰——与 librosa chroma_cqt/CENS 降泛音敏感度的动机一致。
    """
    mono = np.asarray(mono, dtype=np.float64)
    win = np.hanning(N)
    fr = np.fft.rfftfreq(N, 1.0 / fs)
    band = (fr >= fmin) & (fr <= fmax)
    pc = np.full(len(fr), -1)
    v = fr > 25.0
    pc[v] = np.mod(np.round(69 + 12 * np.log2(fr[v] / 440.0)).astype(int), 12)
    acc = np.zeros(12)
    for i in range(0, max(1, len(mono) - N), hop):
        mag = np.abs(np.fft.rfft(mono[i:i + N] * win)) * band
        for c in range(12):
            acc[c] += mag[pc == c].sum()
    s = acc.sum()
    return acc / s if s > 0 else acc


def _corr(a, b):
    a = a - a.mean()
    b = b - b.mean()
    return float((a * b).sum() / (np.sqrt((a * a).sum() * (b * b).sum()) + 1e-12))


def detect_key_from_chroma(ch):
    """返回 (key_name, confidence)，如 ('C major', 0.83)。"""
    best = (-9.0, '')
    for i in range(12):
        cm = _corr(ch, np.roll(KS_MAJOR, i))
        if cm > best[0]:
            best = (cm, f'{NOTE_NAMES[i]} major')
        cn = _corr(ch, np.roll(KS_MINOR, i))
        if cn > best[0]:
            best = (cn, f'{NOTE_NAMES[i]} minor')
    return best[1], best[0]


def detect_key(mono, fs):
    return detect_key_from_chroma(chroma(mono, fs))
