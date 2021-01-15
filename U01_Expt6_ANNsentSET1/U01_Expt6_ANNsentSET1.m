%%%
% This experiment plays audio of spoken sentences or nonword, waiting for 
% a space bar press to continue to the next sentence.

% There are four lists. Each participant should do all four lists, 1 run
% each.
% With quick presses of the spacebar, each list is under 4 minutes. It will
% take ~16 minutes at least to run all 4 lists.

% Modified by Hannah Small for use in U01 experiments
% January 6, 2021

%ABOUT THESE INPUTS
%subjID -   string, should match across all runs for a given participant
%list -      1,2,3, or 4: indicates the particular run of the set we are 
%           currently on, ideally, we want 1 run of every set of materials


function U01_Expt6_ANNsentSET1(subjID, list)

expt_name = 'U01_Expt6_ANNsentSET1';

send_triggers = 0; 

%Trigger codes
start_expt =    1;
end_expt =      2;
start_audio =   3; 
condition_idx = 4; %1 for sentence, 0 for nonword
repeat =        5; %1 for repeat, 0 for not repeat, *will only be on sentence trials*
end_audio =     6;

% Create empty structure.
TrialStruct = struct();
if(send_triggers)
    TrialStruct = Setup_DAQ_Stim(TrialStruct);
end

%first, argument checks
rootDir = pwd();
OUTPUT_FOLDER = 'output';

%handle duplicate filename, and other checks
if ischar(subjID) == 0
    error('subj_ID must be a string')
end


dataDir = [filesep OUTPUT_FOLDER filesep];

if ~exist(OUTPUT_FOLDER, 'dir')
    mkdir(OUTPUT_FOLDER);
end

subject_output = [rootDir dataDir expt_name '_' subjID '_list' num2str(list)];
subject_output_file = [subject_output '.csv'];


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
        trial_onset = previous_run.trial_onset;
        final_audio_filename = previous_run.final_audio_filename;
        final_audio_transcript = previous_run.final_audio_transcript;
        final_condition = previous_run.final_condition;
        final_list = previous_run.final_list;
        audio_ended = previous_run.audio_ended;
        pressed_space_to_continue = previous_run.pressed_space_to_continue;
        trial_completed = previous_run.trial_completed;
        resume_number = previous_run.resume_number;
        date_time_info = previous_run.date_time_info;
        
        NUM_STIMULI = height(previous_run);
        

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
            
            subject_output_file = [subject_output '_resume' num2str(current_resume_number) '.csv'];
            
            fprintf('Resuming list %d at trial % \n', list, start);
        else
            % get materials for this set
            load('all_stimuli.mat')

            stimuli_idx = all_stimuli.list == num2str(list);
            stimuli = all_stimuli(stimuli_idx,:);

            NUM_STIMULI = height(stimuli);

            final_audio_filename = stimuli.filename;
            final_audio_transcript = stimuli.stim_transcript;
            final_condition = stimuli.condition;
            final_list = stimuli.list;

            %set the start at the beginning, not resumed
            start = 1; 

            %initialize arrays for output
            trial_onset = zeros(NUM_STIMULI,1);
            audio_ended = zeros(NUM_STIMULI,1);
            pressed_space_to_continue = zeros(NUM_STIMULI,1);
            trial_completed = zeros(NUM_STIMULI,1);
            resume_number = zeros(NUM_STIMULI,1);
            date_time_info = zeros(NUM_STIMULI,1);
            
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
    load('all_stimuli.mat','all_stimuli')

    stimuli_idx = all_stimuli.list == num2str(list);
    stimuli = all_stimuli(stimuli_idx,:);
    
    NUM_STIMULI = height(stimuli);

    final_audio_filename = stimuli.filename;
    final_audio_transcript = stimuli.stim_transcript;
    final_condition = stimuli.condition;
    final_list = stimuli.list;
    
    %set the start at the beginning, not resumed
    start = 1; 
    current_resume_number = 0;
    
    %initialize arrays for output
    trial_onset = zeros(NUM_STIMULI,1);
    audio_ended = zeros(NUM_STIMULI,1);
    pressed_space_to_continue = zeros(NUM_STIMULI,1);
    trial_completed = zeros(NUM_STIMULI,1);
    resume_number = zeros(NUM_STIMULI,1);
    date_time_info = zeros(NUM_STIMULI,1);

    
end



%% variables to change
INSTRUCTIONS = 'Listen attentively to the sentences. \n\nPress the spacebar to hear the next sentence.';
STIMULI_AUDIO = [ filesep 'stimuli' filesep 'norm_endfix_filt_'];

%color variables
WHITE = [255 255 255];
BLACK = [64 64 64];
GREY = [134 136 138];

%these two arrays correspond to each other
KbName('UnifyKeyNames');
key_mapping = ["1", "2"];
trigger_response_keys = [KbName('1!'), KbName('2@')];
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

[windowPtr,rect]=PsychImaging('OpenWindow',screenNumber, GREY); %, [0 0 1440 900]
[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr);
oldTextSize = Screen('TextSize',windowPtr,50);


% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(rect);

priorityLevel = MaxPriority(windowPtr);
Priority(priorityLevel);


%% Present instructions %%

