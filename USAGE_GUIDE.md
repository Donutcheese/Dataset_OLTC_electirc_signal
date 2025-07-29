# OLTC Simulation - Usage Guide & Examples

## Table of Contents
- [Quick Start](#quick-start)
- [Basic Usage Scenarios](#basic-usage-scenarios)
- [Advanced Configuration](#advanced-configuration)
- [Data Analysis Examples](#data-analysis-examples)
- [Machine Learning Integration](#machine-learning-integration)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Performance Optimization](#performance-optimization)
- [Custom Extensions](#custom-extensions)

---

## Quick Start

### 1. Environment Setup
```matlab
% Verify MATLAB toolboxes
required_toolboxes = {'Simulink', 'Simscape'};
for i = 1:length(required_toolboxes)
    if license('test', required_toolboxes{i})
        fprintf('✓ %s available\n', required_toolboxes{i});
    else
        fprintf('✗ %s missing - please install\n', required_toolboxes{i});
    end
end

% Navigate to project directory
cd('program');
if exist('OLTC_simulation.slx', 'file')
    fprintf('✓ Simulink model found\n');
else
    error('✗ OLTC_simulation.slx not found');
end
```

### 2. Generate Your First Dataset
```matlab
% Generate normal operation dataset (this will take a few minutes)
fprintf('Generating normal operation dataset...\n');
tic;
run('dataset_create.m');
elapsed_time = toc;
fprintf('Dataset generation completed in %.1f seconds\n', elapsed_time);

% Verify output
if exist('normal_Iin.csv', 'file') && exist('normal_Uout.csv', 'file')
    fprintf('✓ Normal operation dataset created successfully\n');
    
    % Quick data inspection
    current_data = csvread('normal_Iin.csv');
    voltage_data = csvread('normal_Uout.csv');
    
    fprintf('Dataset size: %d time points × %d simulations\n', size(current_data));
    fprintf('Current range: %.2f - %.2f A\n', min(current_data(:)), max(current_data(:)));
    fprintf('Voltage range: %.2f - %.2f V\n', min(voltage_data(:)), max(voltage_data(:)));
end
```

---

## Basic Usage Scenarios

### Scenario 1: Standard Dataset Generation
**Use Case**: Generate datasets for basic fault detection model training.

```matlab
%% Standard Dataset Generation Workflow
% This creates the three main dataset types with default parameters

% Step 1: Normal operation baseline
fprintf('Step 1: Generating normal operation data...\n');
run('dataset_create.m');

% Step 2: Single fault condition (ut3 delay)
fprintf('Step 2: Generating ut3 fault data...\n');
run('dataset_ut3_delay.m');

% Step 3: Multiple fault condition (ut4-6 delays)
fprintf('Step 3: Generating ut4-6 fault data...\n');
run('dataset_ut456_delay.m');

% Step 4: Dataset summary
datasets = {
    'normal_Iin.csv', 'normal_Uout.csv', 'Normal Operation';
    'ut3delay_Iin.csv', 'ut3delay_Uout.csv', 'UT3 Fault';
    'ut4-6delay_Iin.csv', 'ut4-6delay_Uout.csv', 'UT4-6 Fault'
};

fprintf('\n=== Dataset Generation Summary ===\n');
for i = 1:size(datasets, 1)
    if exist(datasets{i,1}, 'file') && exist(datasets{i,2}, 'file')
        current_data = csvread(datasets{i,1});
        voltage_data = csvread(datasets{i,2});
        fprintf('✓ %-15s: %d samples, %.1f MB\n', datasets{i,3}, ...
                size(current_data,2), (numel(current_data) + numel(voltage_data)) * 8 / 1e6);
    else
        fprintf('✗ %-15s: Missing files\n', datasets{i,3});
    end
end
```

### Scenario 2: Custom Parameter Testing
**Use Case**: Test OLTC behavior under specific operating conditions.

```matlab
%% Custom Parameter Testing
% Test with specific voltage and load conditions

% Define test conditions
test_conditions = [
    5130, 0.5;  % Low voltage, low load
    5700, 0.7;  % Nominal voltage, medium load  
    6270, 1.0;  % High voltage, high load
];

fprintf('Testing %d custom conditions...\n', size(test_conditions, 1));

for test_idx = 1:size(test_conditions, 1)
    test_voltage = test_conditions(test_idx, 1);
    test_resistance = test_conditions(test_idx, 2);
    
    fprintf('Test %d: V=%.0fV, R=%.1fΩ\n', test_idx, test_voltage, test_resistance);
    
    % Create custom script parameters
    num_samples = 10;  % Smaller dataset for testing
    time_series_length = 1001;
    
    % Fixed parameters for this test
    input_voltages = test_voltage * ones(1, num_samples);
    load_resistances = test_resistance * ones(1, num_samples);
    
    % Initialize data storage
    data_Iin = zeros(time_series_length, num_samples);
    data_Uout = zeros(time_series_length, num_samples);
    
    % Run simulations with fixed parameters
    for i = 1:num_samples
        % Set Simulink parameters
        set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(input_voltages(i)));
        set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(load_resistances(i)));
        
        % Create timing signals (normal operation)
        time = linspace(0, 0.1, time_series_length);
        ut3_signal = timeseries(150 * ones(size(time)), time);
        ut4_signal = timeseries(150 * ones(size(time)), time);
        ut5_signal = timeseries(150 * ones(size(time)), time);
        ut6_signal = timeseries(80 * ones(size(time)), time);
        
        % Run simulation
        simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                     'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
        
        % Extract data
        Iin_data = simOut.get('Iin').Data;
        Uout_data = simOut.get('Uout').Data;
        
        data_Iin(:, i) = Iin_data;
        data_Uout(:, i) = Uout_data;
    end
    
    % Save test results
    csvwrite(sprintf('test_%d_Iin.csv', test_idx), data_Iin);
    csvwrite(sprintf('test_%d_Uout.csv', test_idx), data_Uout);
    
    % Quick analysis
    avg_current = mean(data_Iin(:));
    avg_voltage = mean(data_Uout(:));
    fprintf('  Average current: %.2f A, Average voltage: %.1f V\n', avg_current, avg_voltage);
end
```

### Scenario 3: Fault Severity Analysis
**Use Case**: Study how fault severity affects electrical signatures.

```matlab
%% Fault Severity Analysis
% Systematic analysis of ut3 fault severity levels

% Define fault severity levels (as percentage of normal timing)
severity_levels = [0.1, 0.2, 0.3, 0.4, 0.5];  % 10% to 50% of normal
severity_labels = {'10%', '20%', '30%', '40%', '50%'};

fprintf('Analyzing %d fault severity levels...\n', length(severity_levels));

results = struct();

for sev_idx = 1:length(severity_levels)
    severity = severity_levels(sev_idx);
    fprintf('Processing severity level: %s (%.1f of normal)\n', ...
            severity_labels{sev_idx}, severity);
    
    % Parameters
    num_samples = 20;
    time_series_length = 1001;
    
    % Electrical parameter ranges
    resistance_range = [0.4, 1.0];
    voltage_range = [0.93 * 5700, 1.07 * 5700];
    
    % Generate random electrical parameters
    input_voltages = rand(1, num_samples) * (voltage_range(2) - voltage_range(1)) + voltage_range(1);
    load_resistances = rand(1, num_samples) * (resistance_range(2) - resistance_range(1)) + resistance_range(1);
    
    % Fixed ut3 value for this severity level
    ut3_value = 150 * severity;  % Fixed fault severity
    
    % Initialize storage
    data_Iin = zeros(time_series_length, num_samples);
    data_Uout = zeros(time_series_length, num_samples);
    
    % Run simulations
    for i = 1:num_samples
        % Set parameters
        set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(input_voltages(i)));
        set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(load_resistances(i)));
        
        % Create signals
        time = linspace(0, 0.1, time_series_length);
        ut3_signal = timeseries(ut3_value * ones(size(time)), time);
        ut4_signal = timeseries(150 * ones(size(time)), time);
        ut5_signal = timeseries(150 * ones(size(time)), time);
        ut6_signal = timeseries(80 * ones(size(time)), time);
        
        % Simulate
        simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                     'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
        
        % Store data
        data_Iin(:, i) = simOut.get('Iin').Data;
        data_Uout(:, i) = simOut.get('Uout').Data;
    end
    
    % Save results
    filename_base = sprintf('severity_%s', severity_labels{sev_idx});
    csvwrite([filename_base '_Iin.csv'], data_Iin);
    csvwrite([filename_base '_Uout.csv'], data_Uout);
    
    % Calculate statistics
    results.(sprintf('sev_%d', sev_idx)) = struct();
    results.(sprintf('sev_%d', sev_idx)).severity = severity;
    results.(sprintf('sev_%d', sev_idx)).ut3_value = ut3_value;
    results.(sprintf('sev_%d', sev_idx)).mean_current = mean(data_Iin(:));
    results.(sprintf('sev_%d', sev_idx)).std_current = std(data_Iin(:));
    results.(sprintf('sev_%d', sev_idx)).mean_voltage = mean(data_Uout(:));
    results.(sprintf('sev_%d', sev_idx)).std_voltage = std(data_Uout(:));
    
    fprintf('  ut3=%.1fms, I_avg=%.2fA, V_avg=%.1fV\n', ...
            ut3_value, results.(sprintf('sev_%d', sev_idx)).mean_current, ...
            results.(sprintf('sev_%d', sev_idx)).mean_voltage);
end

% Summary analysis
fprintf('\n=== Fault Severity Analysis Summary ===\n');
fprintf('%-10s %-8s %-12s %-12s %-12s %-12s\n', ...
        'Severity', 'ut3(ms)', 'I_mean(A)', 'I_std(A)', 'V_mean(V)', 'V_std(V)');
for sev_idx = 1:length(severity_levels)
    r = results.(sprintf('sev_%d', sev_idx));
    fprintf('%-10s %-8.1f %-12.3f %-12.3f %-12.1f %-12.1f\n', ...
            severity_labels{sev_idx}, r.ut3_value, r.mean_current, r.std_current, ...
            r.mean_voltage, r.std_voltage);
end
```

---

## Advanced Configuration

### High-Resolution Simulation
**Use Case**: Generate high-resolution data for detailed analysis.

```matlab
%% High-Resolution Simulation Configuration
% Generate dataset with higher sampling rate and longer duration

% Modified parameters for high resolution
num_samples = 25;           % Fewer samples due to larger size
time_series_length = 5001;  % 50kHz sampling rate (0.02ms resolution)
simulation_time = 0.1;      % Keep same simulation duration

fprintf('Configuring high-resolution simulation...\n');
fprintf('Time resolution: %.3f ms\n', simulation_time / time_series_length * 1000);
fprintf('Sampling rate: %.0f Hz\n', time_series_length / simulation_time);

% Standard electrical parameters
resistance_range = [0.4, 1.0];
voltage_range = [0.93 * 5700, 1.07 * 5700];

% Generate unique parameter sets
input_voltages = unique(rand(num_samples * 2, 1) * (voltage_range(2) - voltage_range(1)) + voltage_range(1));
input_voltages = input_voltages(1:num_samples);

load_resistances = unique(rand(num_samples * 2, 1) * (resistance_range(2) - resistance_range(1)) + resistance_range(1));
load_resistances = load_resistances(1:num_samples);

% Initialize high-resolution storage
data_Iin = zeros(time_series_length, num_samples);
data_Uout = zeros(time_series_length, num_samples);

% Normal operation timing
ut3_value = 150; ut4_value = 150; ut5_value = 150; ut6_value = 80;

fprintf('Running high-resolution simulations...\n');
for i = 1:num_samples
    if mod(i, 5) == 0
        fprintf('Completed %d/%d simulations\n', i, num_samples);
    end
    
    % Set parameters
    set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(input_voltages(i)));
    set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(load_resistances(i)));
    
    % High-resolution time vector
    time = linspace(0, simulation_time, time_series_length);
    ut3_signal = timeseries(ut3_value * ones(size(time)), time);
    ut4_signal = timeseries(ut4_value * ones(size(time)), time);
    ut5_signal = timeseries(ut5_value * ones(size(time)), time);
    ut6_signal = timeseries(ut6_value * ones(size(time)), time);
    
    % Run simulation with modified stop time
    simOut = sim('OLTC_simulation', 'StopTime', num2str(simulation_time), ...
                 'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
    
    % Extract and store data
    data_Iin(:, i) = simOut.get('Iin').Data;
    data_Uout(:, i) = simOut.get('Uout').Data;
end

% Save high-resolution dataset
csvwrite('highres_normal_Iin.csv', data_Iin);
csvwrite('highres_normal_Uout.csv', data_Uout);

fprintf('High-resolution dataset saved (%.1f MB)\n', ...
        (numel(data_Iin) + numel(data_Uout)) * 8 / 1e6);
```

### Batch Processing with Parameter Sweeps
**Use Case**: Systematic parameter exploration for research.

```matlab
%% Parameter Sweep Analysis
% Systematic exploration of voltage and resistance parameter space

% Define parameter grids
voltage_levels = linspace(0.90 * 5700, 1.10 * 5700, 5);  % 5 voltage levels
resistance_levels = linspace(0.3, 1.2, 4);               % 4 resistance levels

fprintf('Parameter sweep: %d voltage × %d resistance = %d combinations\n', ...
        length(voltage_levels), length(resistance_levels), ...
        length(voltage_levels) * length(resistance_levels));

% Initialize results storage
sweep_results = struct();
sweep_results.voltage_levels = voltage_levels;
sweep_results.resistance_levels = resistance_levels;
sweep_results.combinations = [];
sweep_results.current_stats = [];
sweep_results.voltage_stats = [];

combination_idx = 1;

for v_idx = 1:length(voltage_levels)
    for r_idx = 1:length(resistance_levels)
        voltage = voltage_levels(v_idx);
        resistance = resistance_levels(r_idx);
        
        fprintf('Combination %d: V=%.0fV, R=%.2fΩ\n', combination_idx, voltage, resistance);
        
        % Simulation parameters
        num_samples = 5;  % Multiple runs per combination
        time_series_length = 1001;
        
        % Fixed electrical parameters for this combination
        input_voltages = voltage * ones(1, num_samples);
        load_resistances = resistance * ones(1, num_samples);
        
        % Storage for this combination
        combo_Iin = zeros(time_series_length, num_samples);
        combo_Uout = zeros(time_series_length, num_samples);
        
        % Run simulations
        for i = 1:num_samples
            % Set parameters
            set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(voltage));
            set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(resistance));
            
            % Normal timing
            time = linspace(0, 0.1, time_series_length);
            ut3_signal = timeseries(150 * ones(size(time)), time);
            ut4_signal = timeseries(150 * ones(size(time)), time);
            ut5_signal = timeseries(150 * ones(size(time)), time);
            ut6_signal = timeseries(80 * ones(size(time)), time);
            
            % Simulate
            simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                         'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
            
            % Store data
            combo_Iin(:, i) = simOut.get('Iin').Data;
            combo_Uout(:, i) = simOut.get('Uout').Data;
        end
        
        % Calculate statistics for this combination
        current_mean = mean(combo_Iin(:));
        current_std = std(combo_Iin(:));
        current_max = max(combo_Iin(:));
        current_min = min(combo_Iin(:));
        
        voltage_mean = mean(combo_Uout(:));
        voltage_std = std(combo_Uout(:));
        voltage_max = max(combo_Uout(:));
        voltage_min = min(combo_Uout(:));
        
        % Store results
        sweep_results.combinations(combination_idx, :) = [voltage, resistance];
        sweep_results.current_stats(combination_idx, :) = [current_mean, current_std, current_min, current_max];
        sweep_results.voltage_stats(combination_idx, :) = [voltage_mean, voltage_std, voltage_min, voltage_max];
        
        % Save individual combination data
        csvwrite(sprintf('sweep_V%.0f_R%.2f_Iin.csv', voltage, resistance*100), combo_Iin);
        csvwrite(sprintf('sweep_V%.0f_R%.2f_Uout.csv', voltage, resistance*100), combo_Uout);
        
        combination_idx = combination_idx + 1;
    end
end

% Save sweep results summary
save('parameter_sweep_results.mat', 'sweep_results');

% Display summary table
fprintf('\n=== Parameter Sweep Results Summary ===\n');
fprintf('%-8s %-8s %-12s %-12s %-12s %-12s\n', ...
        'V(V)', 'R(Ω)', 'I_mean(A)', 'I_std(A)', 'V_mean(V)', 'V_std(V)');
for i = 1:size(sweep_results.combinations, 1)
    fprintf('%-8.0f %-8.2f %-12.3f %-12.3f %-12.1f %-12.1f\n', ...
            sweep_results.combinations(i, 1), sweep_results.combinations(i, 2), ...
            sweep_results.current_stats(i, 1), sweep_results.current_stats(i, 2), ...
            sweep_results.voltage_stats(i, 1), sweep_results.voltage_stats(i, 2));
end
```

---

## Data Analysis Examples

### Signal Analysis and Visualization
```matlab
%% Signal Analysis and Visualization
% Comprehensive analysis of generated OLTC datasets

% Load datasets
fprintf('Loading datasets for analysis...\n');
normal_I = csvread('normal_Iin.csv');
normal_V = csvread('normal_Uout.csv');
ut3_I = csvread('ut3delay_Iin.csv');
ut3_V = csvread('ut3delay_Uout.csv');
ut456_I = csvread('ut4-6delay_Iin.csv');
ut456_V = csvread('ut4-6delay_Uout.csv');

% Time vector for plotting
time_ms = linspace(0, 100, size(normal_I, 1));  % 0 to 100ms

% 1. Time Domain Analysis
figure('Name', 'OLTC Signal Analysis', 'Position', [100 100 1200 800]);

% Current signals comparison
subplot(2, 3, 1);
plot(time_ms, normal_I(:, 1), 'b-', 'LineWidth', 1.5); hold on;
plot(time_ms, ut3_I(:, 1), 'r-', 'LineWidth', 1.5);
plot(time_ms, ut456_I(:, 1), 'g-', 'LineWidth', 1.5);
xlabel('Time (ms)'); ylabel('Current (A)');
title('Current Signals Comparison');
legend('Normal', 'UT3 Fault', 'UT4-6 Fault', 'Location', 'best');
grid on;

% Voltage signals comparison
subplot(2, 3, 2);
plot(time_ms, normal_V(:, 1), 'b-', 'LineWidth', 1.5); hold on;
plot(time_ms, ut3_V(:, 1), 'r-', 'LineWidth', 1.5);
plot(time_ms, ut456_V(:, 1), 'g-', 'LineWidth', 1.5);
xlabel('Time (ms)'); ylabel('Voltage (V)');
title('Voltage Signals Comparison');
legend('Normal', 'UT3 Fault', 'UT4-6 Fault', 'Location', 'best');
grid on;

% 2. Statistical Analysis
current_stats = [
    mean(normal_I(:)), std(normal_I(:)), min(normal_I(:)), max(normal_I(:));
    mean(ut3_I(:)), std(ut3_I(:)), min(ut3_I(:)), max(ut3_I(:));
    mean(ut456_I(:)), std(ut456_I(:)), min(ut456_I(:)), max(ut456_I(:))
];

voltage_stats = [
    mean(normal_V(:)), std(normal_V(:)), min(normal_V(:)), max(normal_V(:));
    mean(ut3_V(:)), std(ut3_V(:)), min(ut3_V(:)), max(ut3_V(:));
    mean(ut456_V(:)), std(ut456_V(:)), min(ut456_V(:)), max(ut456_V(:))
];

% Current statistics
subplot(2, 3, 3);
bar_data = current_stats(:, 1:2);  % Mean and std
bar(bar_data);
xlabel('Condition'); ylabel('Current (A)');
title('Current Statistics');
set(gca, 'XTickLabel', {'Normal', 'UT3', 'UT4-6'});
legend('Mean', 'Std Dev', 'Location', 'best');
grid on;

% Voltage statistics
subplot(2, 3, 4);
bar_data = voltage_stats(:, 1:2);  % Mean and std
bar(bar_data);
xlabel('Condition'); ylabel('Voltage (V)');
title('Voltage Statistics');
set(gca, 'XTickLabel', {'Normal', 'UT3', 'UT4-6'});
legend('Mean', 'Std Dev', 'Location', 'best');
grid on;

% 3. Distribution Analysis
subplot(2, 3, 5);
histogram(normal_I(:), 50, 'Normalization', 'probability', 'FaceAlpha', 0.7); hold on;
histogram(ut3_I(:), 50, 'Normalization', 'probability', 'FaceAlpha', 0.7);
histogram(ut456_I(:), 50, 'Normalization', 'probability', 'FaceAlpha', 0.7);
xlabel('Current (A)'); ylabel('Probability');
title('Current Distribution');
legend('Normal', 'UT3 Fault', 'UT4-6 Fault', 'Location', 'best');
grid on;

subplot(2, 3, 6);
histogram(normal_V(:), 50, 'Normalization', 'probability', 'FaceAlpha', 0.7); hold on;
histogram(ut3_V(:), 50, 'Normalization', 'probability', 'FaceAlpha', 0.7);
histogram(ut456_V(:), 50, 'Normalization', 'probability', 'FaceAlpha', 0.7);
xlabel('Voltage (V)'); ylabel('Probability');
title('Voltage Distribution');
legend('Normal', 'UT3 Fault', 'UT4-6 Fault', 'Location', 'best');
grid on;

% Print summary statistics
fprintf('\n=== Dataset Statistics Summary ===\n');
fprintf('Current Statistics:\n');
fprintf('%-10s %-10s %-10s %-10s %-10s\n', 'Condition', 'Mean(A)', 'Std(A)', 'Min(A)', 'Max(A)');
conditions = {'Normal', 'UT3', 'UT4-6'};
for i = 1:3
    fprintf('%-10s %-10.3f %-10.3f %-10.3f %-10.3f\n', ...
            conditions{i}, current_stats(i, :));
end

fprintf('\nVoltage Statistics:\n');
fprintf('%-10s %-10s %-10s %-10s %-10s\n', 'Condition', 'Mean(V)', 'Std(V)', 'Min(V)', 'Max(V)');
for i = 1:3
    fprintf('%-10s %-10.1f %-10.1f %-10.1f %-10.1f\n', ...
            conditions{i}, voltage_stats(i, :));
end
```

### Feature Extraction for Machine Learning
```matlab
%% Feature Extraction for Machine Learning
% Extract relevant features from time-series data for ML models

% Load all datasets
datasets = {
    'normal_Iin.csv', 'normal_Uout.csv', 0;      % Label 0: Normal
    'ut3delay_Iin.csv', 'ut3delay_Uout.csv', 1;  % Label 1: UT3 fault
    'ut4-6delay_Iin.csv', 'ut4-6delay_Uout.csv', 2  % Label 2: UT4-6 fault
};

fprintf('Extracting features for machine learning...\n');

all_features = [];
all_labels = [];

for dataset_idx = 1:size(datasets, 1)
    % Load data
    current_data = csvread(datasets{dataset_idx, 1});
    voltage_data = csvread(datasets{dataset_idx, 2});
    label = datasets{dataset_idx, 3};
    
    fprintf('Processing %s (label %d)...\n', datasets{dataset_idx, 1}, label);
    
    num_samples = size(current_data, 2);
    
    % Feature extraction for each sample
    sample_features = [];
    
    for sample_idx = 1:num_samples
        current_signal = current_data(:, sample_idx);
        voltage_signal = voltage_data(:, sample_idx);
        
        % Time domain features
        features = [];
        
        % Current features
        features = [features, ...
            mean(current_signal), ...      % Mean current
            std(current_signal), ...       % Current std deviation
            max(current_signal), ...       % Peak current
            min(current_signal), ...       % Minimum current
            max(current_signal) - min(current_signal), ... % Current range
            rms(current_signal)];          % RMS current
        
        % Voltage features
        features = [features, ...
            mean(voltage_signal), ...      % Mean voltage
            std(voltage_signal), ...       % Voltage std deviation
            max(voltage_signal), ...       % Peak voltage
            min(voltage_signal), ...       % Minimum voltage
            max(voltage_signal) - min(voltage_signal), ... % Voltage range
            rms(voltage_signal)];          % RMS voltage
        
        % Statistical moments
        features = [features, ...
            skewness(current_signal), ...  % Current skewness
            kurtosis(current_signal), ...  % Current kurtosis
            skewness(voltage_signal), ...  % Voltage skewness
            kurtosis(voltage_signal)];     % Voltage kurtosis
        
        % Frequency domain features (basic)
        current_fft = abs(fft(current_signal));
        voltage_fft = abs(fft(voltage_signal));
        
        % Dominant frequency components
        [~, current_peak_idx] = max(current_fft(1:end/2));
        [~, voltage_peak_idx] = max(voltage_fft(1:end/2));
        
        features = [features, ...
            current_peak_idx, ...          % Current dominant frequency index
            voltage_peak_idx, ...          % Voltage dominant frequency index
            sum(current_fft.^2), ...       % Current spectral energy
            sum(voltage_fft.^2)];          % Voltage spectral energy
        
        % Temporal features
        % Find switching events (significant changes)
        current_diff = abs(diff(current_signal));
        voltage_diff = abs(diff(voltage_signal));
        
        current_switch_threshold = 3 * std(current_diff);
        voltage_switch_threshold = 3 * std(voltage_diff);
        
        current_switch_times = find(current_diff > current_switch_threshold);
        voltage_switch_times = find(voltage_diff > voltage_switch_threshold);
        
        features = [features, ...
            length(current_switch_times), ...  % Number of current switching events
            length(voltage_switch_times)];     % Number of voltage switching events
        
        % Add timing features if switching events exist
        if ~isempty(current_switch_times)
            features = [features, ...
                current_switch_times(1), ...       % First current switch time
                current_switch_times(end)];        % Last current switch time
        else
            features = [features, 0, 0];
        end
        
        if ~isempty(voltage_switch_times)
            features = [features, ...
                voltage_switch_times(1), ...       % First voltage switch time
                voltage_switch_times(end)];        % Last voltage switch time
        else
            features = [features, 0, 0];
        end
        
        sample_features = [sample_features; features];
    end
    
    % Combine features and labels
    all_features = [all_features; sample_features];
    all_labels = [all_labels; label * ones(num_samples, 1)];
    
    fprintf('  Extracted %d features from %d samples\n', size(sample_features, 2), num_samples);
end

% Feature summary
fprintf('\n=== Feature Extraction Summary ===\n');
fprintf('Total samples: %d\n', size(all_features, 1));
fprintf('Total features: %d\n', size(all_features, 2));
fprintf('Class distribution:\n');
for class = unique(all_labels)'
    fprintf('  Class %d: %d samples\n', class, sum(all_labels == class));
end

% Save features and labels
save('oltc_ml_features.mat', 'all_features', 'all_labels');
csvwrite('oltc_features.csv', all_features);
csvwrite('oltc_labels.csv', all_labels);

fprintf('Features saved to oltc_ml_features.mat and CSV files\n');

% Feature correlation analysis
feature_names = {
    'I_mean', 'I_std', 'I_max', 'I_min', 'I_range', 'I_rms', ...
    'V_mean', 'V_std', 'V_max', 'V_min', 'V_range', 'V_rms', ...
    'I_skew', 'I_kurt', 'V_skew', 'V_kurt', ...
    'I_freq_peak', 'V_freq_peak', 'I_spectral_energy', 'V_spectral_energy', ...
    'I_switch_count', 'V_switch_count', 'I_first_switch', 'I_last_switch', ...
    'V_first_switch', 'V_last_switch'
};

% Basic feature statistics by class
fprintf('\n=== Feature Statistics by Class ===\n');
for class = unique(all_labels)'
    class_features = all_features(all_labels == class, :);
    fprintf('Class %d statistics:\n', class);
    
    % Show first 6 features for brevity
    for feat_idx = 1:min(6, length(feature_names))
        fprintf('  %s: mean=%.3f, std=%.3f\n', ...
                feature_names{feat_idx}, ...
                mean(class_features(:, feat_idx)), ...
                std(class_features(:, feat_idx)));
    end
    fprintf('\n');
end
```

---

## Machine Learning Integration

### Simple Classification Example
```matlab
%% Simple Classification Example
% Basic machine learning workflow using extracted features

% Load features if not already in workspace
if ~exist('all_features', 'var')
    load('oltc_ml_features.mat');
end

fprintf('Training simple classification model...\n');

% Split data into training and testing sets
rng(42);  % For reproducibility
num_samples = size(all_features, 1);
train_ratio = 0.7;

% Stratified split to maintain class proportions
train_indices = [];
test_indices = [];

for class = unique(all_labels)'
    class_indices = find(all_labels == class);
    num_class_samples = length(class_indices);
    num_train = round(num_class_samples * train_ratio);
    
    % Randomly select training samples
    random_indices = randperm(num_class_samples);
    train_class_indices = class_indices(random_indices(1:num_train));
    test_class_indices = class_indices(random_indices(num_train+1:end));
    
    train_indices = [train_indices; train_class_indices];
    test_indices = [test_indices; test_class_indices];
end

% Create training and testing sets
X_train = all_features(train_indices, :);
y_train = all_labels(train_indices);
X_test = all_features(test_indices, :);
y_test = all_labels(test_indices);

fprintf('Training set: %d samples\n', length(train_indices));
fprintf('Test set: %d samples\n', length(test_indices));

% Feature normalization
feature_means = mean(X_train);
feature_stds = std(X_train);

X_train_norm = (X_train - feature_means) ./ feature_stds;
X_test_norm = (X_test - feature_means) ./ feature_stds;

% Simple k-NN classifier
k = 5;
y_pred = zeros(size(y_test));

fprintf('Running k-NN classification (k=%d)...\n', k);

for i = 1:size(X_test_norm, 1)
    % Calculate distances to all training samples
    distances = sqrt(sum((X_train_norm - X_test_norm(i, :)).^2, 2));
    
    % Find k nearest neighbors
    [~, sorted_indices] = sort(distances);
    nearest_labels = y_train(sorted_indices(1:k));
    
    % Majority vote
    y_pred(i) = mode(nearest_labels);
end

% Calculate accuracy
accuracy = sum(y_pred == y_test) / length(y_test);
fprintf('Classification accuracy: %.1f%%\n', accuracy * 100);

% Confusion matrix
classes = unique(all_labels);
num_classes = length(classes);
confusion_matrix = zeros(num_classes, num_classes);

for i = 1:length(y_test)
    true_class_idx = find(classes == y_test(i));
    pred_class_idx = find(classes == y_pred(i));
    confusion_matrix(true_class_idx, pred_class_idx) = ...
        confusion_matrix(true_class_idx, pred_class_idx) + 1;
end

fprintf('\nConfusion Matrix:\n');
fprintf('%-10s', 'True\\Pred');
for class = classes'
    fprintf('%-10s', sprintf('Class %d', class));
end
fprintf('\n');

for i = 1:num_classes
    fprintf('%-10s', sprintf('Class %d', classes(i)));
    for j = 1:num_classes
        fprintf('%-10d', confusion_matrix(i, j));
    end
    fprintf('\n');
end

% Class-specific metrics
fprintf('\nPer-class Performance:\n');
fprintf('%-8s %-10s %-10s %-10s\n', 'Class', 'Precision', 'Recall', 'F1-Score');

for i = 1:num_classes
    tp = confusion_matrix(i, i);
    fp = sum(confusion_matrix(:, i)) - tp;
    fn = sum(confusion_matrix(i, :)) - tp;
    
    precision = tp / (tp + fp);
    recall = tp / (tp + fn);
    f1_score = 2 * precision * recall / (precision + recall);
    
    fprintf('%-8d %-10.3f %-10.3f %-10.3f\n', classes(i), precision, recall, f1_score);
end
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Simulink Model Compilation Errors
```matlab
%% Troubleshooting: Model Compilation Issues

% Check if model exists and can be loaded
try
    load_system('OLTC_simulation');
    fprintf('✓ Model loaded successfully\n');
catch ME
    fprintf('✗ Model loading failed: %s\n', ME.message);
    
    % Check common issues
    if ~exist('OLTC_simulation.slx', 'file')
        fprintf('Solution: Model file not found. Check working directory.\n');
        fprintf('Current directory: %s\n', pwd);
        fprintf('Expected location: program/OLTC_simulation.slx\n');
    end
    
    return;
end

% Check required toolboxes
required_products = {'Simulink', 'Simscape'};
for i = 1:length(required_products)
    if license('test', required_products{i})
        fprintf('✓ %s available\n', required_products{i});
    else
        fprintf('✗ %s not available\n', required_products{i});
        fprintf('Solution: Install %s toolbox\n', required_products{i});
    end
end

% Test basic simulation
try
    fprintf('Testing basic simulation...\n');
    
    % Simple test parameters
    time = linspace(0, 0.1, 1001);
    ut3_signal = timeseries(150 * ones(size(time)), time);
    ut4_signal = timeseries(150 * ones(size(time)), time);
    ut5_signal = timeseries(150 * ones(size(time)), time);
    ut6_signal = timeseries(80 * ones(size(time)), time);
    
    simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                 'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
    
    fprintf('✓ Basic simulation successful\n');
    
catch ME
    fprintf('✗ Simulation failed: %s\n', ME.message);
    fprintf('Solution: Check model configuration and parameter blocks\n');
end
```

#### Issue 2: Memory and Performance Problems
```matlab
%% Troubleshooting: Memory and Performance Issues

% Check system memory
if ispc
    [~, memory_info] = memory;
    available_memory = memory_info.MemAvailableAllArrays / 1e9;  % GB
else
    available_memory = 'Unknown (non-Windows system)';
end

fprintf('Available memory: %s GB\n', num2str(available_memory));

% Estimate memory requirements for different dataset sizes
dataset_sizes = [10, 25, 50, 100, 200];
time_length = 1001;

fprintf('\nMemory requirements for different dataset sizes:\n');
fprintf('%-10s %-15s %-15s\n', 'Samples', 'Memory (MB)', 'Recommended');

for size_idx = 1:length(dataset_sizes)
    num_samples = dataset_sizes(size_idx);
    
    % Estimate memory: 2 matrices (current + voltage) × double precision (8 bytes)
    memory_mb = 2 * time_length * num_samples * 8 / 1e6;
    
    if memory_mb < available_memory * 100  % Use 10% of available memory as threshold
        recommendation = '✓ OK';
    else
        recommendation = '✗ Too large';
    end
    
    fprintf('%-10d %-15.1f %-15s\n', num_samples, memory_mb, recommendation);
end

% Performance optimization suggestions
fprintf('\nPerformance Optimization Tips:\n');
fprintf('1. Use single precision for large datasets:\n');
fprintf('   data_Iin = zeros(time_length, num_samples, ''single'');\n\n');

fprintf('2. Process in batches for very large datasets:\n');
fprintf('   batch_size = 10;\n');
fprintf('   for batch = 1:batch_size:num_samples\n');
fprintf('       %% Process smaller batch\n');
fprintf('   end\n\n');

fprintf('3. Use parallel processing if available:\n');
fprintf('   if license(''test'', ''Parallel_Computing_Toolbox'')\n');
fprintf('       parfor i = 1:num_samples\n');
fprintf('           %% Parallel simulation\n');
fprintf('       end\n');
fprintf('   end\n\n');
```

#### Issue 3: Data Validation and Quality Checks
```matlab
%% Troubleshooting: Data Quality Issues

% Function to validate generated datasets
function validate_generated_data()
    expected_files = {
        'normal_Iin.csv', 'normal_Uout.csv';
        'ut3delay_Iin.csv', 'ut3delay_Uout.csv';
        'ut4-6delay_Iin.csv', 'ut4-6delay_Uout.csv'
    };
    
    condition_names = {'Normal', 'UT3 Delay', 'UT4-6 Delay'};
    
    fprintf('=== Data Validation Report ===\n');
    
    for cond_idx = 1:size(expected_files, 1)
        fprintf('\n%s Condition:\n', condition_names{cond_idx});
        
        current_file = expected_files{cond_idx, 1};
        voltage_file = expected_files{cond_idx, 2};
        
        % Check file existence
        if exist(current_file, 'file') && exist(voltage_file, 'file')
            fprintf('  ✓ Files exist\n');
            
            % Load and validate data
            try
                current_data = csvread(current_file);
                voltage_data = csvread(voltage_file);
                
                % Check dimensions
                if isequal(size(current_data), size(voltage_data))
                    fprintf('  ✓ Matching dimensions: %d × %d\n', size(current_data));
                else
                    fprintf('  ✗ Dimension mismatch: Current %d×%d, Voltage %d×%d\n', ...
                            size(current_data), size(voltage_data));
                end
                
                % Check for invalid values
                current_invalid = sum(isnan(current_data(:)) | isinf(current_data(:)));
                voltage_invalid = sum(isnan(voltage_data(:)) | isinf(voltage_data(:)));
                
                if current_invalid == 0 && voltage_invalid == 0
                    fprintf('  ✓ No invalid values (NaN/Inf)\n');
                else
                    fprintf('  ✗ Invalid values found: Current=%d, Voltage=%d\n', ...
                            current_invalid, voltage_invalid);
                end
                
                % Check value ranges
                current_range = [min(current_data(:)), max(current_data(:))];
                voltage_range = [min(voltage_data(:)), max(voltage_data(:))];
                
                % Expected ranges (approximate)
                expected_current_range = [0, 50];    % Amperes
                expected_voltage_range = [3000, 8000]; % Volts
                
                if current_range(1) >= expected_current_range(1) && ...
                   current_range(2) <= expected_current_range(2)
                    fprintf('  ✓ Current range valid: %.2f - %.2f A\n', current_range);
                else
                    fprintf('  ⚠ Current range unusual: %.2f - %.2f A\n', current_range);
                end
                
                if voltage_range(1) >= expected_voltage_range(1) && ...
                   voltage_range(2) <= expected_voltage_range(2)
                    fprintf('  ✓ Voltage range valid: %.1f - %.1f V\n', voltage_range);
                else
                    fprintf('  ⚠ Voltage range unusual: %.1f - %.1f V\n', voltage_range);
                end
                
                % Check for data variation
                current_std = std(current_data(:));
                voltage_std = std(voltage_data(:));
                
                if current_std > 0.01 && voltage_std > 1
                    fprintf('  ✓ Sufficient signal variation\n');
                else
                    fprintf('  ⚠ Low signal variation: I_std=%.3f, V_std=%.1f\n', ...
                            current_std, voltage_std);
                end
                
            catch ME
                fprintf('  ✗ Data loading failed: %s\n', ME.message);
            end
            
        else
            fprintf('  ✗ Missing files\n');
            if ~exist(current_file, 'file')
                fprintf('    Missing: %s\n', current_file);
            end
            if ~exist(voltage_file, 'file')
                fprintf('    Missing: %s\n', voltage_file);
            end
        end
    end
    
    fprintf('\n=== Validation Complete ===\n');
end

% Run validation
validate_generated_data();
```

---

## Performance Optimization

### Parallel Processing Implementation
```matlab
%% Parallel Processing for Large Datasets

% Check for Parallel Computing Toolbox
if license('test', 'Parallel_Computing_Toolbox')
    fprintf('Parallel Computing Toolbox available\n');
    
    % Initialize parallel pool if not already running
    current_pool = gcp('nocreate');
    if isempty(current_pool)
        fprintf('Starting parallel pool...\n');
        parpool();  % Start with default settings
    else
        fprintf('Using existing parallel pool with %d workers\n', current_pool.NumWorkers);
    end
    
    % Parallel dataset generation example
    num_samples = 40;  % Total samples
    time_series_length = 1001;
    
    % Prepare parameters for parallel processing
    resistance_range = [0.4, 1.0];
    voltage_range = [0.93 * 5700, 1.07 * 5700];
    
    % Generate unique parameter sets
    input_voltages = unique(rand(num_samples * 2, 1) * (voltage_range(2) - voltage_range(1)) + voltage_range(1));
    input_voltages = input_voltages(1:num_samples);
    
    load_resistances = unique(rand(num_samples * 2, 1) * (resistance_range(2) - resistance_range(1)) + resistance_range(1));
    load_resistances = load_resistances(1:num_samples);
    
    % Convert to cell arrays for parfor
    voltage_cell = num2cell(input_voltages);
    resistance_cell = num2cell(load_resistances);
    
    % Parallel simulation execution
    fprintf('Running %d simulations in parallel...\n', num_samples);
    
    % Initialize output storage
    parallel_current_data = cell(num_samples, 1);
    parallel_voltage_data = cell(num_samples, 1);
    
    tic;
    parfor i = 1:num_samples
        try
            % Set parameters for this worker
            voltage = voltage_cell{i};
            resistance = resistance_cell{i};
            
            % Create timing signals
            time = linspace(0, 0.1, time_series_length);
            ut3_signal = timeseries(150 * ones(size(time)), time);
            ut4_signal = timeseries(150 * ones(size(time)), time);
            ut5_signal = timeseries(150 * ones(size(time)), time);
            ut6_signal = timeseries(80 * ones(size(time)), time);
            
            % Note: Model parameter setting in parfor requires special handling
            % Each worker needs its own model instance
            model_name = sprintf('OLTC_simulation_worker_%d', i);
            
            % Copy model for this worker (if needed)
            % This is a simplified approach - actual implementation may vary
            
            % Run simulation
            simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                         'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
            
            % Extract data
            parallel_current_data{i} = simOut.get('Iin').Data;
            parallel_voltage_data{i} = simOut.get('Uout').Data;
            
        catch ME
            warning('Parallel simulation %d failed: %s', i, ME.message);
            parallel_current_data{i} = nan(time_series_length, 1);
            parallel_voltage_data{i} = nan(time_series_length, 1);
        end
    end
    
    parallel_time = toc;
    fprintf('Parallel execution completed in %.1f seconds\n', parallel_time);
    
    % Convert cell arrays to matrices
    data_Iin = zeros(time_series_length, num_samples);
    data_Uout = zeros(time_series_length, num_samples);
    
    for i = 1:num_samples
        if ~isempty(parallel_current_data{i}) && ~any(isnan(parallel_current_data{i}))
            data_Iin(:, i) = parallel_current_data{i};
            data_Uout(:, i) = parallel_voltage_data{i};
        end
    end
    
    % Save results
    csvwrite('parallel_normal_Iin.csv', data_Iin);
    csvwrite('parallel_normal_Uout.csv', data_Uout);
    
    fprintf('Parallel dataset generation completed\n');
    
else
    fprintf('Parallel Computing Toolbox not available\n');
    fprintf('Falling back to sequential processing...\n');
    
    % Sequential processing as fallback
    % (Include standard sequential code here)
end
```

---

## Custom Extensions

### Custom Fault Condition Implementation
```matlab
%% Custom Fault Condition: Intermittent Contact Issues

% Implement custom fault: intermittent contact resistance variation
function generate_intermittent_fault_dataset()
    fprintf('Generating intermittent contact fault dataset...\n');
    
    % Parameters
    num_samples = 30;
    time_series_length = 1001;
    
    % Standard electrical ranges
    resistance_range = [0.4, 1.0];
    voltage_range = [0.93 * 5700, 1.07 * 5700];
    
    % Generate base parameters
    input_voltages = unique(rand(num_samples * 2, 1) * (voltage_range(2) - voltage_range(1)) + voltage_range(1));
    input_voltages = input_voltages(1:num_samples);
    
    load_resistances = unique(rand(num_samples * 2, 1) * (resistance_range(2) - resistance_range(1)) + resistance_range(1));
    load_resistances = load_resistances(1:num_samples);
    
    % Custom fault parameters: intermittent contact resistance
    base_contact_resistance = 0.01;  % Base contact resistance (Ohms)
    fault_contact_resistance = 0.05; % Faulty contact resistance (Ohms)
    intermittent_probability = 0.3;  % 30% chance of fault at any time point
    
    % Storage
    data_Iin = zeros(time_series_length, num_samples);
    data_Uout = zeros(time_series_length, num_samples);
    
    for i = 1:num_samples
        fprintf('Simulation %d/%d\n', i, num_samples);
        
        % Base simulation parameters
        voltage = input_voltages(i);
        resistance = load_resistances(i);
        
        % Generate intermittent fault pattern
        time = linspace(0, 0.1, time_series_length);
        fault_pattern = rand(size(time)) < intermittent_probability;
        
        % Create variable contact resistance
        contact_resistance = base_contact_resistance * ones(size(time));
        contact_resistance(fault_pattern) = fault_contact_resistance;
        
        % Modify load resistance to include contact resistance variation
        total_resistance = resistance + contact_resistance;
        
        % For simplicity, use average resistance for simulation
        % In practice, you might need to modify the Simulink model
        % to accept time-varying resistance
        avg_resistance = mean(total_resistance);
        
        % Standard timing (normal operation)
        ut3_signal = timeseries(150 * ones(size(time)), time);
        ut4_signal = timeseries(150 * ones(size(time)), time);
        ut5_signal = timeseries(150 * ones(size(time)), time);
        ut6_signal = timeseries(80 * ones(size(time)), time);
        
        % Set simulation parameters
        set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(voltage));
        set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(avg_resistance));
        
        % Run simulation
        simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                     'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');
        
        % Extract base data
        base_current = simOut.get('Iin').Data;
        base_voltage = simOut.get('Uout').Data;
        
        % Post-process to add intermittent effects
        % Modify current based on resistance variation
        for t_idx = 1:length(time)
            if fault_pattern(t_idx)
                % Reduce current during high resistance periods
                resistance_ratio = base_contact_resistance / contact_resistance(t_idx);
                base_current(t_idx) = base_current(t_idx) * resistance_ratio;
                
                % Add voltage drop due to contact resistance
                voltage_drop = base_current(t_idx) * (contact_resistance(t_idx) - base_contact_resistance);
                base_voltage(t_idx) = base_voltage(t_idx) - voltage_drop;
            end
        end
        
        % Store modified data
        data_Iin(:, i) = base_current;
        data_Uout(:, i) = base_voltage;
    end
    
    % Save custom fault dataset
    csvwrite('intermittent_fault_Iin.csv', data_Iin);
    csvwrite('intermittent_fault_Uout.csv', data_Uout);
    
    fprintf('Intermittent fault dataset generated\n');
    
    % Generate fault pattern summary
    total_time_points = time_series_length * num_samples;
    total_fault_points = sum(sum(rand(time_series_length, num_samples) < intermittent_probability));
    fault_percentage = total_fault_points / total_time_points * 100;
    
    fprintf('Fault statistics:\n');
    fprintf('  Total time points: %d\n', total_time_points);
    fprintf('  Fault occurrences: %d (%.1f%%)\n', total_fault_points, fault_percentage);
    fprintf('  Average fault duration: %.2f ms per occurrence\n', ...
            0.1 * 1000 / time_series_length);
end

% Run custom fault generation
generate_intermittent_fault_dataset();
```

### Data Export and Integration Functions
```matlab
%% Data Export and Integration Utilities

% Function to export data in multiple formats
function export_dataset_multiple_formats(dataset_name)
    fprintf('Exporting %s dataset in multiple formats...\n', dataset_name);
    
    % Load data
    current_file = sprintf('%s_Iin.csv', dataset_name);
    voltage_file = sprintf('%s_Uout.csv', dataset_name);
    
    if ~exist(current_file, 'file') || ~exist(voltage_file, 'file')
        error('Dataset files not found: %s', dataset_name);
    end
    
    current_data = csvread(current_file);
    voltage_data = csvread(voltage_file);
    
    % Create output directory
    output_dir = sprintf('%s_export', dataset_name);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % 1. MATLAB format (.mat)
    save(fullfile(output_dir, [dataset_name '.mat']), 'current_data', 'voltage_data');
    fprintf('  ✓ MATLAB format saved\n');
    
    % 2. JSON format
    dataset_struct.current_data = current_data;
    dataset_struct.voltage_data = voltage_data;
    dataset_struct.metadata = struct(...
        'num_samples', size(current_data, 2), ...
        'time_points', size(current_data, 1), ...
        'sampling_rate', 10000, ...
        'duration_ms', 100, ...
        'export_date', datestr(now));
    
    json_str = jsonencode(dataset_struct);
    fid = fopen(fullfile(output_dir, [dataset_name '.json']), 'w');
    fprintf(fid, '%s', json_str);
    fclose(fid);
    fprintf('  ✓ JSON format saved\n');
    
    % 3. Excel format
    try
        % Combine data for Excel export
        combined_data = [current_data, voltage_data];
        
        % Create headers
        current_headers = arrayfun(@(x) sprintf('I_sim_%d', x), 1:size(current_data, 2), 'UniformOutput', false);
        voltage_headers = arrayfun(@(x) sprintf('V_sim_%d', x), 1:size(voltage_data, 2), 'UniformOutput', false);
        headers = [current_headers, voltage_headers];
        
        % Write to Excel
        excel_file = fullfile(output_dir, [dataset_name '.xlsx']);
        writecell([headers; num2cell(combined_data)], excel_file);
        fprintf('  ✓ Excel format saved\n');
    catch
        fprintf('  ⚠ Excel export failed (may require additional toolboxes)\n');
    end
    
    % 4. HDF5 format (for large datasets)
    try
        h5_file = fullfile(output_dir, [dataset_name '.h5']);
        
        % Create HDF5 file
        if exist(h5_file, 'file')
            delete(h5_file);
        end
        
        h5create(h5_file, '/current_data', size(current_data));
        h5write(h5_file, '/current_data', current_data);
        
        h5create(h5_file, '/voltage_data', size(voltage_data));
        h5write(h5_file, '/voltage_data', voltage_data);
        
        % Add metadata
        h5writeatt(h5_file, '/', 'num_samples', size(current_data, 2));
        h5writeatt(h5_file, '/', 'time_points', size(current_data, 1));
        h5writeatt(h5_file, '/', 'sampling_rate', 10000);
        h5writeatt(h5_file, '/', 'description', ['OLTC dataset: ' dataset_name]);
        
        fprintf('  ✓ HDF5 format saved\n');
    catch
        fprintf('  ⚠ HDF5 export failed\n');
    end
    
    % 5. Python/NumPy format (.npy)
    try
        % Save as .npy files (requires additional tools)
        % For now, save as structured text that can be easily imported
        numpy_dir = fullfile(output_dir, 'numpy_format');
        if ~exist(numpy_dir, 'dir')
            mkdir(numpy_dir);
        end
        
        % Save with Python-friendly format
        dlmwrite(fullfile(numpy_dir, 'current_data.txt'), current_data, 'delimiter', ',', 'precision', '%.6f');
        dlmwrite(fullfile(numpy_dir, 'voltage_data.txt'), voltage_data, 'delimiter', ',', 'precision', '%.6f');
        
        % Create Python loading script
        python_script = fullfile(numpy_dir, 'load_data.py');
        fid = fopen(python_script, 'w');
        fprintf(fid, '#!/usr/bin/env python3\n');
        fprintf(fid, 'import numpy as np\n\n');
        fprintf(fid, '# Load OLTC dataset: %s\n', dataset_name);
        fprintf(fid, 'current_data = np.loadtxt(''current_data.txt'', delimiter='','')\n');
        fprintf(fid, 'voltage_data = np.loadtxt(''voltage_data.txt'', delimiter='','')\n\n');
        fprintf(fid, 'print(f"Loaded dataset: {current_data.shape} current, {voltage_data.shape} voltage")\n');
        fclose(fid);
        
        fprintf('  ✓ Python/NumPy format saved\n');
    catch
        fprintf('  ⚠ Python/NumPy export failed\n');
    end
    
    fprintf('Export completed. Files saved in: %s\n', output_dir);
end

% Example usage for all datasets
datasets_to_export = {'normal', 'ut3delay', 'ut4-6delay'};
for i = 1:length(datasets_to_export)
    if exist([datasets_to_export{i} '_Iin.csv'], 'file')
        export_dataset_multiple_formats(datasets_to_export{i});
    end
end
```

This comprehensive usage guide provides practical examples and tutorials for all aspects of the OLTC simulation system, from basic usage to advanced customization and integration with external tools.