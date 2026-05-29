"""Q4 -- cross-section sketch of the 15-slot / 8-pole SPMSM (Design 1).

Produces q4_geometry.png used as the geometry illustration in the
EE568 HW2 report.

All radii / widths / angles below come from the Q3 analytical design.
Run from the HW2 folder:  python q4_geometry.py
"""

from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Polygon, Wedge

OUT_DIR = Path(__file__).parent
DPI = 200

plt.rcParams.update({
    "font.family": "serif",
    "font.size": 11,
    "mathtext.fontset": "cm",
    "axes.linewidth": 0.8,
})

# ---------------------------------------------------------------------------
# Design parameters (mm, deg)
# ---------------------------------------------------------------------------
R_so   = 50.0       # stator outer
R_si   = 31.0       # stator inner (bore)
R_ro   = 30.0       # rotor outer (magnet surface)
R_rc   = 26.0       # rotor iron outer (under magnets)
R_sh   = 18.4       # shaft radius (R_rc - w_ry)

w_s    = 4.49       # slot opening (tangential)
h_slot = 11.36      # slot height (radial)

N_s    = 15         # stator slots
N_m    = 8          # rotor magnets
alpha_m_mech = 40.0 # magnet arc, mechanical degrees (160 elec / 4 pp)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def annular_sector(r_in, r_out, theta_start_deg, theta_end_deg, n=64):
    """Return Polygon vertices for an annular sector between two radii
    and two angles (degrees, CCW)."""
    th = np.linspace(np.radians(theta_start_deg),
                     np.radians(theta_end_deg), n)
    outer = np.column_stack([r_out * np.cos(th), r_out * np.sin(th)])
    inner = np.column_stack([r_in  * np.cos(th[::-1]),
                             r_in  * np.sin(th[::-1])])
    return np.vstack([outer, inner])


def slot_polygon(slot_center_deg, w_s_mm, h_mm, r_inner):
    """Return rectangular slot polygon (a slot whose tangential width is
    w_s at the bore and which extends radially outward by h_mm)."""
    # Half tangential angle subtended by w_s at the bore
    half_ang = np.degrees(np.arctan2(w_s_mm / 2, r_inner))
    # Inner bottom-left and bottom-right at r_inner
    th1 = np.radians(slot_center_deg - half_ang)
    th2 = np.radians(slot_center_deg + half_ang)
    p1 = (r_inner * np.cos(th1), r_inner * np.sin(th1))
    p2 = (r_inner * np.cos(th2), r_inner * np.sin(th2))
    # Outer corners: project radially outward by h_mm
    r_out = r_inner + h_mm
    p3 = (r_out * np.cos(th2), r_out * np.sin(th2))
    p4 = (r_out * np.cos(th1), r_out * np.sin(th1))
    return np.array([p1, p2, p3, p4])


# ---------------------------------------------------------------------------
# Figure
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(8.5, 8.5))

# ---- Stator iron (annulus from R_si to R_so, with 15 slot cuts) -----------
stator_outer = Circle((0, 0), R_so, facecolor="0.78",
                      edgecolor="black", lw=0.8, zorder=1)
ax.add_patch(stator_outer)
stator_bore = Circle((0, 0), R_si, facecolor="white",
                     edgecolor="black", lw=0.8, zorder=2)
ax.add_patch(stator_bore)

# Slot polygons (centred on slot 1 at theta = 90 deg / top of figure)
slot_pitch_deg = 360.0 / N_s
slot_centers = [90.0 - (k - 1) * slot_pitch_deg for k in range(1, N_s + 1)]

for k, theta_c in enumerate(slot_centers, start=1):
    poly = slot_polygon(theta_c, w_s, h_slot, R_si)
    ax.add_patch(Polygon(poly, facecolor="#fff2a8",
                         edgecolor="black", lw=0.5, zorder=3))
    # Slot number, just inside the bore
    r_label = R_si - 1.8
    ax.text(r_label * np.cos(np.radians(theta_c)),
            r_label * np.sin(np.radians(theta_c)),
            str(k), ha="center", va="center", fontsize=8, color="0.25",
            zorder=4)

# Air gap (light blue ring just for visibility)
ax.add_patch(Circle((0, 0), R_si, facecolor="#e6f0ff",
                    edgecolor="none", zorder=1.5))
ax.add_patch(Circle((0, 0), R_ro, facecolor="white",
                    edgecolor="none", zorder=1.6))

# ---- Magnets (8 alternating N/S) ------------------------------------------
# Magnet 1 centred at theta = 90 - 22.5 = 67.5 deg (between slots 1 and 2)
# so the d-axis (N magnet centre) aligns with the slot opening of slot ~1
mag_pitch_deg = 360.0 / N_m   # = 45 deg
mag_centers = [90.0 - 22.5 - (k - 1) * mag_pitch_deg
               for k in range(1, N_m + 1)]

