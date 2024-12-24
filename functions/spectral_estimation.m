function [] = spectral_estimation(EEG_data, fs, max_lag)


    epilepticRelizationNumber = 1033;
    normalRealizationNumber = 537;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    WSS    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Statistical mean

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
    num_lags = length(ax_lags);
    figure()
    sgtitle('WSS: statistical auto-correlation');

    rand_time_id_list = zeros(6, 1);
    for index = 1 : 6
        rand_time_id = randi([interval_lower_limit, interval_higher_limit]);
        rand_time_id_list(index) = rand_time_id;
        ensembleRxx = zeros(num_lags, 1);
        X_t1 = EEG_data(:, rand_time_id);
        for i = 1:num_lags
            lag = ax_lags(i);
            X_t2 = EEG_data(:, rand_time_id + lag);
            ensembleRxx(i) = sum(X_t1 .* X_t2);
        end
        subplot(2, 3, index)
        plot(ax_lags, ensembleRxx);
        title("Sample index: " + rand_time_id);
        xlabel("Temporal lag (samples)");
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
    realization_numbers(1) = epilepticRelizationNumber;
    realization_numbers(2) = normalRealizationNumber;
    for index = 1 : 2
        realization_number = realization_numbers(index);
        time_sample = EEG_data(realization_number, :)';
        temporalRxx = xcorr(time_sample, max_lag)';
        subplot(2, 2, index)
        plot(time_sample);
        xlabel("Samples");
        ylabel("Amplitude (µV)");
        if (index == 1)
            title("EEG epileptic signal: " + realization_numbers(index));
        else
            title("EEG normal signal: " + realization_numbers(index));
        end

        temporalRxxList(index, :) = temporalRxx;
        subplot(2, 2, index+2)
        plot(ax_lags, temporalRxx);
        if (index == 1)
            title("Epileptic temporal auto-correlation: " + realization_numbers(index));
        else
            title("Normal temporal auto-correlation: " + realization_numbers(index));
        end
        xlabel("Temporal lag (samples)");
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
    for index = 1 : 2
        temporalRxx = temporalRxxList(index, :);
        temporalFftInterval = fft(temporalRxx, Nfft)';
        temporalMagnitude = abs(fftshift(temporalFftInterval));
        temporalMagnitudeDb = 10 * log10(temporalMagnitude);
        subplot(2, 2, index)
        plot(ax_freq, temporalMagnitudeDb);
        xlim([0 60])
        ylim([40 130])
        if (index == 1)
            title("Epileptic dB magnitude: realization " + realization_numbers(index));
        else
            title("Normal dB magnitude: realization " + realization_numbers(index));
        end
        xlabel("Frequency (Hz)");
        ylabel("Spectral density (dB)");
    end



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Instant power spectral density: difference in epileptic/non-epileptic
    T_staz = 1;
    N_cb = T_staz * fs;
    Nfft = 2^(ceil(log2(length(ax_lags))));

    for index = 1 : 2
        subplot(2, 2, index + 2);
        signal = EEG_data(realization_numbers(index), :);
        spectrogram(signal, N_cb, 0, Nfft, fs);
        xlim([0 0.110])
        clim([-40 40]);
        if (index == 1)
            title("Epileptic spectrogram: realization " + realization_numbers(index));
        else
            title("Normal spectrogram: realization " + realization_numbers(index));
        end
        
    end

    physical_resolution = 2*fs / N_cb;
    computational_resolution = fs / Nfft;
    annotation('textbox', [.9 .4 .1 .2], ...
        'String', ['Physical resol: ', string(physical_resolution), newline, 'Computational resol: ', string(computational_resolution)], ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Instant power spectral density: different stationary times
    figure()
    sgtitle('Power spectral density with different stationary times');
    T_stazs = [0.5, 1, 5, 10];
    index = 1;
    for T_staz = T_stazs
        N_cb = T_staz * fs;
        Nfft = 2^(ceil(log2(length(ax_lags))));
        subplot(2, 2, index);
        index = index + 1;
        signal = EEG_data(epilepticRelizationNumber, :);
        spectrogram(signal, N_cb, 0, Nfft, fs);
        xlim([0 0.110])
        clim([-40 40]);
        title("Stationary time: " + T_staz + " sec");
    end



    return


end