# OLTC Electric Signal Dataset API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Core Functions](#core-functions)
3. [Simulink Model Interface](#simulink-model-interface)
4. [Data Generation Scripts](#data-generation-scripts)
5. [Parameters and Configuration](#parameters-and-configuration)
6. [Usage Examples](#usage-examples)
7. [Data Format Specifications](#data-format-specifications)

## Overview

This documentation provides comprehensive information about all public APIs, functions, and components in the OLTC (On-Load Tap Changer) Electric Signal Dataset project. The project is designed for generating simulation datasets for AI-based fault diagnosis in oil-immersed power transformers.

## Core Functions

### 1. dataset_create.m
**Purpose**: Generates dataset under normal operating conditions for OLTC.

**Function Signature**:
```matlab
% No explicit function signature - script file
% Outputs: normal_Iin.csv, normal_Uout.csv
```

**Parameters** (configurable within script):
- `num_samples`: Number of simulation runs (default: 50)
- `time_series_length`: Length of each time series (default: 1001)
- `resistance_range`: Load resistance range [min, max] (default: [0.4, 1.0])
- `voltage_range`: Source voltage fluctuation range (default: [0.93*5700, 1.07*5700])
- `ut3_value`: Fixed timing parameter (default: 150ms)
- `ut4_value`: Fixed timing parameter (default: 150ms)
- `ut5_value`: Fixed timing parameter (default: 150ms)
- `ut6_value`: Fixed timing parameter (default: 80ms)

**Output Files**:
- `normal_Iin.csv`: Input current data matrix (1001 x 50)
- `normal_Uout.csv`: Output voltage data matrix (1001 x 50)

### 2. dataset_ut3_delay.m
**Purpose**: Generates dataset with ut3 parameter delay condition (fault simulation).

**Function Signature**:
```matlab
% No explicit function signature - script file
% Outputs: ut3delay_Iin.csv, ut3delay_Uout.csv
```

**Parameters** (configurable within script):
- `num_samples`: Number of simulation runs (default: 50)
- `time_series_length`: Length of each time series (default: 1001)
- `resistance_range`: Load resistance range [min, max] (default: [0.4, 1.0])
- `voltage_range`: Source voltage fluctuation range (default: [0.93*5700, 1.07*5700])
- `ut3_values`: Randomly generated between 20%-50% of normal value (30ms - 75ms)
- `ut4_value`: Fixed timing parameter (default: 150ms)
- `ut5_value`: Fixed timing parameter (default: 150ms)
- `ut6_value`: Fixed timing parameter (default: 80ms)

**Output Files**:
- `ut3delay_Iin.csv`: Input current data matrix (1001 x 50)
- `ut3delay_Uout.csv`: Output voltage data matrix (1001 x 50)

### 3. dataset_ut456_delay.m
**Purpose**: Generates dataset with ut4, ut5, ut6 parameter delay conditions (fault simulation).

**Function Signature**:
```matlab
% No explicit function signature - script file
% Outputs: ut4-6delay_Iin.csv, ut4-6delay_Uout.csv
```

**Parameters** (configurable within script):
- `num_samples`: Number of simulation runs (default: 50)
- `time_series_length`: Length of each time series (default: 1001)
- `resistance_range`: Load resistance range [min, max] (default: [0.4, 1.0])
- `voltage_range`: Source voltage fluctuation range (default: [0.93*5700, 1.07*5700])
- `ut3_value`: Fixed timing parameter (default: 150ms)
- `ut4_values`: Increased by 10%-50% from normal (165ms - 225ms)
- `ut5_values`: Increased by 10%-50% from normal (165ms - 225ms)
- `ut6_values`: Increased by 10%-50% from normal (88ms - 120ms)

**Output Files**:
- `ut4-6delay_Iin.csv`: Input current data matrix (1001 x 50)
- `ut4-6delay_Uout.csv`: Output voltage data matrix (1001 x 50)

## Simulink Model Interface

### OLTC_simulation.slx
**Purpose**: Core Simulink model for OLTC operation simulation.

**Key Components**:
1. **AC Voltage Source**: Configurable amplitude for source voltage simulation
2. **Series RLC Branch1**: Configurable resistance for load simulation
3. **External Inputs**: ut3, ut4, ut5, ut6 timing signals
4. **Outputs**: 
   - `Iin`: Input current timeseries
   - `Uout`: Output voltage timeseries

**Model Parameters**:
- `StopTime`: Simulation duration (default: 0.1 seconds)
- `SampleTime`: Implicit from time_series_length (10kHz sampling rate)

## Parameters and Configuration

### Common Parameters Across All Scripts

| Parameter | Description | Default Value | Range/Type |
|-----------|-------------|---------------|------------|
| `num_samples` | Number of simulation iterations | 50 | Integer > 0 |
| `time_series_length` | Data points per simulation | 1001 | Integer > 0 |
| `resistance_range` | Load resistance bounds (Ω) | [0.4, 1.0] | [min, max] |
| `voltage_range` | Source voltage bounds (V) | [5301, 6099] | [min, max] |

### Timing Parameters (milliseconds)

| Parameter | Normal Operation | ut3 Delay | ut4-6 Delay | Description |
|-----------|-----------------|-----------|-------------|-------------|
| `ut3` | 150 | 30-75 | 150 | Transition timing 3 |
| `ut4` | 150 | 150 | 165-225 | Transition timing 4 |
| `ut5` | 150 | 150 | 165-225 | Transition timing 5 |
| `ut6` | 80 | 80 | 88-120 | Transition timing 6 |

## Usage Examples

### Example 1: Generate Normal Operation Dataset
```matlab
% Navigate to program directory
cd program/

% Run the normal dataset creation script
dataset_create

% Output files will be created:
% - normal_Iin.csv (1001x50 matrix)
% - normal_Uout.csv (1001x50 matrix)
```

### Example 2: Generate Custom-sized Dataset
```matlab
% Edit dataset_create.m before running
% Change line 3:
num_samples = 100;  % Generate 100 samples instead of 50

% Run the script
dataset_create
```

### Example 3: Generate Fault Condition Dataset (ut3 delay)
```matlab
% Navigate to program directory
cd program/

% Run the ut3 delay dataset creation script
dataset_ut3_delay

% Output files will be created:
% - ut3delay_Iin.csv (1001x50 matrix)
% - ut3delay_Uout.csv (1001x50 matrix)
```

### Example 4: Custom Voltage and Resistance Ranges
```matlab
% Edit any dataset script before running
% For example, in dataset_create.m:

% Custom resistance range (0.2 to 2.0 Ohms)
resistance_range = [0.2, 2.0];

% Custom voltage range (±5% instead of ±7%)
voltage_range = [0.95 * 5700, 1.05 * 5700];

% Run the script
dataset_create
```

### Example 5: Programmatic Usage with Modified Parameters
```matlab
% Create a wrapper function for batch processing
function generate_multiple_datasets(num_runs, samples_per_run)
    for i = 1:num_runs
        % Modify parameters
        edit_parameter('dataset_create.m', 'num_samples', samples_per_run);
        
        % Run simulation
        run('dataset_create.m');
        
        % Rename output files
        movefile('normal_Iin.csv', sprintf('normal_Iin_run%d.csv', i));
        movefile('normal_Uout.csv', sprintf('normal_Uout_run%d.csv', i));
    end
end

% Generate 5 datasets with 100 samples each
generate_multiple_datasets(5, 100);
```

## Data Format Specifications

### Output CSV File Format
All generated CSV files follow the same format:
- **Dimensions**: 1001 rows × 50 columns (default)
- **Row**: Represents time points (0 to 0.1 seconds, 10kHz sampling)
- **Column**: Represents individual simulation runs
- **Data Type**: Double precision floating point
- **Units**:
  - Current files (*_Iin.csv): Amperes (A)
  - Voltage files (*_Uout.csv): Volts (V)

### Time Series Structure
```
Time(s)    Sample1    Sample2    ...    Sample50
0.0000     I1(t0)     I2(t0)     ...    I50(t0)
0.0001     I1(t1)     I2(t1)     ...    I50(t1)
...        ...        ...        ...    ...
0.1000     I1(t1000)  I2(t1000)  ...    I50(t1000)
```

### Loading Data for Analysis
```matlab
% Load input current data
data_Iin = csvread('normal_Iin.csv');
% data_Iin is a 1001x50 matrix

% Extract single simulation run
simulation_1_current = data_Iin(:, 1);

% Extract specific time range (e.g., 0.05-0.06 seconds)
time_indices = 501:601;  % Corresponds to 0.05-0.06s
subset_data = data_Iin(time_indices, :);

% Calculate statistics across all simulations
mean_current = mean(data_Iin, 2);  % Mean at each time point
std_current = std(data_Iin, 0, 2);  % Standard deviation
```

### Integration with Machine Learning
```python
# Python example for loading data
import numpy as np
import pandas as pd

# Load data
current_data = np.loadtxt('normal_Iin.csv', delimiter=',')
voltage_data = np.loadtxt('normal_Uout.csv', delimiter=',')

# Reshape for ML models (samples, timesteps, features)
n_samples = current_data.shape[1]
n_timesteps = current_data.shape[0]

# Combine current and voltage as features
X = np.zeros((n_samples, n_timesteps, 2))
X[:, :, 0] = current_data.T
X[:, :, 1] = voltage_data.T

# Labels for classification
y_normal = np.zeros(n_samples)  # Label 0 for normal operation
```

## Best Practices and Recommendations

### 1. Parameter Selection
- Keep `num_samples` ≥ 50 for statistical significance
- Ensure voltage range reflects real transformer operating conditions
- Load resistance should cover expected operational range

### 2. Simulation Performance
- Large `num_samples` values may require significant computation time
- Consider parallel processing for multiple dataset generation
- Monitor system memory when generating large datasets

### 3. Data Validation
```matlab
% Validate generated data
function validate_dataset(filename)
    data = csvread(filename);
    fprintf('Data shape: %d x %d\n', size(data));
    fprintf('Min value: %f\n', min(data(:)));
    fprintf('Max value: %f\n', max(data(:)));
    fprintf('Any NaN values: %d\n', sum(isnan(data(:))));
    fprintf('Any Inf values: %d\n', sum(isinf(data(:))));
end

validate_dataset('normal_Iin.csv');
```

### 4. Error Handling
The scripts include basic error handling for empty timeseries data. Additional validation recommended:
```matlab
% Add before simulation loop
if ~exist('OLTC_simulation', 'file')
    error('Simulink model OLTC_simulation.slx not found');
end

% Add after simulation
if size(data_Iin, 1) ~= time_series_length
    warning('Unexpected data length in simulation %d', i);
end
```

## Troubleshooting

### Common Issues and Solutions

1. **"Simulink model not found" error**
   - Ensure OLTC_simulation.slx is in MATLAB path
   - Use `addpath('path/to/model')` if needed

2. **Empty timeseries data**
   - Check Simulink model output signal names match script expectations
   - Verify model runs without errors in Simulink GUI

3. **Insufficient unique random values**
   - Increase random value generation multiplier (currently 2x)
   - Check parameter ranges allow sufficient variation

4. **Memory issues with large datasets**
   - Process data in batches
   - Clear variables between runs using `clear data_Iin data_Uout`

## Version Information
- MATLAB Version: Compatible with R2018b and later
- Simulink Version: Requires Simscape Electrical toolbox
- Data Format Version: 1.0

## License
Refer to the LICENSE file in the repository root for licensing information.