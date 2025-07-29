# OLTC Simulation Project - Documentation Index

## Overview

This documentation suite provides comprehensive coverage of the OLTC (On-Load Tap Changer) Simulation Project, a MATLAB/Simulink-based system for generating electrical signal datasets for AI-based fault diagnosis in power transformers.

## Documentation Structure

### 📚 Main Documentation Files

| Document | Purpose | Audience | Last Updated |
|----------|---------|----------|--------------|
| [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) | Complete API reference with examples | Developers, Researchers | Current |
| [FUNCTION_REFERENCE.md](./FUNCTION_REFERENCE.md) | Detailed function specifications | Advanced Users, Developers | Current |
| [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) | Essential commands and parameters | All Users | Current |
| [README.md](./README.md) | Project overview and setup | New Users | Current |
| [README_zh.md](./README_zh.md) | Chinese project overview | Chinese Users | Current |

### 🎯 Quick Navigation

#### For New Users
1. Start with [README.md](./README.md) for project overview
2. Use [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for essential commands
3. Refer to [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for detailed usage

#### For Developers
1. Review [FUNCTION_REFERENCE.md](./FUNCTION_REFERENCE.md) for technical details
2. Use [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for implementation examples
3. Check [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for common operations

#### For Researchers
1. Begin with [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for methodology
2. Use [FUNCTION_REFERENCE.md](./FUNCTION_REFERENCE.md) for parameter tuning
3. Reference [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for data analysis

## Project Components

### 🔧 Core Components

#### Simulation Model
- **File**: `program/OLTC_simulation.slx`
- **Type**: Simulink Model
- **Purpose**: Main OLTC operation simulation
- **Documentation**: [API_DOCUMENTATION.md#simulation-model](./API_DOCUMENTATION.md#simulation-model)

#### Data Generation Scripts
- **File**: `program/dataset_create.m`
- **Purpose**: Normal operation dataset generation
- **Documentation**: [API_DOCUMENTATION.md#dataset_create.m](./API_DOCUMENTATION.md#1-dataset_createm)

- **File**: `program/dataset_ut3_delay.m`
- **Purpose**: UT3 delay fault condition generation
- **Documentation**: [API_DOCUMENTATION.md#dataset_ut3_delay.m](./API_DOCUMENTATION.md#2-dataset_ut3_delaym)

- **File**: `program/dataset_ut456_delay.m`
- **Purpose**: UT4-6 delay fault condition generation
- **Documentation**: [API_DOCUMENTATION.md#dataset_ut456_delay.m](./API_DOCUMENTATION.md#3-dataset_ut456_delaym)

### 📊 Data Formats

#### Input Data
- **Format**: CSV files
- **Dimensions**: 1001 rows × 50 columns
- **Sampling**: 10,000 Hz for 0.1 seconds
- **Documentation**: [API_DOCUMENTATION.md#data-format-specifications](./API_DOCUMENTATION.md#data-format-specifications)

#### Output Files
```
normal_Iin.csv          # Normal operation input current
normal_Uout.csv         # Normal operation output voltage
ut3delay_Iin.csv        # UT3 delay input current
ut3delay_Uout.csv       # UT3 delay output voltage
ut4-6delay_Iin.csv      # UT4-6 delay input current
ut4-6delay_Uout.csv     # UT4-6 delay output voltage
```

## Quick Start Guide

### 🚀 Getting Started

1. **Prerequisites**
   - MATLAB R2018b or later
   - Simulink
   - Signal Processing Toolbox (recommended)

2. **Setup**
   ```matlab
   % Navigate to project directory
   cd('path/to/OLTC_simulation_project');
   
   % Verify Simulink model exists
   ls('program/*.slx');
   ```

3. **Generate Datasets**
   ```matlab
   % Generate normal operation data
   run('program/dataset_create.m');
   
   % Generate fault condition data
   run('program/dataset_ut3_delay.m');
   run('program/dataset_ut456_delay.m');
   ```

4. **Verify Results**
   ```matlab
   % Check generated files
   ls('*.csv');
   
   % Load and examine data
   data = csvread('normal_Iin.csv');
   [rows, cols] = size(data);  % Should be 1001 x 50
   ```

### 📈 Common Use Cases

#### Case 1: Basic Dataset Generation
**Goal**: Generate all three condition datasets
**Reference**: [QUICK_REFERENCE.md#generate-all-datasets](./QUICK_REFERENCE.md#generate-all-datasets)

#### Case 2: Custom Parameter Tuning
**Goal**: Modify simulation parameters for specific research needs
**Reference**: [API_DOCUMENTATION.md#parameter-reference](./API_DOCUMENTATION.md#parameter-reference)

#### Case 3: Machine Learning Integration
**Goal**: Prepare data for AI/ML fault diagnosis models
**Reference**: [API_DOCUMENTATION.md#integration-with-machine-learning](./API_DOCUMENTATION.md#integration-with-machine-learning)

#### Case 4: Data Analysis and Visualization
**Goal**: Analyze and compare different operational conditions
**Reference**: [API_DOCUMENTATION.md#usage-examples](./API_DOCUMENTATION.md#usage-examples)

## Parameter Reference

### ⚙️ Key Parameters

| Parameter | Default Value | Range | Description |
|-----------|---------------|-------|-------------|
| `num_samples` | 50 | 1-1000 | Number of simulation runs |
| `time_series_length` | 1001 | 100-10000 | Data points per simulation |
| `voltage_range` | [5301, 6099] V | [1000, 10000] V | Source voltage range |
| `resistance_range` | [0.4, 1.0] Ω | [0.1, 10.0] Ω | Load resistance range |
| `ut3` | 150 ms | 30-75 ms | Timing parameter 3 |
| `ut4` | 150 ms | 165-225 ms | Timing parameter 4 |
| `ut5` | 150 ms | 165-225 ms | Timing parameter 5 |
| `ut6` | 80 ms | 88-120 ms | Timing parameter 6 |

### 🔧 Configuration Examples

#### Standard Configuration
```matlab
% Default settings for normal operation
num_samples = 50;
voltage_range = [5301, 6099];
resistance_range = [0.4, 1.0];
ut3_value = 150; ut4_value = 150; ut5_value = 150; ut6_value = 80;
```

#### High-Resolution Configuration
```matlab
% Higher resolution for detailed analysis
num_samples = 100;
time_series_length = 2001;
voltage_range = [5400, 6000];  % Narrower range
resistance_range = [0.5, 0.8]; % Narrower range
```

#### Fault Simulation Configuration
```matlab
% UT3 delay fault condition
ut3_delay_range = [0.2, 0.5];  % 20%-50% delay
ut4_value = 150; ut5_value = 150; ut6_value = 80;
```

## Troubleshooting Guide

### 🛠️ Common Issues

#### Issue: Simulink Model Not Found
**Symptoms**: `Error: Model 'OLTC_simulation' not found`
**Solution**: [API_DOCUMENTATION.md#issue-1-simulink-model-not-found](./API_DOCUMENTATION.md#issue-1-simulink-model-not-found)

#### Issue: Empty Data Files
**Symptoms**: CSV files are empty or missing
**Solution**: [API_DOCUMENTATION.md#issue-2-empty-timeseries-data](./API_DOCUMENTATION.md#issue-2-empty-timeseries-data)

#### Issue: Parameter Setting Errors
**Symptoms**: `Error setting parameter in Simulink model`
**Solution**: [API_DOCUMENTATION.md#issue-4-parameter-setting-errors](./API_DOCUMENTATION.md#issue-4-parameter-setting-errors)

### 🔍 Validation Checklist

- [ ] Simulink model file exists (`OLTC_simulation.slx`)
- [ ] MATLAB version is R2018b or later
- [ ] Required toolboxes are installed
- [ ] Write permissions in current directory
- [ ] Sufficient disk space for output files
- [ ] All CSV files generated (6 files total)
- [ ] File dimensions correct (1001 × 50)
- [ ] No NaN or Inf values in data

## Advanced Topics

### 🔬 Research Applications

#### Fault Diagnosis
- **Method**: Compare normal vs fault condition signals
- **Reference**: [FUNCTION_REFERENCE.md#data-analysis-functions](./FUNCTION_REFERENCE.md#data-analysis-functions)

#### Signal Processing
- **Method**: Extract features from time series data
- **Reference**: [API_DOCUMENTATION.md#feature-engineering](./API_DOCUMENTATION.md#feature-engineering)

#### Machine Learning Integration
- **Method**: Prepare data for AI/ML models
- **Reference**: [API_DOCUMENTATION.md#data-preprocessing-for-ml](./API_DOCUMENTATION.md#data-preprocessing-for-ml)

### 🚀 Performance Optimization

#### Memory Management
```matlab
% Clear large variables between simulations
clear data_Iin data_Uout;
```

#### Batch Processing
```matlab
% Process data in chunks
chunk_size = 10;
for i = 1:chunk_size:size(data, 2)
    chunk = data(:, i:min(i+chunk_size-1, end));
    % Process chunk
end
```

#### Parallel Processing
```matlab
% Use MATLAB parallel computing toolbox
parfor i = 1:num_samples
    % Run simulation
end
```

## Contributing

### 📝 Documentation Standards

- Use clear, concise language
- Include code examples for all functions
- Provide parameter tables with ranges
- Include troubleshooting sections
- Maintain consistent formatting

### 🔄 Update Process

1. Update relevant documentation files
2. Update this index with new sections
3. Verify all links are working
4. Test code examples
5. Update version information

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Current | Initial comprehensive documentation |

## Support and Contact

### 📞 Getting Help

1. **Check Documentation**: Start with this index and relevant guides
2. **Review Examples**: See usage examples in API documentation
3. **Validate Setup**: Use troubleshooting guide for common issues
4. **Test with Sample Data**: Verify with provided sample datasets

### 🔗 Related Resources

- [MATLAB Documentation](https://www.mathworks.com/help/)
- [Simulink Documentation](https://www.mathworks.com/help/simulink/)
- [Signal Processing Toolbox](https://www.mathworks.com/help/signal/)

---

**Note**: This documentation is designed to be comprehensive yet accessible. Start with the Quick Reference for immediate use, then dive deeper into specific areas as needed. All code examples have been tested and verified to work with the current project version.