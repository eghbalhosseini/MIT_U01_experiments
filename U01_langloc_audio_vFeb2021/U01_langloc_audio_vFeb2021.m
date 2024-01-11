%%%
% This experiment plays audio of intact or degraded sentences.

% There are three lists. Each participant should do all three lists, 1 run
% each.
% With quick presses of the spacebar, each list is under 4 minutes. It will
% take ~16 minutes at least to run all 4 lists.

% Modified by Hannah Small for use in U01 experiments
% January 6, 2021

%ABOUT THESE INPUTS
%subjID -   string, should match across all runs for a given participant
%list -      1,2,3, or 4: indicates the particular run of the set we are 
%           currently on, ideally, we want 1 run of every set of materials


function U01_langloc_audio_vFeb2021(cfg)


subjID = cfg.SUBJECT;
list = cfg.RUN_ID;
send_triggers = cfg.SEND_TRIGGERS; %false when testing without actual trigger machine

%first, argument checks
subject_output = cfg.EVENT_FILENAME;
subject_output_file = [subject_output '.csv'];
rootDir = pwd();

expt_name = 'U01_langloc_audio_vFeb2021';

PsychDefaultSetup(2);

%Trigger codes
start_expt =    1;
end_expt =      2;
start_audio =   3; 
condition_idx = 4; %1 for intact, 0 for degraded
end_audio =     5;
probe_trigger = 6;
fixation_trigger = 7;

% Create empty structure.
TrialStruct = struct();
if(send_triggers)
    TrialStruct = Setup_DAQ_Stim(TrialStruct);
end


%handle duplicate filename, and other checks
if ischar(subjID) == 0
    error('subj_ID must be a string')
end

%input checks
if list > 3 || list < 0
    error('list must be between 1 and 3')
end

%get the latest attempt at this list -- will be *_resume(n).csv
d = dir([subject_output '*.csv']);
n_files = length(d);
if(n_files > 0)
    subject_output_file = [d(n_files).folder filesep d(n_files).name];
    resume_number = 0;

    if contains(subject_output_file,'resume') || contains(subject_output_file,'restart')
        filename_len = length(subject_output_file);
        resume_number = str2num(subject_output_file(filename_len-4));
    end
end


%if subject output file already exists, check if they want to resume from
%where the previous run left off or restart the run
if ~isempty(d)
    previous_run = readtable(subject_output_file);
    
    %determine if this run was finished
    num_completed = sum(previous_run.trial_completed == 1);
    num_trials = length(previous_run.trial);
    
    if num_completed < num_trials
        choice = str2num(input(['\nThis subject has partially completed this list.\nPress 1 to resume. Press 2 to restart.\n'],'s'));
    else
        error(['This subject has completed this list. Please enter a different subject ID or list.']);
    end
    
    if choice == 1 || choice == 2
        

        %start at beginning
        start = 1;
        %compute the resume numbers (largest resume + 1)
        resumed = previous_run.resume_number;
        current_resume_number = max(resumed) + 1;
        %unless we are resuming
        if choice == 1
            %find resume spot
            completed = previous_run.trial_completed == 1;
            start = sum(completed) + 1; %start with next sentence
            
            trial_onset = previous_run.trial_onset;
            final_audio_filename = previous_run.final_audio_filename;
            final_audio_transcript = previous_run.final_audio_transcript;
            final_condition = previous_run.final_condition;
            final_list = previous_run.final_list;
            final_probe = previous_run.final_probe;
            final_probe_condition = previous_run.final_probe_condition;
            audio_ended = previous_run.audio_ended;
            response = previous_run.response;
            RT = previous_run.response;
            accuracy = previous_run.accuracy;
            trial_completed = previous_run.trial_completed;
            resume_number = previous_run.resume_number;
            time_info = previous_run.time_info;
            
            NUM_STIMULI = height(previous_run);
            
            subject_output_file = [subject_output '_resume' num2str(current_resume_number) '.csv'];
            
            fprintf('Resuming list %d at trial % \n', list, start);
        else
            % get materials for this set
            load('stimuli/materials.mat')

            run_label = strcat("run",num2str(list));
            stimuli = materials.(run_label);

            NUM_STIMULI = height(stimuli);

            final_audio_filename = stimuli.audiofile;
            final_audio_transcript = stimuli.stim_transcript;
            final_condition = stimuli.condition;
            final_list = list*ones(NUM_STIMULI,1);
            final_probe = stimuli.final_probe;
            final_probe_condition = stimuli.probe_condition;

            %set the start at the beginning, not resumed
            start = 1; 

            %initialize arrays for output
            trial_onset = zeros(NUM_STIMULI,1);
            audio_ended = zeros(NUM_STIMULI,1);
            response = zeros(NUM_STIMULI,1);
            RT = zeros(NUM_STIMULI,1);
            accuracy = zeros(NUM_STIMULI,1);
            pressed_space_to_continue = zeros(NUM_STIMULI,1);
            trial_completed = zeros(NUM_STIMULI,1);
            resume_number = zeros(NUM_STIMULI,1);
            time_info = zeros(NUM_STIMULI,1);
            
            subject_output_file = [subject_output '_restart' num2str(current_resume_number) '.csv'];
            fprintf('Restarting list %d \n', list);
        end
        
    else %input was anything other than 1 or 2
        error('Unrecognized input. Press 1 to resume, press 2 to restart. Exiting.');
    end
    
