function [] = digital_filter(EEG_data, fc)


    N = length(EEG_data);
    time = (0:N-1) / fc;



    % *************************************************************************
    % ***************************** Bandpass filter ***************************
    % *************************************************************************
    f1 = 0.5;
    f2 = 42;
    F1 = f1 - 0.5;
    F2 = f1 + 0.5;
    F3 = f2 - 2;
    F4 = f2 + 2;
    A_stop = 80;                                                               % db attenuation
    delta = 10^(-A_stop / 20);
    [n, Wn, beta, filtype] = kaiserord([F1 F2 F3 F4], [0 1 0], [delta delta delta], fc);
    fir_filter = fir1(n, Wn, filtype, kaiser(n+1, beta));
    bandpass_filtered_eeg = filter(fir_filter, 1, EEG_data);





    % *************************************************************************
    % ****************************** Notch filter *****************************
    % *************************************************************************
    f0 = 50;
    w0 = (2 * pi * f0) / fc;
    r = 1;
    R = 0.60;
    a1 = -2 * R * cos(w0);
    a2 = R^2;
    b1 = -2 * r * cos(w0);
    b2 = r^2;
    a_notch = [1 a1 a2];
    b_notch = [1 b1 b2];
    notch_filtered_eeg = filter(b_notch, a_notch, EEG_data);





    % *************************************************************************
    % ************************ Bandpass + notch filter ************************
    % *************************************************************************
    bandpass_notch_filtered_eeg = filter(b_notch, a_notch, bandpass_filtered_eeg);





    % *************************************************************************
    % ***************************** Signal graphs *****************************
    % *************************************************************************
    figure;
    subplot(2, 2, 1);
    plot(time, EEG_data);
    title('Initial signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    subplot(2, 2, 2);
    plot(time, bandpass_filtered_eeg);
    title('Bandpass filtered signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    ylim([-300 300]);
    subplot(2, 2, 3);
    plot(time, notch_filtered_eeg);
    title('Notch filtered signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    subplot(2, 2, 4);
    plot(time, bandpass_notch_filtered_eeg);
    title('Bandpass + notch signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    ylim([-300 300]);





    % *************************************************************************
    % ****************************** Group delay ******************************
    % *************************************************************************
    figure;
    [gd_bandpass, gd_window_bandpass] = grpdelay(fir_filter, 1, 512, fc);
    subplot(2, 1, 1);
    time_gd_bandpass = gd_bandpass / fc;
    plot(gd_window_bandpass, time_gd_bandpass);
    xlabel('Frequency (Hz)');
    ylabel('Group delay (seconds)');
    title('Group delay - Kaiser FIR windows');
    grid on;
    [gd_notch, gd_window_notch] = grpdelay(b_notch, a_notch, 512, fc);
    subplot(2, 1, 2);
    time_gd_notch = gd_notch / fc;
    plot(gd_window_notch, time_gd_notch);
    xlabel('Frequency (Hz)');
    ylabel('Group delay (seconds)');
    title('Group delay - notch filter');
    grid on;





    % *************************************************************************
    % ******************************* PDF graphs ******************************
    % *************************************************************************
    figure;
    Nint = 64;
    subplot(2, 2, 1);
    pdf_estim(EEG_data(:, 1), Nint, 1);
    title('Probability density with artifact');
    subplot(2, 2, 2);
    pdf_estim(bandpass_filtered_eeg(:, 1), Nint, 1);
    title('Probability density - bandpass filter');
    subplot(2, 2, 3);
    pdf_estim(notch_filtered_eeg(:, 1), Nint, 1);
    title('Probability density - notch filter');
    subplot(2, 2, 4);
    pdf_estim(bandpass_notch_filtered_eeg(:, 1), Nint, 1);
    title('Probability density - bandpass + notch filter');




    % *************************************************************************
    % ****************************** Spectrogram ******************************
    % *************************************************************************
    T_staz = 400E-3;                                                           % stationary time
    n_cb = ceil(T_staz*fc);                                                    % samples for windowing
    n_fft = 2^(ceil(log2(n_cb)) + 1);                                          % frequency resolution
    figure
    subplot(2, 2, 1);
    [S, F, ~] = spectrogram(EEG_data, n_cb, 0, n_fft, fc);
    plot(F, 20*log10(mean(abs(S'))), 'r');
    title('Spectrogram with artifact');
    xlabel('Frequency');
    ylabel('Magnitudine');
    subplot(2, 2, 2);
    [S, F, ~] = spectrogram(bandpass_filtered_eeg, n_cb, 0, n_fft, fc);
    plot(F, 20*log10(mean(abs(S'))), 'r');
    title('Spectrogram without artifact - bandpass');
    xlabel('Frequency');
    ylabel('Magnitudine');
    subplot(2, 2, 3);
    [S, F, ~] = spectrogram(notch_filtered_eeg, n_cb, 0, n_fft, fc);
    plot(F, 20*log10(mean(abs(S'))), 'r');
    title('Spectrogram without artifact - notch filter');
    xlabel('Frequency');
    ylabel('Magnitudine');
    subplot(2, 2, 4);
    [S, F, ~] = spectrogram(bandpass_notch_filtered_eeg, n_cb, 0, n_fft, fc);
    plot(F, 20*log10(mean(abs(S'))), 'r');
    title('Spectrogram without artifact - bandpass + notch filter');
    xlabel('Frequency');
    ylabel('Magnitudine');


end

