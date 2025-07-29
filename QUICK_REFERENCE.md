# OLTC Simulation Quick Reference Guide

## 🚀 Quick Start

### Generate Normal Dataset
```bash
cd program/
matlab -r "dataset_create; exit"
```
Output: `normal_Iin.csv`, `normal_Uout.csv`

### Generate Fault Datasets
```bash
# ut3 delay fault
matlab -r "dataset_ut3_delay; exit"

# ut4-6 delay fault
matlab -r "dataset_ut456_delay; exit"
```

## 📊 Data Structure

| File | Description | Dimensions | Unit |
|------|-------------|------------|------|
| `*_Iin.csv` | Input current | 1001×50 | Amperes |
| `*_Uout.csv` | Output voltage | 1001×50 | Volts |

- **Rows**: Time points (0-0.1s, 10kHz sampling)
- **Columns**: Individual simulation runs

## ⚙️ Key Parameters

### Default Configuration
```matlab
num_samples = 50;              % Number of simulations
time_series_length = 1001;     % Data points per simulation
resistance_range = [0.4, 1.0]; % Load resistance (Ω)
voltage_range = [5301, 6099];  % Source voltage (V)
```

### Timing Parameters (ms)
| Parameter | Normal | ut3 Delay | ut4-6 Delay |
|-----------|--------|-----------|-------------|
| ut3 | 150 | 30-75 | 150 |
| ut4 | 150 | 150 | 165-225 |
| ut5 | 150 | 150 | 165-225 |
| ut6 | 80 | 80 | 88-120 |

## 💻 Common Operations

### Load Data (MATLAB)
```matlab
% Load data
data_Iin = csvread('normal_Iin.csv');
data_Uout = csvread('normal_Uout.csv');

% Extract single run
run1_current = data_Iin(:, 1);
run1_voltage = data_Uout(:, 1);

% Calculate mean across runs
mean_current = mean(data_Iin, 2);
mean_voltage = mean(data_Uout, 2);
```

### Load Data (Python)
```python
import numpy as np

# Load data
current = np.loadtxt('normal_Iin.csv', delimiter=',')
voltage = np.loadtxt('normal_Uout.csv', delimiter=',')

# Shape: (1001, 50) - time × samples
print(f"Data shape: {current.shape}")
```

### Visualize Data
```matlab
% MATLAB plot
time = linspace(0, 0.1, 1001);
plot(time, data_Iin(:, 1));
xlabel('Time (s)'); ylabel('Current (A)');
title('OLTC Input Current');
```

```python
# Python plot
import matplotlib.pyplot as plt

time = np.linspace(0, 0.1, 1001)
plt.plot(time, current[:, 0])
plt.xlabel('Time (s)')
plt.ylabel('Current (A)')
plt.title('OLTC Input Current')
plt.show()
```

## 🔧 Customization Examples

### Change Number of Samples
Edit line 3 in any dataset script:
```matlab
num_samples = 100;  % Generate 100 samples
```

### Modify Parameter Ranges
```matlab
% Wider resistance range
resistance_range = [0.2, 2.0];

% Tighter voltage range (±3%)
voltage_range = [0.97 * 5700, 1.03 * 5700];
```

### Batch Processing
```matlab
% Generate multiple datasets
for i = 1:5
    dataset_create;
    movefile('normal_Iin.csv', sprintf('batch_%d_Iin.csv', i));
    movefile('normal_Uout.csv', sprintf('batch_%d_Uout.csv', i));
end
```

## 📝 File Outputs

### Normal Operation
- Script: `dataset_create.m`
- Outputs: `normal_Iin.csv`, `normal_Uout.csv`

### ut3 Delay Fault
- Script: `dataset_ut3_delay.m`
- Outputs: `ut3delay_Iin.csv`, `ut3delay_Uout.csv`

### ut4-6 Delay Fault
- Script: `dataset_ut456_delay.m`
- Outputs: `ut4-6delay_Iin.csv`, `ut4-6delay_Uout.csv`

## 🐛 Common Issues

### Model Not Found
```matlab
addpath('path/to/program/folder');
```

### Memory Issues
```matlab
clear data_Iin data_Uout;  % Clear between runs
```

### Check Data Validity
```matlab
% Quick validation
data = csvread('normal_Iin.csv');
fprintf('Size: %dx%d, Range: [%.2f, %.2f]\n', ...
    size(data), min(data(:)), max(data(:)));
```

## 📚 See Also
- [Full API Documentation](API_DOCUMENTATION.md)
- [Project README](README.md)
- [Sample Datasets](sample_dataset/)