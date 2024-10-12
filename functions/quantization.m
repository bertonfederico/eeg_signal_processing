function [] = quantization(EEG_data)




    % Usual EEG range --> [-100 µV, 100 µV]
    %       With 0 fractionary bits  -->   2^(n−1)−1 ≥ 100     -->  n >= 8
    %       With 1 fractionary bit   -->                            n >= 9
    % Epilepsy EEG range --> [-1000 µV, 1000 µV]
    %       With 0 fractionary bits  -->   2^(n−1)−1 ≥ 1500    -->  n >= 12
    %       With 1 fractionary bit   -->                            n >= 13
    % This dataset range --> [-1000 µV, 1000 µV]







    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Signals study %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Showing samples

    figure()
    for index = 1 : 6
        signal = EEG_data(index, :);
        signal = digital_filter(signal, 500, 0, 0, 1);
        subplot(2, 3, index);
        plot(signal);
        grid
        title("Signal " + index);
        ylabel("Amplitude (µV)");
        xlabel("Sample");
    end
    sgtitle('Signal examples');


    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Joining samples

    aggregated_data = EEG_data';
    aggregated_data = aggregated_data(:);
    aggregated_data = aggregated_data';
    aggregated_data = aggregated_data(aggregated_data < 1024 & aggregated_data >= -1024);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Aggregated PDF and CDF
    
    figure();
    sgtitle("Aggregated data PDF (Gaussian-like)");
    subplot(1, 2, 1);
    grid
    [xi, ~, ~, ~, ~, cdf_x] = pdf_estim(aggregated_data, 401, 1);
    title("PDF");
    subplot(1, 2, 2);
    grid
    plot(xi, cdf_x);
    xlabel('Amplitude (µV)');
    ylabel('Cumulative probability');
    title("CDF");







    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%% UNIFORM QUANTIZATION - 12 bit %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Target bits values

    B_target = 12;                                           % total number of bits
    B_frac_target = 1;                                       % bits for fractionary part
    Nfp_target = 2^(-B_frac_target);                         % range between representable numbers
    Mfp_target = Nfp_target * (2^(B_target - 1) - 1);        % max number representable: 1 removed for sign, 1 removed for zero
    mfp_target = -(Nfp_target + Mfp_target);                 % min number representable



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Uniform quantization

    [compressed_aggregated_data, ~, OUTERR, ~, ~, ~] = ...
            FpQuantize(aggregated_data, -B_target, B_frac_target, 'round');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Showing signal PDF and error PDF

    figure()
    sgtitle('Linear quantization - 12 bits');
    subplot(1, 2, 1);
    pdf_estim(aggregated_data, 401, 1);
    title("Signal PDF");
    xlabel("Signal amplitude (µV)");
    ylabel("Probability");
    subplot(1, 2, 2);
    pdf_estim(OUTERR, 401, 1);
    title("Error PDF");
    xlabel("Error amplitude (µV)");
    ylabel("Probability");
    


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Showing comparison between SQNRestim and DR_db

    R = 2 * abs(mfp_target);                                            % length of representable interval
    DR_db = 20 * log10(R / Nfp_target);                                 % dynamic range
    sign_power = mean(compressed_aggregated_data .^ 2) + (mean(compressed_aggregated_data) .^ 2);
    error_power = mean(OUTERR .^ 2) + (mean(OUTERR) .^ 2);
    SQNRestim = 10*log10(sign_power / error_power);
    annotation('textbox', [.9 .4 .1 .2], ...
        'String', ['Dynamic range: ', string(DR_db), newline, 'SQNR estimation: ', string(SQNRestim)], ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');













    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%% OPTIMAL QUANTIZATION - 10 bit %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Target and LUT avaiable bits

    % Target bits
    B_target = 10;
    B_sign = 1;
    B_frac_target = 2;
    B_int_target = B_target - B_frac_target - B_sign;
    Nfp_target = 2^(-B_frac_target);
    Mfp_target = Nfp_target * (2^(B_target - 1) - 1);
    mfp_target = -(Nfp_target + Mfp_target);

    % LUT bits values
    B_starting = 14;
    B_frac_starting = 3;
    Nfp_starting = 2^(-B_frac_starting);




    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Splitting unlikely data and likely data, since probability of |mod| < 128 is 9.71%

    max_value = 2^(B_starting - 1 - B_frac_starting) - 1;   % 1023
    min_value = - 2^(B_starting - 1 - B_frac_starting);     % -1024
    positive_separator_value = 127;
    negative_separator_value = -128;
    [aggregated_data, ~, ~, ~, ~, ~] = FpQuantize(aggregated_data, -B_starting, B_frac_starting, 'round');
    likely_data = aggregated_data(aggregated_data <= positive_separator_value & aggregated_data >= negative_separator_value);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Managing unlikely data with linear quantization

    error_range = 100;
    necessary_ranges_num = round((max_value - positive_separator_value) / error_range);
    Mfp_targe_unlikely = Nfp_target * necessary_ranges_num;
    LUT_min_positive_range = 2^(B_int_target) - 1 - Mfp_targe_unlikely;
    LUT_max_positive_range = 2^(B_int_target) - 1;
    LUT_min_negative_range = - 2^(B_int_target);
    LUT_max_negative_range = - 2^(B_int_target) + Mfp_targe_unlikely;
    LUT_unlikely_dimension = (max_value - positive_separator_value) / Nfp_starting;
    LUT_unlikely_positive_part = linspace(LUT_min_positive_range, LUT_max_positive_range, LUT_unlikely_dimension);
    LUT_unlikely_negative_part = linspace(LUT_min_negative_range, LUT_max_negative_range, LUT_unlikely_dimension);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Managing likely data with optimal quantization

    likely_data = [likely_data negative_separator_value positive_separator_value];
    [~,  ~, ~, ~, ~, cdf_x] = pdf_estim(likely_data', 2^B_starting-2*LUT_unlikely_dimension, 0);
    gx_likely = cdf_x * (LUT_min_positive_range - LUT_max_negative_range) + LUT_max_negative_range;



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Mixing and quantizing likely and unlikely data

    gx = [LUT_unlikely_negative_part gx_likely LUT_unlikely_positive_part];
    [gx_quantized, ~, ~, ~, ~, ~] = FpQuantize(gx, -B_target, B_frac_target, 'ceil');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compression and decompression functions

    % Creating compressing/decompressing function
    samples = linspace(min_value, max_value, 2^B_starting);
    [samples_quantized, ~, ~, ~, ~, ~] = FpQuantize(samples, -B_starting, B_frac_starting, 'round');
    [gx_quant_decomp, ~, idx] = unique(gx_quantized, 'stable');
    Y_addr_reverse = accumarray(idx, samples_quantized, [], @mean);
    decomp_dictionary = dictionary(gx_quant_decomp, Y_addr_reverse');
    compress_dictionary = dictionary(samples_quantized, gx_quantized);

    % Plotting compressing and decompressing function
    figure();
    sgtitle('Optimal quantization - 10 bits');
    subplot(2, 2, 1);
    plot(samples, gx_quantized);
    grid
    title("Compression function");
    subplot(2, 2, 3);
    plot(keys(decomp_dictionary), values(decomp_dictionary));
    grid
    title("Decompression function");



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Testing compression and decompression for non-linear quantization

    testing_data = aggregated_data(aggregated_data > -123 & aggregated_data < 123);
    compressed_data = compress_dictionary(testing_data);
    decompressed_data = decomp_dictionary(compressed_data);
    
    % Showing signal PDF and error PDF
    subplot(2, 2, 2);
    pdf_estim(compressed_data, 51, 1);
    title("Compressed signal PDF - non-linear part");
    xlabel("Compressed signal amplitude (µV)");
    ylabel("Probability");
    subplot(2, 2, 4);
    bef_afte_diff = testing_data - decompressed_data;
    pdf_estim(bef_afte_diff, 51, 1);
    title("Error PDF - non-linear part");
    xlabel("Error amplitude");
    ylabel("Probability");
    
    % Showing comparison between SQNRestim and DR_db
    R = 2 * abs(mfp_target);
    DR_db = 20 * log10(R / Nfp_target);
    sign_power = mean(decompressed_data .^ 2) + (mean(decompressed_data) .^ 2);
    error_power = mean(abs(bef_afte_diff) .^ 2) + (mean(abs(bef_afte_diff)) .^ 2);
    SQNRestim_optimal = 10*log10(sign_power / error_power);
    annotation('textbox', [.9 .4 .1 .2], ...
        'String', ['Dynamic range (non-linear): ', string(DR_db), newline, 'SQNR estimation (non-linear): ', string(SQNRestim_optimal)], ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');





    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Testing compression and decompression for linear part

    testing_data = aggregated_data(aggregated_data <= -300 | aggregated_data >= 300);
    testing_data = testing_data(testing_data > -900 & testing_data < 900);
    compressed_data = compress_dictionary(testing_data);
    decompressed_data = decomp_dictionary(compressed_data);

    % Showing comparison between SQNRestim and DR_db
    sign_power = mean(decompressed_data .^ 2) + (mean(decompressed_data) .^ 2);
    bef_afte_diff = testing_data - decompressed_data;
    error_power = mean(abs(bef_afte_diff) .^ 2) + (mean(abs(bef_afte_diff)) .^ 2);
    SQNRestim_optimal = 10*log10(sign_power / error_power);
    fprintf('SQNRestim for linear in optimal: %.2f\n', SQNRestim_optimal);
    

end

