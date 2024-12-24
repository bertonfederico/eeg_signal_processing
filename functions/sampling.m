function [downsampled_dataset] = sampling(dataset, fs_original, fs_new)

    downsample_factor = round(fs_original / fs_new);
    [~, col_size] = size(dataset);
    indices = 1:downsample_factor:col_size;
    downsampled_dataset = dataset(:, indices);

    figure()
    sgtitle('Original and downsampled dataset (1.0 - 1.05 sec)');
    subplot(1, 2, 1);
    plot(dataset(1, :), '-o');
    title("Original dataset")
    xlabel("Samples");
    ylabel("Amplitude (µV)");
    xlim([5000 5250])
    subplot(1, 2, 2);
    plot(downsampled_dataset(1, :), '-o');
    title("Downsampled dataset")
    xlabel("Samples");
    ylabel("Amplitude (µV)");
    xlim([500 525])


end

