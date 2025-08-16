# Example Mandelbrot Generated Simulation.
# By: Brilliant G Purnawan

import numpy as np
import matplotlib.pyplot as plt

# Image Parameters
W, H = 500, 500          # image width, height (px)
MAX_ITER = 200           # more iterations = sharper boundary detail
RE_MIN, RE_MAX = -2.5, 1.0
IM_MIN, IM_MAX = -1.2, 1.2

# Generate pixel grid mapped to complex plane
re = np.linspace(RE_MIN, RE_MAX, W)
im = np.linspace(IM_MIN, IM_MAX, H)
R, I = np.meshgrid(re, im)
C = R + 1j * I

# Escape-time iteration
Z = np.zeros_like(C, dtype=np.complex128)
iters = np.zeros(C.shape, dtype=int)
mask = np.ones(C.shape, dtype=bool)

for n in range(1, MAX_ITER + 1):
    Z[mask] = Z[mask] * Z[mask] + C[mask]
    escaped = np.greater(np.abs(Z), 2, where=mask)
    iters[escaped & mask] = n
    mask &= ~escaped
    if not mask.any():
        break

img = iters

# Plot & save
plt.figure(figsize=(8, 6), dpi=100)
plt.imshow(img, extent=[RE_MIN, RE_MAX, IM_MIN, IM_MAX], origin='lower')
plt.title("Mandelbrot Set (escape-time visualisation)")
plt.xlabel("Re(c)")
plt.ylabel("Im(c)")
plt.axis('off')
plt.tight_layout()
plt.savefig("mandelbrot.png", dpi=200)
plt.show()
