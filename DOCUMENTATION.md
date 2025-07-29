# OLTC Simulation Project – Comprehensive Documentation

## Table of Contents
1. Project Overview
2. Directory Structure
3. Simulation Model (`OLTC_simulation.slx`)
4. Dataset Generation APIs (MATLAB Scripts)
   1. `dataset_create.m` – Normal Operation
   2. `dataset_ut3_delay.m` – *ut3* Delay Condition
   3. `dataset_ut456_delay.m` – *ut4–6* Delay Condition
5. Generated Dataset Format
6. Getting Started – End-to-End Example
7. Frequently Asked Questions
8. License

---

## 1. Project Overview
This repository contains a Simulink model and MATLAB scripts used to simulate the behaviour of an On-Load Tap Changer (OLTC) installed in oil-immersed power transformers. The main goal is to generate labelled datasets that can be fed into machine-learning pipelines for:
* Condition monitoring
* Fault diagnosis (e.g. *ut3* delay, *ut4–6* delay)
* Remaining-life estimation and predictive maintenance

If you are only interested in ready-made data, jump directly to the `sample_dataset/` folder. If you need to **re-generate** or **extend** the dataset, continue reading.

---

## 2. Directory Structure
```text
├── DOCUMENTATION.md   ← <-- current file
├── LICENSE
├── README.md          ← Short landing page (EN)
├── README_zh.md       ← Short landing page (ZH-CN)
├── program/           ← MATLAB & Simulink source
│   ├── OLTC_simulation.slx    ← Core Simulink model
│   ├── dataset_create.m       ← Generates *normal* operation data
│   ├── dataset_ut3_delay.m    ← Generates data with *ut3* delay
│   └── dataset_ut456_delay.m  ← Generates data with *ut4–6* delay
└── sample_dataset/    ← Six CSV files (3 conditions × {Iin, Uout})
```

---

## 3. Simulation Model — `OLTC_simulation.slx`
The Simulink model encapsulates the electrical and mechanical behaviour of an OLTC during a tap-changing operation. Key blocks include:

| Block | Purpose |
|-------|---------|
| **AC Voltage Source** | Provides the primary supply voltage. Its *Amplitude* parameter is programmatically updated by the MATLAB scripts to create voltage variability. |
| **Series RLC Branch1** | Represents the load. Its *Resistance* value is likewise varied at runtime. |
| **Iin & Uout Probes** | Scope blocks exporting the input current (`Iin`) and output voltage (`Uout`) as `timeseries` objects to the MATLAB workspace. |

> Note: No manual interaction is required; the MATLAB scripts set model parameters, launch the simulation, and harvest results automatically.

---

## 4. Dataset Generation APIs (MATLAB Scripts)
All **public APIs** for data generation reside in the three top-level MATLAB scripts inside `program/`. Each script can be executed standalone from the MATLAB command window *or* integrated into larger automation pipelines.

General execution pattern:
```matlab
cd program               % change into the program directory
run('dataset_create.m')  % replace with the script you need
```
After execution you will find two CSV files in the working directory, named according to the operating condition (see tables below).

### Common Parameters
The following variables appear in all scripts and can be tuned to control the simulation batch size and signal length.

| Variable | Default | Description |
|----------|---------|-------------|
| `num_samples` | `50` | Number of **independent** simulation runs. |
| `time_series_length` | `1001` | Number of points per signal (0.1 s at 10 kHz sampling). |
| `voltage_range` | `[0.93, 1.07] * 5700` | Min/Max factor applied to nominal 5.7 kV source voltage. |
| `resistance_range` | `[0.4, 1.0]` | Unit-less multiplier applied to nominal load resistance. |

Additional variables specific to each script are listed below.

