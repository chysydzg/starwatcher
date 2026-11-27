# Dźwięki scenek satelity: uderzenie młotka w blachę (mody nieharmoniczne cienkiej płyty), grzechotka klucza (seria
# krótkich klików z rezonansem), ryk silnika rakiety (szum brązowy z narastaniem i trzaskiem). Zapis WAV 48 kHz.
import numpy as np, scipy.signal as ss, scipy.io.wavfile as wf, sys, os
sr = 48000
rng = np.random.default_rng(3)
out = sys.argv[1]
def save(name, x):
    x = x / np.abs(x).max() * 10 ** (-3 / 20)
    wf.write(os.path.join(out, name + ".wav"), sr, (x * 32767).astype(np.int16))

# młotek w blachę: krótki szum uderzenia + mody płyty (stosunki jak w cienkiej blasze), szybkie gaśnięcie.
# earshot: AudioSet Clang 0.77, ale opisy CLAP nie pasują ('a metal clang' z +0.8; słyszy werbel/kalimbę);
# wersje z gęstymi modami i z obuchem wypadły gorzej (Clang 0.67 i brak dopasowania)
n = int(0.45 * sr); t = np.arange(n) / sr
hit = rng.normal(0, 1, n) * np.exp(-t / 0.004)
modes = sum(a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * np.exp(-t / d) for f, a, d in
            [(620, 1.0, 0.09), (1130, 0.8, 0.07), (1710, 0.6, 0.05), (2430, 0.5, 0.04), (3360, 0.35, 0.03), (4520, 0.2, 0.02)])
save("metal_hit", 0.6 * ss.lfilter(*ss.butter(2, 6000 / (sr / 2)), hit) + modes)

# grzechotka: 9 klików zapadki co 55 ms, każdy z krótkim metalicznym dźwiękiem
n = int(0.6 * sr); x = np.zeros(n)
for k in range(9):
    i = int((0.03 + k * 0.055 + rng.normal(0, 0.003)) * sr); L = int(0.03 * sr); tt = np.arange(L) / sr
    c = rng.normal(0, 1, L) * np.exp(-tt / 0.0015) + 0.5 * np.sin(2 * np.pi * 3200 * tt) * np.exp(-tt / 0.008)
    x[i:i + L] += c[:n - i]
save("ratchet", ss.lfilter(*ss.butter(2, [900 / (sr / 2), 9000 / (sr / 2)], "band"), x))

# ryk rakiety: brązowy szum, dolnoprzepustowy, narasta przez 1,5 s, trzyma, potem cichnie (odlot), trzask
n = int(7.0 * sr); t = np.arange(n) / sr
brown = np.cumsum(rng.normal(0, 1, n)); brown -= ss.lfilter(*ss.butter(1, 15 / (sr / 2), "high"), brown) * 0 + np.convolve(brown, np.ones(4800) / 4800, "same")
roar = ss.lfilter(*ss.butter(3, 900 / (sr / 2)), brown) + 0.15 * ss.lfilter(*ss.butter(2, [1500 / (sr / 2), 5000 / (sr / 2)], "band"), rng.normal(0, 1, n)) * (rng.random(n) < 0.02)
env = np.clip(t / 1.5, 0, 1) ** 1.5 * np.clip((7.0 - t) / 3.0, 0, 1)
save("rocket", roar * env)
print("ok")
