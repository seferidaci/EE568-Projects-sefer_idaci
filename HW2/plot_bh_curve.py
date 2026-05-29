"""Plot the M19_24G non-linear B-H curve loaded into Maxwell."""

from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt

HW2_DIR = Path(__file__).parent
TAB = HW2_DIR / "M19_24G_BH.tab"
OUT = HW2_DIR / "q4_bh_curve.png"

# H_MAX = 6366 to plot up to the last point before the saturated tail.
H_MAX = 6366.0

data = np.genfromtxt(TAB, skip_header=1)
H, B = data[:, 0], data[:, 1]
mask = H <= H_MAX + 1e-6
H, B = H[mask], B[mask]

fig, ax = plt.subplots(figsize=(7, 4.2))
ax.plot(H, B, "o-", color="#1f4eaf", lw=1.5, markersize=5)
ax.axhline(1.4, ls="--", color="0.4", lw=1.0)
ax.text(H_MAX * 0.98, 1.42, "knee ~1.4 T",
        ha="right", va="bottom", fontsize=9, color="0.4")
ax.set_xlim(0, H_MAX)
ax.set_ylim(0, 2.0)
ax.set_xlabel(r"$H$ (A/m)")
ax.set_ylabel(r"$B$ (T)")
ax.set_title("M19$\\_$24G B--H curve loaded into Maxwell")
ax.grid(True, which="both", alpha=0.3)
fig.tight_layout()
fig.savefig(OUT, dpi=200, bbox_inches="tight")
print(f"Wrote {OUT}")
