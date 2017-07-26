clear all
close all

% Directory in which the uniform data format files are stored
dataFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\classification results\';

%% Collect all files in the given directory
fileList = dir(fullfile(dataFolder, '*.mat'));
numberOfFiles=length(fileList);
nameOfFile = cell(numberOfFiles, 1);

for i = 1:numberOfFiles
    fprintf('\n')
    nameOfFile{i}=fileList(i).name;
    
    %% Load the files 1 by 1.
    disp(['Loading file ' nameOfFile{i}])
    load([dataFolder nameOfFile{i}])

    mean_stdev_skewness = classification.classification;
    
    if i == 1
        h = figure;
        
        meanActivity = cell2mat(mean_stdev_skewness(:,1));
        stdevActivity = cell2mat(mean_stdev_skewness(:,2));
        skewnessFactor = cell2mat(mean_stdev_skewness(:,3));
        
        %% Create a subplot for every variable (mean,stdev and skewness)
        sp1 = subplot(1,3,1);
        %% Mean:
        bins = -0.05:.01:0.1;
        [mean_neuron_distributions, ~] = hist(meanActivity, bins, 0);
        %hist(meanActivity, bins, 0);
        plot(bins, mean_neuron_distributions)
        grid on
        ylabel('Number of networks')
        xlabel('Mean activity difference')
        title('Mean')
        
        sp2 = subplot(1,3,2);
        %% Standard deviation:
        bins2 = -0:.02:0.3;
        [stdev_neuron_distributions, ~] = hist(stdevActivity, bins2, 0);
        %hist(stdevActivity, bins2, 0);
        plot(bins2, stdev_neuron_distributions)
        grid on
        ylabel('Number of networks')
        xlabel('Stdev activity difference')
        title('Standard deviation')
        
        sp3 = subplot(1,3,3);
        %% Skewness:
        bins3 = -2:1:20;
        [skewness_neuron_distributions, ~] = hist(skewnessFactor, bins3, 0);
        %hist(skewnessFactor, bins3, 0);
        plot(bins3, skewness_neuron_distributions)
        grid on
        ylabel('Number of networks')
        xlabel('Skewness activity difference')
        title('Skewness')
        
    else
        simulated_mean_value = cell2mat(mean_stdev_skewness(:,1));
        simulated_std_value = cell2mat(mean_stdev_skewness(:,2));
        simulated_skewness_value = cell2mat(mean_stdev_skewness(:,3));
  
        subplot(sp1)
        hold all
        plot([simulated_mean_value, simulated_mean_value],[0,max(mean_neuron_distributions)], 'r')
        
        subplot(sp2)
        hold all
        plot([simulated_std_value, simulated_std_value],[0,max(stdev_neuron_distributions)], 'r')
        
        subplot(sp3)
        hold all
        plot([simulated_skewness_value, simulated_skewness_value],[0,max(skewness_neuron_distributions)], 'r')
    end
    
    %% Export plot as pdf
    
    fileName = 'model_validation';
    set(gcf,'PaperOrientation','landscape', 'PaperPositionMode', 'manual', 'PaperUnits', 'centimeters', 'Paperposition', [-1 3 30 15]);
    fullPath = [dataFolder fileName];
    print(gcf, fullPath, '-dpdf'); 
    
end

%% Determine the P-value of the mean, standard deviation and skewness distributions of the activity difference, and determine if H0 schould be rejected or not
[h_mean, p_mean] = kstest2(meanActivity, simulated_mean_value);
[h_stdev, p_stdev] = kstest2(stdevActivity, simulated_std_value);
[h_skewness, p_skewness] = kstest2(skewnessFactor, simulated_skewness_value);

[h_mean_ttest, p_mean_ttest] = ttest2(meanActivity, simulated_mean_value);
[h_stdev_ttest, p_stdev_ttest] = ttest2(stdevActivity, simulated_std_value);
[h_skewness_ttest, p_skewness_ttest] = ttest2(skewnessFactor, simulated_skewness_value);