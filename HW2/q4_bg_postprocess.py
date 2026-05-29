"""Post-process the no-load parametric sweep exported from ANSYS Maxwell 2D.

The sweep rotates the rotor over one electrical period (rotor_angle = 0..90 deg
mech, 8-pole machine) while observing a stationary probe in the airgap.
At each rotor position, the parametric solve records:

  * B_x, B_y at the probe point  (from a Fields Report)
  * Cogging torque on the rotor  (from a Parameter)

This script projects (B_x, B_y) -> B_r using the constant probe angle in
the lab frame, plots the waveform, FFT, and cogging torque, and prints a
comparison to the analytical Q3 values.

Output figures:
  q4_bg_theta.png     -- B_r vs electrical angle
  q4_bg_fft.png       -- harmonic spectrum (electrical orders)
  q4_cogging.png      -- cogging torque vs mechanical angle
"""

from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

# =========================================================================
#                              Inputs
# =========================================================================
HW2_DIR = Path(__file__).parent
CSV_B   = HW2_DIR / "q4_bfield_sweep.csv"
CSV_T   = HW2_DIR / "q4_cogging_sweep.csv"

# Probe location in the LAB (Global) frame, mm
PROBE_X_MM = -27.6
PROBE_Y_MM =  13.2
ALPHA_PROBE_RAD = np.arctan2(PROBE_Y_MM, PROBE_X_MM)   # lab-frame angle
R_PROBE_MM      = np.hypot(PROBE_X_MM, PROBE_Y_MM)

POLE_PAIRS = 4                # 8 poles
N_POLES   = 8
B_ANALYTICAL_PEAK = 0.989     # T  (Q3 analytical Bg waveform peak with Carter)
MAGNET_ARC_ELEC_DEG = 160.0   # electrical degrees of magnet pole arc
# Analytical fundamental of the rectangular Bg waveform = (4/pi)*sin(alpha_m*pi/2)*Bpeak
B_ANALYTICAL_FUND = (4.0 / np.pi) * np.sin(np.deg2rad(MAGNET_ARC_ELEC_DEG) / 2.0) * B_ANALYTICAL_PEAK
T_ANALYTICAL = 4.85           # Nm (Q3 rated -- for context only; no-load avg is ~0)
PHI_ANALYTICAL = 2.18e-3      # Wb (Q3 analytical flux per pole)

# Machine geometry / winding (from Q3)
R_GAP_M  = 30.5e-3            # m, mid-gap radius
L_E_M    = 102e-3             # m, effective stack length
N_PH     = 20                 # series turns per phase
KW1_ANALYTICAL = 0.9566       # Q2 analytical fundamental winding factor

N_HARM_PLOT = 13              # how many electrical harmonics to show on the bar chart


# =========================================================================
def load_b_csv(path: Path):
    """Return (theta_mech_deg, Bx, By) from the Maxwell parametric CSV.
    Columns: rotor_angle[deg], stator_angle[deg], Bx_probe[T], By_probe[T]."""
    arr = np.loadtxt(path, delimiter=",", skiprows=1)
    theta_mech_deg = arr[:, 0]
    bx = arr[:, 2]
    by = arr[:, 3]
    return theta_mech_deg, bx, by


def load_torque_csv(path: Path):
    """Return (theta_mech_deg, torque_Nm). Strips 'deg' and 'NewtonMeter' suffixes."""
    theta = []
    tau   = []
    with open(path, "r", encoding="utf-8") as f:
        next(f)  # header
        for line in f:
            parts = line.strip().split(",")
            if len(parts) < 3:
                continue
            theta.append(float(parts[1].replace("deg", "")))
            tau.append(  float(parts[2].replace("NewtonMeter", "")))
    return np.array(theta), np.array(tau)


