function [] = spectral_estimation(EEG_data, fs, max_lag)



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    WSS    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Statistical mean

    % Statistical mean
    matrixMean = mean(EEG_data);
    figure()
    sgtitle('WSS: statistical mean');
    subplot(1, 2, 1)
    scatter(1:length(matrixMean), matrixMean, 'MarkerEdgeAlpha', 0.01);
    title("Statistical mean");
    xlabel("Sample index");
    ylabel("Statistical mean (µV)");

    % Statistical mean PDF
    subplot(1, 2, 2)
    [~, ~, mean_x, ~, variance_x] = pdf_estim(matrixMean, 51, 1);
    title("Statistical mean PDF");
    annotation('textbox', [.9 .4 .1 .2], ...
        'String', ['Mean value: ', string(mean_x), newline, 'Variance: ', string(variance_x)], ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Statistical autocorrelation

    ax_lags = -max_lag : 1 : max_lag;
    interval_lower_limit = max_lag;
    interval_higher_limit = length(EEG_data(1, :)) - max_lag;
    figure()
    sgtitle('WSS: statistical auto-correlation');

    statisticalRxxList = zeros(6, 2*max_lag + 1);
    rand_time_id_list = zeros(6, 1);
    for index = 1 : 6
        rand_time_id = randi([interval_lower_limit, interval_higher_limit]);
        rand_time_id_list(index) = rand_time_id;
        time_sample = EEG_data(:, rand_time_id)';
        statisticalRxx = xcorr(time_sample, max_lag)';
        statisticalRxxList(index, :) = statisticalRxx';
        subplot(2, 3, index)
        plot(ax_lags, statisticalRxx);
        title("Sample index: " + rand_time_id);
        xlabel("Temporal delay (samples)");
        ylabel("Auto-correlation");
    end






    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    ERGODICITY    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Temporal mean

    % Temporal mean
    matrixMean = mean(EEG_data, 2)';
    figure
    sgtitle('Ergodicity: temporal mean');
    subplot(1, 2, 1)
    scatter(1:length(matrixMean), matrixMean, 'MarkerEdgeAlpha', 0.8);
    title("Temporal mean");
    xlabel("Realization number");
    ylabel("Temporal mean (µV)");
    xlim([1 length(matrixMean)]);

    % Temporal mean PDF
    subplot(1, 2, 2)
    [~, ~, mean_x, ~, variance_x] = pdf_estim(matrixMean, 51, 1);
    title("Temporal mean PDF");
    annotation('textbox', [.9 .4 .1 .2], ...
        'String', ['Mean value: ', string(mean_x), newline, 'Variance: ', string(variance_x)], ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    xlim([-3 3]);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Temporal autocorrelation
        
    ax_lags = -max_lag : 1 : max_lag;
    figure()
    sgtitle('Ergodicity: temporal auto-correlation');

    temporalRxxList = zeros(6, 2*max_lag + 1);
    realization_numbers = randi([1, size(EEG_data, 1)], 1, 6);
    realization_numbers(1) = 1076;
    for index = 1 : 6
        realization_number = realization_numbers(index);
        time_sample = EEG_data(realization_number, :)';
        temporalRxx = xcorr(time_sample, max_lag)';
        temporalRxxList(index, :) = temporalRxx;
        subplot(2, 3, index)
        plot(ax_lags, temporalRxx);
        title("Realization index: " + realization_number);
        xlabel("Temporal delay (samples)");
        ylabel("Auto-correlation");
    end






    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        PSD       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Mean power spectral density
    figure()
    sgtitle('Power spectral density for different realizations');

    Nfft = 2^(ceil(log2(length(ax_lags))));
    ax_freq = -fs/2 : fs/Nfft : fs/2 - fs/Nfft;
    for index = 1 : 3
        temporalRxx = temporalRxxList(index, :);
        temporalFftInterval = fft(temporalRxx, Nfft)';
        temporalMagnitude = abs(fftshift(temporalFftInterval));
        temporalMagnitudeDb = 10 * log10(temporalMagnitude);
        subplot(2, 3, index)
        plot(ax_freq, temporalMagnitudeDb);
        xlim([0 60])
        ylim([40 130])
        title("dB magnitude - realization " + realization_numbers(index));
        xlabel("Frequency (Hz)");
        ylabel("Spectral density (dB)");
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Instant power spectral density
    T_staz = 1;
    N_cb = T_staz * fs;
    Nfft = 2^(ceil(log2(length(ax_lags))));

    for index = 1 : 3
        subplot(2, 3, index + 3);
        signal = EEG_data(realization_numbers(index), :);
        spectrogram(signal, N_cb, 0, Nfft, fs);
        xlim([0 0.110])
        clim([-40 40]);
        if (index == 1)
            title("Epileptic spectrogram: " + realization_numbers(index));
        else
            title("Normal spectrogram: " + realization_numbers(index));
        end
        
    end

    physical_resolution = 2*fs / N_cb;
    computational_resolution = fs / Nfft;
    annotation('textbox', [.9 .4 .1 .2], ...
        'String', ['Physical resol: ', string(physical_resolution), newline, 'Computational resol: ', string(computational_resolution)], ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');



    return


end