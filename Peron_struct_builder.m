%% This script is used to build a uniform data format (structure array) of the Peron data.
%
% Different functions will be called that together will build a structure array
% that contains all the necessary information needed for the uniform data format.
%
% Functions:
% get_input_files
% get_max_volumes
% load_data_across_sessions
%
% Credentials:
% This script was written by Thijs Groenveld, a bioinformatics intern at
% the Neurophysiology department of the Donders Institute.
% All rights reserved. 
%
% You are free to use this script for research purposes as long as you
% credit the maker of the script(s).
% 17-05-2017

%% Directory's

% What is the directory where the data files are stored?
% Donders Institute link:
% directory = 'C:\Users\admin-thijs\Google Drive\Svoboda Data files & scripts\SSC2\'; 

% Home directory link
directory = 'C:\Users\thijs\Google Drive\Svoboda Data files & scripts\SSC2\'; 

% What is the directory of the folder in which you want the results to be saved?
% Donders Institute link:
% saveFolder = 'C:\Users\admin-thijs\Google Drive\Svoboda Data files & scripts\code for analysis\scripts\Thijs\Project\Results\Peron_data\';

% Home directory link
saveFolder = 'C:\Users\thijs\Google Drive\Svoboda Data files & scripts\code for analysis\scripts\Thijs\Project\Results\';


%% Function calls and building the structure
% Use the get_input_files function to extract the needed files from the given directory
[loadFile, chosenAnimal, sessionsDate, animalNames] = get_input_files(directory);

% Determine the maximum number of volumes from any session and keep the overall maximum number of volumes
[maxVolumes] = get_max_volumes(loadFile, directory);

% Build the structure array by assigning a value to the first field
animal.animalName = chosenAnimal;

% Specify the preferred data window from which you want to record the data
dataWindow = [-1500 2500];
animal.dataWindow = dataWindow;

for i = 2:maxVolumes
    volume = i;
    fprintf('\n')
    disp(['Analyzing volume: ' num2str(i)])
    % Use the selected input files, to extract the needed Data and save that in a struct for every volume
    [Data] = load_data_across_sessions(volume, sessionsDate, directory, loadFile, dataWindow);
    
    %% Make a struct for the Data of the chosenAnimal that's being analysed.
    animal.whiskerMat = Data.whiskerMat;
    animal.neuronMat = Data.luminesMat;
    animal.upsample_rate = Data.upsample_rate;
    animal.binsize_whisker = Data.binsize_whisker; 
    animal.binsize_neurons = Data.binsize_lumines; 
    animal.dtstart = Data.dtstart;
    animal.protraction_retraction = Data.protraction_retraction;
    animal.distance_pole = Data.distance_pole;
    animal.nNeurons = Data.nNeurons;
    animal.nTime = Data.nTime;
    animal.nTrial = Data.nTrial;
    animal.volume = volume;
    
    % Save the animal struct to a .mat file with the animal name in the specified save_folder.
    fileName = animal.animalName;
    structName = [fileName,'_volume_',num2str(i),'.mat'];
    save([saveFolder structName], 'animal');
end
