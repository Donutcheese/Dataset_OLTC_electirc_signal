% 初始化参数
% Initialize parameters
num_samples = 50;  % 运行50次仿真 / Run 50 simulations
time_series_length = 1001;  % 每个时间序列数据长度 (根据仿真步数定) / Length of each time series (depends on simulation steps)

% 初始化存储数据矩阵
% Initialize data storage matrices
data_Iin = zeros(time_series_length, num_samples);   % 输入电流数据矩阵 / Input current data matrix
data_Uout = zeros(time_series_length, num_samples);  % 输出电压数据矩阵 / Output voltage data matrix

% 电源电压和负载电阻的随机范围
% Random range for source voltage and load resistance
resistance_range = [0.4, 1.0];  % 负载阻值范围 / Load resistance range
voltage_range = [0.93 * 5700, 1.07 * 5700];  % 电源电压波动范围 / Source voltage fluctuation range

% 生成电源电压的随机值，确保无重复
% Generate random unique values for source voltage
input_voltages = unique(rand(num_samples * 2, 1) * (voltage_range(2) - voltage_range(1)) + voltage_range(1));
input_voltages = input_voltages(1:num_samples);  % 取前50个唯一值 / Take the first 50 unique values

% 生成负载电阻的随机值，确保无重复
% Generate random unique values for load resistance
load_resistances = unique(rand(num_samples * 2, 1) * (resistance_range(2) - resistance_range(1)) + resistance_range(1));
load_resistances = load_resistances(1:num_samples);  % 取前50个唯一值 / Take the first 50 unique values

% 固定 ut3, ut4, ut5, ut6 为正常值
% Set ut3, ut4, ut5, ut6 to normal fixed values
ut3_value = 150;
ut4_value = 150;
ut5_value = 150;
ut6_value = 80;

% 运行仿真(num_samples)次
% Run simulation for num_samples times
for i = 1:num_samples
    % 从无重复集合中取出电源电压和负载电阻
    % Get unique source voltage and load resistance from the set
    input_voltage = input_voltages(i);  % 唯一的电压值 / Unique voltage value
    load_resistance = load_resistances(i);  % 唯一的负载电阻 / Unique load resistance
    
    % 设置 Simulink 模型中的电源电压和负载电阻参数
    % Set source voltage and load resistance parameters in Simulink model
    set_param('OLTC_simulation/AC Voltage Source', 'Amplitude', num2str(input_voltage));  % 设置电源电压 / Set source voltage
    set_param('OLTC_simulation/Series RLC Branch1', 'Resistance', num2str(load_resistance));  % 设置负载电阻 / Set load resistance

    % 创建 ut3, ut4, ut5, ut6 的 timeseries 信号
    % Create timeseries signals for ut3, ut4, ut5, ut6
    time = linspace(0, 0.1, time_series_length);  % 仿真时间 / Simulation time
    ut3_signal = timeseries(ut3_value * ones(size(time)), time);  % 固定 ut3 为150ms / ut3 fixed at 150ms
    ut4_signal = timeseries(ut4_value * ones(size(time)), time);  % 固定 ut4 为150ms / ut4 fixed at 150ms
    ut5_signal = timeseries(ut5_value * ones(size(time)), time);  % 固定 ut5 为150ms / ut5 fixed at 150ms
    ut6_signal = timeseries(ut6_value * ones(size(time)), time);  % 固定 ut6 为80ms / ut6 fixed at 80ms