mag_colors = []
for k in range(1, N_m + 1):
    is_north = (k % 2 == 1)
    color = "#f4a8a8" if is_north else "#a8b9f4"   # red = N, blue = S
    mag_colors.append((is_north, color))

for (theta_c, (is_north, color)) in zip(mag_centers, mag_colors):
    poly = annular_sector(R_rc, R_ro,
                          theta_c - alpha_m_mech / 2,
                          theta_c + alpha_m_mech / 2)
    ax.add_patch(Polygon(poly, facecolor=color,
                         edgecolor="black", lw=0.6, zorder=2.5))
    # N/S label
    r_lbl = 0.5 * (R_rc + R_ro)
    ax.text(r_lbl * np.cos(np.radians(theta_c)),
            r_lbl * np.sin(np.radians(theta_c)),
            "N" if is_north else "S",
            ha="center", va="center", fontsize=11, fontweight="bold",
            color="black", zorder=3)

# ---- Rotor iron (disk from 0 to R_rc) -------------------------------------
ax.add_patch(Circle((0, 0), R_rc, facecolor="0.60",
                    edgecolor="black", lw=0.8, zorder=2))
# Shaft hole
ax.add_patch(Circle((0, 0), R_sh, facecolor="white",
                    edgecolor="black", lw=0.8, zorder=3))
ax.text(0, 0, "shaft", ha="center", va="center", fontsize=9, color="0.3",
        zorder=4)
ax.text(0, -22, "rotor iron", ha="center", va="center", fontsize=10,
        color="white", zorder=4)

# ---- Dimension callouts ---------------------------------------------------
# R_so callout
ax.annotate(r"$R_{so}=50$ mm",
            xy=(R_so * np.cos(np.radians(-30)),
                R_so * np.sin(np.radians(-30))),
            xytext=(65, -30),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

# R_si callout
ax.annotate(r"$R_{si}=31$ mm",
            xy=(R_si * np.cos(np.radians(-60)),
                R_si * np.sin(np.radians(-60))),
            xytext=(50, -55),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

# R_ro / magnet outer
ax.annotate(r"$R_{ro}=30$ mm",
            xy=(R_ro * np.cos(np.radians(15)),
                R_ro * np.sin(np.radians(15))),
            xytext=(55, 15),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

# Magnet thickness l_m
ax.annotate(r"$l_m=4$ mm",
            xy=(R_rc * np.cos(np.radians(-15)),
                R_rc * np.sin(np.radians(-15))),
            xytext=(45, -10),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

# Air gap g
ax.annotate(r"$g=1$ mm",
            xy=(R_ro * np.cos(np.radians(40)),
                R_ro * np.sin(np.radians(40))),
            xytext=(48, 32),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

# Slot dimensions
ax.annotate(r"$w_s=4.49$ mm",
            xy=(0, R_si + h_slot / 2),
            xytext=(-58, 40),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

ax.annotate(r"$h_{\rm slot}=11.36$ mm",
            xy=(0, R_si + h_slot),
            xytext=(-65, 30),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

# Magnet pole arc / pitch
ax.annotate(r"$\alpha_m=40\degree$ mech ($160\degree$ elec)",
            xy=(0.5 * (R_rc + R_ro) * np.cos(np.radians(67.5)),
                0.5 * (R_rc + R_ro) * np.sin(np.radians(67.5))),
            xytext=(-78, 20),
            arrowprops=dict(arrowstyle="->", lw=0.7), fontsize=10)

# Title
ax.set_title("Design 1 -- 15-slot / 8-pole SPMSM cross-section",
             fontsize=12)

ax.set_xlim(-90, 90)
ax.set_ylim(-80, 80)
ax.set_aspect("equal")
ax.axis("off")

# Legend
from matplotlib.patches import Patch
legend_elems = [
    Patch(facecolor="0.78", edgecolor="black", label="stator iron"),
    Patch(facecolor="0.60", edgecolor="black", label="rotor iron"),
    Patch(facecolor="#f4a8a8", edgecolor="black", label="magnet N"),
    Patch(facecolor="#a8b9f4", edgecolor="black", label="magnet S"),
    Patch(facecolor="#fff2a8", edgecolor="black", label="slot (copper)"),
    Patch(facecolor="#e6f0ff", edgecolor="black", label="air gap"),
]
ax.legend(handles=legend_elems, loc="lower right", fontsize=9,
          framealpha=0.9, ncol=2)

fig.tight_layout()
fig.savefig(OUT_DIR / "q4_geometry.png", dpi=DPI, bbox_inches="tight")
plt.close(fig)

print("Wrote q4_geometry.png")