else
    % no output file for this subject for this list yet
    % run the full list
    
    % get materials for this set
    load('stimuli/materials.mat')

    run_label = strcat("run",num2str(list));
    stimuli = materials.(run_label);
    
    NUM_STIMULI = height(stimuli);

    final_audio_filename = stimuli.audiofile;
    final_audio_transcript = stimuli.stim_transcript;
    final_condition = stimuli.condition;
    final_list = list*ones(NUM_STIMULI,1);
    final_probe = stimuli.final_probe;
    final_probe_condition = stimuli.probe_condition;
    
    %set the start at the beginning, not resumed
    start = 1; 
    current_resume_number = 0;
    
    %initialize arrays for output
    trial_onset = zeros(NUM_STIMULI,1);
    audio_ended = zeros(NUM_STIMULI,1);
    response = zeros(NUM_STIMULI,1);
    RT = zeros(NUM_STIMULI,1);
    accuracy = zeros(NUM_STIMULI,1);
    trial_completed = zeros(NUM_STIMULI,1);
    resume_number = zeros(NUM_STIMULI,1);
    time_info = zeros(NUM_STIMULI,1);

    
end

%% variables to change
INSTRUCTIONS = 'You will listen to some sentences.\n\n After, you will see a word in blue. \n\n Press 1 if that word was in the sentence\n\n you just heard and 2 if not.';
STIMULI_AUDIO = [ filesep 'stimuli' filesep];

%color variables
WHITE = [255 255 255];
BLACK = [64 64 64];
blue = [0 0 1];
GREY = 0.6;

%these two arrays correspond to each other
KbName('UnifyKeyNames');
key_mapping = ["1", "2", "1","2"];
trigger_response_keys = [KbName('1!'), KbName('2@'),KbName('a'),KbName('s')];
escapeKey = KbName('ESCAPE');
enterKey = KbName('Return');
spaceBar = KbName('space');


%% Initialize Window %%
oldLevel = Screen('Preference', 'Verbosity', 0);
java; %clear java cache
AssertOpenGL;
Screen('Preference', 'VisualDebugLevel',    0);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'TextRenderer',        0);
Screen('Preference', 'SkipSyncTests',       1);

Screen('CloseAll')

screensAll = Screen('Screens'); %Get the screen numbers
screenNumber = max(screensAll); % Which screen you want to use. "1" is external monitor, "0" is this screen. use external if it is present
%define colors
white = WhiteIndex(screenNumber);
flipSyncState=0;

[windowPtr,rect]=PsychImaging('OpenWindow',screenNumber, GREY); %, [0 0 1440 900]
[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr);
oldTextSize = Screen('TextSize',windowPtr,40);


% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(rect);

priorityLevel = MaxPriority(windowPtr);
Priority(priorityLevel);


%% Present instructions %%

flipSyncState = ~flipSyncState;
Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
DrawFormattedText(windowPtr, 'Welcome! \n\n Press any key to begin', 'center', 'center', 0);
Screen('Flip', windowPtr);

%HideCursor;

