function [] = quantization(aggregated_data)




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
    fprintf('\n\nUniform quantization\n');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Target bits values

    B_target = 12;                                           % total number of bits avaiable
    B_frac_target = 1;                                       % bits for fractionary part
    Nfp_target = 2^(-B_frac_target);                         % range between representable numbers
    Mfp_target = Nfp_target * (2^(B_target - 1) - 1);        % max number representable: 1 removed for sign, 1 removed for zero
    mfp_target = -(Nfp_target + Mfp_target);                 % min number representable



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Uniform quantization
    
    [compressed_aggregated_data, ~, OUTERR, ~, ~, ~] = FpQuantize(aggregated_data, -B_target, B_frac_target, 'round');



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
    fprintf('Dynamic range in dB: %.2f\n', DR_db);
    sign_power = mean(compressed_aggregated_data .^ 2) + (mean(compressed_aggregated_data) .^ 2);
    error_power = mean(OUTERR .^ 2) + (mean(OUTERR) .^ 2);
    SQNRestim = 10*log10(sign_power / error_power);
    fprintf('SQNR estimation for linear: %.2f\n', SQNRestim);










    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%% OPTIMAL QUANTIZATION - 12 bit %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Since probability for values over 100 µV is very low, quantization is splittend in linear for higher data, optimal for lower data
    fprintf('\n\nOptimal quantization\n');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Target and LUT avaiable bits

    % Target bits
    B_target = 12;                                                  % total number of bits avaiables
    B_sign = 1;                                                     % bits for sign
    B_int_target = B_target - B_sign;                               % bits for integer

    % LUT bits
    B_starting = 16;                                                % total number of bits
    B_frac_starting = 5;                                            % fractional bits
    Nfp_starting = 2^(-B_frac_starting);                            % range between representable numbers

    % Initial quantization of data to limit lookup table length
    [aggregated_data_lut, ~, ~, ~, ~, ~] = FpQuantize(aggregated_data, -B_starting, B_frac_starting, 'round');



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Splitting unlikely data and likely data, since probability of |mod| > 123 is low
    max_value = 2^(B_starting - 1 - B_frac_starting) - 1;     %  1023
    min_value = - 2^(B_starting - 1 - B_frac_starting);       % -1024
    positive_separator_value = 223;
    negative_separator_value = -224;
    likely_data = aggregated_data_lut(aggregated_data_lut <= positive_separator_value & aggregated_data_lut >= negative_separator_value);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Managing unlikely data with linear quantization
    error_range = 2^4;                                                                             % compression range length
    necessary_ranges_semi_num = floor((max_value - positive_separator_value) / error_range);       % necessary n. of ranges for unlikely positive data
    LUT_min_positive_limit = 2^(B_int_target) - 1 - necessary_ranges_semi_num;                     % min limit for positive target
    LUT_max_positive_limit = 2^(B_int_target) - 1;                                                 % max limit for positive target
    LUT_min_negative_limit = - 2^(B_int_target);                                                   % min limit for negative target
    LUT_max_negative_limit = - 2^(B_int_target) + necessary_ranges_semi_num;                       % max limit for negative target
    LUT_unlikely_semi_dim = (max_value - positive_separator_value) / Nfp_starting;                 % necessary n. of values for unlikely positive data
    LUT_unlikely_positive_linspace = linspace(LUT_min_positive_limit, LUT_max_positive_limit, LUT_unlikely_semi_dim);      % linespace for positive data
    LUT_unlikely_negative_linspace = linspace(LUT_min_negative_limit, LUT_max_negative_limit, LUT_unlikely_semi_dim);      % linespace for negative data



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Managing likely data with optimal quantization
    [~,  ~, ~, ~, ~, cdf_x] = pdf_estim(likely_data, 2^B_starting-2*LUT_unlikely_semi_dim, 0);             % CDF for likely data
    gx_likely = cdf_x * (LUT_min_positive_limit - LUT_max_negative_limit - 1) + LUT_max_negative_limit;    % CDF scaling and shifting



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Mixing and quantizing likely and unlikely data
    gx = [LUT_unlikely_negative_linspace gx_likely LUT_unlikely_positive_linspace];
    gx_quantized = round(gx);                                                              % rounding values to integer (quantization)



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compression and decompression dictionaries

    % Compression dictionary
    samples = linspace(min_value, max_value, 2^B_starting);
    [samples_quantized, ~, ~, ~, ~, ~] = FpQuantize(samples, -B_starting, B_frac_starting, 'round');
    compress_dictionary = dictionary(samples_quantized, gx_quantized);

    % Decompression dictionary
    [gx_quant_decomp, ~, idx] = unique(gx_quantized, 'stable');
    Y_addr_reverse = accumarray(idx, samples_quantized, [], @mean);
    decomp_dictionary = dictionary(gx_quant_decomp, Y_addr_reverse');

    % Plotting compressing and decompressing function
    figure();
    sgtitle('Optimal quantization - 12 bits');
    subplot(2, 2, 1);
    plot(samples, gx_quantized);
    xlabel("Original signals values");
    ylabel("Compressed signals values");
    grid
    title("Compression function");
    subplot(2, 2, 3);
    plot(keys(decomp_dictionary), values(decomp_dictionary));
    ylabel("Original signals values");
    xlabel("Compressed signals values");
    grid
    title("Decompression function");



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Testing compression and decompression for non-linear quantization

    testing_data = aggregated_data(aggregated_data > -123 & aggregated_data < 123);
    [testing_data_lut, ~, ~, ~, ~, ~] = FpQuantize(testing_data, -B_starting, B_frac_starting, 'round');
    compressed_data = compress_dictionary(testing_data_lut);
    decompressed_data = decomp_dictionary(compressed_data);
    
    % Showing signal PDF and error PDF
    subplot(2, 2, 2);
    pdf_estim(compressed_data, 51, 1);
    title("Compressed signal PDF - non-linear quantization");
    xlabel("Compressed signal amplitude");
    ylabel("Probability");
    subplot(2, 2, 4);
    bef_afte_diff = testing_data - decompressed_data;
    pdf_estim(bef_afte_diff, 21, 1);
    title("Error PDF - non-linear quantization");
    xlabel("Error amplitude");
    ylabel("Probability");
    
    % Showing SQNRestim
    sign_power = mean(decompressed_data .^ 2) + (mean(decompressed_data) .^ 2);
    error_power = mean(abs(bef_afte_diff) .^ 2) + (mean(abs(bef_afte_diff)) .^ 2);
    SQNRestim_optimal = 10*log10(sign_power / error_power);
    fprintf('SQNR estimation for non-linear: %.2f\n', SQNRestim_optimal);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Testing compression and decompression for linear quantization

    testing_data = aggregated_data(aggregated_data <= -123 | aggregated_data > 123);
    [testing_data_lut, ~, ~, ~, ~, ~] = FpQuantize(testing_data, -B_starting, B_frac_starting, 'round');
    compressed_data = compress_dictionary(testing_data_lut);
    decompressed_data = decomp_dictionary(compressed_data);

    % Showing SQNRestim
    sign_power = mean(decompressed_data .^ 2) + (mean(decompressed_data) .^ 2);
    bef_afte_diff = testing_data - decompressed_data;
    error_power = mean(abs(bef_afte_diff) .^ 2) + (mean(abs(bef_afte_diff)) .^ 2);
    SQNRestim_optimal = 10*log10(sign_power / error_power);
    fprintf('SQNR estimation for linear: %.2f\n', SQNRestim_optimal);
    

end

