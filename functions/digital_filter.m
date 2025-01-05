function [total_filtered] = digital_filter(EEG_data, fc, notch_R)


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
    A_stop = 80;
    delta = 10^(-A_stop / 20);
    [n, Wn, beta, filtype] = kaiserord([F1 F2 F3 F4], [0 1 0], [delta delta delta], fc);
    fir_filter = fir1(n, Wn, filtype, kaiser(n+1, beta));

    % FIR filter with linear convolution
    M = length(EEG_data);
    L = length(fir_filter);
    bandpass_filtered_eeg_0 = conv(EEG_data, fir_filter);

    % FIR filter with padding and linear convolution
    EEG_data_padded = [EEG_data(end-L+1:end), EEG_data];
    bandpass_filtered_padded_eeg = conv(EEG_data_padded, fir_filter);
    bandpass_filtered_eeg_1 = bandpass_filtered_padded_eeg(L+1:L+M);

    % FIR filter with circular convolution & FFT
    filter_padded = [fir_filter zeros(1, M - length(fir_filter))];
    bandpass_filtered_eeg_2 = ifft(fft(filter_padded).*fft(EEG_data));
    Nfft = 1000;
    [freq_resp_fir, freq_fir] = freqz(fir_filter, 1, Nfft, fc);



    % *************************************************************************
    % ****************************** Notch filter *****************************
    % *************************************************************************
    f0 = 50;
    w0 = (2 * pi * f0) / fc;
    r = 1;
    R = notch_R;
    a1 = -2 * R * cos(w0);
    a2 = R^2;
    b1 = -2 * r * cos(w0);
    b2 = r^2;
    a_notch = [1 a1 a2];
    b_notch = [1 b1 b2];

    % Notch-filtered signal
    notch_filtered_eeg = filter(b_notch, a_notch, EEG_data);

    % Frequency response for plot
    Nfft = 1000;
    [freq_resp_notch, freq_notch] = freqz(b_notch, a_notch, Nfft, fc);

    % Poles and zeros for plot
    zeri = zeros(2, 1);
    zeri(1) = r * cos(w0) + 1i * r * sin(w0);
    zeri(2) = r * cos(w0) - 1i * r * sin(w0);
    poles = zeros(2, 1);
    poles(1) = R * cos(w0) + 1i * R * sin(w0);
    poles(2) = R * cos(w0) - 1i * R * sin(w0);





    % *************************************************************************
    % ************************ Bandpass + notch filter ************************
    % *************************************************************************
    total_filtered = filter(b_notch, a_notch, bandpass_filtered_eeg_2);
    




    % *************************************************************************
    % ***************************** FIR comparison ****************************
    % *************************************************************************
    figure;
    sgtitle('FIR convolutions comparison')
    subplot(3, 1, 1);
    plot(time(1:5000), bandpass_filtered_eeg_0(1:5000));
    title('FIR with linear convolution');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');

    subplot(3, 1, 2);
    plot(time(1:5000), bandpass_filtered_eeg_1(1:5000));
    title('FIR with padding and linear convolution');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');

    subplot(3, 1, 3);
    plot(time(1:5000), bandpass_filtered_eeg_2(1:5000));
    title('FIR with circular convolution');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');

    
    
    
    
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
    plot(time, bandpass_filtered_eeg_2);
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
    plot(time, total_filtered);
    title('Bandpass + notch signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    ylim([-300 300]);





    % *************************************************************************
    % ************************* FIR impulse & frequence ***********************
    % *************************************************************************
    figure;
    subplot(2, 2, 1);
    stem(fir_filter);
    title('Band-pass filter impulse response');
    xlim([1210 1360]);

    subplot(2, 2, 2);
    plot(freq_fir, 20*log10(abs(freq_resp_fir)));
    title('Band-pass filter frquency response');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    xlim([0 70]);
    ylim([-200 10]);

    subplot(2, 2, 3);
    plot(time, EEG_data);
    title('Original signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    xlim([0 30]);
    ylim([-1000 1000]);

    subplot(2, 2, 4);
    plot(time, bandpass_filtered_eeg_2);
    title('Bandpass filtered signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    xlim([0 30]);
    ylim([-400 500]);





    % *************************************************************************
    % ************************* IIR impulse & frequence ***********************
    % *************************************************************************
    figure;
    subplot(2, 2, 1);
    hold on
    angles = -pi : 2*pi/2048 : pi;
    plot(cos(angles), sin(angles))
    axis([-1.3, 1.3, -1.3, 1.3]);
    plot(poles, 'o');
    plot(zeri, '*');
    title('Poles-zeros pattern');
    hold off

    subplot(2, 2, 2);
    plot(freq_notch, 20*log10(abs(freq_resp_notch)));
    title('Notch filter magnitude frquency response');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');

    subplot(2, 2, 3);
    plot(freq_notch, unwrap(angle(freq_resp_notch)));
    title('Notch filter phase frquency response');
    xlabel('Frequency (Hz)');
    ylabel('Phase (degrees)');

    subplot(2, 2, 4);
    plot(time, notch_filtered_eeg);
    title('Notch filtered signal');
    xlabel('Time (s)');
    ylabel('Amplitude (µV)');
    xlim([0 30]);
    ylim([-400 500]);




    % *************************************************************************
    % ****************************** Group delay ******************************
    % *************************************************************************
    figure;
    [gd_bandpass, gd_window_bandpass] = grpdelay(fir_filter, 1, [], fc);
    subplot(2, 1, 1);
    time_gd_bandpass = gd_bandpass / fc;
    plot(gd_window_bandpass, time_gd_bandpass);
    xlabel('Frequency (Hz)');
    ylabel('Group delay (samples)');
    title('Group delay - Kaiser FIR windows');
    grid on;

    subplot(2, 1, 2);
    [gd_notch, gd_window_notch] = grpdelay(b_notch, a_notch, [], fc);
    time_gd_notch = gd_notch / fc;
    plot(gd_window_notch, time_gd_notch);
    xlabel('Frequency (Hz)');
    ylabel('Group delay (samples)');
    title('Group delay - notch filter');
    grid on;





    % *************************************************************************
    % ******************************* PDF graphs ******************************
    % *************************************************************************
    figure;
    Nint = 64;
    subplot(2, 2, 1);
    pdf_estim(EEG_data', Nint, 1);
    title('Probability density with artifact');
    subplot(2, 2, 2);
    pdf_estim(bandpass_filtered_eeg_2', Nint, 1);
    title('Probability density - bandpass filter');
    subplot(2, 2, 3);
    pdf_estim(notch_filtered_eeg', Nint, 1);
    title('Probability density - notch filter');
    subplot(2, 2, 4);
    pdf_estim(total_filtered', Nint, 1);
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
    [S, F, ~] = spectrogram(bandpass_filtered_eeg_2, n_cb, 0, n_fft, fc);
    plot(F, 20*log10(mean(abs(S'))), 'r');
    title('Filtered spectrogram - bandpass');
    xlabel('Frequency');
    ylabel('Magnitudine');

    subplot(2, 2, 3);
    [S, F, ~] = spectrogram(notch_filtered_eeg, n_cb, 0, n_fft, fc);
    plot(F, 20*log10(mean(abs(S'))), 'r');
    title('Filtered spectrogram - notch filter');
    xlabel('Frequency');
    ylabel('Magnitudine');

    subplot(2, 2, 4);
    [S, F, ~] = spectrogram(total_filtered, n_cb, 0, n_fft, fc);
    plot(F, 20*log10(mean(abs(S'))), 'r');
    title('Filtered spectrogram - bandpass + notch filter');
    xlabel('Frequency');
    ylabel('Magnitudine');


end

