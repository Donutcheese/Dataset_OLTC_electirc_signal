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

