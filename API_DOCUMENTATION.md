# OLTC Simulation Project - API Documentation

## Table of Contents
- [Project Overview](#project-overview)
- [System Requirements](#system-requirements)
- [Core Components](#core-components)
- [Public APIs](#public-apis)
- [Data Generation Functions](#data-generation-functions)
- [Simulink Model](#simulink-model)
- [Data Formats](#data-formats)
- [Usage Examples](#usage-examples)
- [Configuration Parameters](#configuration-parameters)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Project Overview

The OLTC (On-Load Tap Changer) Simulation Project provides comprehensive tools for simulating electrical behavior of oil-immersed power transformer tap changers. The system generates datasets for AI-based fault diagnosis systems using deep learning approaches.

### Key Features
- **Simulink-based OLTC simulation** with realistic electrical parameters
- **Multiple fault condition modeling** (normal, ut3 delay, ut4-6 delay)
- **Configurable dataset generation** for machine learning training
- **High-resolution data capture** (10,000Hz sampling rate)
- **Randomized parameter testing** for robust model training

## System Requirements

- **MATLAB R2018b or later**
- **Simulink** with the following toolboxes:
  - Simscape Electrical (Power Systems)
  - Signal Processing Toolbox
- **Minimum 4GB RAM** for simulation processing
- **1GB free disk space** for dataset storage

## Core Components

The project consists of three main functional modules:

1. **Simulation Engine** (`OLTC_simulation.slx`)
2. **Dataset Generators** (MATLAB scripts)
3. **Data Output System** (CSV export functionality)

## Public APIs

### Data Generation Functions

#### `dataset_create.m`

**Purpose**: Generates datasets under normal OLTC operating conditions.

**Function Signature**:
```matlab
% No explicit function signature - script execution
% Modifiable parameters available at script header
```

**Parameters**:
- `num_samples` (integer, default: 50): Number of simulation runs
- `time_series_length` (integer, default: 1001): Data points per simulation
- `resistance_range` (array, default: [0.4, 1.0]): Load resistance variation range (Ohms)
- `voltage_range` (array, default: [0.93*5700, 1.07*5700]): Source voltage fluctuation range (V)

**Timing Parameters** (Fixed for Normal Operation):
- `ut3_value`: 150ms (Contact opening delay)
- `ut4_value`: 150ms (Transition period)
- `ut5_value`: 150ms (Contact closing delay)
- `ut6_value`: 80ms (Stabilization period)

**Output Files**:
- `normal_Iin.csv`: Input current data matrix (1001×50)
- `normal_Uout.csv`: Output voltage data matrix (1001×50)

**Example Usage**:
```matlab
% Modify parameters in script header
num_samples = 100;  % Generate 100 simulations instead of 50
time_series_length = 1001;  % Keep default resolution

% Run the script
run('dataset_create.m');
```

---

#### `dataset_ut3_delay.m`

**Purpose**: Generates datasets with ut3 parameter delay fault conditions.

**Function Signature**:
```matlab
% No explicit function signature - script execution
% Modifiable parameters available at script header
```

**Parameters**:
- `num_samples` (integer, default: 50): Number of simulation runs
- `time_series_length` (integer, default: 1001): Data points per simulation
- `resistance_range` (array, default: [0.4, 1.0]): Load resistance variation range (Ohms)
- `voltage_range` (array, default: [0.93*5700, 1.07*5700]): Source voltage fluctuation range (V)

**Timing Parameters**:
- `ut3_values`: Variable (20%-50% of normal 150ms) - **FAULT CONDITION**
- `ut4_value`: 150ms (Fixed normal)
- `ut5_value`: 150ms (Fixed normal)
- `ut6_value`: 80ms (Fixed normal)

**Fault Modeling**:
- **ut3 delay range**: 30ms - 75ms (150ms × 0.2 to 150ms × 0.5)
- **Fault type**: Contact opening mechanism delay
- **Random distribution**: Uniform across delay range

**Output Files**:
- `ut3delay_Iin.csv`: Input current data with ut3 fault (1001×50)
- `ut3delay_Uout.csv`: Output voltage data with ut3 fault (1001×50)

**Example Usage**:
```matlab
% Customize fault severity
% Edit line 34 in the script:
ut3_values = unique(rand(num_samples * 2, 1) * 0.3 + 0.1) * 150;  % 10%-40% range

% Run simulation
run('dataset_ut3_delay.m');
```

---

#### `dataset_ut456_delay.m`

**Purpose**: Generates datasets with ut4, ut5, and ut6 parameter delay fault conditions.

**Function Signature**:
```matlab
% No explicit function signature - script execution
% Modifiable parameters available at script header
```

**Parameters**:
- `num_samples` (integer, default: 50): Number of simulation runs
- `time_series_length` (integer, default: 1001): Data points per simulation
- `resistance_range` (array, default: [0.4, 1.0]): Load resistance variation range (Ohms)
- `voltage_range` (array, default: [0.93*5700, 1.07*5700]): Source voltage fluctuation range (V)

**Timing Parameters**:
- `ut3_value`: 150ms (Fixed normal)
- `ut4_values`: Variable (110%-150% of normal 150ms) - **FAULT CONDITION**
- `ut5_values`: Variable (110%-150% of normal 150ms) - **FAULT CONDITION**
- `ut6_values`: Variable (110%-150% of normal 80ms) - **FAULT CONDITION**

**Fault Modeling**:
- **ut4/ut5 delay range**: 165ms - 225ms (150ms × 1.1 to 150ms × 1.5)
- **ut6 delay range**: 88ms - 120ms (80ms × 1.1 to 80ms × 1.5)
- **Fault type**: Multiple timing mechanism degradation
- **Random distribution**: Independent uniform distributions for each parameter

**Output Files**:
- `ut4-6delay_Iin.csv`: Input current data with multiple faults (1001×50)
- `ut4-6delay_Uout.csv`: Output voltage data with multiple faults (1001×50)

**Example Usage**:
```matlab
% Adjust fault severity ranges
% Edit lines 32-38 in the script for custom ranges:
ut4_values = unique(150 + rand(num_samples * 2, 1) * (0.3 * 150 - 0.05 * 150) + 0.05 * 150);  % 5%-30% increase

% Run simulation
run('dataset_ut456_delay.m');
```

## Simulink Model

### `OLTC_simulation.slx`

**Purpose**: Core simulation engine modeling OLTC electrical and mechanical behavior.

**Model Components**:
- **AC Voltage Source**: Configurable amplitude power supply
- **Series RLC Branch**: Load impedance modeling
- **OLTC Mechanism**: 9-step switching process simulation
- **Measurement Blocks**: Current and voltage sensors
- **External Inputs**: ut3, ut4, ut5, ut6 timing signals

**Configurable Parameters**:

| Parameter | Block Location | Purpose | Range |
|-----------|---------------|---------|-------|
| `Amplitude` | `AC Voltage Source` | Supply voltage | 5301V - 6099V |
| `Resistance` | `Series RLC Branch1` | Load resistance | 0.4Ω - 1.0Ω |
| `ExternalInput` | Model level | Timing signals | timeseries objects |

**Simulation Settings**:
- **Stop Time**: 0.1 seconds
- **Solver**: Variable-step (auto-selected)
- **Sample Rate**: 10,000 Hz
- **Output Points**: 1001 samples per run

**External Signal Interface**:
```matlab
% Signal format for external inputs
ut3_signal = timeseries(value_array, time_array);
ut4_signal = timeseries(value_array, time_array);
ut5_signal = timeseries(value_array, time_array);
ut6_signal = timeseries(value_array, time_array);

% Simulation execution
simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
             'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
```

**Output Variables**:
- `Iin`: Input current timeseries (Amperes)
- `Uout`: Output voltage timeseries (Volts)

## Data Formats

### CSV Output Structure

All generated datasets follow a consistent matrix format:

**Dimensions**: `[time_points × simulation_runs]`
- **Rows**: 1001 time points (0.1ms resolution over 0.1s)
- **Columns**: 50 simulation runs (default)

**File Naming Convention**:
- `{condition}_{signal}.csv`
- **Conditions**: `normal`, `ut3delay`, `ut4-6delay`
- **Signals**: `Iin` (input current), `Uout` (output voltage)

### Sample Data Structure

```matlab
% Example data matrix structure
data_matrix = [
    % Time Point 1 across all simulations
    t1_sim1, t1_sim2, t1_sim3, ..., t1_sim50;
    % Time Point 2 across all simulations  
    t2_sim1, t2_sim2, t2_sim3, ..., t2_sim50;
    % ...
    % Time Point 1001 across all simulations
    t1001_sim1, t1001_sim2, t1001_sim3, ..., t1001_sim50
];
```

### Data Value Ranges

| Signal Type | Typical Range | Units | Notes |
|-------------|--------------|-------|-------|
| Input Current (Iin) | 0.5 - 15.0 | Amperes | Varies with load and voltage |
| Output Voltage (Uout) | 4500 - 6500 | Volts | Transformer secondary |
| Time Resolution | 0.0001 | Seconds | 10kHz sampling |

## Usage Examples

### Basic Dataset Generation

```matlab
%% Example 1: Generate Normal Operation Dataset
% Navigate to program directory
cd('program');

% Generate normal operation data
run('dataset_create.m');

% Verify output files
if exist('normal_Iin.csv', 'file') && exist('normal_Uout.csv', 'file')
    fprintf('Normal operation dataset generated successfully.\n');
    
    % Load and inspect data
    current_data = csvread('normal_Iin.csv');
    voltage_data = csvread('normal_Uout.csv');
    
    fprintf('Data dimensions: %d x %d\n', size(current_data));
    fprintf('Current range: %.2f - %.2f A\n', min(current_data(:)), max(current_data(:)));
    fprintf('Voltage range: %.2f - %.2f V\n', min(voltage_data(:)), max(voltage_data(:)));
end
```

### Custom Parameter Configuration

```matlab
%% Example 2: Custom Simulation Parameters
% Edit parameters before running
edit('dataset_create.m');

% Modify these values in the script header:
num_samples = 100;                    % More simulations
time_series_length = 2001;            % Higher resolution (20kHz)
resistance_range = [0.2, 1.5];       % Wider load range
voltage_range = [0.90*5700, 1.10*5700]; % Wider voltage range

% Save and run
run('dataset_create.m');
```

### Fault Condition Analysis

```matlab
%% Example 3: Comprehensive Fault Dataset Generation
% Generate all fault conditions
fault_scripts = {'dataset_create.m', 'dataset_ut3_delay.m', 'dataset_ut456_delay.m'};
fault_labels = {'normal', 'ut3_fault', 'ut456_fault'};

for i = 1:length(fault_scripts)
    fprintf('Generating %s dataset...\n', fault_labels{i});
    run(fault_scripts{i});
    fprintf('Completed %s\n', fault_labels{i});
end

fprintf('All fault condition datasets generated.\n');
```

### Data Loading and Preprocessing

```matlab
%% Example 4: Load and Preprocess Generated Data
function [X, y] = load_oltc_dataset()
    % Load all datasets
    normal_I = csvread('normal_Iin.csv');
    normal_U = csvread('normal_Uout.csv');
    
    ut3_I = csvread('ut3delay_Iin.csv');
    ut3_U = csvread('ut3delay_Uout.csv');
    
    ut456_I = csvread('ut4-6delay_Iin.csv');
    ut456_U = csvread('ut4-6delay_Uout.csv');
    
    % Combine features (current + voltage)
    normal_X = [normal_I; normal_U];
    ut3_X = [ut3_I; ut3_U];
    ut456_X = [ut456_I; ut456_U];
    
    % Combine all data
    X = [normal_X, ut3_X, ut456_X];
    
    % Create labels (0: normal, 1: ut3 fault, 2: ut456 fault)
    y = [zeros(1, size(normal_X,2)), ones(1, size(ut3_X,2)), 2*ones(1, size(ut456_X,2))];
    
    fprintf('Dataset loaded: %d features x %d samples\n', size(X));
    fprintf('Classes: Normal=%d, UT3=%d, UT456=%d\n', ...
            sum(y==0), sum(y==1), sum(y==2));
end

% Usage
[features, labels] = load_oltc_dataset();
```

## Configuration Parameters

### Global Simulation Settings

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `num_samples` | 50 | 1-1000 | Number of independent simulation runs |
| `time_series_length` | 1001 | 100-10000 | Data points per simulation |
| `simulation_time` | 0.1 | 0.01-1.0 | Total simulation duration (seconds) |

### Electrical Parameters

| Parameter | Default | Physical Range | Units |
|-----------|---------|----------------|-------|
| `resistance_range` | [0.4, 1.0] | [0.1, 10.0] | Ohms |
| `voltage_range` | [5301, 6099] | [4000, 8000] | Volts |
| `sampling_rate` | 10000 | 1000-50000 | Hz |

### OLTC Timing Parameters

| Parameter | Normal Value | Fault Range | Description |
|-----------|-------------|-------------|-------------|
| `ut3` | 150ms | 30-75ms | Contact opening delay |
| `ut4` | 150ms | 165-225ms | Transition process |
| `ut5` | 150ms | 165-225ms | Contact closing delay |
| `ut6` | 80ms | 88-120ms | Stabilization period |

### Performance Tuning

```matlab
%% Memory Optimization for Large Datasets
% For large datasets, consider processing in batches
batch_size = 10;  % Process 10 simulations at a time
total_samples = 100;

for batch = 1:batch_size:total_samples
    batch_end = min(batch + batch_size - 1, total_samples);
    fprintf('Processing batch %d-%d...\n', batch, batch_end);
    
    % Modify num_samples in script
    % Process batch
    % Save intermediate results
end
```

## Error Handling

### Common Issues and Solutions

#### 1. Simulink Model Not Found
**Error**: `Cannot find Simulink model 'OLTC_simulation'`

**Solution**:
```matlab
% Ensure correct working directory
cd('program');  % Navigate to program folder
if ~exist('OLTC_simulation.slx', 'file')
    error('OLTC_simulation.slx not found in current directory');
end
```

#### 2. Empty Timeseries Data
**Error**: `Timeseries data for Iin or Uout is empty`

**Solution**:
```matlab
% Add error checking in simulation loop
if ~isempty(Iin_timeseries) && ~isempty(Uout_timeseries)
    % Process data
else
    warning('Simulation %d failed - retrying...', i);
    % Retry simulation or skip
    continue;
end
```

#### 3. Memory Issues with Large Datasets
**Error**: `Out of memory`

**Solution**:
```matlab
% Use smaller batch sizes or data types
data_Iin = zeros(time_series_length, num_samples, 'single');  % Use single precision
data_Uout = zeros(time_series_length, num_samples, 'single');

% Or process in batches
batch_size = 10;
for batch = 1:batch_size:num_samples
    % Process batch and save incrementally
end
```

#### 4. Parameter Setting Failures
**Error**: `Invalid parameter value`

**Solution**:
```matlab
% Validate parameters before setting
try
    set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(input_voltage));
catch ME
    warning('Failed to set voltage parameter: %s', ME.message);
    % Use fallback value or skip simulation
end
```

### Debug Mode Configuration

```matlab
%% Enable Debug Mode
debug_mode = true;

if debug_mode
    % Additional logging
    fprintf('Simulation %d: V=%.1f, R=%.2f, ut3=%.1f\n', ...
            i, input_voltage, load_resistance, ut3_value);
    
    % Save intermediate variables
    debug_data.voltage(i) = input_voltage;
    debug_data.resistance(i) = load_resistance;
    debug_data.timing(i,:) = [ut3_value, ut4_value, ut5_value, ut6_value];
end
```

## Best Practices

### 1. Reproducibility

```matlab
% Set random seed for reproducible results
rng(42);  % Fixed seed

% Document parameter changes
param_log = struct();
param_log.num_samples = num_samples;
param_log.voltage_range = voltage_range;
param_log.resistance_range = resistance_range;
param_log.timestamp = datetime('now');

% Save parameter log with data
save('simulation_parameters.mat', 'param_log');
```

### 2. Data Validation

```matlab
% Validate generated data
function validate_dataset(data_matrix, signal_name)
    % Check for NaN or Inf values
    if any(isnan(data_matrix(:))) || any(isinf(data_matrix(:)))
        warning('Invalid values found in %s dataset', signal_name);
    end
    
    % Check expected dimensions
    expected_size = [1001, 50];
    if ~isequal(size(data_matrix), expected_size)
        warning('Unexpected data dimensions for %s: [%d x %d]', ...
                signal_name, size(data_matrix));
    end
    
    % Check value ranges
    if strcmp(signal_name, 'current')
        valid_range = [0, 50];  % Amperes
    else  % voltage
        valid_range = [3000, 8000];  % Volts
    end
    
    if min(data_matrix(:)) < valid_range(1) || max(data_matrix(:)) > valid_range(2)
        warning('%s values outside expected range [%.1f, %.1f]', ...
                signal_name, valid_range);
    end
end
```

### 3. Performance Optimization

```matlab
% Pre-allocate arrays with appropriate data types
data_Iin = zeros(time_series_length, num_samples, 'single');
data_Uout = zeros(time_series_length, num_samples, 'single');

% Minimize Simulink model compilation
model_compiled = false;
if ~model_compiled
    % Load and compile model once
    load_system('OLTC_simulation');
    model_compiled = true;
end

% Use parallel processing for independent simulations
if license('test', 'Parallel_Computing_Toolbox')
    parfor i = 1:num_samples
        % Parallel simulation loop
    end
end
```

### 4. File Organization

```matlab
% Create organized output structure
output_dir = sprintf('OLTC_Dataset_%s', datestr(now, 'yyyymmdd_HHMMSS'));
mkdir(output_dir);

% Save with descriptive names
filename_current = fullfile(output_dir, sprintf('%s_current_%dsamples.csv', condition, num_samples));
filename_voltage = fullfile(output_dir, sprintf('%s_voltage_%dsamples.csv', condition, num_samples));

csvwrite(filename_current, data_Iin);
csvwrite(filename_voltage, data_Uout);
```

### 5. Documentation Standards

```matlab
% Add comprehensive headers to generated data files
header_info = {
    sprintf('# OLTC Dataset - %s Condition', condition);
    sprintf('# Generated: %s', datestr(now));
    sprintf('# Samples: %d', num_samples);
    sprintf('# Time points: %d', time_series_length);
    sprintf('# Sampling rate: 10000 Hz');
    sprintf('# Simulation time: 0.1 seconds');
    '# Data format: [time_points x simulation_runs]';
    '# Units: Current (A), Voltage (V)';
};

% Write header as separate file
header_file = strrep(filename_current, '.csv', '_info.txt');
fid = fopen(header_file, 'w');
for i = 1:length(header_info)
    fprintf(fid, '%s\n', header_info{i});
end
fclose(fid);
```

---

## Support and Maintenance

For technical support or bug reports, please refer to the project repository or contact the development team. This API documentation is maintained alongside the codebase and should be updated when new features or modifications are implemented.

**Last Updated**: Generated automatically from codebase analysis
**Version Compatibility**: MATLAB R2018b+, Simulink 2018b+