def load_flux_linkage_csv(path: Path):
    """Return (theta_mech_deg, psi_A, psi_B, psi_C) in Wb."""
    theta = []
    psi_a = []
    psi_b = []
    psi_c = []
    with open(path, "r", encoding="utf-8") as f:
        next(f)  # header
        for line in f:
            parts = line.strip().split(",")
            if len(parts) < 6:
                continue
            theta.append(float(parts[1].replace("deg", "")))
            psi_a.append(float(parts[3].replace("Wb", "")))
            psi_b.append(float(parts[4].replace("Wb", "")))
            psi_c.append(float(parts[5].replace("Wb", "")))
    return (np.array(theta), np.array(psi_a),
            np.array(psi_b), np.array(psi_c))


def project_radial(bx, by, alpha_rad):
    return bx * np.cos(alpha_rad) + by * np.sin(alpha_rad)


def flux_per_pole(theta_mech_deg, br):
    """Flux per pole by spatial integration of B_r along the airgap.

    By the rotational symmetry of the no-load problem (the stator is fixed,
    only the rotor rotates), the temporal record of B_r at a stationary
    probe as the rotor sweeps through one electrical period is identical
    to a spatial snapshot of B_r along one electrical-period arc at the
    airgap at a fixed time.  So integrating |B_r| over the 0-90 deg
    rotor-angle range (= 2 pole pitches) and dividing by 2 gives the
    average flux per pole.

        Phi_pole = (1/2) * L_e * R_gap * Integral_{0}^{pi/2} |B_r| dtheta_m
    """
    theta_rad = np.deg2rad(theta_mech_deg)
    integral_abs = np.trapezoid(np.abs(br), theta_rad)        # over 0..pi/2
    n_poles_swept = N_POLES * (theta_mech_deg[-1] - theta_mech_deg[0]) / 360.0
    phi = R_GAP_M * L_E_M * integral_abs / n_poles_swept
    return phi


def fft_electrical(theta_mech_deg, br):
    """FFT in electrical order. Theta sweep covers one full electrical period
    (90 deg mech = 360 deg elec for an 8-pole machine), so the discrete FFT
    bins map directly to electrical harmonic orders k = 1, 2, 3, ..."""
    # Drop the wrap point if rotor_angle ends exactly at 90 deg
    if np.isclose(theta_mech_deg[-1], 90.0):
        theta_mech_deg = theta_mech_deg[:-1]
        br = br[:-1]
    N = len(br)
    fft_c = np.fft.rfft(br)
    amp = 2.0 * np.abs(fft_c) / N
    amp[0] /= 2.0
    return np.arange(len(amp)), amp


