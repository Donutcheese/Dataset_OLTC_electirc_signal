# OLTC Simulation Project - Function Reference

## Table of Contents
1. [Simulink Model Functions](#simulink-model-functions)
2. [Data Generation Functions](#data-generation-functions)
3. [Utility Functions](#utility-functions)
4. [Parameter Configuration](#parameter-configuration)
5. [Output Functions](#output-functions)

## Simulink Model Functions

### OLTC_simulation.slx

**Description**: Main Simulink simulation model for OLTC operations

**Model Structure**:
```
OLTC_simulation/
├── AC Voltage Source          # Power source
├── Series RLC Branch1         # Load resistance
├── OLTC Control System        # Timing control
├── Current Measurement        # Iin output
└── Voltage Measurement        # Uout output
```

**Key Parameters**:
- **AC Voltage Source/Amplitude**: Source voltage (V)
- **Series RLC Branch1/Resistance**: Load resistance (Ω)
- **Simulation/StopTime**: Simulation duration (s)
- **Simulation/Solver**: ODE solver type

**External Inputs**:
- `ut3_signal`: Timing parameter 3 (timeseries)
- `ut4_signal`: Timing parameter 4 (timeseries)
- `ut5_signal`: Timing parameter 5 (timeseries)
- `ut6_signal`: Timing parameter 6 (timeseries)

**Outputs**:
- `Iin`: Input current time series
- `Uout`: Output voltage time series

**Usage**:
```matlab
% Run simulation with external inputs
simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
             'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');

% Extract results
Iin_timeseries = simOut.get('Iin');
Uout_timeseries = simOut.get('Uout');
```

## Data Generation Functions

### dataset_create.m

**Purpose**: Generate normal operation datasets

**Function Type**: Script (no input parameters)

**Key Variables**:
```matlab
num_samples = 50;                    % Number of simulation runs
time_series_length = 1001;           % Data points per simulation
resistance_range = [0.4, 1.0];       % Load resistance range (ohms)
voltage_range = [5301, 6099];        % Source voltage range (V)
ut3_value = 150;                     % Fixed ut3 timing (ms)
ut4_value = 150;                     % Fixed ut4 timing (ms)
ut5_value = 150;                     % Fixed ut5 timing (ms)
ut6_value = 80;                      % Fixed ut6 timing (ms)
```

**Main Algorithm**:
1. Generate unique random values for voltage and resistance
2. Create fixed timing signals for ut3-ut6
3. Run simulations in loop
4. Collect and store data matrices
5. Save to CSV files

**Output Files**:
- `normal_Iin.csv`: Input current data (1001 × 50)
- `normal_Uout.csv`: Output voltage data (1001 × 50)

**Error Handling**:
```matlab
% Check for empty timeseries data
if ~isempty(Iin_timeseries) && ~isempty(Uout_timeseries)
    % Process data
else
    warning('Timeseries data for Iin or Uout is empty in iteration %d', i);
end
```

### dataset_ut3_delay.m

**Purpose**: Generate ut3 delay fault condition datasets

**Function Type**: Script (no input parameters)

**Key Variables**:
```matlab
num_samples = 50;                    % Number of simulation runs
ut3_delay_range = [0.2, 0.5];       % ut3 delay factor range
ut4_value = 150;                    % Fixed ut4 timing (ms)
ut5_value = 150;                    % Fixed ut5 timing (ms)
ut6_value = 80;                     % Fixed ut6 timing (ms)
```

**Main Algorithm**:
1. Generate random ut3 delay values (20%-50% of normal)
2. Maintain normal values for ut4, ut5, ut6
3. Run simulations with varying ut3 delays
4. Collect and store fault condition data
5. Save to CSV files

**Output Files**:
- `ut3delay_Iin.csv`: Input current data with ut3 delay (1001 × 50)
- `ut3delay_Uout.csv`: Output voltage data with ut3 delay (1001 × 50)

**ut3 Delay Calculation**:
```matlab
% Generate random ut3 delay values
ut3_values = unique(rand(num_samples * 2, 1) * 0.5 + 0.2) * 150;
ut3_values = ut3_values(1:num_samples);
```

### dataset_ut456_delay.m

**Purpose**: Generate ut4, ut5, ut6 delay fault condition datasets

**Function Type**: Script (no input parameters)

**Key Variables**:
```matlab
num_samples = 50;                    % Number of simulation runs
ut3_value = 150;                    % Fixed ut3 timing (ms)
ut4_delay_range = [0.1, 0.5];       % ut4 delay factor range
ut5_delay_range = [0.1, 0.5];       % ut5 delay factor range
ut6_delay_range = [0.1, 0.5];       % ut6 delay factor range
```

**Main Algorithm**:
1. Generate random delay values for ut4, ut5, ut6 (10%-50% increase)
2. Maintain normal value for ut3
3. Run simulations with multiple timing delays
4. Collect and store complex fault condition data
5. Save to CSV files

**Output Files**:
- `ut4-6delay_Iin.csv`: Input current data with ut4-6 delays (1001 × 50)
- `ut4-6delay_Uout.csv`: Output voltage data with ut4-6 delays (1001 × 50)

**Delay Calculation**:
```matlab
% Generate random delay values for ut4, ut5, ut6
ut4_values = unique(150 + rand(num_samples * 2, 1) * (0.5 * 150 - 0.1 * 150) + 0.1 * 150);
ut5_values = unique(150 + rand(num_samples * 2, 1) * (0.5 * 150 - 0.1 * 150) + 0.1 * 150);
ut6_values = unique(80 + rand(num_samples * 2, 1) * (0.5 * 80 - 0.1 * 80) + 0.1 * 80);
```

## Utility Functions

### Parameter Generation Functions

#### Generate Unique Random Values
```matlab
function values = generate_unique_values(num_samples, range, multiplier)
    % Generate unique random values within specified range
    values = unique(rand(num_samples * 2, 1) * (range(2) - range(1)) + range(1));
    values = values(1:num_samples);
    if nargin > 2
        values = values * multiplier;
    end
end
```

**Usage**:
```matlab
% Generate unique voltage values
voltage_values = generate_unique_values(50, [0.93, 1.07], 5700);

% Generate unique resistance values
resistance_values = generate_unique_values(50, [0.4, 1.0]);
```

#### Create Timeseries Signals
```matlab
function signal = create_timeseries_signal(value, time_length, duration)
    % Create timeseries signal with constant value
    time = linspace(0, duration, time_length);
    signal = timeseries(value * ones(size(time)), time);
end
```

**Usage**:
```matlab
% Create ut3 signal
ut3_signal = create_timeseries_signal(150, 1001, 0.1);
```

### Data Validation Functions

#### Validate Dataset
```matlab
function [is_valid, issues] = validate_dataset(filename, expected_rows, expected_cols)
    % Validate dataset file
    is_valid = true;
    issues = {};
    
    if ~exist(filename, 'file')
        is_valid = false;
        issues{end+1} = sprintf('File %s does not exist', filename);
        return;
    end
    
    try
        data = csvread(filename);
        [rows, cols] = size(data);
        
        if rows ~= expected_rows
            is_valid = false;
            issues{end+1} = sprintf('Expected %d rows, got %d', expected_rows, rows);
        end
        
        if cols ~= expected_cols
            is_valid = false;
            issues{end+1} = sprintf('Expected %d columns, got %d', expected_cols, cols);
        end
        
        if any(isnan(data(:)))
            is_valid = false;
            issues{end+1} = 'Dataset contains NaN values';
        end
        
        if any(isinf(data(:)))
            is_valid = false;
            issues{end+1} = 'Dataset contains Inf values';
        end
        
    catch ME
        is_valid = false;
        issues{end+1} = sprintf('Error reading file: %s', ME.message);
    end
end
```

**Usage**:
```matlab
% Validate a dataset
[is_valid, issues] = validate_dataset('normal_Iin.csv', 1001, 50);
if ~is_valid
    for i = 1:length(issues)
        warning(issues{i});
    end
end
```

## Parameter Configuration

### Simulation Parameters

#### Basic Simulation Settings
```matlab
% Core simulation parameters
simulation_params = struct();
simulation_params.num_samples = 50;
simulation_params.time_series_length = 1001;
simulation_params.simulation_time = 0.1;
simulation_params.sample_rate = 10000;
```

#### Electrical Parameters
```matlab
% Electrical system parameters
electrical_params = struct();
electrical_params.voltage_range = [5301, 6099];      % V
electrical_params.resistance_range = [0.4, 1.0];     % Ω
electrical_params.nominal_voltage = 5700;            % V
electrical_params.nominal_resistance = 0.7;          % Ω
```

#### Timing Parameters
```matlab
% Timing parameters for different conditions
timing_params = struct();
timing_params.normal = struct();
timing_params.normal.ut3 = 150;  % ms
timing_params.normal.ut4 = 150;  % ms
timing_params.normal.ut5 = 150;  % ms
timing_params.normal.ut6 = 80;   % ms

timing_params.ut3_delay = struct();
timing_params.ut3_delay.range = [0.2, 0.5];  % Factor of normal
timing_params.ut3_delay.ut4 = 150;           % ms
timing_params.ut3_delay.ut5 = 150;           % ms
timing_params.ut3_delay.ut6 = 80;            % ms

timing_params.ut456_delay = struct();
timing_params.ut456_delay.ut3 = 150;         % ms
timing_params.ut456_delay.range = [0.1, 0.5]; % Factor increase
```

### Parameter Setting Functions

#### Set Simulink Parameters
```matlab
function set_simulink_parameters(voltage, resistance)
    % Set voltage and resistance parameters in Simulink model
    set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(voltage));
    set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(resistance));
end
```

#### Create Timing Signals
```matlab
function [ut3_sig, ut4_sig, ut5_sig, ut6_sig] = create_timing_signals(ut3, ut4, ut5, ut6, time_length)
    % Create timing signals for simulation
    time = linspace(0, 0.1, time_length);
    ut3_sig = timeseries(ut3 * ones(size(time)), time);
    ut4_sig = timeseries(ut4 * ones(size(time)), time);
    ut5_sig = timeseries(ut5 * ones(size(time)), time);
    ut6_sig = timeseries(ut6 * ones(size(time)), time);
end
```

## Output Functions

### Data Storage Functions

#### Save Data to CSV
```matlab
function save_to_csv(data, filename, description)
    % Save data matrix to CSV file with validation
    try
        csvwrite(filename, data);
        fprintf('✓ %s saved successfully (%s)\n', filename, description);
    catch ME
        error('Failed to save %s: %s', filename, ME.message);
    end
end
```

#### Save Simulation Results
```matlab
function save_simulation_results(data_Iin, data_Uout, condition)
    % Save simulation results for a specific condition
    save_to_csv(data_Iin, sprintf('%s_Iin.csv', condition), 'input current data');
    save_to_csv(data_Uout, sprintf('%s_Uout.csv', condition), 'output voltage data');
end
```

### Data Analysis Functions

#### Calculate Statistics
```matlab
function stats = calculate_dataset_statistics(data)
    % Calculate comprehensive statistics for dataset
    stats = struct();
    stats.mean = mean(data(:));
    stats.std = std(data(:));
    stats.max = max(data(:));
    stats.min = min(data(:));
    stats.rms = rms(data(:));
    stats.range = stats.max - stats.min;
    stats.variance = var(data(:));
    stats.median = median(data(:));
end
```

#### Compare Datasets
```matlab
function comparison = compare_datasets(data1, data2, label1, label2)
    % Compare two datasets and return statistics
    stats1 = calculate_dataset_statistics(data1);
    stats2 = calculate_dataset_statistics(data2);
    
    comparison = struct();
    comparison.dataset1 = struct('label', label1, 'stats', stats1);
    comparison.dataset2 = struct('label', label2, 'stats', stats2);
    comparison.differences = struct();
    
    fields = fieldnames(stats1);
    for i = 1:length(fields)
        field = fields{i};
        comparison.differences.(field) = stats2.(field) - stats1.(field);
    end
end
```

### Visualization Functions

#### Plot Time Series
```matlab
function plot_timeseries(data, time, title_str, ylabel_str)
    % Plot time series data
    figure;
    plot(time, data, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel(ylabel_str);
    title(title_str);
    grid on;
end
```

#### Plot Comparison
```matlab
function plot_comparison(data1, data2, time, label1, label2, title_str, ylabel_str)
    % Plot comparison of two time series
    figure;
    plot(time, data1, 'b-', 'LineWidth', 2, 'DisplayName', label1);
    hold on;
    plot(time, data2, 'r--', 'LineWidth', 2, 'DisplayName', label2);
    xlabel('Time (s)');
    ylabel(ylabel_str);
    title(title_str);
    legend('show');
    grid on;
end
```

## Error Handling and Logging

### Error Handling Functions

#### Safe Simulation Run
```matlab
function [success, data_Iin, data_Uout, error_msg] = safe_simulation_run(sim_params)
    % Run simulation with error handling
    success = false;
    data_Iin = [];
    data_Uout = [];
    error_msg = '';
    
    try
        % Run simulation
        simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                     'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
        
        % Extract data
        Iin_timeseries = simOut.get('Iin');
        Uout_timeseries = simOut.get('Uout');
        
        if ~isempty(Iin_timeseries) && ~isempty(Uout_timeseries)
            data_Iin = Iin_timeseries.Data;
            data_Uout = Uout_timeseries.Data;
            success = true;
        else
            error_msg = 'Empty timeseries data returned';
        end
        
    catch ME
        error_msg = ME.message;
    end
end
```

### Logging Functions

#### Log Simulation Progress
```matlab
function log_simulation_progress(iteration, total, condition)
    % Log simulation progress
    progress = (iteration / total) * 100;
    fprintf('[%s] Progress: %d/%d (%.1f%%)\n', condition, iteration, total, progress);
end
```

#### Log Dataset Generation
```matlab
function log_dataset_generation(condition, num_samples, duration)
    % Log dataset generation completion
    fprintf('✓ Generated %s dataset: %d samples in %.2f seconds\n', ...
            condition, num_samples, duration);
end
```

This function reference provides detailed information about all components, functions, and utilities available in the OLTC simulation project, enabling users to understand and extend the system effectively.