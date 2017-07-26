%% This script is made to classify neurons upon their neuronal activity.
% Get the uniform data format files from the data that needs to be analyzed
% Load these uniform data format files one by one and classify the neurons.
%
% INPUT:
% Uniform data format file(s); (structure array)
%
% OUTPUT:
% A structure array with all the scores per neuron for every volume.
% 
% Example use:
% classify_neurons
%
% Credentials:
% This script was written by Thijs Groenveld, a bioinformatics intern at
% the Neurophysiology department of the Donders Institute.
% All rights reserved. 
%
% You are free to use this script for research purposes as long as you
% credit the maker of the script(s).
% 15-06-2017

close all

% Results directory Peron data, Donders Institute pc
%dataFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\Peron_data\';
%saveFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\classification results\';

% Results directory Simulated data, Donders Institute pc
dataFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\Simulated_data\';
saveFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\classification results\';

%{
% Results directory Simulated data with membrane potentials, Donders Institute pc
dataFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\Simulated_data\';
saveFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\classification results\';
%}

fileList = dir(fullfile(dataFolder, '*.mat'));
numberOfFiles=length(fileList);
nameOfFile = cell(numberOfFiles, 1);

mean_stdev_skewness = cell(numberOfFiles, 3);

classificationName = input('Enter the name of the dataset type: \n', 's');

for i = 1:numberOfFiles
    fprintf('\n')
    nameOfFile{i}=fileList(i).name;

    %% Load the files 1 by 1.
    disp(['Loading file ' nameOfFile{i}])
    load([dataFolder nameOfFile{i}])
    
    dataWindow = animal.dataWindow;
    neuronMat = animal.neuronMat;
    [nNeurons, nTime_l, ~] = size(neuronMat);
    binsize_neurons = animal.binsize_neurons;
    neuronTime = (0:nTime_l-1)*binsize_neurons+dataWindow(1);
    [~,zeron_l] = min(abs(neuronTime));
    
    x1 = dataWindow(1);
    x2 = dataWindow(2);
    windowSize = (x1-x2)*-1;
    interval = windowSize/nTime_l;
    neuronScores = cell(nNeurons,3);
    time_vector_trial = dataWindow(1):binsize_neurons:dataWindow(2);

    for ns = 1:nNeurons
        x = neuronMat(ns,:,:);
        z = nanmean(x,3);
        
        %% Retrieve the measurements from before and after the first touch in the chosen windows.
        % Retrieve Neuron Scores from neurons before the first touch
        dataWindow1 = [-1350 -950];
        [~,nWindow1_start] = min(abs(time_vector_trial-dataWindow1(1)));
        [~,nWindow1_end] = min(abs(time_vector_trial-dataWindow1(2)));
        
        nWindow1_start = nWindow1_start(1);
        nWindow1_end = nWindow1_end(1);
        valuesWindow1 = z(nWindow1_start:nWindow1_end);
        neuronScores{ns,1} = mean(valuesWindow1);
        
        % Retrieve Neuron Scores from neurons after the first touch
        dataWindow2= [50 450];
        [~,nWindow2_start] = min(abs(time_vector_trial-dataWindow2(1)));
        [~,nWindow2_end] = min(abs(time_vector_trial-dataWindow2(2)));

        nWindow2_start = nWindow2_start(1);
        nWindow2_end = nWindow2_end(1);
        valuesWindow2 = z(nWindow2_start:nWindow2_end);
        neuronScores{ns,2} = mean(valuesWindow2);
        
        %% Calculate neuron scores by dividing the mean window after by the mean window before the first touch
        neuronScores{ns,3} = neuronScores{ns,2} - neuronScores{ns,1};
        
        %{
        %% Plot the activity of one neuron
        neuronMin = min(z);
        neuronMax = max(z);
        
        figure;
        plot(neuronTime, z)
        xlim(dataWindow)
        hold all
        plot([zeron_l, zeron_l], [neuronMin, neuronMax], '-k', 'LineWidth',1)
        xlabel('Time (ms)')
        ylabel('\Delta F / F')
        title('Average activity of one neuron over trials')
        ylim([min([0, 1.1*neuronMin]),1.1*neuronMax])
        grid on
        box on
        name = classificationName;
        fileName = strcat(name,'_hist');
        fullPath = [saveFolder fileName];
        print(gcf, fullPath, '-dpdf'); 
        %}
    end
    
    % Schrijf de classificatie matrix naar je resultaten struct
    animal.classification = neuronScores;
    activityDifference = cell2mat(neuronScores(:,3));
  
    %{
    %% Make a histogram of the classification scores
    %bins = -80:3:80;
    activityBefore = cell2mat(neuronScores(:,1));
    activityAfter = cell2mat(neuronScores(:,2));
    activityDifference = cell2mat(neuronScores(:,3));
   
    % Binsize experimental data
    %bins = -.2:.01:.7;
    
    % Binsize simulated data
    %bins = -2:.05:2;
    
    %figure; hist(activityBefore, bins, 0)
    %figure; hist(activityAfter,bins, 0)
    %figure; hist(activityDifference,bins, 0)
    
    figure;
    [before, ~] = hist(activityBefore, bins, 0);
    [after, ~] = hist(activityAfter, bins, 0);
    [difference, ~] = hist(activityDifference, bins, 0);
    plot(bins, before)
    hold all
    plot(bins, after)
    plot(bins, difference)
    legend('Before','After','Difference')
    grid on
    ylabel('Number of neurons')
    xlabel('Mean \Delta F / F')
    title('Distribution of the neuronal network activity')
    
    %% Export plot as pdf
    [~,name,~] = fileparts(nameOfFile{i});
    fileName = strcat(name,'_hist');
    fullPath = [saveFolder fileName];
    print(gcf, fullPath, '-dpdf'); 
    %}
    
    % Save the mean, standard deviation and skewness per volume/network into
    mean_stdev_skewness{i,1} = nanmean(activityDifference);
    mean_stdev_skewness{i,2} = nanstd(activityDifference);
    mean_stdev_skewness{i,3} = skewness(activityDifference); 
    
    classification.classification = mean_stdev_skewness;
    
    % Save the animal struct to a .mat file with the animal name in the specified save_folder.
    fileName = classificationName;
    structName = [fileName,'.mat'];
    save([saveFolder structName], 'classification');

end
