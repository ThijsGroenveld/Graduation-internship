function [loadFile, chosenAnimal, sessionsDate, animalNames] = get_input_files(directory)
%%
% Get the recording datasets of every day/session from all the svoboda mice 
% Extract the unique animals from these datasets, prompt the user to choose
% one animal and collect all the files & session dates from the chosen animal.
%
% INPUT:
% * directory (string): This variable stores the directory of the files that need to be analyzed
%
% OUTPUT:
% * loadFile: A cell array with the full file names of all the sessions of the chosenAnimal which can be directly loaded.
% * chosenAnimal: A string with the name of the animal chosen by the user.
% * sessionsDate: A cell array with the dates for every session of the chosenAnimal.
% * animalNames: A cell array with the names of all the mice in the directory.
%       
% Example use:
% [loadFile, chosenAnimal, sessionsDate, animalNames] = get_input_files(directory)
%
% Credentials:
% This script was written by Thijs Groenveld, a bioinformatics intern at
% the Neurophysiology Department of the Donders Institute.
% All rights reserved. 
%
% You are free to use this script for research purposes as long as you
% credit the maker of the script(s).
% 17-05-2017

fileList = dir(fullfile(directory, '*.mat'));
numberOfFiles=length(fileList);
nameOfFile = cell(numberOfFiles, 1);
animalNames = cell(numberOfFiles, 1);

%% Find the animal names
for i = 1:numberOfFiles % Loop through all files
    nameOfFile{i}=fileList(i).name; % Collect all the folder names in the directory
    str = nameOfFile{i};
    expression = '[a-z]{2}\d{6}'; % Extract the animal names from the file names
    animalNames(i) = regexp(str,expression,'match');
end

animalNames = unique(animalNames); % Save only the unique animal names

%% Ask for user input to choose a specific animal from the list
fprintf('Choose one of the following animals: \n')
fprintf('%s\n',animalNames{1:end})
chosenAnimal = input('Which animal do you want to analyze? ','s');

x = strcmp(chosenAnimal, animalNames);
if x ~= 1
    disp('The chosen animal is not included in the list, please try again')
    fprintf('%s\n',animalNames{1:end})
    chosenAnimal = input('Which animal do you want to analyze? ','s');
end

%% Make a loadFile variable for all the sessions for the chosen animal
loadFile = cell(1, numberOfFiles);

for j = 1:numberOfFiles % Loop through all files
    str = nameOfFile{j};
    animal = chosenAnimal; % Filter on the chosen animal name
    sessionName = '_\d{4}_\d{2}_\d{2}[a-z]?_data_struct\.mat';
    expression = strcat(animal,sessionName); % Create a regular expression that combines the animal name to all the sessions of this animal.
    loadFile{1, j} = regexp(str,expression,'match'); % Create a loadFile variable in which all the sessions of this animal are stored.
end

sessionVec = ~cellfun('isempty',loadFile); % Mark all the sessions for the chosenAnimal with a 1
loadFile(~sessionVec) = []; % Delete all the cells from the loadFile list which are empty

%% Extract the session dates for the specific animal from the loadFile list
sessionsDate = cell(length(loadFile),1);

for k = 1:length(loadFile)
    str = loadFile{k};
    expression = '\d{4}_\d{2}_\d{2}[a-z]?'; % Extract all the session dates
    sessionsDate(k) = regexp(str,expression,'match');
end


end