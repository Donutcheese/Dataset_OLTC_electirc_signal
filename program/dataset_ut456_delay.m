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

% 固定 ut3 为正常值
% Set ut3 to normal fixed value
ut3_value = 150;

% 生成 ut4, ut5, ut6 的随机变化值，确保在 10%-50% 内增加
% Generate random varying values for ut4, ut5, ut6, increased by 10%-50%
ut4_values = unique(150 + rand(num_samples * 2, 1) * (0.5 * 150 - 0.1 * 150) + 0.1 * 150);
ut4_values = ut4_values(1:num_samples);  % 取前50个唯一值 / Take the first 50 unique values

ut5_values = unique(150 + rand(num_samples * 2, 1) * (0.5 * 150 - 0.1 * 150) + 0.1 * 150);
ut5_values = ut5_values(1:num_samples);  % 取前50个唯一值 / Take the first 50 unique values

ut6_values = unique(80 + rand(num_samples * 2, 1) * (0.5 * 80 - 0.1 * 80) + 0.1 * 80);
ut6_values = ut6_values(1:num_samples);  % 取前50个唯一值 / Take the first 50 unique values

% 运行仿真50次
% Run simulation for 50 times
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
    ut4_signal = timeseries(ut4_values(i) * ones(size(time)), time);  % ut4 随机变化 / ut4 random value
    ut5_signal = timeseries(ut5_values(i) * ones(size(time)), time);  % ut5 随机变化 / ut5 random value
    ut6_signal = timeseries(ut6_values(i) * ones(size(time)), time);  % ut6 随机变化 / ut6 random value

    % 运行仿真，获取数据
    % Run simulation and get data
    simOut = sim('OLTC_simulation', 'StopTime', '0.1', ...
                 'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');  % 根据您的模型名称设置 / Set according to your model name
    
    % 获取输入电流和输出电压的时间序列
    % Get time series for input current and output voltage
    Iin_timeseries = simOut.get('Iin');  % 假设 Iin 是 timeseries 对象 / Assume Iin is a timeseries object
    Uout_timeseries = simOut.get('Uout');  % 假设 Uout 也是 timeseries 对象 / Assume Uout is also a timeseries object

    % 检查获取到的 timeseries 是否有效
    % Check if the obtained timeseries is valid
    if ~isempty(Iin_timeseries) && ~isempty(Uout_timeseries)
        % 提取 timeseries 对象中的数据部分
        % Extract data part from timeseries object
        Iin_data = Iin_timeseries.Data;  % 提取 Iin 的数据 / Extract Iin data
        Uout_data = Uout_timeseries.Data;  % 提取 Uout 的数据 / Extract Uout data
        
        % 存储数据到矩阵
        % Store data into matrices
        data_Iin(:, i) = Iin_data;
        data_Uout(:, i) = Uout_data;
    else
        warning('Timeseries data for Iin or Uout is empty in iteration %d', i);  % 警告：数据为空 / Warning: data is empty
    end
end

% 将输入电流和输出电压保存到 CSV 文件
% Save input current and output voltage to CSV files
csvwrite('ut4-6delay_Iin.csv', data_Iin);
csvwrite('ut4-6delay_Uout.csv', data_Uout);