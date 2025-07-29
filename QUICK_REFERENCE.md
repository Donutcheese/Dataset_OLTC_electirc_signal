# OLTC Simulation Project - Quick Reference Guide

## Quick Start Commands

### Generate All Datasets
```matlab
% Generate normal operation dataset
run('program/dataset_create.m');

% Generate ut3 delay dataset  
run('program/dataset_ut3_delay.m');

% Generate ut4-6 delay dataset
run('program/dataset_ut456_delay.m');
```

### Load and Verify Data
```matlab
% Load a dataset
data = csvread('normal_Iin.csv');

% Check dimensions
[rows, cols] = size(data);  % Should be 1001 x 50

% Quick visualization
plot(data(:,1));  % Plot first simulation
```

## Essential Parameters

### Simulation Settings
| Parameter | Value | Description |
|-----------|-------|-------------|
| `num_samples` | 50 | Number of simulation runs |
| `time_series_length` | 1001 | Data points per simulation |
| `StopTime` | 0.1 | Simulation duration (seconds) |
| `SampleRate` | 10000 | Sampling frequency (Hz) |

### Timing Parameters (Normal Operation)
| Parameter | Value (ms) | Description |
|-----------|------------|-------------|
| `ut3` | 150 | Timing parameter 3 |
| `ut4` | 150 | Timing parameter 4 |
| `ut5` | 150 | Timing parameter 5 |
| `ut6` | 80 | Timing parameter 6 |

### Electrical Parameters
| Parameter | Range | Description |
|-----------|-------|-------------|
| `voltage_range` | [5301, 6099] V | Source voltage range |
| `resistance_range` | [0.4, 1.0] Ω | Load resistance range |

## File Structure

```
project/
├── program/
│   ├── OLTC_simulation.slx      # Main Simulink model
│   ├── dataset_create.m         # Normal operation generator
│   ├── dataset_ut3_delay.m      # UT3 delay generator
│   └── dataset_ut456_delay.m    # UT4-6 delay generator
├── sample_dataset/
│   ├── normal_Iin.csv           # Normal input current
│   ├── normal_Uout.csv          # Normal output voltage
│   ├── ut3delay_Iin.csv         # UT3 delay input current
│   ├── ut3delay_Uout.csv        # UT3 delay output voltage
│   ├── ut4-6delay_Iin.csv       # UT4-6 delay input current
│   └── ut4-6delay_Uout.csv      # UT4-6 delay output voltage
└── README.md                    # Project documentation
```

## Common Operations

### Modify Number of Simulations
```matlab
% In any .m file, change:
num_samples = 100;  % Instead of 50
```

### Change Parameter Ranges
```matlab
% Modify voltage range
voltage_range = [5400, 6000];  % Narrower range

% Modify resistance range  
resistance_range = [0.5, 0.8]; % Narrower range
```

### Custom Timing Delays
```matlab
% For ut3 delay, modify:
ut3_values = unique(rand(num_samples * 2, 1) * 0.3 + 0.1) * 150;  % 10%-40% delay

% For ut4-6 delay, modify:
ut4_values = unique(150 + rand(num_samples * 2, 1) * (0.3 * 150) + 0.1 * 150);  % 10%-40% increase
```

## Data Analysis Commands

### Basic Statistics
```matlab
% Load data
data = csvread('normal_Iin.csv');

% Calculate statistics
mean_val = mean(data(:));
std_val = std(data(:));
max_val = max(data(:));
min_val = min(data(:));
```

### Compare Conditions
```matlab
% Load different conditions
normal = csvread('normal_Iin.csv');
ut3delay = csvread('ut3delay_Iin.csv');

% Compare means
normal_mean = mean(normal(:));
ut3_mean = mean(ut3delay(:));
difference = ut3_mean - normal_mean;
```

### Plot Comparison
```matlab
% Create time vector
time = linspace(0, 0.1, 1001);

% Plot comparison
figure;
plot(time, normal(:,1), 'b-', time, ut3delay(:,1), 'r--');
xlabel('Time (s)');
ylabel('Current (A)');
legend('Normal', 'UT3 Delay');
title('Current Comparison');
```

## Troubleshooting Quick Fixes

### Model Not Found
```matlab
% Check current directory
pwd
ls *.slx

% Navigate to correct directory
cd('program');
```

### Empty Data
```matlab
% Check if data exists
if exist('normal_Iin.csv', 'file')
    data = csvread('normal_Iin.csv');
    if isempty(data)
        disp('Data file is empty');
    end
end
```

### Parameter Errors
```matlab
% Verify parameter paths
set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', '5700');
set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', '0.7');
```

## Machine Learning Integration

### Prepare Data for ML
```matlab
% Load all datasets
normal_Iin = csvread('normal_Iin.csv');
normal_Uout = csvread('normal_Uout.csv');
ut3delay_Iin = csvread('ut3delay_Iin.csv');
ut3delay_Uout = csvread('ut3delay_Uout.csv');

% Combine features
X_normal = [normal_Iin; normal_Uout];
X_ut3delay = [ut3delay_Iin; ut3delay_Uout];

% Create labels
y_normal = zeros(size(X_normal, 2), 1);
y_ut3delay = ones(size(X_ut3delay, 2), 1);

% Final dataset
X = [X_normal, X_ut3delay];
y = [y_normal; y_ut3delay];
```

### Feature Extraction
```matlab
% Extract basic features
features = [];
for i = 1:size(data, 2)
    signal = data(:, i);
    signal_features = [mean(signal), std(signal), max(signal), min(signal), rms(signal)];
    features = [features; signal_features];
end
```

## Performance Tips

1. **Memory Management**: Clear large variables after use
   ```matlab
   clear data_Iin data_Uout;
   ```

2. **Batch Processing**: Process data in chunks for large datasets
   ```matlab
   chunk_size = 10;
   for i = 1:chunk_size:size(data, 2)
       chunk = data(:, i:min(i+chunk_size-1, end));
       % Process chunk
   end
   ```

3. **Save Intermediate Results**: Save progress during long simulations
   ```matlab
   if mod(i, 10) == 0
       save('intermediate_results.mat', 'data_Iin', 'data_Uout');
   end
   ```

## Validation Checklist

- [ ] All CSV files generated (6 files total)
- [ ] File dimensions correct (1001 × 50)
- [ ] No NaN or Inf values in data
- [ ] Data ranges are reasonable
- [ ] Simulink model runs without errors
- [ ] Output files are not empty

## Contact and Support

For issues or questions:
1. Check the main documentation (`API_DOCUMENTATION.md`)
2. Verify all prerequisites are met
3. Test with sample datasets first
4. Check MATLAB and Simulink versions compatibility