DrawFormattedText(windowPtr, 'Welcome! \n\n Press Enter to begin', 'center', 'center', 0);
Screen('Flip', windowPtr);

%HideCursor;

triggerKey = enterKey;
while 1
    [keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
    if keyCode(escapeKey)
        Screen('CloseAll');
        fprintf('Experiment quit by pressing ESCAPE\n');
        break;
    elseif ismember(find(keyCode,1), triggerKey)        % used to be: keyCode(KbName(triggerKey))
        break;
    end
    WaitSecs(0.001);
end

% present instructions
DrawFormattedText(windowPtr, ['\n\n' INSTRUCTIONS ], 'center', 'center', 0);
DrawFormattedText(windowPtr, 'Press the spacebar when you are ready to begin', 'center', screenYpixels .* 0.85,  0);
Screen('Flip', windowPtr);
WaitSecs(0.5); %some buffer time for key press to work
triggerKey = spaceBar;
while 1
    [keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
    if keyCode(escapeKey)
        Screen('CloseAll');
        fprintf('Experiment quit by pressing ESCAPE\n');
        break;
    elseif ismember(find(keyCode,1), triggerKey)        % used to be: keyCode(KbName(triggerKey))
        break;
    end
    WaitSecs(0.001);
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

for j =start:NUM_STIMULI

    t = now; 
    date_time = datetime(t,'ConvertFrom','datenum');
    
%    date_time_info(j,1) = date_time;
    trial_onset(j,1) = GetSecs() - startTime; %save the onset time of the trial
    %go to grey screen
    Screen(windowPtr, 'Flip');
    
    %PLAY AUDIO
    %% Set audio  %%
    stimuli = final_audio_filename(j,1); %get stimuli ID
    condition = final_condition{j,1};
    repeat_trigger = 0;
    if(condition == "sentence")
        cond_trigger = 1;
    elseif(condition == "sentence_repeat")
        cond_trigger = 1;
        repeat_trigger = 1;
    elseif(condition == "nonword")
        cond_trigger = 0;
    end
    
    
    theFile = string(strcat(rootDir ,STIMULI_AUDIO ,stimuli)); %get the current audio file
    [y, freq] = audioread(theFile);
    wavedata = y';
    nrchannels = size(wavedata,1); % Number of rows == number of channels
    audioDur = length(y)/freq;
    
    pahandle = PsychPortAudio('Open', [], [], 1, freq, nrchannels);
    % Open the default audio device [], with default mode [] (==Only playback),
    % and a required latencyclass of zero 0 == no low-latency mode, as well as
    % a frequency of freq and nrchannels sound channels.
    % This returns a handle to the audio device:
    PsychPortAudio('FillBuffer', pahandle, wavedata);
    % Fill the audio playback buffer with the audio data 'wavedata':
    PsychPortAudio('Start', pahandle, 1, 0, 1);
    timeLimit = audioDur;
    
    %SEND START AUDIO TRIGGER
    TriggerCode = zeros(1,8);
    TriggerCode(start_expt) = 1;
    TriggerCode(start_audio) = 1;
    TriggerCode(condition_idx) = cond_trigger;
    TriggerCode(repeat) = repeat_trigger;
    TriggerCode(end_audio) = 0;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    
    %wait for audio to finish
    WaitSecs(timeLimit);
    stimuli_end_time = GetSecs();
    audio_ended(j,1) = stimuli_end_time-startTime;
    
    %SEND END AUDIO TRIGGER
    TriggerCode = zeros(1,8);
    TriggerCode(start_expt) = 1;
    TriggerCode(start_audio) = 0;
    TriggerCode(condition_idx) = cond_trigger;
    TriggerCode(repeat) = repeat_trigger;
    TriggerCode(end_audio) = 1;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    
    trial_completed(j,1) = 1;
    resume_number(j,1) = current_resume_number;
    
    
    DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
    DrawFormattedText(windowPtr, '(Press space to continue)', 'center', screenYpixels.*0.60, 0);
    Screen(windowPtr, 'Flip');
    
    %wait for response to continue with task
    triggerKey = trigger_response_keys; %determined at top of script
    response_period_start = GetSecs;
    
    while 1 %wait for max 3 seconds before continuing
        [keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
        if keyCode(escapeKey)
            Screen('CloseAll');
            fprintf('Experiment quit by pressing ESCAPE\n');
            break;
        elseif ismember(find(keyCode,1), spaceBar)
            %index = find(triggerKey == find(keyCode,1));
            pressed_space_to_continue(j,1) = 1; % continued by the participant pressing, not automatic
            %RT(j, 1) = seconds - stimuli_end_time;
            break;
        end
        WaitSecs(0.001);
    end
    
    %record output for every trial
    trial = [1:NUM_STIMULI]';
        
    output = table(final_list, trial, trial_onset, final_audio_filename, final_condition, final_audio_transcript, audio_ended, pressed_space_to_continue, trial_completed,resume_number);
    writetable(output, subject_output_file, 'WriteVariableNames', true)
    
end

%SEND END EXPT TRIGGER
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
Screen('Flip', windowPtr);
WaitSecs(0.5);

triggerKey = enterKey;

while 1
    [keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
    if keyCode(escapeKey)
        Screen('CloseAll');
        fprintf('Experiment quit by pressing ESCAPE\n');
        break;
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

