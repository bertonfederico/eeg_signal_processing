function [xi, pdf_x, mean_x, square_x, variance_x] = pdf_estim(x, Nint, Graph)


    % pdf_estim 
    % estimate pdf, mean, mean square root, variance of a signal, starting from
    % samples
    % 
    % input parameters:
    % x      = vector of occourrences; must be a column vector
    % Nint   = Number of intervals for histogram evaluation
    % Graph  = Graph flag (1 - Display Graph; 0 Do NOT Display)
    % 
    % Output parameters
    % xi         = set of xi coordinates in which pdf is evaluated (bar centers)
    % pdf_x      = values of estimated pdf in xi
    % mean_x     = estimated mean value of x
    % square_x   = estimated mean square value of x
    % variance_x = estimated variance value of x (var_x = square_x - mean_x^2)

    
    L = length(x);

    DELTA = (max(x) - min(x)) / Nint;
    [Ci, xi] = hist(x, Nint);
    pdf_x = (Ci / L) / DELTA;

    if Graph == 1
        bar(xi, pdf_x)
        hold on
        plot(xi, pdf_x)
        hold off
        xlabel('Amplitude (µV)');
        ylabel('Probability');
    end 

    mean_x     = mean(x);
    square_x   = mean(x .* x);
    variance_x = square_x - (mean_x .* mean_x);


end

