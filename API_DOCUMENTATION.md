# OLTC Simulation Project - API Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Core Components](#core-components)
3. [Simulation Model](#simulation-model)
4. [Data Generation Scripts](#data-generation-scripts)
5. [Data Format Specifications](#data-format-specifications)
6. [Usage Examples](#usage-examples)
7. [Parameter Reference](#parameter-reference)
8. [Troubleshooting](#troubleshooting)

## Project Overview

The OLTC (On-Load Tap Changer) Simulation Project provides a comprehensive framework for simulating and analyzing electrical signals in oil-immersed power transformers. The project is designed for AI-based fault diagnosis systems using deep learning approaches.

### Key Features
- **Simulink-based simulation** of OLTC mechanical operations
- **Multi-condition data generation** (normal, ut3 delay, ut4-6 delay)
- **High-frequency sampling** (10,000 Hz) for detailed signal analysis
- **Randomized parameter variation** for robust dataset creation
- **CSV output format** for easy integration with ML frameworks

## Core Components

### 1. OLTC_simulation.slx
**Type**: Simulink Model File  
**Purpose**: Main simulation model for OLTC operations

**Description**: This is the core simulation model that replicates the mechanical operation process of an On-Load Tap Changer. The model simulates 9 operational steps with 3 critical phases involving significant electrical parameter changes.

**Key Parameters**:
- AC Voltage Source amplitude
- Series RLC Branch resistance
- Timing parameters (ut3, ut4, ut5, ut6)

**Outputs**:
- `Iin`: Input current time series
- `Uout`: Output voltage time series

## Data Generation Scripts

### 1. dataset_create.m
**Purpose**: Generate datasets under normal operating conditions

**Function Signature**:
```matlab
% No input parameters - uses default configuration
% Outputs: normal_Iin.csv, normal_Uout.csv
```

**Key Features**:
- Generates 50 simulation runs by default
- Uses fixed timing parameters (ut3=150ms, ut4=150ms, ut5=150ms, ut6=80ms)
- Randomizes source voltage and load resistance
- Ensures unique parameter combinations

**Usage Example**:
```matlab
% Run the script in MATLAB
dataset_create;
% This will generate:
% - normal_Iin.csv (1001 x 50 matrix)
% - normal_Uout.csv (1001 x 50 matrix)
```

**Configuration Parameters**:
```matlab
num_samples = 50;                    % Number of simulation runs
time_series_length = 1001;           % Data points per simulation
resistance_range = [0.4, 1.0];       % Load resistance range (ohms)
voltage_range = [5301, 6099];        % Source voltage range (V)
```

### 2. dataset_ut3_delay.m
**Purpose**: Generate datasets with ut3 parameter delay conditions

**Function Signature**:
```matlab
% No input parameters - uses default configuration
% Outputs: ut3delay_Iin.csv, ut3delay_Uout.csv
```

**Key Features**:
- Introduces random delays in ut3 parameter (20%-50% of normal 150ms)
- Maintains normal values for ut4, ut5, ut6
- Simulates specific fault condition in timing mechanism

**Usage Example**:
```matlab
% Run the script in MATLAB
dataset_ut3_delay;
% This will generate:
% - ut3delay_Iin.csv (1001 x 50 matrix)
% - ut3delay_Uout.csv (1001 x 50 matrix)
```

**Configuration Parameters**:
```matlab
num_samples = 50;                    % Number of simulation runs
ut3_delay_range = [0.2, 0.5];       % ut3 delay factor range
ut4_value = 150;                    % Fixed ut4 value (ms)
ut5_value = 150;                    % Fixed ut5 value (ms)
ut6_value = 80;                     % Fixed ut6 value (ms)
```

### 3. dataset_ut456_delay.m
**Purpose**: Generate datasets with ut4, ut5, ut6 parameter delay conditions

**Function Signature**:
```matlab
% No input parameters - uses default configuration
% Outputs: ut4-6delay_Iin.csv, ut4-6delay_Uout.csv
```

**Key Features**:
- Introduces random delays in ut4, ut5, ut6 parameters (10%-50% increase)
- Maintains normal value for ut3
- Simulates complex fault conditions affecting multiple timing parameters

**Usage Example**:
```matlab
% Run the script in MATLAB
dataset_ut456_delay;
% This will generate:
% - ut4-6delay_Iin.csv (1001 x 50 matrix)
% - ut4-6delay_Uout.csv (1001 x 50 matrix)
```

**Configuration Parameters**:
```matlab
num_samples = 50;                    % Number of simulation runs
ut3_value = 150;                    % Fixed ut3 value (ms)
ut4_delay_range = [0.1, 0.5];       % ut4 delay factor range
ut5_delay_range = [0.1, 0.5];       % ut5 delay factor range
ut6_delay_range = [0.1, 0.5];       % ut6 delay factor range
```

## Data Format Specifications

### CSV File Structure
All generated CSV files follow the same structure:
- **Dimensions**: 1001 rows × 50 columns
- **Rows**: Time series data points (0.1 seconds at 10,000 Hz)
- **Columns**: Individual simulation runs
- **Data Type**: Double precision floating point

### File Naming Convention
```
{condition}_{signal_type}.csv
```
Where:
- `condition`: normal, ut3delay, ut4-6delay
- `signal_type`: Iin (input current), Uout (output voltage)

### Sample Data Files
```
normal_Iin.csv          # Normal operation input current
normal_Uout.csv         # Normal operation output voltage
ut3delay_Iin.csv        # ut3 delay condition input current
ut3delay_Uout.csv       # ut3 delay condition output voltage
ut4-6delay_Iin.csv      # ut4-6 delay condition input current
ut4-6delay_Uout.csv     # ut4-6 delay condition output voltage
```

## Usage Examples

### Example 1: Generate Normal Operation Dataset
```matlab
% Load the script
run('program/dataset_create.m');

% Verify the output files exist
if exist('normal_Iin.csv', 'file') && exist('normal_Uout.csv', 'file')
    disp('Normal operation dataset generated successfully');
    
    % Load and examine the data
    normal_current = csvread('normal_Iin.csv');
    normal_voltage = csvread('normal_Uout.csv');
    
    % Display data dimensions
    fprintf('Current data: %d time points × %d simulations\n', ...
            size(normal_current, 1), size(normal_current, 2));
    fprintf('Voltage data: %d time points × %d simulations\n', ...
            size(normal_voltage, 1), size(normal_voltage, 2));
end
```

### Example 2: Generate All Fault Condition Datasets
```matlab
% Generate ut3 delay dataset
run('program/dataset_ut3_delay.m');

% Generate ut4-6 delay dataset
run('program/dataset_ut456_delay.m');

% Verify all datasets are created
datasets = {'normal', 'ut3delay', 'ut4-6delay'};
signals = {'Iin', 'Uout'};

for i = 1:length(datasets)
    for j = 1:length(signals)
        filename = sprintf('%s_%s.csv', datasets{i}, signals{j});
        if exist(filename, 'file')
            fprintf('✓ %s created successfully\n', filename);
        else
            fprintf('✗ %s missing\n', filename);
        end
    end
end
```

### Example 3: Custom Dataset Generation
```matlab
% Modify parameters for custom dataset
num_samples = 100;  % Increase to 100 simulations
time_series_length = 1001;

% Modify voltage and resistance ranges
voltage_range = [5400, 6000];  % Narrower voltage range
resistance_range = [0.5, 0.8]; % Narrower resistance range

% Run custom simulation
% (Copy and modify one of the existing scripts)
```

### Example 4: Data Analysis and Visualization
```matlab
% Load all datasets
normal_Iin = csvread('normal_Iin.csv');
normal_Uout = csvread('normal_Uout.csv');
ut3delay_Iin = csvread('ut3delay_Iin.csv');
ut3delay_Uout = csvread('ut3delay_Uout.csv');

% Create time vector
time = linspace(0, 0.1, 1001);

% Plot comparison of normal vs fault conditions
figure;
subplot(2,1,1);
plot(time, normal_Iin(:,1), 'b-', 'LineWidth', 2);
hold on;
plot(time, ut3delay_Iin(:,1), 'r--', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Input Current (A)');
title('Input Current Comparison: Normal vs UT3 Delay');
legend('Normal', 'UT3 Delay');

subplot(2,1,2);
plot(time, normal_Uout(:,1), 'b-', 'LineWidth', 2);
hold on;
plot(time, ut3delay_Uout(:,1), 'r--', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Output Voltage (V)');
title('Output Voltage Comparison: Normal vs UT3 Delay');
legend('Normal', 'UT3 Delay');
```

## Parameter Reference

### Simulation Parameters
| Parameter | Description | Default Value | Range |
|-----------|-------------|---------------|-------|
| `num_samples` | Number of simulation runs | 50 | 1-1000 |
| `time_series_length` | Data points per simulation | 1001 | 100-10000 |
| `resistance_range` | Load resistance range (ohms) | [0.4, 1.0] | [0.1, 10.0] |
| `voltage_range` | Source voltage range (V) | [5301, 6099] | [1000, 10000] |

### Timing Parameters
| Parameter | Description | Normal Value | Delay Range |
|-----------|-------------|--------------|-------------|
| `ut3` | Timing parameter 3 (ms) | 150 | 30-75 (20%-50%) |
| `ut4` | Timing parameter 4 (ms) | 150 | 165-225 (10%-50% increase) |
| `ut5` | Timing parameter 5 (ms) | 150 | 165-225 (10%-50% increase) |
| `ut6` | Timing parameter 6 (ms) | 80 | 88-120 (10%-50% increase) |

### Simulink Model Parameters
| Parameter | Path | Description |
|-----------|------|-------------|
| AC Voltage Source | `OLTC_simulation/AC Voltage Source` | Source voltage amplitude |
| Load Resistance | `OLTC_simulation/Series RLC Branch1` | Load resistance value |

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Simulink Model Not Found
**Error**: `Error: Model 'OLTC_simulation' not found`
**Solution**: 
```matlab
% Ensure the .slx file is in the current directory
ls *.slx
% If not found, navigate to the correct directory
cd('path/to/program');
```

#### Issue 2: Empty Timeseries Data
**Error**: `Warning: Timeseries data for Iin or Uout is empty`
**Solution**:
```matlab
% Check if the Simulink model outputs are correctly configured
% Verify the output block names match: 'Iin' and 'Uout'
% Ensure the simulation time is sufficient (0.1 seconds)
```

#### Issue 3: CSV File Write Errors
**Error**: `Error writing CSV file`
**Solution**:
```matlab
% Check write permissions in the current directory
% Ensure sufficient disk space
% Verify the data matrix is not empty before writing
```

#### Issue 4: Parameter Setting Errors
**Error**: `Error setting parameter in Simulink model`
**Solution**:
```matlab
% Verify the parameter path is correct
% Ensure the model is loaded before setting parameters
% Check parameter value ranges are within acceptable limits
```

### Performance Optimization Tips

1. **Batch Processing**: For large datasets, consider running simulations in batches
2. **Memory Management**: Clear large variables between simulation runs
3. **Parallel Processing**: Use MATLAB's parallel computing toolbox for multiple simulations
4. **Data Compression**: Consider saving data in compressed formats for large datasets

### Validation and Quality Assurance

```matlab
% Data validation function
function validate_dataset(filename)
    data = csvread(filename);
    
    % Check dimensions
    [rows, cols] = size(data);
    assert(rows == 1001, 'Expected 1001 time points');
    assert(cols == 50, 'Expected 50 simulations');
    
    % Check for NaN or Inf values
    assert(~any(isnan(data(:))), 'Dataset contains NaN values');
    assert(~any(isinf(data(:))), 'Dataset contains Inf values');
    
    % Check data range
    fprintf('Data range: [%.2f, %.2f]\n', min(data(:)), max(data(:)));
    
    disp('Dataset validation passed');
end
```

## Integration with Machine Learning

### Data Preprocessing for ML
```matlab
% Load and prepare data for machine learning
function [X, y] = prepare_ml_data()
    % Load all datasets
    normal_Iin = csvread('normal_Iin.csv');
    normal_Uout = csvread('normal_Uout.csv');
    ut3delay_Iin = csvread('ut3delay_Iin.csv');
    ut3delay_Uout = csvread('ut3delay_Uout.csv');
    
    % Combine features (current and voltage)
    X_normal = [normal_Iin; normal_Uout];
    X_ut3delay = [ut3delay_Iin; ut3delay_Uout];
    
    % Create labels (0: normal, 1: ut3 delay)
    y_normal = zeros(size(X_normal, 2), 1);
    y_ut3delay = ones(size(X_ut3delay, 2), 1);
    
    % Combine datasets
    X = [X_normal, X_ut3delay];
    y = [y_normal; y_ut3delay];
end
```

### Feature Engineering
```matlab
% Extract statistical features from time series
function features = extract_features(data)
    features = [];
    for i = 1:size(data, 2)
        signal = data(:, i);
        
        % Statistical features
        mean_val = mean(signal);
        std_val = std(signal);
        max_val = max(signal);
        min_val = min(signal);
        rms_val = rms(signal);
        
        % Frequency domain features
        fft_vals = abs(fft(signal));
        dominant_freq = find(fft_vals == max(fft_vals), 1);
        
        % Combine features
        signal_features = [mean_val, std_val, max_val, min_val, rms_val, dominant_freq];
        features = [features; signal_features];
    end
end
```

This documentation provides a comprehensive guide to using the OLTC simulation project for research, development, and machine learning applications in power transformer fault diagnosis.