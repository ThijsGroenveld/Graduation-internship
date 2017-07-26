%% This Script is written to load all simulated data files and extract the information needed to build the uniform data format(structure array).

% Donders directory
directory = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\simulation data\sims_Thijs_an171923_vol4_11-Jul-2017\'; 
saveFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda data files & scripts\code for analysis\scripts\Thijs\Project\Results\Simulated_data\';

fileList = dir(fullfile(directory, '*calciumdata.mat'));
numberOfFiles = length(fileList);
currentFile = cell(1,1);

str = fileList.name;
expression = '[a-z]{2}\d{6}'; % filter for the animal names
animalName = regexp(str,expression,'match');
nVolume = str2double(regexp(str, '(?<=_vol)[0-9]*', 'match'));

animal.animalName = animalName{1};
animal.trial = cell(1,numberOfFiles);

%% Collect the whiskermat
spikeTrainFile = ['*' animalName{1} '*Thalamic_Spike_Trains.mat'];
fullFileName = dir(fullfile(directory, spikeTrainFile));
disp(['Loading file ' fullFileName.name])
load([directory fullFileName.name])

%% Concatenate the whiskerStruct traces to one whiskermatrix for every simulation trial
[nTraces,nTrial] = size(WhiskerTrace.Recording);
[~,nDataPoints] = size(WhiskerTrace.Recording{1,1});
whiskerMat_temp = zeros(nTraces,nDataPoints);

for i = 1:numberOfFiles
    whiskerAngle = WhiskerTrace.Recording{1,i};
    whiskerCurvature = WhiskerTrace.Recording{2,i};
    whiskerMat_temp = cat(1, whiskerAngle, whiskerCurvature);
    animal.trial{i}.whiskerMat_temp = whiskerMat_temp;
end

%% Create a 3D whisker matrix for all the simulation trials
whiskerMat = zeros(nTraces, nDataPoints, nTrial);

for j = 1:nTrial
    whiskerMat(:,:,j) = animal.trial{j}.whiskerMat_temp;
end

%% Collect the main barrel
cellInfoFile = ['cellinfo*' animalName{1} '*.mat'];
fullFileName2 = dir(fullfile(directory, cellInfoFile));
disp(['Loading file ' fullFileName2.name])
load([directory fullFileName2.name])

animal.dataWindow = SvobodaStruct.window.window;

for k = 1:Nbarrel
    barrelNumber = barrelstruct{k,1}.mainbarrel;
    if barrelNumber == 1
        mainBarrelNumber = k;
    end
end

%% Collect the indices from the main barrel neurons
dataFile = ['sims_Thijs*' animalName{1} '*simulation_1.mat'];
fullFileName3 = dir(fullfile(directory, dataFile));
disp(['Loading file ' fullFileName3.name])
load([directory fullFileName3.name])

%% Collect the information over all trials
for ns = 1:numberOfFiles
    currentFile{ns} = fileList(ns).name;
    disp(['Loading file ' currentFile{ns}])
    load([directory currentFile{1,1}])
    
    % Select the main barrel neurons and build the calcium matrices
    neuronMat_temp = lummat(find(cellinfo_all(:,5)== mainBarrelNumber),:);
    
    [nNeurons,~] = size(neuronMat_temp);
    [~,nTime] = size(neuronMat_temp);
    binsize_neurons = 1 / Para.frame_rate_c;
    
    str = currentFile{ns};
    trialNumber = str2double(regexp(str, '(?<=_simulation_)[0-9]*', 'match'));
    animal.trial{trialNumber}.neuronMat_temp = neuronMat_temp;
end

%% Create a 3D neuron matrix for all the simulation trials
neuronMat = zeros(nNeurons, nTime, nTrial);

for m = 1:nTrial
    neuronMat(:,:,m) = animal.trial{m}.neuronMat_temp;
end

animal.whiskerMat = whiskerMat;
animal.neuronMat = neuronMat;
animal.binsize_whisker = WhiskerTrace.binsize;
animal.binsize_neurons = binsize_neurons;
animal.nNeurons = nNeurons;
animal.nTime = nTime;
animal.nTrial = nTrial;
animal.volume = nVolume;
animal.mainBarrelNumber = mainBarrelNumber;

%%
% Save the animal struct to a .mat file with the animal name in the specified saveFolder.
fileName = animal.animalName;
structName = ['sim_', fileName,'_volume_',num2str(nVolume),'.mat'];
save([saveFolder structName], 'animal','-v7.3');

