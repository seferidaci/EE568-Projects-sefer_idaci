"""Schematic diagrams for the Q3 analytical-modelling section.

Produces three PNGs used in the EE568 HW2 report:
    q3_geometry_sketch.png  -- developed slot/tooth/magnet geometry
    q3_mec.png              -- 1D magnetic equivalent circuit
    q3_flux_funnel.png      -- flux funnelling from slot pitch into tooth

Run from the HW2 folder:  python q3_diagrams.py
"""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Polygon, Rectangle

OUT_DIR = Path(__file__).parent
DPI = 200

plt.rcParams.update({
    "font.family": "serif",
    "font.size": 16,
    "mathtext.fontset": "cm",
    "axes.linewidth": 0.8,
})


# ---------------------------------------------------------------------------
# 1.  Slot / tooth geometry (developed view)
# ---------------------------------------------------------------------------
def geometry_sketch():
    fig, ax = plt.subplots(figsize=(9.0, 5.6))

    # Layers (y-extents)
    rotor_y  = (-0.9,  0.0)
    magnet_y = ( 0.0,  1.2)
    airgap_y = ( 1.2,  1.5)
    teeth_y  = ( 1.5,  3.0)
    yoke_y   = ( 3.0,  3.6)

    x_left, x_right = -4.2, 4.2

    # Stator yoke (label placed on the right side, outside the body)
    ax.add_patch(Rectangle((x_left, yoke_y[0]), x_right - x_left,
                           yoke_y[1] - yoke_y[0], facecolor="0.75",
                           edgecolor="black", lw=0.8))
    ax.annotate("stator yoke", xy=(x_right, 0.5 * (yoke_y[0] + yoke_y[1])),
                xytext=(x_right + 0.6, 0.5 * (yoke_y[0] + yoke_y[1])),
                ha="left", va="center", fontsize=15,
                arrowprops=dict(arrowstyle="-", lw=0.6))

    # Teeth + slot (linearised view over one slot pitch centred on x=0)
    slot_half  = 0.75   # half slot opening width
    tau_half   = 2.10   # half slot pitch (tooth-centre to tooth-centre)

    # Left tooth (extends from x_left up to slot edge)
    ax.add_patch(Rectangle((-3.5, teeth_y[0]), 3.5 - slot_half,
                           teeth_y[1] - teeth_y[0],
                           facecolor="0.88", edgecolor="black", lw=0.8))
    # Slot
    ax.add_patch(Rectangle((-slot_half, teeth_y[0]), 2 * slot_half,
                           teeth_y[1] - teeth_y[0],
                           facecolor="#fff2a8", edgecolor="black", lw=0.8))
    # Right tooth
    ax.add_patch(Rectangle((slot_half, teeth_y[0]), 3.5 - slot_half,
                           teeth_y[1] - teeth_y[0],
                           facecolor="0.88", edgecolor="black", lw=0.8))

    # Tooth / slot labels (inside the bodies)
    ax.text(-2.1, 2.25, "tooth", ha="center", va="center", fontsize=15)
    ax.text(0.0,  2.25, "slot",  ha="center", va="center", fontsize=15)
    ax.text( 2.1, 2.25, "tooth", ha="center", va="center", fontsize=15)

    # Tooth-centre dashed guide lines (to anchor the slot pitch dimension)
    for x in (-tau_half, tau_half):
        ax.plot([x, x], [teeth_y[0], 4.55], linestyle=":",
                color="0.45", lw=0.7)

    # Air gap
    ax.add_patch(Rectangle((x_left, airgap_y[0]), x_right - x_left,
                           airgap_y[1] - airgap_y[0],
                           facecolor="#d6e7ff", edgecolor="black", lw=0.4))
    ax.annotate("air gap $g$", xy=(x_right, 0.5 * (airgap_y[0] + airgap_y[1])),
                xytext=(x_right + 0.6, 0.5 * (airgap_y[0] + airgap_y[1])),
                ha="left", va="center", fontsize=15,
                arrowprops=dict(arrowstyle="-", lw=0.6))

    # Magnet
    ax.add_patch(Rectangle((x_left, magnet_y[0]), x_right - x_left,
                           magnet_y[1] - magnet_y[0],
                           facecolor="#f4c6c6", edgecolor="black", lw=0.8))
    ax.text(0, 0.5 * (magnet_y[0] + magnet_y[1]),
            r"Magnet  ($B_r$, $l_m$, $\mu_r$)",
            ha="center", va="center")

    # Rotor core
    ax.add_patch(Rectangle((x_left, rotor_y[0]), x_right - x_left,
                           rotor_y[1] - rotor_y[0],
                           facecolor="0.55", edgecolor="black", lw=0.8))
    ax.text(0, 0.5 * (rotor_y[0] + rotor_y[1]), "rotor core",
            ha="center", va="center", color="white")

    # ---- Dimensions stacked ABOVE the yoke (no collision) ----
    # Row 1 (closest to yoke): w_tb/2, w_s, w_tb/2  at y_dim1
    # Row 2 (above row 1):     slot pitch tau_s    at y_dim2
    y_dim1 = 3.85
    y_dim2 = 4.45

    # w_s above the slot
    ax.annotate("", xy=(-slot_half, y_dim1), xytext=(slot_half, y_dim1),
                arrowprops=dict(arrowstyle="<->", lw=0.9))
    ax.text(0, y_dim1 + 0.08, r"$w_s$", ha="center", va="bottom", fontsize=15)

    # w_tb/2 on each side
    ax.annotate("", xy=(-tau_half, y_dim1), xytext=(-slot_half, y_dim1),
                arrowprops=dict(arrowstyle="<->", lw=0.9))
    ax.text((-tau_half - slot_half) / 2, y_dim1 + 0.08, r"$w_{tb}/2$",
            ha="center", va="bottom", fontsize=15)

    ax.annotate("", xy=(slot_half, y_dim1), xytext=(tau_half, y_dim1),
                arrowprops=dict(arrowstyle="<->", lw=0.9))
    ax.text((tau_half + slot_half) / 2, y_dim1 + 0.08, r"$w_{tb}/2$",
            ha="center", va="bottom", fontsize=15)

    # Slot pitch tau_s on top
    ax.annotate("", xy=(-tau_half, y_dim2), xytext=(tau_half, y_dim2),
                arrowprops=dict(arrowstyle="|-|", lw=1.0))
    ax.text(0, y_dim2 + 0.12, r"slot pitch $\tau_s$",
            ha="center", va="bottom", fontsize=17)

    # g and l_m dimensions on the left, outside the body
    ax.annotate("", xy=(-4.55, airgap_y[0]), xytext=(-4.55, airgap_y[1]),
                arrowprops=dict(arrowstyle="<->", lw=0.9))
    ax.text(-4.75, 0.5 * (airgap_y[0] + airgap_y[1]), "$g$",
            ha="right", va="center", fontsize=15)

    ax.annotate("", xy=(-4.55, magnet_y[0]), xytext=(-4.55, magnet_y[1]),
                arrowprops=dict(arrowstyle="<->", lw=0.9))
    ax.text(-4.75, 0.5 * (magnet_y[0] + magnet_y[1]), "$l_m$",
            ha="right", va="center", fontsize=15)

    # R_si callout (anchored at bore line on the right)
    ax.annotate("bore $R_{si}$", xy=(x_right, airgap_y[1]),
                xytext=(x_right + 0.6, airgap_y[1] + 0.4),
                arrowprops=dict(arrowstyle="->", lw=0.8),
                ha="left", va="center", fontsize=15)

    ax.set_xlim(-5.5, 6.5)
    ax.set_ylim(-1.2, 5.0)
    ax.set_aspect("equal")
    ax.axis("off")

    fig.tight_layout()
    fig.savefig(OUT_DIR / "q3_geometry_sketch.png", dpi=DPI,
                bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------------------
# 2.  1D magnetic equivalent circuit
# ---------------------------------------------------------------------------
def mec_circuit():
    fig, ax = plt.subplots(figsize=(7.5, 4.6))

    # Coordinates of the circuit nodes
    x_m, x_g = 1.0, 4.5
    y_bot, y_top = 0.0, 3.3
    y_src_bot, y_src_top = 0.4, 1.0
    y_rm_bot, y_rm_top   = 1.4, 2.3
    y_rg_bot, y_rg_top   = 1.4, 2.3

    # Top yoke (short)
    ax.plot([x_m, x_g], [y_top, y_top], color="black", lw=1.4)
    ax.text(0.5 * (x_m + x_g), y_top + 0.08,
            r"stator yoke  ($\mathcal{R}_{Fe}\!\to\!0$)",
            ha="center", va="bottom", fontsize=15)

    # Bottom yoke (short)
    ax.plot([x_m, x_g], [y_bot, y_bot], color="black", lw=1.4)
    ax.text(0.5 * (x_m + x_g), y_bot - 0.12,
            r"rotor core  ($\mathcal{R}_{Fe}\!\to\!0$)",
            ha="center", va="top", fontsize=15)

    # ---- Magnet branch (left) ----
    # Wire from bottom up to MMF source
    ax.plot([x_m, x_m], [y_bot, y_src_bot], color="black", lw=1.2)
    # Battery: long line (+) and short line (-)
    ax.plot([x_m - 0.30, x_m + 0.30], [y_src_bot + 0.25] * 2,
            color="black", lw=1.6)
    ax.plot([x_m - 0.15, x_m + 0.15], [y_src_bot + 0.45] * 2,
            color="black", lw=1.6)
    ax.text(x_m - 0.45, y_src_bot + 0.35, "$B_r$", ha="right",
            va="center", fontsize=17)
    # Wire from source up to R_m
    ax.plot([x_m, x_m], [y_src_top, y_rm_bot], color="black", lw=1.2)
    # R_m box
    ax.add_patch(Rectangle((x_m - 0.30, y_rm_bot), 0.60,
                           y_rm_top - y_rm_bot, facecolor="white",
                           edgecolor="black", lw=1.2))
    ax.text(x_m, 0.5 * (y_rm_bot + y_rm_top), r"$\mathcal{R}_m$",
            ha="center", va="center")
    ax.text(x_m + 0.45, 0.5 * (y_rm_bot + y_rm_top),
            r"$=\dfrac{l_m}{\mu_0\mu_r A}$",
            ha="left", va="center", fontsize=15)
    # Wire from R_m to top yoke
    ax.plot([x_m, x_m], [y_rm_top, y_top], color="black", lw=1.2)

    # Vertical label "magnet branch"
    ax.text(x_m - 1.7, 0.5 * (y_bot + y_top), "magnet",
            ha="center", va="center", rotation=90, fontsize=15,
            color="0.35")

    # ---- Air-gap branch (right) ----
    ax.plot([x_g, x_g], [y_top, y_rg_top], color="black", lw=1.2)
    ax.add_patch(Rectangle((x_g - 0.30, y_rg_bot), 0.60,
                           y_rg_top - y_rg_bot, facecolor="white",
                           edgecolor="black", lw=1.2))
    ax.text(x_g, 0.5 * (y_rg_bot + y_rg_top), r"$\mathcal{R}_g$",
            ha="center", va="center")
    ax.text(x_g + 0.45, 0.5 * (y_rg_bot + y_rg_top),
            r"$=\dfrac{g}{\mu_0 A}$",
            ha="left", va="center", fontsize=15)
    ax.plot([x_g, x_g], [y_rg_bot, y_bot], color="black", lw=1.2)

    ax.text(x_g + 2.3, 0.5 * (y_bot + y_top), "air gap",
            ha="center", va="center", rotation=90, fontsize=15,
            color="0.35")

    # Flux arrow along the top yoke
    arrow = FancyArrowPatch((x_m + 0.6, y_top - 0.18),
                            (x_g - 0.6, y_top - 0.18),
                            arrowstyle="-|>", mutation_scale=15,
                            color="#1f4eaf", lw=2.0)
    ax.add_patch(arrow)
    ax.text(0.5 * (x_m + x_g), y_top - 0.42, r"$\Phi$",
            ha="center", va="center", color="#1f4eaf", fontsize=18)

    # Divider equation off to the side
    ax.text(0.5 * (x_m + x_g), -0.85,
            r"$\dfrac{B_g}{B_r}"
            r"=\dfrac{\mathcal{R}_m}{\mathcal{R}_m+\mathcal{R}_g}"
            r"=\dfrac{l_m}{l_m+\mu_r g}$",
            ha="center", va="top", fontsize=17)

    ax.set_xlim(-1.2, 8.0)
    ax.set_ylim(-1.6, 4.0)
    ax.set_aspect("equal")
    ax.axis("off")

    fig.tight_layout()
    fig.savefig(OUT_DIR / "q3_mec.png", dpi=DPI, bbox_inches="tight")
    plt.close(fig)


# ---------------------------------------------------------------------------
# 3.  Flux funnelling into one tooth
# ---------------------------------------------------------------------------
def flux_funnel():
    fig, ax = plt.subplots(figsize=(7.5, 5.2))

    # Geometry parameters (in arbitrary plot units)
    tau_s_half  = 3.0
    w_tb_half   = 0.95
    y_band_bot, y_band_top = 2.4, 2.9
    y_funnel_bot, y_funnel_top = 0.6, 2.4
    y_tooth_bot, y_tooth_top   = -1.4, 0.6

    # Air-gap band (slot pitch wide, B_g,avg)
    ax.add_patch(Rectangle((-tau_s_half, y_band_bot),
                           2 * tau_s_half,
                           y_band_top - y_band_bot,
                           facecolor="#d6e7ff",
                           edgecolor="black", lw=0.8))

    # Slot pitch brace + label
    ax.annotate("", xy=(-tau_s_half, y_band_top + 0.4),
                xytext=(tau_s_half, y_band_top + 0.4),
                arrowprops=dict(arrowstyle="|-|", lw=1.0))
    ax.text(0, y_band_top + 0.55,
            r"one slot pitch $\tau_s$  (flux density $B_{g,\mathrm{avg}}$)",
            ha="center", va="bottom")

    # Downward flux arrows over the full slot pitch
    for x in [-2.7, -2.1, -1.5, -0.9, -0.3, 0.3, 0.9, 1.5, 2.1, 2.7]:
        arrow = FancyArrowPatch((x, y_band_top - 0.05),
                                (x, y_band_bot + 0.05),
                                arrowstyle="-|>", mutation_scale=10,
                                color="#1f4eaf", lw=1.4)
        ax.add_patch(arrow)

    # Funnel (gray flux-collecting region)
    funnel = Polygon([(-tau_s_half, y_band_bot),
                      (-w_tb_half, y_funnel_bot),
                      (w_tb_half,  y_funnel_bot),
                      (tau_s_half, y_band_bot)],
                     closed=True, facecolor="0.88",
                     edgecolor="black", lw=0.9)
    ax.add_patch(funnel)

    # Tooth body
    ax.add_patch(Rectangle((-w_tb_half, y_tooth_bot),
                           2 * w_tb_half,
                           y_tooth_top - y_tooth_bot,
                           facecolor="0.82",
                           edgecolor="black", lw=0.9))

    # Flux arrows inside the tooth (thicker, fewer) -- stop above the label
    arrow_tip_y = -0.3
    for x in [-0.5, -0.15, 0.15, 0.5]:
        arrow = FancyArrowPatch((x, y_funnel_bot - 0.05),
                                (x, arrow_tip_y),
                                arrowstyle="-|>", mutation_scale=14,
                                color="#1f4eaf", lw=2.0)
        ax.add_patch(arrow)

    # "tooth (B_t)" label placed BELOW the arrows
    ax.text(0, y_tooth_bot + 0.35, r"tooth  ($B_t$)",
            ha="center", va="center", fontsize=17)

    # w_tb dimension below the tooth
    y_w = y_tooth_bot - 0.25
    ax.annotate("", xy=(-w_tb_half, y_w),
                xytext=(w_tb_half, y_w),
                arrowprops=dict(arrowstyle="<->", lw=1.0))
    ax.text(0, y_w - 0.15, r"$w_{tb}$", ha="center", va="top")

    # Side labels "slot" on either side of the funnel
    ax.text(-2.0, 1.4, "slot", ha="center", va="center", fontsize=15,
            color="0.35")
    ax.text( 2.0, 1.4, "slot", ha="center", va="center", fontsize=15,
            color="0.35")

    # Conservation equation
    ax.text(0, -2.4,
            r"$B_{g,\mathrm{avg}}\cdot\tau_s \;=\; B_t\cdot w_{tb}$"
            r"   (flux conservation)",
            ha="center", va="center", fontsize=17)

    ax.set_xlim(-4.0, 4.0)
    ax.set_ylim(-3.0, 4.0)
    ax.set_aspect("equal")
    ax.axis("off")

    fig.tight_layout()
    fig.savefig(OUT_DIR / "q3_flux_funnel.png", dpi=DPI,
                bbox_inches="tight")
    plt.close(fig)


if __name__ == "__main__":
    geometry_sketch()
    mec_circuit()
    flux_funnel()
    print("Wrote q3_geometry_sketch.png, q3_mec.png, q3_flux_funnel.png")
