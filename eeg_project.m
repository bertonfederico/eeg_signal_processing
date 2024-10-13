clear all
close all
addpath("functions\")





% *************************************************************************
% ****************************** Filtering ********************************
% *************************************************************************
% Example for both passband and notch filters required
EEG_dataset_test_1 = readmatrix("eeg_dataset\filtering\passband_notch\subj_1.csv");
fs = 512;
notch_R = 0.60;
digital_filter(EEG_dataset_test_1', fs, notch_R, 1, 0);
pause

% Example for onlye passband filter required
EEG_dataset_test_2 = load("eeg_dataset\filtering\passband\1.mat");
EEG_dataset_test_2 = EEG_dataset_test_2.dataBuffer;
fs = 5000;
digital_filter(EEG_dataset_test_2, fs, 0, 1, 0);
pause

% Matrix filter
fs = 5000;
loadedData = load('eeg_dataset\spectral_estimation\merged_data.mat');
EEG_data = loadedData.dataBuffer;
filteredEEG_data = zeros(size(EEG_data));
for i = 1:size(EEG_data, 1)
    filteredEEG_data(i, :) = digital_filter(EEG_data(i, :), fs, 0, 0, 1);
end
pause




% *************************************************************************
% ************************** Spectral estimation **************************
% *************************************************************************
fs_original = 5000;
loadedData = load('eeg_dataset\spectral_estimation\filtered_EEG_data.mat');
dataBuffer = loadedData.filteredEEG_data;
max_lag = 15000;
spectral_estimation(dataBuffer, fs_original, max_lag);
pause





% *************************************************************************
% *********************** Sampling and quantization ***********************
% *************************************************************************
% Sampling
fs_new = 500;
EEG_data_downsampled = sampling(dataBuffer, fs_original, fs_new);

% Quantization
quantization(EEG_data_downsampled);
















