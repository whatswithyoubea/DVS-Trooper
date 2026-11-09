# RTL Design and Verification of ML-Based CPU DVFS Governor (DVS Trooper)

[![Course](https://img.shields.io/badge/Course-SD0212%20RTL%20Design%20%26%20Verification-blue.svg)](https://github.com/Stewartsson/dvs-trooper)
[![Institution](https://img.shields.io/badge/Institution-St.%20Joseph's%20Institute%20of%20Technology-red.svg)](https://stjosephstechnology.ac.in)
[![Simulation](https://img.shields.io/badge/EDA%20Playground-Live%20Simulation%20(BSTX)-brightgreen.svg)](https://edaplayground.com/x/BSTX)
[![FPGA Target](https://img.shields.io/badge/Vivado-100MHz%20Timing%20Closure-orange.svg)](https://www.xilinx.com)

> 🚀 **Live Interactive EDA Playground Project**: [https://edaplayground.com/x/BSTX](https://edaplayground.com/x/BSTX)

---

## 📌 Project Overview
**DVS Trooper** is a Machine Learning-assisted Dynamic Voltage and Frequency Scaling (DVFS) CPU governor designed and verified in **SystemVerilog**. It addresses the latency limitations of traditional reactive DVFS governors by predicting imminent power supply voltage droops before hardware alarm thresholds are violated.

The design compares two distinct governors under identical workload, voltage samples, and fault profiles:
1. **Baseline Governor (Reactive)**: Throttles clock frequency from **FAST** (1) to **SLOW** (0) only after a physical droop or thermal alarm is asserted.
2. **Predictive Governor (ML-Assisted)**: Employs a trained digital predictor evaluating cycle-to-cycle voltage drops ($\Delta V \ge 40\text{ mV}$) and sustained active workload samples ($busy \ge 3$) to request SLOW **one clock cycle earlier** than the reactive baseline, actively preventing droop-induced timing faults.

---

## 👥 Student Team & Project Metadata
**Institution**: St. Joseph’s Institute of Technology (Autonomous), Chennai – 600 119  
**Department**: Electronics and Communication Engineering (ECE)  
**Course**: SD0212 RTL DESIGN AND VERIFICATION (EEC Project)  
**Batch**: 2024–2028 | **Academic Year**: 2026–2027  

### Team Members & Verified Project Links
| S.No | Student Name | Register Number | EDA Playground Link | GitHub Repository |
|:---:|:---|:---:|:---:|:---|
| 1 | **Bernice Eleora Judson** | `312424106032` | [`edaplayground.com/x/WzeJ`](https://edaplayground.com/x/WzeJ) | [@bernice](https://github.com) |
| 2 | **Jayachandiran S** | `312424106068` | [`edaplayground.com/x/Q8kb`](https://edaplayground.com/x/Q8kb) | [@jayachandiran](https://github.com) |
| 3 | **John Stewartsson J R** | `312424106073` | [**`edaplayground.com/x/BSTX`**](https://edaplayground.com/x/BSTX) | [**@Stewartsson**](https://github.com/Stewartsson/dvs-trooper) |
| 4 | **Kishore R** | `312424106087` | [`edaplayground.com/x/DLBt`](https://edaplayground.com/x/DLBt) | [@kishore-r](https://github.com) |
| 5 | **Rozario Shaan Soris J** | `312424106136` | [`edaplayground.com/x/cwDY`](https://edaplayground.com/x/cwDY) | [@rozario-shaan](https://github.com) |

### Faculty Mentors
- **Supervisor**: Dr. R. Nirosha, M.E., Ph.D., Assistant Professor, ECE
- **Head of the Department**: Dr. P G V Ramesh, M.Tech., Ph.D., Professor & HOD, ECE
- **Principal**: Dr. R. Priscilla, M.E., Ph.D.

---

## 📈 EDA Playground Simulation Waveforms (EPWave)

The design and testbench have been simulated and fully verified on EDA Playground (`https://edaplayground.com/x/BSTX`):

![EPWave Simulation Waveform](docs/epwave_simulation.png)

### Key Waveform Verification Points:
1. **Zero Errors (`error_count[31:0] == 0`)**: The error counter remains flat at `0` throughout the entire 225 ns simulation run, confirming that all self-checking assertions passed.
2. **Complete Test Sequence (`check_count[31:0] == 18`)**: Ramps up to 18, demonstrating full execution of all targeted functional scenarios.
3. **ML Early Warning Detection (~50 ns)**: `warn` is registered high as voltage drop exceeds 40 mV under sustained busy conditions.
4. **1-Clock Cycle Predictive Advantage (~55 ns)**:
   - `predictive_fast` transitions from `1` (FAST) down to `0` (SLOW) at **55 ns**.
   - `baseline_fast` remains at `1` until the actual `droop` fault alarm asserts at **65 ns**.
   - **Proves the ML governor prevents timing failures by throttling 1 full 10 ns clock cycle ahead of reactive hardware.**
5. **Thermal Fault Safety (~145 ns)**: `hot` alarm immediately overrides both governors to SLOW.
6. **Idle Power Savings (~185 ns)**: When `busy` falls to `0`, both governors switch to SLOW to minimize dynamic power dissipation.

---

## 🏗️ Hardware Architecture & Gate-Level Design

### 1. Droop Predictor (`droop_predictor.sv`)
- **12-bit Voltage Subtractor**: Computes non-negative voltage delta: $drop = \max(V_{previous} - V_{sample}, 0)$.
- **8-bit Saturating Counter**: Tracks sustained active workload duration ($busy == 1$), saturating at 255.
- **Learned Threshold Comparators**:
  - Voltage drop threshold: $\Delta V \ge 40\text{ mV}$
  - Sustained workload threshold: $busy\_count \ge 3$
- **AND Decision Tree**: Asserts early warning signal `warn` on registered clock edge when conditions match.

### 2. DVFS Governor (`dvs_governor.sv`)
- **Fault Priority Logic**: Immediate asynchronous/synchronous override on `hot`, `droop`, or predictive `early_warn`.
- **Hysteresis Recovery Sequencer**: Requires 3 consecutive healthy cycles before restoring FAST clock speed, preventing limit-cycle oscillation.

### 3. Integrated Comparison Top (`dvs_compare.sv`)
- Synthesizes both the baseline governor (`early_warn = 0`) and the ML predictive governor (`early_warn = warn`) side-by-side on identical workload vectors.

---

## ⚡ Synthesis & FPGA Implementation Results

Synthesized and placed & routed targeting AMD / Xilinx 7-Series FPGA architecture in Vivado:

| Metric | Baseline Governor | DVS Trooper (Predictive Top) | Device Available | Utilization |
|:---|:---:|:---:|:---:|:---:|
| **Slice LUTs** | 9 | **41** | 53,200 | 0.08% |
| **Slice Registers (FFs)** | 5 | **31** | 106,400 | 0.03% |
| **Occupied Slices** | 4 | **18** | 13,300 | 0.14% |
| **Target Clock Frequency** | 100 MHz | **100 MHz** | — | Timing Met |
| **Worst Negative Slack (WNS)** | — | **+5.327 ns** | — | Clean Setup |
| **Worst Hold Slack (WHS)** | — | **+0.167 ns** | — | Clean Hold |

---

## 📂 Repository File Tree
```
dvs-trooper/
├── .gitignore
├── README.md             # Comprehensive project documentation
├── droop_predictor.sv    # ML droop prediction logic
├── dvs_compare.sv        # Top-level comparison module
├── dvs_governor.sv       # DVFS governor with recovery state machine
├── tb_dvs.sv             # Self-checking verification testbench
├── docs/
│   └── epwave_simulation.png  # EPWave simulation waveform capture
└── report/
    └── SD0212_RTL_Design_and_Verification_ML_DVFS_Governor_Final.pdf  # 24-page Project Report
```

---

## 📜 Full Project Report
The official 24-page college project report prepared according to the Anna University / Autonomous St. Joseph’s Institute of Technology format is available in [`report/SD0212_RTL_Design_and_Verification_ML_DVFS_Governor_Final.pdf`](report/SD0212_RTL_Design_and_Verification_ML_DVFS_Governor_Final.pdf).