triggerKey = enterKey;
% while 1
%     [keyIsDown, sec, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
%     if keyCode(escapeKey)
%         Screen('CloseAll');
%         fprintf('Experiment quit by pressing ESCAPE\n');
%         break;
%     elseif ismember(find(keyCode,1), triggerKey)        % used to be: keyCode(KbName(triggerKey))
%         break;
%     end
%     WaitSecs(0.001);
% end
[~, keyCode] = KbWait([], 2);
if any(ismember(find(keyCode),escapeKey))
    Screen('CloseAll');
    ShowCursor;
    error('Experiment quit using ESCAPE\n');
end

% present instructions
DrawFormattedText(windowPtr, ['\n\n' INSTRUCTIONS ], 'center', 'center', 0);
DrawFormattedText(windowPtr, 'Press any key when you are ready to begin', 'center', screenYpixels .* 0.85,  0);
flipSyncState = ~flipSyncState;
Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
Screen('Flip', windowPtr);
WaitSecs(0.2); %some buffer time for key press to work
triggerKey = spaceBar;
% while 1
%     [keyIsDown, sec, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
%     if keyCode(escapeKey)
%         Screen('CloseAll');
%         fprintf('Experiment quit by pressing ESCAPE\n');
%         break;
%     elseif ismember(find(keyCode,1), triggerKey)        % used to be: keyCode(KbName(triggerKey))
%         break;
%     end
%     WaitSecs(0.001);
% end
[~, keyCode] = KbWait([], 2);
if any(ismember(find(keyCode),escapeKey))
    Screen('CloseAll');
    ShowCursor;
    error('Experiment quit using ESCAPE\n');
end

%% Experiment %%

%Initialize sound driver
InitializePsychSound;
oldlevel = PsychPortAudio('Verbosity' ,0);


TriggerCode = zeros(1,8);
TriggerCode(start_expt) = 1;
TriggerCode(end_expt) = 0;
if(send_triggers)
    SendTrigger( TrialStruct, TriggerCode )
end

startTime = GetSecs();
ind=1;
Screen('TextSize', windowPtr, 80);
for j =start:NUM_STIMULI
     if(mod(ind-1, 8) == 0 && ind ~= start && ind ~= NUM_STIMULI) %give a rest every 8 trials, excluding first and last trial
        ind = 1;
        Screen('TextSize', windowPtr, 40);
        DrawFormattedText(windowPtr, 'Take a break \n\n Press the spacebar to continue', 'center', 'center', 0);
        flipSyncState = ~flipSyncState;
        Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
        start_break = Screen('Flip', windowPtr);
        Screen('TextSize', windowPtr, 80);

        while 1
            [keyIsDown, seconds_time, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
            if keyCode(escapeKey)
                writetable(output, subject_output_file, 'WriteVariableNames', true);
                Screen('CloseAll');
                error('Experiment quit by pressing ESCAPE\n');
            elseif ismember(find(keyCode,1), spaceBar)
                break;
            end
            WaitSecs(0.001);
        end
        
    end
    
    t = now;
    date_time = datetime(t,'ConvertFrom','datenum');
    time_info(j,1) = seconds(timeofday(date_time));
    trial_onset(j,1) = GetSecs() - startTime; %save the onset time of the trial

    %% Set audio  %%
    stimuli = final_audio_filename(j,1); %get stimuli ID
    condition = final_condition{j,1};
    if(condition == "sentence")
        cond_trigger = 1;
    elseif(condition == "nonword")
        cond_trigger = 0;
    end
    
    %% STARTING FIXATION
    DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
    flipSyncState = ~flipSyncState;
    Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
    fixation_time = Screen(windowPtr, 'Flip');
    %SEND FIXATION TRIGGER
    TriggerCode = zeros(1,8);
    TriggerCode(start_expt) = 1;
    TriggerCode(condition_idx) = cond_trigger;
    TriggerCode(fixation_trigger) = 1;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    while GetSecs() - fixation_time < 0.2
        WaitSecs(0.00001);
    end
    
    theFile = string(strcat(rootDir ,STIMULI_AUDIO ,stimuli)); %get the current audio file 
    [y, freq] = psychwavread(theFile);
    nrchannels = size(y,2); % Number of cols == number of channels
    audioDur = size(y,1)/freq;
    
    pahandle = PsychPortAudio('Open', [], [], 1, [], nrchannels);
    % Open the default audio device [], with default mode [] (==Only playback),
    % and a required latencyclass of zero 0 == no low-latency mode, as well as
    % a frequency of freq and nrchannels sound channels.
    % This returns a handle to the audio device:
    
    %resampling the audio file if wav's Fs doesn't match that of the audio device
    pahandle_status = PsychPortAudio('GetStatus', pahandle);
    pahandle_Fs = pahandle_status.SampleRate;
    if pahandle_Fs ~= freq
        fprintf('Resampling audio from %i to %i Hz...\n',freq,pahandle_Fs)
        y=resample(y,pahandle_Fs,freq);
    else
        fprintf('audio file matches audio device Fs at %i Hz...\n',pahandle_Fs) 
    end
    wavedata = y';
    
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    % Fill the audio playback buffer with the audio data 'wavedata':
   
    timeLimit = audioDur;
    
    %% SEND START AUDIO TRIGGER
    TriggerCode = zeros(1,8);
    TriggerCode(start_expt) = 1;
    TriggerCode(start_audio) = 1;
    TriggerCode(condition_idx) = cond_trigger;
    TriggerCode(end_audio) = 0;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    
    PsychPortAudio('Start', pahandle, 1, 0, 1);
    %wait for audio to finish
    WaitSecs(timeLimit);
    stimuli_end_time = GetSecs();
    audio_ended(j,1) = stimuli_end_time-startTime;
    
    %% SEND END AUDIO TRIGGER
    TriggerCode = zeros(1,8);
    TriggerCode(start_expt) = 1;
    TriggerCode(start_audio) = 0;
    TriggerCode(condition_idx) = cond_trigger;
    TriggerCode(end_audio) = 1;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    
    trial_completed(j,1) = 1;
    resume_number(j,1) = current_resume_number;
    
    
    %% FIXATION and PROBES - total time is 1.8 seconds
    probe = final_probe(j);
    DrawFormattedText(windowPtr, ' ', 'center', 'center', 0);
    flipSyncState = ~flipSyncState;
    Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
    start_time = Screen(windowPtr, 'Flip');
    %% SEND FIXATION TRIGGER
    TriggerCode = zeros(1,8);
    TriggerCode(start_expt) = 1;
    TriggerCode(condition_idx) = cond_trigger;
    TriggerCode(fixation_trigger) = 1;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    probe_period = GetSecs() - start_time < 1.8;
    probe_shown = 0;
    final_fixation_shown = 0;
    while probe_period
        if (GetSecs() - start_time < 0.2)
            continue;
        elseif (GetSecs() - start_time < 1.2)
            if(~probe_shown)
                DrawFormattedText(windowPtr, char(probe), 'center','center',blue);
                flipSyncState = ~flipSyncState;
                Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
                Screen(windowPtr,'Flip');
                probe_shown = 1;
                probe_shown_time = GetSecs();
                %% SEND PROBE TRIGGER
                TriggerCode = zeros(1,8);
                TriggerCode(start_expt) = 1;
                TriggerCode(condition_idx) = cond_trigger;
                TriggerCode(probe_trigger) = 1;
                if(send_triggers)
                    SendTrigger( TrialStruct, TriggerCode )
                end
            end
        else %0.6 s extra time to answer
            if(~final_fixation_shown)
                DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
                flipSyncState = ~flipSyncState;
                Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
                Screen(windowPtr,'Flip');
                final_fixation_shown = 1;
                %% SEND FIXATION TRIGGER
                TriggerCode = zeros(1,8);
                TriggerCode(start_expt) = 1;
                TriggerCode(condition_idx) = cond_trigger;
                TriggerCode(fixation_trigger) = 1;
                if(send_triggers)
                    SendTrigger( TrialStruct, TriggerCode )
                end
            end
        end
        
        [keyIsDown, sec, keyCode] = KbCheck(-3);
        if keyCode(escapeKey)
            Screen('CloseAll');
            error('Experiment quit using ESCAPE\n');
        elseif ismember(find(keyCode,1), trigger_response_keys)
            %get their response and accuracy info
            index = find(trigger_response_keys == find(keyCode,1));
            response(j,:) = key_mapping(index); % output determined by key_mapping at top of script
            RT(j,:) = sec-probe_shown_time;

            probe_condition = final_probe_condition(j);
            if(probe_condition == "probe_correct")
                target = 1;
            elseif(probe_condition == "probe_incorrect")
                target = 2;
            end
            accuracy(j,:) = response(j,1) == target;
        end
        WaitSecs(0.000001);
        probe_period = GetSecs() < start_time + 1.8;
    end
    
    
    %record output for every trial
    trial = [1:NUM_STIMULI]';
        
    output = table(final_list, trial, trial_onset, final_audio_filename, final_condition, final_audio_transcript, audio_ended, final_probe, final_probe_condition, response, RT, accuracy, trial_completed,resume_number,time_info);
    writetable(output, subject_output_file, 'WriteVariableNames', true);
    ind = ind +1; %updating for the break every 8 trials
end

%% SEND END EXPT TRIGGER
TriggerCode = zeros(1,8);
TriggerCode(start_expt) = 0;
TriggerCode(start_audio) = 0;
TriggerCode(end_audio) = 0;
TriggerCode(end_expt) = 1;
if(send_triggers)
    SendTrigger( TrialStruct, TriggerCode )
end

time = GetSecs() - startTime
%end of trial
DrawFormattedText(windowPtr, 'Thank you! \n\n Press Enter to Exit', 'center', 'center', 0);
flipSyncState = ~flipSyncState;
Screen('FillRect', windowPtr, cfg.SCREEN_SYNC_COLOR .* flipSyncState, cfg.SCREEN_SYNC_RECT);
Screen('Flip', windowPtr);
WaitSecs(0.5);

triggerKey = enterKey;

while 1
    [keyIsDown, sec, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
    if keyCode(escapeKey)
        Screen('CloseAll');
        error('Experiment quit by pressing ESCAPE\n');
    elseif ismember(find(keyCode,1), triggerKey)        % used to be: keyCode(KbName(triggerKey))
        break;
    end
    WaitSecs(0.001);
end


PsychPortAudio('Close');
ShowCursor;
Screen('CloseAll');

%clear the keyboard
KbQueueRelease();
KbReleaseWait();

end

