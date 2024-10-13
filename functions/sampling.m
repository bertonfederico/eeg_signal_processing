function [downsampled_dataset] = sampling(dataset, fs_original, fs_new)

    downsample_factor = round(fs_original / fs_new);
    [~, col_size] = size(dataset);
    indices = 1:downsample_factor:col_size;
    downsampled_dataset = dataset(:, indices);

end

