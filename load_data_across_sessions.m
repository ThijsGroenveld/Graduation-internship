function [Data] = load_data_across_sessions(volume, sessionsDate, directory, loadFile, dataWindow)

%% Collect the neurons that are present in one volume across all sessions
%
% Open all files from the loadFile and collect the neurons that are present
% in the volume specified in the volume variable across all the session.
% Collect the neuronal activity of these neurons within the dataWindow and
% build a 3D matrix with these values. This matrix stores the number of
% neurons times the number of datapoints within the dataWindow times the
% number of trials in which they were recorded.
%
% INPUT:
% * volume (int): The number of the volume from which the neurons need to be collected
% * sessionsDate (cell array): A cell array with all the session dates from the chosen animal
% * directory (string): This variable stores the directory of the files that need to be analyzed
% * loadFile (cell array): A cell array with the full file names of all the sessions of the chosenAnimal which can be directly loaded.
% * dataWindow (double): A 1x2 double with the time window from which the data needs to be collected.
%
% OUTPUT
% * Data (struct): This structure array contains several variables created by this function or passed on to this function.
%   This structure array stores the following variables; whiskerMat, luminesMat, upsample_rate, binsize_whi, binsize_lum, 
%   dtstart, nTrial, nTime, nNeurons, protraction_retraction and distance_pole.
%
%   These variables store respectively; a 3D matrix with the whisker angle and curvature over time per trial, 
%   a 3D matrix with the luminescence data of all neurons over time per trial. The upsample rate from the measurements, 
%   the bin sizes for the whisker data and luminescence data, the start times, the number of trials, data points and neurons, 
%   and two cell arrays that store whether the touch took place during a protraction or retraction whisker movement and 
%   the distance from the pole that the whisker touched.
%
% NB 
% * Ntime is not the same for whisker and calcium recordings, due to different sampling rates
% * Only neurons that are recorded across all sessions (with session 1 as 'reference') are included 
% * Only trials with whisker recordings are included, and where not all calcium recordings are 'NaN' 
%
% Example use:
% [Data] = load_data_across_sessions(volume, sessionsDate, directory, loadFile, dataWindow)
%
% Credentials:
% This script was written by Fleur Zeldenrust (assistant professor) and Thijs Groenveld (bioinformatics intern) 
% of the Neurophysiology department of the Donders Institute.
% All rights reserved. 
%
% You are free to use this script for research purposes as long as you
% credit the maker(s) of the script(s).
% 02-06-2017

%% plot / print/ save

Nsession = length(loadFile);
validsessionvec = ones(1,Nsession);
Nneuron_max = 0;
Ntrial_tot = 0;     % total number of trials
Ntrial_totkeep = 0; % total number of kept trials
nllmax = 0;         % maximum number of data points luminescence recordings
nwlmax = 0;         % maximum number of data points whisker recordings
nantrials_tot = 0;
notouchtrials_tot = 0;
nowhiskertrials_tot = 0;

window.start = 'first touch'; % 'first' (start trial), 'pole in reach' or 'first touch'
window.window = dataWindow;
plotcheck = 0;


if (strcmp(window.start, 'first') && window.window(1)<0)
    disp('Cannot include data before the start of the trial. Starting at 0.')
    window.window(1) = 0;
end