#### 4.1 `dataset_create.m` – Normal Operation
| Variable | Default | Role |
|----------|---------|------|
| `ut3_value` | `150` | Fixed switch-over time (ms) for *ut3*. |
| `ut4_value` | `150` | Fixed switch-over time (ms) for *ut4*. |
| `ut5_value` | `150` | Fixed switch-over time (ms) for *ut5*. |
| `ut6_value` | `80`  | Fixed switch-over time (ms) for *ut6*. |

**Outputs**
```
ut3delay_Iin.csv   % input current for normal condition
ut3delay_Uout.csv   % output voltage for normal condition
```

**Example**
```matlab
% Produce 100 normal-operation samples of 5 000 points each
num_samples = 100;
time_series_length = 5000;
run('dataset_create.m');
```

#### 4.2 `dataset_ut3_delay.m` – *ut3* Delay Condition
| Variable | Default | Role |
|----------|---------|------|
| `ut3_values` | `rand(...) * [0.2 … 0.5] * 150` | Randomised delay for *ut3* (20–50 % increase). |
| `ut4_value` | `150` | Kept constant. |
| `ut5_value` | `150` | Kept constant. |
| `ut6_value` | `80`  | Kept constant. |

**Outputs**
```
ut3delay_Iin.csv
ut3delay_Uout.csv
```

**Example**
```matlab
% Generate 30 samples with custom voltage range
num_samples = 30;
voltage_range = [0.9, 1.1] * 5700;
run('dataset_ut3_delay.m');
```

#### 4.3 `dataset_ut456_delay.m` – *ut4–6* Delay Condition
| Variable | Default | Role |
|----------|---------|------|
| `ut4_values` | `150 + rand(...) * (0.1 … 0.5) * 150` | Random increase 10–50 % |
| `ut5_values` | idem |
| `ut6_values` | `80 + rand(...) * (0.1 … 0.5) * 80` |
| `ut3_value`  | `150` | Fixed reference |

**Outputs**
```
ut4-6delay_Iin.csv
ut4-6delay_Uout.csv
```

**Example**
```matlab
% Stress-test with 200 simulations and extended timeline
num_samples = 200;
time_series_length = 2001;  % 0.2 s @ 10 kHz
run('dataset_ut456_delay.m');
```

---

## 5. Generated Dataset Format
Every CSV file contains a **matrix** of size `time_series_length × num_samples`:
* **Rows** – Time instants (`t = 0 … 0.1 s` by default)
* **Columns** – Independent simulation runs

This layout is convenient for direct ingestion into frameworks like Pandas, Numpy, or MATLAB itself:
```python
import numpy as np
Iin = np.loadtxt('ut3delay_Iin.csv', delimiter=',')  # shape (1001, 50)
```

---

## 6. Getting Started – End-to-End Example
1. Open MATLAB/Simulink.
2. `cd` into the repository root, then into `program/`.
3. Make sure the Simulink model opens without errors:
   ```matlab
   open_system('OLTC_simulation.slx');
   ```
4. Execute one of the scripts, e.g.:
   ```matlab
   run('dataset_ut3_delay.m');
   ```
5. Find newly created CSV files beside the script or move them to `sample_dataset/` as needed.
6. Analyse data in Python:
   ```python
   import pandas as pd, matplotlib.pyplot as plt
   Iin = pd.read_csv('ut3delay_Iin.csv', header=None)
   Iin.iloc[:,0].plot(title='First simulation – Input current');
   plt.show()
   ```

---

## 7. Frequently Asked Questions
**Q. I get an error like _"Timeseries data is empty"_.**  
A. Ensure that the probe blocks in `OLTC_simulation.slx` are named exactly `Iin` and `Uout`. Mismatched names prevent the script from fetching data.

**Q. How do I change the simulation stop time?**  
Set `StopTime` in the MATLAB script when calling `sim(...)` and adapt `time_series_length` accordingly.

**Q. Can I parallelise simulations?**  
Yes. Wrap the `for`-loop with a `parfor` and make sure the Simulink model supports fast-restart.

---

## 8. License
This project is licensed under the terms of the MIT license (see `LICENSE`).