def plot_br_vs_theta(theta_mech_deg, br, out_path):
    theta_elec = POLE_PAIRS * theta_mech_deg
    fig, ax = plt.subplots(figsize=(9, 4.3))
    ax.plot(theta_elec, br, lw=1.4, color="#1f4eaf", label="FEA at tooth-tip probe")
    ax.axhline( B_ANALYTICAL_PEAK, ls="--", color="0.45",
                label=fr"Analytical peak $\hat B_g={B_ANALYTICAL_PEAK}$ T (Carter avg.)")
    ax.axhline(-B_ANALYTICAL_PEAK, ls="--", color="0.45")
    ax.set_xlabel(r"Electrical angle $\theta_e$ (deg)")
    ax.set_ylabel(r"Radial flux density $B_r$ (T)")
    ax.set_title("Mid-gap air-gap flux density at a stator-fixed tooth-tip probe")
    ax.set_xlim(0, 360)
    ax.set_xticks(np.arange(0, 361, 45))
    ax.grid(alpha=0.3)
    ax.legend(loc="upper right", fontsize=10)
    fig.tight_layout()
    fig.savefig(out_path, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {out_path}")


def plot_harmonics(orders, amplitudes, out_path):
    fig, ax = plt.subplots(figsize=(8, 4.3))
    n_show = min(N_HARM_PLOT, len(amplitudes) - 1)
    bars = ax.bar(orders[:n_show + 1], amplitudes[:n_show + 1],
                  color="#1f4eaf", width=0.7)
    if len(bars) > 1:
        bars[1].set_color("#d73027")     # electrical fundamental
        ax.text(1, amplitudes[1], f"{amplitudes[1]:.3f} T",
                ha="center", va="bottom", fontsize=10)
    ax.axhline(B_ANALYTICAL_FUND, ls="--", color="0.45",
               label=(rf"Analytical fundamental "
                      rf"$(4/\pi)\sin(\alpha_m/2)\hat B_g={B_ANALYTICAL_FUND:.3f}$ T"))
    ax.set_xlabel("Electrical harmonic order")
    ax.set_ylabel("Amplitude (T)")
    ax.set_title(r"Harmonic spectrum of $B_r(\theta_e)$")
    ax.set_xticks(orders[:n_show + 1])
    ax.grid(alpha=0.3, axis="y")
    ax.legend(loc="upper right", fontsize=10)
    fig.tight_layout()
    fig.savefig(out_path, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {out_path}")


def plot_flux_linkages(theta_mech_deg, psi_a, psi_b, psi_c, out_path):
    """Plot the three phase flux linkages over one electrical period.
    Each is plotted both raw (with whatever DC offset Maxwell stores) and
    relative to its own mean -- the AC part is the physically meaningful
    rotor-driven linkage."""
    theta_e = POLE_PAIRS * theta_mech_deg

    fig, ax = plt.subplots(figsize=(9, 4.3))
    for name, psi, color in [
        ("$\\psi_A$", psi_a, "#1f4eaf"),
        ("$\\psi_B$", psi_b, "#d73027"),
        ("$\\psi_C$", psi_c, "#2ca25f"),
    ]:
        ax.plot(theta_e, (psi - psi.mean()) * 1e3, lw=1.4,
                color=color, label=name)
    ax.set_xlabel(r"Electrical angle $\theta_e$ (deg)")
    ax.set_ylabel("Phase flux linkage (mWb), AC component")
    ax.set_title("No-load magnet flux linkage per phase (DC offset removed)")
    ax.set_xlim(0, 360)
    ax.set_xticks(np.arange(0, 361, 45))
    ax.axhline(0, ls=":", color="0.4")
    ax.grid(alpha=0.3)
    ax.legend(loc="upper right", fontsize=10, ncol=3)
    fig.tight_layout()
    fig.savefig(out_path, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {out_path}")


def winding_factor_from_psi_and_bg(psi_fund_peak_Wb, b_fund_T):
    """Back-calculate k_w,1 from FEA fundamental flux linkage and fundamental Bg.

    For a sinusoidal radial flux density at the airgap with fundamental
    peak B_g,1, the flux through one pole pitch is:
        Phi_pole,1 = 2 * B_g,1 * R_gap * L_e / p
    The peak phase flux linkage on harmonic 1 is:
        psi_A,1_peak = N_ph * k_w,1 * Phi_pole,1
    Hence:
        k_w,1 = psi_A,1_peak / (N_ph * Phi_pole,1)
    """
    phi_pole_1 = 2.0 * b_fund_T * R_GAP_M * L_E_M / POLE_PAIRS
    return psi_fund_peak_Wb / (N_PH * phi_pole_1), phi_pole_1


def plot_cogging(theta_mech_deg, tau_Nm, out_path):
    fig, ax = plt.subplots(figsize=(9, 4.3))
    ax.plot(theta_mech_deg, tau_Nm * 1e3, lw=1.4, color="#1f4eaf", label="FEA cogging")
    ax.axhline(0, ls=":", color="0.4")
    ax.set_xlabel(r"Mechanical angle $\theta_m$ (deg)")
    ax.set_ylabel("Cogging torque (mN$\\cdot$m)")
    pp = (tau_Nm.max() - tau_Nm.min()) * 1e3
    ax.set_title(f"No-load cogging torque (peak-to-peak {pp:.2f} mN$\\cdot$m, "
                 f"{100*pp*1e-3/T_ANALYTICAL:.2f}% of rated)")
    ax.set_xlim(0, 90)
    ax.set_xticks(np.arange(0, 91, 15))
    ax.grid(alpha=0.3)
    ax.legend(loc="upper right", fontsize=10)
    fig.tight_layout()
    fig.savefig(out_path, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {out_path}")


# =========================================================================
if __name__ == "__main__":
    print(f"Probe at ({PROBE_X_MM}, {PROBE_Y_MM}) mm  ->  "
          f"r = {R_PROBE_MM:.3f} mm,  alpha = {np.degrees(ALPHA_PROBE_RAD):.3f} deg")
    print(f"Projection coeffs:  cos(alpha) = {np.cos(ALPHA_PROBE_RAD):+.4f},  "
          f"sin(alpha) = {np.sin(ALPHA_PROBE_RAD):+.4f}")
    print()

    # ---- B field --------------------------------------------------------
    theta_mech_deg, bx, by = load_b_csv(CSV_B)
    br = project_radial(bx, by, ALPHA_PROBE_RAD)

    print(f"|B|_peak at probe   : {np.hypot(bx, by).max():.4f} T")
    print(f"B_r peak (positive) : {br.max():+.4f} T")
    print(f"B_r peak (negative) : {br.min():+.4f} T")
    print()

    plot_br_vs_theta(theta_mech_deg, br, HW2_DIR / "q4_bg_theta.png")

    orders, amps = fft_electrical(theta_mech_deg, br)
    plot_harmonics(orders, amps, HW2_DIR / "q4_bg_fft.png")

    print(" k | amplitude (T) | comment")
    print("---+---------------+----------------------")
    for n in range(min(N_HARM_PLOT + 1, len(amps))):
        comment = ""
        if n == 0:
            comment = "DC (should be ~0)"
        elif n == 1:
            comment = "<- electrical fundamental"
        elif n in (3, 5, 7):
            comment = "magnet shape odd harmonic"
        elif n == 15:
            comment = "slot-pole interaction"
        print(f" {n:2d}|  {amps[n]:11.4f}  | {comment}")

    print()
    fea_peak = max(br.max(), -br.min())
    print("---- Comparison to analytical (Q3) ----")
    print(f"Waveform peak (flat-top of square-wave shape):")
    print(f"   FEA at tooth-tip probe :  {fea_peak:.4f} T")
    print(f"   Analytical (Carter avg.):  {B_ANALYTICAL_PEAK:.4f} T")
    print(f"   Difference              :  {100*(fea_peak-B_ANALYTICAL_PEAK)/B_ANALYTICAL_PEAK:+.2f}%   "
          f"(tooth-tip reads above spatial average)")
    print()
    print(f"Fundamental Fourier component of Bg(theta_e):")
    print(f"   FEA                     :  {amps[1]:.4f} T")
    print(f"   Analytical (4/pi)*sin(am/2)*Bpeak : {B_ANALYTICAL_FUND:.4f} T")
    print(f"   Difference              :  {100*(amps[1]-B_ANALYTICAL_FUND)/B_ANALYTICAL_FUND:+.2f}%")
    print()

    # ---- Cogging torque -------------------------------------------------
    theta_t, tau = load_torque_csv(CSV_T)
    plot_cogging(theta_t, tau, HW2_DIR / "q4_cogging.png")

    print(f"Cogging torque, peak-to-peak : {(tau.max()-tau.min())*1e3:.3f} mN.m")
    print(f"Cogging RMS                  : {np.std(tau)*1e3:.3f} mN.m")
    print(f"Rated torque (analytical)    : {T_ANALYTICAL*1e3:.1f} mN.m")
    print(f"Cogging p-p / rated          : {100*(tau.max()-tau.min())/T_ANALYTICAL:.3f} %")

    # ---- Flux per pole --------------------------------------------------
    phi_fea = flux_per_pole(theta_mech_deg, br)
    print()
    print("---- Flux per pole (mid-gap spatial integration) ----")
    print(f"FEA       : {phi_fea*1e3:.4f} mWb")
    print(f"Analytical: {PHI_ANALYTICAL*1e3:.4f} mWb")
    print(f"Difference: {100*(phi_fea-PHI_ANALYTICAL)/PHI_ANALYTICAL:+.2f}%")
