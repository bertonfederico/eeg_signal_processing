clear all
close all
addpath("functions\")





% *************************************************************************
% ****************************** Filtering ********************************
% *************************************************************************
%% Example for both passband and notch filters required
EEG_dataset_test_1 = readmatrix("eeg_dataset\filter\subj_1.csv");
fs = 512;
notch_R = 0.60;
digital_filter(EEG_dataset_test_1', fs, notch_R, 1);
pause





% *************************************************************************
% ************************** Spectral estimation **************************
% *************************************************************************
%% Spectral estimation
fs_original = 5000;
loadedData = load('eeg_dataset\psd\filtered_EEG_data.mat');
dataBuffer = loadedData.filteredEEG_data;
max_lag = 15000;
spectral_estimation(dataBuffer, fs_original, max_lag);
pause





% *************************************************************************
% *********************** Sampling and quantization ***********************
% *************************************************************************
%% Sampling
fs_new = 500;
loadedData = load('eeg_dataset\quantization\joined.mat');
dataBuffer = loadedData.data_cleaned;
EEG_data_downsampled = sampling(dataBuffer, fs_original, fs_new);

% Quantization
quantization(EEG_data_downsampled);

