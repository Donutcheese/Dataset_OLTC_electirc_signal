% 初始化参数
num_samples = 50;  % 运行50次仿真
time_series_length = 1001;  % 每个时间序列数据长度 (根据仿真步数定)

% 初始化存储数据矩阵
data_Iin = zeros(time_series_length, num_samples);
data_Uout = zeros(time_series_length, num_samples);

% 电源电压和负载电阻的随机范围
resistance_range = [0.4, 1.0];  % 负载阻值范围
voltage_range = [0.93 * 5700, 1.07 * 5700];  % 电源电压波动范围

% 生成电源电压的随机值，确保无重复
input_voltages = unique(rand(num_samples * 2, 1) * (voltage_range(2) - voltage_range(1)) + voltage_range(1));
input_voltages = input_voltages(1:num_samples);  % 取前50个唯一值

% 生成负载电阻的随机值，确保无重复
load_resistances = unique(rand(num_samples * 2, 1) * (resistance_range(2) - resistance_range(1)) + resistance_range(1));
load_resistances = load_resistances(1:num_samples);  % 取前50个唯一值

% 固定 ut3, ut4, ut5, ut6 为正常值
ut3_value = 150;

% % 生成 ut4, ut5, ut6 的随机变化值，确保在 10%-50% 内增加
ut4_values = unique(150 + rand(num_samples * 2, 1) * (0.5 * 150 - 0.1 * 150) + 0.1 * 150);
ut4_values = ut4_values(1:num_samples);  % 取前50个唯一值

ut5_values = unique(150 + rand(num_samples * 2, 1) * (0.5 * 150 - 0.1 * 150) + 0.1 * 150);
ut5_values = ut5_values(1:num_samples);  % 取前50个唯一值

ut6_values = unique(80 + rand(num_samples * 2, 1) * (0.5 * 80 - 0.1 * 80) + 0.1 * 80);
ut6_values = ut6_values(1:num_samples);  % 取前50个唯一值

% 运行仿真50次
for i = 1:num_samples
    % 从无重复集合中取出电源电压和负载电阻
    input_voltage = input_voltages(i);  % 唯一的电压值
    load_resistance = load_resistances(i);  % 唯一的负载电阻
    
    % 设置 Simulink 模型中的电源电压和负载电阻参数
    set_param('safffffff22015/AC Voltage Source', 'Amplitude', num2str(input_voltage));  % 设置电源电压
    set_param('safffffff22015/Series RLC Branch1', 'Resistance', num2str(load_resistance));  % 设置负载电阻

    % 创建 ut3, ut4, ut5, ut6 的 timeseries 信号
    time = linspace(0, 7, time_series_length);  % 仿真时间
    ut3_signal = timeseries(ut3_value * ones(size(time)), time);  % 固定 ut3 为150ms
    ut4_signal = timeseries(ut4_value * ones(size(time)), time);  % 固定 ut4 为150ms
    ut5_signal = timeseries(ut5_value * ones(size(time)), time);  % 固定 ut5 为150ms
    ut6_signal = timeseries(ut6_value * ones(size(time)), time);  % 固定 ut6 为80ms

    % 运行仿真，获取数据
    simOut = sim('safffffff22015', 'StopTime', '0.1', ...
                 'ExternalInput', '[ut3_signal, ut4_signal, ut5_signal, ut6_signal]');  % 根据您的模型名称设置
    
    % 获取输入电流和输出电压的时间序列
    Iin_timeseries = simOut.get('Iin');  % 假设 Iin 是 timeseries 对象
    Uout_timeseries = simOut.get('Uout');  % 假设 Uout 也是 timeseries 对象

    % 检查获取到的 timeseries 是否有效
    if ~isempty(Iin_timeseries) && ~isempty(Uout_timeseries)
        % 提取 timeseries 对象中的数据部分
        Iin_data = Iin_timeseries.Data;  % 提取 Iin 的数据
        Uout_data = Uout_timeseries.Data;  % 提取 Uout 的数据
        
        % 存储数据到矩阵
        data_Iin(:, i) = Iin_data;
        data_Uout(:, i) = Uout_data;
    else
        warning('Timeseries data for Iin or Uout is empty in iteration %d', i);
    end
end

% 将输入电流和输出电压保存到 CSV 文件
csvwrite('ut4-6delay_Iin.csv', data_Iin);
csvwrite('ut4-6delay_Uout.csv', data_Uout);