for ns = 1:Nsession
    %% Load 
    fprintf('\n')
    currentFile = loadFile{ns};
    disp(['Loading file ' currentFile{1}])
    load([directory currentFile{1,1}])
    
    nVolume = length(s.timeSeriesArrayHash.value);
    
    if volume > nVolume
        disp(['Volume ' num2str(volume) ' does not exist for session ' sessionsDate{ns}{1} '; skipping session.'])
        validsessionvec(ns) = 0;
        continue
    
    else
        
        %% Checks
        % check if multiple whiskers were recorded
        [nwhiskertrace, ~] = size(s.timeSeriesArrayHash.value{1}.valueMatrix);
        if nwhiskertrace>2
            disp('More than 2 whisker traces detected:')
            for nw = 1:nwhiskertrace
                disp(s.timeSeriesArrayHash.value{1}.idStrs{nw})
            end
            whiskertracen = input('Which traces should be used? (give 2d array)');
        else
            whiskertracen = [1,2];
        end
        
        % number of trials for this volume
        trialvec = unique(s.timeSeriesArrayHash.value{volume}.trial);
        Ntrial_temp = length(trialvec);
        
        binsize_lum = s.timeSeriesArrayHash.value{volume}.time(2)-s.timeSeriesArrayHash.value{volume}.time(1);
        binsize_whi = s.timeSeriesArrayHash.value{1}.time(2)-s.timeSeriesArrayHash.value{1}.time(1);
        upsample_rate_new = ((binsize_lum)/(binsize_whi));
        
        if exist('upsample_rate_old','var')
            if ~(upsample_rate_new == upsample_rate_old)
                % error('Files do not have the same sampling rates')
                disp(['Volume ' num2str(volume) ' does not have the same sampling rate as previous sessions; skipping session.'])
                validsessionvec(ns) = 0;
                continue
            end
        end
        
        % Check if the number of recorded neurons corresponds to other sessions
        [Nneuron_new, ~] = size(s.timeSeriesArrayHash.value{volume}.valueMatrix);
        if Nneuron_new>Nneuron_max
            Nneuron_max = Nneuron_new;
        end
        
        ids_new = s.timeSeriesArrayHash.value{volume}.ids;
        if exist('Nneuron_old', 'var')
            if ~(Nneuron_new == Nneuron_old)
                disp('Not the same number of neurons in new file. Checking ids')
                neuronkeepvec_new = [];
                neuronkeepvec_old = ones(1,Nneuron_old);
                for nn = 1:Nneuron_old
                    corresponding_neuron = find(ids_new == ids_old(nn));
                    if isempty(corresponding_neuron)
                        neuronkeepvec_old(nn) = 0;
                    else
                        neuronkeepvec_new = [neuronkeepvec_new; corresponding_neuron];
                    end
                    corresponding_neuron = [];
                end
                
                % With this piece of code, the user can choose to discard or keep sessions 
                % that lead to a loss of neurons that are recorded across all sessions.
                if Nneuron_new<Nneuron_old
                    keep = input([num2str(Nneuron_old-Nneuron_new) ' neurons discarded; ' num2str(Nneuron_new) ' neurons kept. Keep session? (y/n)'],'s');
                    if strcmp(keep, 'n')
                        disp(['Discarding session ' {ns}])
                        validsessionvec(ns) = 0;
                        continue
                    end
                end
                                
                if isempty(neuronkeepvec_new)
                    disp('No neurons left, skipping this session')
                    validsessionvec(ns) = 0;
                    continue
                end
                neuronkeepvec_old = find(neuronkeepvec_old==1); % for later use at concatenation
                
                Nneuron_new = length(neuronkeepvec_new);
                ids_new = ids_new(neuronkeepvec_new);
            else
                disp('The same number of neurons in new file. Not checking ids')
                neuronkeepvec_new = 1:Nneuron_new;
                neuronkeepvec_old = neuronkeepvec_new;
            end
        else
            disp('First file. Not checking ids')
            neuronkeepvec_new = 1:Nneuron_new;
            neuronkeepvec_old = neuronkeepvec_new;
        end
        
        
        %% Put (valid) trials in matrix
        
        if strcmp(window.start, 'pole in reach')
            Ntime_w = 1000;
            Ntime_l = 100;
        elseif (~isempty(window.window) && ~strcmp(window.start, 'pole in reach'))
            whiskertime = window.window(1):binsize_whi:window.window(end);
            Ntime_w = length(whiskertime);
            
            lumtime = window.window(1):binsize_lum:window.window(end);
            Ntime_l = length(lumtime);
        else
            error('Please give an appropriate time window')
        end
        
        whiskermat_temp = NaN*ones(2,Ntime_w,Ntrial_temp);
        luminesmat_temp = NaN*ones(Nneuron_new,Ntime_l,Ntrial_temp);
        
        validvec = ones(size(trialvec));
        dtstart_temp = nan*ones(1,Ntrial_temp);
        distance_pole_temp = nan(1, Ntrial_temp);
        
        disp(['Number of trials for volume ' num2str(volume) ': ' num2str(Ntrial_temp)])
        
        nantrials_temp = 0;
        notouchtrials_temp = 0;
        nowhiskertrials_temp = 0;
        protraction_retraction_temp = nan(1,Ntrial_temp);
        
        for nt = 1:Ntrial_temp
            disp(['Trial ' num2str(nt) '/' num2str(Ntrial_temp) ': trial id ' num2str(trialvec(nt))])
            % nt_tot = nt+Ntrial_tot;
            whiskertrialvec = find(s.timeSeriesArrayHash.value{1}.trial == trialvec(nt));
            try
                distance_pole_temp(nt) = s.trialPropertiesHash.value{3}(s.trialIds == trialvec(nt));
            catch
                disp('Error: volume has trial IDs that are not present in data: skipping trial')
                validvec(nt) = 0;
                continue
            end
            
            if isempty(whiskertrialvec)
                disp(['No whisker data, skipping trial with id ' num2str(trialvec(nt))])
                validvec(nt)=0;
                nowhiskertrials_temp = nowhiskertrials_temp+1;
                
            else
                luminestrialvec = find(s.timeSeriesArrayHash.value{volume}.trial == trialvec(nt));
                
                %% Make appropriate time window
                whiskertime_thistrial = s.timeSeriesArrayHash.value{1}.time(whiskertrialvec);
                luminestime_thistrial = s.timeSeriesArrayHash.value{volume}.time(luminestrialvec);
                whiskertrace = s.timeSeriesArrayHash.value{1}.valueMatrix(whiskertracen,whiskertrialvec);
                luminestrace = s.timeSeriesArrayHash.value{volume}.valueMatrix(neuronkeepvec_new,luminestrialvec);
                tstart = max(whiskertime_thistrial(1), luminestime_thistrial(1));
                tend = min(whiskertime_thistrial(end), luminestime_thistrial(end));
                if isempty(window.start)
                    % nothing needed, use calculated tstart and tend;
                elseif strcmp(window.start, 'pole in reach')
                    if isfield(window, 'window')
                        disp('Using times pole in reach; ignoring given window')
                    end
                    tpole  = s.eventSeriesArrayHash.value{1}.eventTimes(s.eventSeriesArrayHash.value{1}.eventTrials==trialvec(nt));
                    tstart = tpole(1);
                    tend   = tpole(2);
                    
                elseif strcmp(window.start, 'first touch')
                    ttouchpro = s.eventSeriesArrayHash.value{2}.eventTimes{1}(s.eventSeriesArrayHash.value{2}.eventTrials{1}==trialvec(nt));
                    ttouchre  = s.eventSeriesArrayHash.value{2}.eventTimes{2}(s.eventSeriesArrayHash.value{2}.eventTrials{2}==trialvec(nt));
                                      
                    if ~isempty(ttouchpro) && ~isempty(ttouchre)
                        ttouchpro = ttouchpro(1);
                        ttouchre  = ttouchre(1);
                        [ttouch, nprore] = min([ttouchpro, ttouchre]);
                        if nprore == 1
                            protraction_retraction_temp(nt) = 1;
                        elseif nprore == 2
                            protraction_retraction_temp(nt) = -1;
                        else
                            disp('Error')
                            keyboard
                        end
 
                    elseif ~isempty(ttouchpro) && isempty(ttouchre)
                        ttouch = ttouchpro(1);
                        protraction_retraction_temp(nt) = 1;
                 
                    elseif isempty(ttouchpro) && ~isempty(ttouchre)
                        ttouch = ttouchre(1);
                        protraction_retraction_temp(nt) = -1;
                      
                    else
                        disp(['No touch data, skipping trial with id ' num2str(trialvec(nt))])
                        validvec(nt)=0;
                        ttouch = tstart;
                        notouchtrials_temp = notouchtrials_temp+1;
                    end
                    tstart = ttouch+window.window(1);
                    tend   = ttouch+window.window(2);
                elseif strcmp(window.start, 'first')
                    tstart = tstart+window.window(1);
                    tend   = tstart+window.window(2);
                end
                
                
                %% Find appropriate whisker recordings
                if strcmp(window.start, 'pole in reach')
                    % variable length
                    [~, nstart] = min(abs(whiskertime_thistrial-tstart));
                    [~, nend] = min(abs(whiskertime_thistrial-tend));
                    whiskertrace = whiskertrace(:,nstart:nend);
                else
                    % fixed length
                    if ((tstart>whiskertime_thistrial(1)) && (tend<whiskertime_thistrial(end)))
                        % window fits in trial
                        [~, nstart] = min(abs(whiskertime_thistrial-tstart));
                        whiskertrace = whiskertrace(:,nstart:nstart+Ntime_w-1);
                        whiskertime_thistrial = whiskertime_thistrial(nstart:nstart+Ntime_w-1);
                    elseif (tstart<whiskertime_thistrial(1) && ~strcmp(window.start, 'pole in reach'))
                        % no recording in beginning of window, add NaN
                        [~, nend] = min(abs(whiskertime_thistrial-tend));
                        whiskertrace_temp = whiskertrace(:,1:nend);
                        whiskertime_thistrial = whiskertime_thistrial(1:nend);
                        lw = length(whiskertrace_temp(1,:));
                        whiskertrace = [nan*ones(2,Ntime_w-lw), whiskertrace_temp];
                    elseif (tend>whiskertime_thistrial(end) && ~strcmp(window.start, 'pole in reach'))
                        % no recording in end of window, add NaN at the end
                        [~, nstart] = min(abs(whiskertime_thistrial-tstart));
                        whiskertrace_temp = whiskertrace(:,nstart:end);
                        whiskertime_thistrial = whiskertime_thistrial(nstart:end);
                        lw = length(whiskertrace_temp(1,:));
                        whiskertrace = [whiskertrace_temp, nan*ones(2,Ntime_w-lw)];
                    else
                        disp('Chosen window too large for trials, skip trial')
                        validvec(nt) = 0;
                        whiskertrace = nan(2,Ntime_w);
                    end
                end
                if strcmp(window.start, 'pole in reach')
                    nwl = length(whiskertrace(1,:));
                    if nwl>nwlmax
                        nwlmax = nwl;
                    end
                    whiskermat_temp(:,1:nwl,nt) = whiskertrace;
                else
                    try
                        whiskermat_temp(:,:,nt) = whiskertrace;
                    catch
                        keyboard
                    end
                end
                
                
                
                %% Find appropriate neural recordings
                if strcmp(window.start, 'pole in reach')
                    % variable length
                    [~, nstart] = min(abs(luminestime_thistrial-tstart));
                    [~, nend] = min(abs(luminestime_thistrial-tend));
                    luminestrace = luminestrace(:,nstart:nend);
                else
                    % fixed length
                    if ((tstart>=luminestime_thistrial(1)) && (tend<=luminestime_thistrial(end)))
                        % window fits in trial
                        [~, nstart] = min(abs(luminestime_thistrial-tstart));
                        if ((luminestime_thistrial(nstart)<tstart) && ((nstart+Ntime_l)<=length(luminestime_thistrial)))
                            % causality: always align to next neural recording
                            nstart = nstart+1;
                        end
                        luminestrace = luminestrace(:,nstart:nstart+Ntime_l-1);
                        luminestime_thistrial = luminestime_thistrial(nstart:nstart+Ntime_l-1);
                    elseif (tstart<luminestime_thistrial(1))
                        % no recording in beginning of window, add NaN
                        [~, nend] = min(abs(luminestime_thistrial-tend));
                        if ((luminestime_thistrial(nend)<tend) && (nend+1<= (length(luminestime_thistrial))))
                            % causality: always align to next neural recording
                            nend = nend+1;
                        end
                        if nend<Ntime_l
                            luminestrace_temp = luminestrace(:,1:nend);
                            luminestime_thistrial = luminestime_thistrial(1:nend);
                            lw = length(luminestrace_temp(1,:));
                            luminestrace = [nan*ones(Nneuron_new,Ntime_l-lw), luminestrace_temp];
                        else
                            luminestrace = luminestrace(:,nend-Ntime_l+1:nend);
                        end
                    elseif (tend>luminestime_thistrial(end))
                        % no recording in end of window, add NaN at the end
                        [~, nstart] = min(abs(luminestime_thistrial-tstart));
                        if ((luminestime_thistrial(nstart)<tstart) && ((nstart+Ntime_l)<=length(luminestime_thistrial)))
                            % causality: always align to next neural recording
                            nstart = nstart+1;
                        end
                        luminestrace_temp = luminestrace(:,nstart:end);
                        luminestime_thistrial = luminestime_thistrial(nstart:end);
                        lw = length(luminestrace_temp(1,:));
                        luminestrace = [luminestrace_temp, nan*ones(Nneuron_new,Ntime_l-lw)];
                    else
                        disp('Chosen window too large for trials, skipping trial')
                        validvec(nt)=0;
                        luminestrace = nan(Nneuron_new,Ntime_l);
                    end
                end
                if strcmp(window.start, 'pole in reach')
                    nll = length(luminestrace(1,:));
                    if nll>nllmax
                        nllmax = nll;
                    end
                    luminesmat_temp(:,1:nll,nt) = luminestrace;
                else
                    try
                        luminesmat_temp(:,:,nt) = luminestrace;
                    catch
                        keyboard
                    end
                end
                
                dtstart_temp(nt) = whiskertime_thistrial(1)-luminestime_thistrial(1);
                
            end
            
            if Nneuron_new*Ntime_l == sum(sum(isnan(luminesmat_temp(:,:,nt))))
                disp(['Only NaNs in neural recording, skipping trial with id ' num2str(trialvec(nt))])
                validvec(nt)=0;
                nantrials_temp = nantrials_temp + 1;
                
            end
            if plotcheck
                f = figure;
                subplot(3,1,1)
                plot(whiskertime, squeeze(whiskermat_temp(1,:,nt)))
                box on
                grid on
                title('Whisker angle')
                subplot(3,1,2)
                plot(whiskertime, squeeze(whiskermat_temp(2,:,nt)))
                box on
                grid on
                title('Whisker curvature')
                subplot(3,1,3)
                plot(lumtime, squeeze(luminesmat_temp(:,:,nt)))
                box on
                grid on
                title('\Delta F / F')
                xlabel('time (ms)')
                pause
                close(f)
            end
        end
        
    end
    Ntrial_tempkeep = sum(validvec);
    whiskermat_temp = whiskermat_temp(:,:,validvec == 1); % Vul alle waarden met een valid '1' toe aan de matrix
    luminesmat_temp = luminesmat_temp(:,:,validvec == 1); % Vul alle waarden met een valid '1' toe aan de matrix
    dtstart_temp    = dtstart_temp(validvec == 1);
    
    protraction_retraction_temp = protraction_retraction_temp(validvec == 1);
    distance_pole_temp = distance_pole_temp(validvec == 1);
    
    %% Concatenate with previous sessions
    if exist('whiskermat','var')
        if (~isempty(luminesmat_temp)) && (~isempty(whiskermat_temp))
            whiskermat = cat(3,whiskermat, whiskermat_temp);
        end
    else
        whiskermat = whiskermat_temp;
    end
    if exist('luminesmat','var')
        if (~isempty(luminesmat_temp)) && (~isempty(whiskermat_temp))
            luminesmat = cat(3,luminesmat(neuronkeepvec_old,:,:), luminesmat_temp);
        end
    else
        luminesmat = luminesmat_temp;
    end
    
    if exist('dtstart','var')
        if (~isempty(luminesmat_temp)) && (~isempty(whiskermat_temp))
            dtstart = [dtstart dtstart_temp];
        end
    else
        dtstart = dtstart_temp;
    end
    
    if exist('protraction_retraction','var')
        if (~isempty(luminesmat_temp)) && (~isempty(whiskermat_temp))
            protraction_retraction = [protraction_retraction protraction_retraction_temp];
        end
    else
        protraction_retraction = protraction_retraction_temp;
    end
    
    if exist('distance_pole','var') % is de if loop hieronder echt nodig? de limunes/whiskerMats zijn niet echt relevant..
        if (~isempty(luminesmat_temp)) && (~isempty(whiskermat_temp))
            distance_pole = [distance_pole distance_pole_temp];
        end
    else
        distance_pole = distance_pole_temp;
    end
    
    
    %% For the next round
    Nneuron_old = Nneuron_new;
    ids_old = ids_new;
    upsample_rate_old = upsample_rate_new;
    if ~(length(ids_old)==Nneuron_old)
        error('Number of neuron ids does not correspond to number of recordings')
    end
    Ntrial_tot = Ntrial_tot+Ntrial_temp;
    Ntrial_totkeep = Ntrial_totkeep+Ntrial_tempkeep;
    nantrials_tot = nantrials_tot+nantrials_temp;
    notouchtrials_tot = notouchtrials_tot+notouchtrials_temp;
    nowhiskertrials_tot = nowhiskertrials_tot+nowhiskertrials_temp;
