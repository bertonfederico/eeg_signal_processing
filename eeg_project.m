clear all
close all
addpath("functions\")





% *************************************************************************
% ****************************** Filtering ********************************
% *************************************************************************
% Example for both passband and notch filters required
% EEG_dataset_test_1 = readmatrix("eeg_dataset\filtering\passband_notch\subj_1.csv");
% fs = 512;
% notch_R = 0.60;
% digital_filter(EEG_dataset_test_1', fs, notch_R, 1, 0);
% pause

% Example for onlye passband filter required
% EEG_dataset_test_2 = load("eeg_dataset\filtering\passband\1.mat");
% EEG_dataset_test_2 = EEG_dataset_test_2.dataBuffer;
% fs = 5000;
% digital_filter(EEG_dataset_test_2, fs, 0, 1, 0);
% pause

% Matrix filter
% fs = 5000;
% loadedData = load('eeg_dataset\spectral_estimation\merged_data.mat');
% EEG_data = loadedData.dataBuffer;
% filteredEEG_data = zeros(size(EEG_data));
% for i = 1:size(EEG_data, 1)
%     filteredEEG_data(i, :) = digital_filter(EEG_data(i, :), fs, 0, 0, 1);
% end
% pause





% *************************************************************************
% *********************** Sampling and quantization ***********************
% *************************************************************************

% Importing filtered dataset
fs_original = 5000;
loadedData = load('eeg_dataset\spectral_estimation\filtered_EEG_data.mat');
dataBuffer = loadedData.filteredEEG_data;

% Sampling
fs_new = 500;
downsample_factor = round(fs_original / fs_new);
[row_size, col_size] = size(dataBuffer);
EEG_data_downsampled = zeros(row_size, col_size/downsample_factor);
for row = 1 : row_size
    EEG_data_downsampled(row, :) = dataBuffer(row, 1 : downsample_factor : end);
end

% Quantization
quantization(EEG_data_downsampled);






% *************************************************************************
% ************************** Spectral estimation **************************
% *************************************************************************
%fs = 5000;
%loadedData = load('eeg_dataset\spectral_estimation\merged_data.mat');
%dataBuffer = loadedData.dataBuffer;
%spectral_estimation(dataBuffer, fs);









