function [maxVolumes] = get_max_volumes(loadFile, directory)

%% Collect the maximum number of volumes across multiple sessions of one animal from the loadFile list.
%
% INPUT:
% * loadFile (cell array): A cell array with the full file names of all the sessions of the chosenAnimal which can be directly loaded
% * directory (string): This variable stores the directory of the files that need to be analyzed
%
% OUTPUT:
% * maxVolumes(1x1 double): A variable with the maximum number of volumes found in any of the sessions of the loadFile
%
% Example use:
% [maxVolumes] = get_max_volumes(loadFile, directory)
%
% Credentials:
% This script was written by Thijs Groenveld, a bioinformatics intern at
% the Neurophysiology Department of the Donders Institute.
% All rights reserved.
%
% You are free to use this script for research purposes as long as you
% credit the maker(s) of the script(s).
% 05-06-2017

nSession = length(loadFile);
disp('Pre-loading all sessions to determine maximum volume...')
nOfVolumes = nan(1,nSession);

%% Open and read all the sessions from the loadFile variable.
for ns = 1:nSession
    %% Load 
    currentFile = loadFile{ns};
    disp(['Loading: ' currentFile{1}])
    load([directory currentFile{1,1}])
    
    nVolume = length(s.timeSeriesArrayHash.value);
    nOfVolumes(ns) = nVolume;
end

% Print the volume numbers per session
disp(['The number of volumes for the sessions are respectively: ' num2str(nOfVolumes)])

% Extract the maximum number from the nOfVolumes vector
maxVolumes = max(nOfVolumes);

end












