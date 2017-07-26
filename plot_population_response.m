%% This script is made to plot the neuronal activity for every volume.
% Get the datastructs of all the analyzed mice.
% Load these files 1 by 1 and plot the neuronal response.
%
% INPUT:
% None
%
% OUTPUT:
% The plotwindow contains of 6 different plots of the same data.
% subplot 1: Image of the mean neuronal activity per neuron
% subplot 2: Plot of the mean neuronal activity for all neurons
% subplot 3: Plot of the median neuronal activity for all neurons
% subplot 4: Image of the Differences and Approximate Derivatives from the neuronal activity per neuron
% subplot 5: Plot of the Differences and Approximate Derivatives from the mean neuronal activity for all neurons
% subplot 6: Plot of the Differences and Approximate Derivatives from the median neuronal activity for all neurons
%
% Example use:
% plot_population_response
%
% Credentials:
% This script was written by Thijs Groenveld, a bioinformatics intern at
% the Neurophysiology department of the Donders Institute inside the
% Huygensbuilding. All rights reserved. 
%
% You are free to use this script for research purposes as long as you
% credit the maker of the script(s).
% 17-05-2017

close all

% Experimental data
dataFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\Peron_data\';
saveFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\animal_volume_plots\';

% Simulated data
%dataFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\Simulated_data\';
%saveFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\';

fileList = dir(fullfile(dataFolder, '*.mat'));
numberOfFiles=length(fileList);
nameOfFile = cell(numberOfFiles, 1);

for i = 1:numberOfFiles
    fprintf('\n')
    nameOfFile{i}=fileList(i).name;
    disp(['Loading file ' nameOfFile{i}])
    load([dataFolder nameOfFile{i}])
        
    dataWindow = animal.dataWindow;
    neuronMat = animal.neuronMat;
    [Nneuron, Ntime_l, ~] = size(neuronMat);
    binsize_neurons = animal.binsize_neurons;
    neuronTime = (0:Ntime_l-1)*binsize_neurons+dataWindow(1);
    [~,zeron_l] = min(abs(neuronTime));
    
    % Define the vertical 0 line y limits for every calculation type (mean/median,diff mean, diff median)
    meanMin = min(nanmean(nanmean(neuronMat,3)));
    meanMax = max(nanmean(nanmean(neuronMat,3)));
    
    medianMin = min(nanmedian(nanmedian(neuronMat,3)));
    medianMax = max(nanmedian(nanmedian(neuronMat,3)));
    
    %{
        %% Divergence
        gtemp = zeros(size(luminesMat,1),size(luminesMat,2)-1);
        
        for lp = 1:size(luminesMat,3)
            atemp = luminesMat(:,:,lp);
            gtemp(lp,1:size(atemp,2)-1) = nanmean(diff(atemp')');
            etemp(lp,1:size(atemp,2)-1) = nanmedian(diff(atemp')');
        end
        
        figure; plot(smooth(mean(gtemp),2),'r')
        figure; imagesc(gtemp);
        
        %meanDiffMin = min(nanmean(diff(nNeuronNtime)));
        %meanDiffMax = max(nanmean(diff(nNeuronNtime)));
        
        %medianDiffMin = min(nanmedian(diff(nNeuronNtime)));
        %medianDiffMax = max(nanmedian(diff(nNeuronNtime)));
    %}
    %%
    
    figure
    
    subplot(1,3,1)
    imagesc(neuronTime, 1:Nneuron, mean(neuronMat,3))
    colorbar
    c = colorbar;
    c.Label.String = 'Mean \Delta F / F';
    c.Label.FontSize = 10;
    hold all
    plot([zeron_l, zeron_l], [0, Nneuron+1], '-k', 'LineWidth',1)
    ylabel('Neurons')
    xlabel('Time (ms)')
    title('Average activity over trials per neuron')
    
    subplot(1,3,2)
    plot(neuronTime, nanmean(nanmean(neuronMat,3)))
    xlim(dataWindow)
    hold all
    plot([zeron_l, zeron_l], [meanMin, meanMax], '-k', 'LineWidth',1)
    xlabel('Time (ms)')
    ylabel('Average \Delta F / F')
    title('Average activity of all neurons over trials')
    ylim([min([0, meanMin]),1.1*meanMax])
    grid on
    box on
    curtick = get(gca, 'YTick');
    set(gca, 'YTickLabel', cellstr(num2str(curtick(:))));
    
    subplot(1,3,3)
    plot(neuronTime, nanmedian(nanmedian(neuronMat,3)))
    xlim(dataWindow)
    hold all
    plot([zeron_l, zeron_l], [medianMin, medianMax], '-k', 'LineWidth',1)
    xlabel('Time (ms)')
    ylabel('Median \Delta F / F')
    title('Median activity of all neurons over trials')
    ylim([min([0, medianMin]),1.1*medianMax])
    grid on
    box on
   %keyboard
    
    %% The following subplots are written to show the diff for every neuron over all timepoints,
    %{
        % the nanmean and nanmedian over all time points. Do we want this -> new fix or change all to show over trials
        % just like Tansu's code is doing above with the 'gtemp' variable in the data
        subplot(2,3,4)
        imagesc(lumtime, 1:Nneuron, gtemp) % dit print per neuron ipv over trials
        colorbar
        hold all
        plot([zeron_l, zeron_l], [0, Nneuron+1], '-k', 'LineWidth',1)
        ylabel('Neurons')
        xlabel('Time (ms)')
        title('Average derivative activity over trials')
        
        subplot(2,3,5)
        plot(lumtime, nanmean(diff(gtemp)))
        xlim(window.window)
        hold all
        plot([zeron_l, zeron_l], [meanDiffMin, meanDiffMax], '-k', 'LineWidth',1)
        xlabel('Time (ms)')
        ylabel('Mean diff \Delta F / F')
        title('Average derivative activity over trials')
        grid on
        box on
               
        subplot(2,3,6)
        plot(lumtime, etemp))
        xlim(window.window)
        hold all
        plot([zeron_l, zeron_l], [medianDiffMin, medianDiffMax], '-k', 'LineWidth',1)
        xlabel('Time (ms)')
        ylabel('Median diff \Delta F / F')
        title('Median derivative activity over trials')
        grid on
        box on
    %}
    
    %% Export subplot as pdf
    
    [~,name,~] = fileparts(nameOfFile{i});
    filename = strcat(name, '_population');
    %figure_name =  [filename, '.pdf'];
    set(gcf,'PaperOrientation','landscape', 'PaperPositionMode', 'manual', 'PaperUnits', 'centimeters', 'Paperposition', [-1 3 30 15]);
    fullPath = [saveFolder filename];
    print(gcf, fullPath, '-dpdf');
    
    close all

end


