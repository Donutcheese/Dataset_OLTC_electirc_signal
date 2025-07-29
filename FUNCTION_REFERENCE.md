# OLTC Simulation - Function Reference Guide

## Quick Function Index

| Function | Purpose | Output Files | Key Parameters |
|----------|---------|--------------|----------------|
| [`dataset_create.m`](#dataset_createm) | Normal operation data generation | `normal_Iin.csv`, `normal_Uout.csv` | All timing parameters fixed |
| [`dataset_ut3_delay.m`](#dataset_ut3_delaym) | UT3 fault condition simulation | `ut3delay_Iin.csv`, `ut3delay_Uout.csv` | ut3 variable (20-50% of normal) |
| [`dataset_ut456_delay.m`](#dataset_ut456_delaym) | Multiple timing fault simulation | `ut4-6delay_Iin.csv`, `ut4-6delay_Uout.csv` | ut4,ut5,ut6 variable (110-150% of normal) |

---

## `dataset_create.m`

### Synopsis
```matlab
% Normal OLTC operation dataset generation
% Fixed timing parameters, randomized electrical conditions
```

### Configurable Parameters
```matlab
num_samples = 50;                     % Number of simulation runs
time_series_length = 1001;            % Data points per simulation
resistance_range = [0.4, 1.0];       % Load resistance range (Ohms)
voltage_range = [0.93*5700, 1.07*5700]; % Voltage fluctuation range (V)
```

### Fixed Timing Parameters
```matlab
ut3_value = 150;  % Contact opening delay (ms)
ut4_value = 150;  % Transition period (ms) 
ut5_value = 150;  % Contact closing delay (ms)
ut6_value = 80;   % Stabilization period (ms)
```

### Generated Outputs
- **`normal_Iin.csv`**: Input current data (1001×50 matrix)
- **`normal_Uout.csv`**: Output voltage data (1001×50 matrix)

### Usage Pattern
```matlab
cd('program');
% Optionally edit parameters in script
run('dataset_create.m');
```

---

## `dataset_ut3_delay.m`

### Synopsis
```matlab
% UT3 fault condition dataset generation
% Variable ut3 timing, fixed other parameters, randomized electrical conditions
```

### Configurable Parameters
```matlab
num_samples = 50;                     % Number of simulation runs
time_series_length = 1001;            % Data points per simulation
resistance_range = [0.4, 1.0];       % Load resistance range (Ohms)
voltage_range = [0.93*5700, 1.07*5700]; % Voltage fluctuation range (V)
```

### Timing Parameters
```matlab
ut3_values = variable;  % 20%-50% of 150ms (FAULT: 30-75ms)
ut4_value = 150;        % Fixed normal (ms)
ut5_value = 150;        % Fixed normal (ms)
ut6_value = 80;         % Fixed normal (ms)
```

### Fault Characteristics
- **Fault Type**: Contact opening mechanism delay
- **Severity Range**: 30ms - 75ms (50-80% reduction from normal)
- **Distribution**: Uniform random within range
- **Physical Meaning**: Sluggish contact separation

### Generated Outputs
- **`ut3delay_Iin.csv`**: Input current with ut3 fault (1001×50 matrix)
- **`ut3delay_Uout.csv`**: Output voltage with ut3 fault (1001×50 matrix)

### Usage Pattern
```matlab
cd('program');
% Optionally modify fault severity in line 34
run('dataset_ut3_delay.m');
```

### Customization Example
```matlab
% Edit line 34 for custom fault range:
ut3_values = unique(rand(num_samples * 2, 1) * 0.3 + 0.1) * 150;  % 10%-40% range
```

---

## `dataset_ut456_delay.m`

### Synopsis
```matlab
% Multiple timing fault dataset generation  
% Variable ut4, ut5, ut6 timing, fixed ut3, randomized electrical conditions
```

### Configurable Parameters
```matlab
num_samples = 50;                     % Number of simulation runs
time_series_length = 1001;            % Data points per simulation
resistance_range = [0.4, 1.0];       % Load resistance range (Ohms)
voltage_range = [0.93*5700, 1.07*5700]; % Voltage fluctuation range (V)
```

### Timing Parameters
```matlab
ut3_value = 150;        % Fixed normal (ms)
ut4_values = variable;  % 110%-150% of 150ms (FAULT: 165-225ms)
ut5_values = variable;  % 110%-150% of 150ms (FAULT: 165-225ms)  
ut6_values = variable;  % 110%-150% of 80ms (FAULT: 88-120ms)
```

### Fault Characteristics
- **Fault Type**: Multiple timing mechanism degradation
- **ut4/ut5 Range**: 165ms - 225ms (10-50% increase from normal)
- **ut6 Range**: 88ms - 120ms (10-50% increase from normal)
- **Distribution**: Independent uniform random for each parameter
- **Physical Meaning**: Worn or damaged switching mechanisms

### Generated Outputs
- **`ut4-6delay_Iin.csv`**: Input current with multiple faults (1001×50 matrix)
- **`ut4-6delay_Uout.csv`**: Output voltage with multiple faults (1001×50 matrix)

### Usage Pattern
```matlab
cd('program');
% Optionally modify fault ranges in lines 32-38
run('dataset_ut456_delay.m');
```

### Customization Example
```matlab
% Edit lines 32-38 for custom fault ranges:
ut4_values = unique(150 + rand(num_samples * 2, 1) * (0.2 * 150) + 0.05 * 150);  % 5%-25% increase
ut5_values = unique(150 + rand(num_samples * 2, 1) * (0.2 * 150) + 0.05 * 150);  % 5%-25% increase
ut6_values = unique(80 + rand(num_samples * 2, 1) * (0.2 * 80) + 0.05 * 80);     % 5%-25% increase
```

---

## Common Parameters Across All Functions

### Electrical Parameter Ranges
```matlab
% Standard operating ranges
resistance_range = [0.4, 1.0];              % Load resistance (Ohms)
voltage_range = [0.93*5700, 1.07*5700];     % ±7% voltage variation (V)

% Extended ranges for broader testing
resistance_range = [0.2, 1.5];              % Wider load range
voltage_range = [0.85*5700, 1.15*5700];     % ±15% voltage variation
```

### Simulation Control
```matlab
num_samples = 50;           % Standard dataset size
num_samples = 100;          % Large dataset
num_samples = 20;           % Quick testing

time_series_length = 1001;  % Standard resolution (10kHz)
time_series_length = 2001;  % High resolution (20kHz)
time_series_length = 501;   % Low resolution (5kHz)
```

---

## Simulink Model Interface

### Required Model: `OLTC_simulation.slx`

#### Key Blocks and Parameters
```matlab
% AC Voltage Source configuration
set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(voltage));

% Load resistance configuration  
set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(resistance));

% External timing signals
simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
             'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
```

#### Output Signal Access
```matlab
% Extract simulation results
Iin_timeseries = simOut.get('Iin');    % Input current
Uout_timeseries = simOut.get('Uout');  % Output voltage

% Convert to data arrays
Iin_data = Iin_timeseries.Data;
Uout_data = Uout_timeseries.Data;
```

---

## Data Processing Functions

### Data Loading Template
```matlab
function [current_data, voltage_data] = load_dataset(condition)
    % Load OLTC dataset for specified condition
    % condition: 'normal', 'ut3delay', or 'ut4-6delay'
    
    switch condition
        case 'normal'
            current_data = csvread('normal_Iin.csv');
            voltage_data = csvread('normal_Uout.csv');
        case 'ut3delay'
            current_data = csvread('ut3delay_Iin.csv');
            voltage_data = csvread('ut3delay_Uout.csv');
        case 'ut4-6delay'
            current_data = csvread('ut4-6delay_Iin.csv');
            voltage_data = csvread('ut4-6delay_Uout.csv');
        otherwise
            error('Unknown condition: %s', condition);
    end
end
```

### Batch Processing Template
```matlab
function generate_all_datasets(num_samples)
    % Generate all three dataset types with specified sample count
    if nargin < 1, num_samples = 50; end
    
    scripts = {'dataset_create.m', 'dataset_ut3_delay.m', 'dataset_ut456_delay.m'};
    conditions = {'normal', 'ut3_delay', 'ut456_delay'};
    
    for i = 1:length(scripts)
        fprintf('Generating %s dataset (%d samples)...\n', conditions{i}, num_samples);
        
        % Modify num_samples in script if needed
        % This requires manual editing or text replacement
        
        run(scripts{i});
        fprintf('Completed %s dataset.\n', conditions{i});
    end
end
```

---

## Error Handling Patterns

### Robust Simulation Loop
```matlab
% Error-resistant simulation execution
for i = 1:num_samples
    try
        % Set parameters
        set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(input_voltage));
        set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(load_resistance));
        
        % Run simulation
        simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                     'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
        
        % Extract data
        Iin_data = simOut.get('Iin').Data;
        Uout_data = simOut.get('Uout').Data;
        
        % Validate data
        if isempty(Iin_data) || isempty(Uout_data)
            warning('Empty data in simulation %d, skipping...', i);
            continue;
        end
        
        % Store data
        data_Iin(:, i) = Iin_data;
        data_Uout(:, i) = Uout_data;
        
    catch ME
        warning('Simulation %d failed: %s', i, ME.message);
        % Continue with next simulation
        continue;
    end
end
```

### Data Validation Function
```matlab
function isValid = validate_oltc_data(data_matrix, signal_type)
    % Validate OLTC simulation data
    % signal_type: 'current' or 'voltage'
    
    isValid = true;
    
    % Check for invalid values
    if any(isnan(data_matrix(:))) || any(isinf(data_matrix(:)))
        warning('Invalid values (NaN/Inf) detected');
        isValid = false;
    end
    
    % Check dimensions
    expected_rows = 1001;  % Standard time series length
    if size(data_matrix, 1) ~= expected_rows
        warning('Unexpected number of time points: %d (expected %d)', ...
                size(data_matrix, 1), expected_rows);
        isValid = false;
    end
    
    % Check value ranges
    switch signal_type
        case 'current'
            valid_range = [0, 50];  % Amperes
        case 'voltage'
            valid_range = [3000, 8000];  % Volts
        otherwise
            warning('Unknown signal type: %s', signal_type);
            return;
    end
    
    data_min = min(data_matrix(:));
    data_max = max(data_matrix(:));
    
    if data_min < valid_range(1) || data_max > valid_range(2)
        warning('%s values [%.2f, %.2f] outside expected range [%.2f, %.2f]', ...
                signal_type, data_min, data_max, valid_range(1), valid_range(2));
        isValid = false;
    end
end
```

---

## Performance Optimization

### Memory-Efficient Processing
```matlab
% For large datasets, use single precision
data_Iin = zeros(time_series_length, num_samples, 'single');
data_Uout = zeros(time_series_length, num_samples, 'single');

% Process in batches for very large datasets
batch_size = 10;
for batch_start = 1:batch_size:num_samples
    batch_end = min(batch_start + batch_size - 1, num_samples);
    % Process batch_start:batch_end
    % Save intermediate results if needed
end
```

### Parallel Processing Template
```matlab
% Use parallel processing if available
if license('test', 'Parallel_Computing_Toolbox')
    % Prepare data for parallel processing
    input_voltages_cell = num2cell(input_voltages);
    load_resistances_cell = num2cell(load_resistances);
    ut_values_cell = num2cell(ut3_values);  % or ut4,ut5,ut6 values
    
    % Parallel simulation loop
    parfor i = 1:num_samples
        % Individual simulation code here
        % Note: Simulink models may need special handling in parfor
    end
else
    % Fall back to sequential processing
    for i = 1:num_samples
        % Sequential simulation code
    end
end
```

---

## Quick Start Checklist

### Prerequisites
- [ ] MATLAB R2018b+ installed
- [ ] Simulink with Simscape Electrical toolbox
- [ ] Navigate to `program/` directory
- [ ] Verify `OLTC_simulation.slx` exists

### Basic Dataset Generation
```matlab
% 1. Generate normal operation data
run('dataset_create.m');

% 2. Generate ut3 fault data  
run('dataset_ut3_delay.m');

% 3. Generate multiple fault data
run('dataset_ut456_delay.m');

% 4. Verify output files
files = {'normal_Iin.csv', 'normal_Uout.csv', ...
         'ut3delay_Iin.csv', 'ut3delay_Uout.csv', ...
         'ut4-6delay_Iin.csv', 'ut4-6delay_Uout.csv'};

for i = 1:length(files)
    if exist(files{i}, 'file')
        fprintf('✓ %s generated\n', files{i});
    else
        fprintf('✗ %s missing\n', files{i});
    end
end
```

### Custom Configuration
```matlab
% Edit script parameters before running
% Common modifications:
%   - num_samples: Change dataset size
%   - resistance_range: Adjust load conditions  
%   - voltage_range: Modify supply voltage variation
%   - ut_values calculation: Customize fault severity
```

This function reference provides quick access to all essential information for using the OLTC simulation system effectively.