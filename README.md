# Dataset_OLTC_electirc_signal
A simulink of OLTC to create multipule situation for the machine learning training

[English](./README.md) | [中文](./README_zh.md)

## Project Overview
This project provides simulation models and datasets for On-Load Tap Changer (OLTC) in oil-immersed power transformers, focusing on AI-based fault diagnosis systems. The repository includes Simulink models for OLTC operation simulation, data generation tools, and sample datasets for AI training.

## Project Objectives
This project targets oil-immersed tap changers, developing an AI-based fault diagnosis system using deep learning. The research is built upon two core elements:
1. **Dataset Collection**: Comprehensive operational data covering normal operation, latent faults, and various load conditions
2. **Machine Learning Models**: Deep learning models for fault detection and prediction

## Key Components
- **Simulink Models**: Detailed simulation of OLTC mechanical operations
- **Data Generation Tools**: Scripts to generate training datasets with various operational conditions
- **Sample Datasets**: Pre-generated datasets for immediate testing
- **Deep Learning Implementation**: Code for training and testing AI models

## OLTC Operational Characteristics
The mechanical operation process of OLTC can be divided into 9 steps, with 3 steps involving significant electrical parameter changes (stable state, transition process, intermediate state). The electrical parameters used as inputs include current and output voltage.

## Dataset instruction
The sample_dataset folder contains input current and output voltage sample data for an On-Load Tap Changer (OLTC) under three different operating conditions. Each condition includes corresponding input current (.lin.csv) and output voltage (.Uout.csv) data files:

Normal Operation:
`normal_lin.csv` - Input current data under normal operating conditions
`normal_Uout.csv` - Output voltage data under normal operating conditions

ut3 Delay Condition:
`ut3delay_lin.csv` - Input current data with ut3 parameter delay
`ut3delay_Uout.csv` - Output voltage data with ut3 parameter delay

ut4-6 Delay Condition:
`ut4-6delay_lin.csv` - Input current data with ut4 to ut6 parameters delay
`ut4-6delay_Uout.csv` - Output voltage data with ut4 to ut6 parameters delay

Each data file contains results from 50 independent switching simulations, with each simulation recording 0.1 seconds of data at a sampling rate of 10,000Hz, resulting in 1001 time points per switching operation. These datasets can be used to train and test AI models for identifying and diagnosing normal operations and various fault conditions in on-load tap changers.

## Dataset Generation Scripts and Simulation Model

The following files are provided for dataset generation and simulation:

- `OLTC_simulation.slx`: Simulink model file, the source for all OLTC simulations.
- `dataset_create.m`: MATLAB script for generating datasets under normal operating conditions.
- `dataset_ut3_delay.m`: MATLAB script for generating datasets with ut3 parameter delay condition.
- `dataset_ut456_delay.m`: MATLAB script for generating datasets with ut4, ut5, ut6 parameter delay condition.

You can modify the parameters (such as `num_samples`) in the `.m` files to change the number of simulation runs and the size of the generated dataset. Each `.m` script will call the Simulink model to generate the corresponding data.