end

%% Discard padded zeros
if strcmp(window.start, 'pole in reach')
    whiskermat = whiskermat(:,1:nwlmax,:);
    luminesmat = luminesmat(:,1:nllmax,:);
end

nNeurons = size(luminesmat(:,:,:),1);
nTime = size(luminesmat(:,:,:),2);
nTrial = size(luminesmat(:,:,:),3);

upsample_rate = upsample_rate_new;

%% Print summary
fprintf('\n');
disp(['In a total of ' num2str(Nsession) ' sessions, ' num2str(sum(validsessionvec)) ' were valid (overlapping neuron ids with first session).'])
disp(['There were ' num2str(Ntrial_tot) ' trials, of which ' num2str(Ntrial_totkeep) ' were kept.'])
disp(['There were ' num2str(nantrials_tot) ' trials with only NaNs in the recordings'])
disp(['There were ' num2str(notouchtrials_tot) ' trials with no first touch data'])
disp(['There were ' num2str(nowhiskertrials_tot) ' trials with no whisker data'])
disp('NB Overlap possible')
disp(['Out of a maximum of ' num2str(Nneuron_max) ' neurons, ' num2str(Nneuron_old) ' were kept (shared across all sessions)'])

%% Make a struct for the data of the chosenAnimal that's being analysed.
Data = struct('whiskerMat',whiskermat,'luminesMat',luminesmat,'upsample_rate',...
    upsample_rate, 'binsize_whisker', binsize_whi, 'binsize_lumines', binsize_lum,...
    'dtstart', dtstart, 'nTrial', nTrial, 'nTime',nTime, 'nNeurons', nNeurons, 'protraction_retraction',protraction_retraction,...
    'distance_pole',distance_pole);

end
