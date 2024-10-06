clear all
close all
addpath("functions\")





% *************************************************************************
% ************************** EEG data reading *****************************
% *************************************************************************
EEG_data = readmatrix("eeg_dataset\subj_1.csv");
fc = 512;                                                                  % samples per second




% *************************************************************************
% ****************************** Filtering ********************************
% *************************************************************************
digital_filter(EEG_data, fc);



