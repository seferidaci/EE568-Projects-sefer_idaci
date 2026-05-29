# EE568 — Design of Electrical Machines

**Sefer İDACİ — 2575421** · Middle East Technical University · Spring 2026

Coursework projects for EE568 (Graduate-level *Design of Electrical Machines*).

## Projects

| # | Topic | Folder | Report |
|---|---|---|---|
| **HW1** | Switched Reluctance Motor — analytical model, linear vs.\ non-linear FEA in ANSYS Maxwell | [HW1/](HW1/) | [PDF](HW1/report/) |
| **HW2** | Surface-PM Synchronous Machine (Design 1: 15 slots / 8 poles, FSCW) — winding design, analytical sizing, 2D FEA verification | [HW2/](HW2/) | [PDF](HW2/report/EE568_HW2_Report_Sefer_IDACI_2575421.pdf) |

## Repository layout

```
EE568-Projects-sefer_idaci/
├── HW1/                       # Project 1 — SRM analysis & FEA
├── HW2/                       # Project 2 — SPMSM design & FEA
├── Lecture_Notes/             # Hand-typed lecture notes (LaTeX)
└── README.md
```

## Building the HW2 report

```bash
cd HW2/report
pdflatex EE568_HW2_Report_Sefer_IDACI_2575421.tex   # run twice for ToC + cross-refs
```

Requires a working MATLAB installation (R2022b or newer) to regenerate the Q1–Q3 analytical figures via [HW2/ee568_hw2_analytical.m](HW2/ee568_hw2_analytical.m), and Python 3.11+ with `numpy` and `matplotlib` to regenerate the Q4 FEA post-processing figures via [HW2/q4_bg_postprocess.py](HW2/q4_bg_postprocess.py).
