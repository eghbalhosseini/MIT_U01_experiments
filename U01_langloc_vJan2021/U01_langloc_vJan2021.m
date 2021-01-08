% Created by: Hannah Small, for aphasia project in Ev Federenko's lab
% 08/26/2019 --- MODIFIED for ecog project 01/10/2020 by Hannah Small
% updated 12/23/2020 for U01 ecog experiments

% This is a language localizer experiment with two conditions: sentences,
% and nonword lists. Each trial contains a list of 12 words or nonwords and
% a memory probe. The memory probe is either a word from the
% the preceding list or a word that did not show in the list at all.
% The subject must indicate if the word was present by pressing '1' or that
% the word was not present by pressing '2'.
% The purpose of the memory probe is the keep the subject alert and reading
% each word of the list.

% Every 8 trials there is an optional break. Press space to continue the
% task

% The materials are prepared when prepstim() is run, including the
% 20 sentences and 20 nonword lists, the orders of the conditions and their
% onset times, the memory probes (correct and incorrect), and the order of
% the probe presentation.
% prepstim() should be run before this experiment is run if there is no
% materials.mat present.
%
% The order is pseudorandom, with no more than 3 of sentences or nonwords
% being showed consecutively.

%Each trial will be structured as follows (8s total):
%200ms fixation
%each word/nonword presented for 400ms for the total stim duration of 400x12=4.8s
%200ms fixation
%1000ms probe presentation (in a different color)
%600ms extra time to answer (they can answer as soon as the probe appears and until the end of the trial)
%6.8 seconds per trial

%total time without breaks is 6.8x40 = 272s -- 4 min 32 s.


%-subject ID (a string)
%-subset of the materials to use (1-3)
%-run (1-3,


function U01_langloc_vJan2021(subjectID, set, run_number)

%Creating the output file for this subject
rootDir=pwd();
if exist([rootDir filesep 'output'], 'dir')
    %do nothing
else
    mkdir ('output');
end

save_path = [rootDir filesep 'output' filesep];
expt_name = 'U01_langloc_vJan2021';

%handle duplicate filename, and other checks
if ischar(subjectID) == 0
    error('subj_ID must be a string')
end

dataFile_csv = [save_path  (strcat(expt_name,'_',subjectID,'_run',num2str(run_number))) '.csv'];

if exist(dataFile_csv,'file')
    previous_run = readtable(dataFile_csv);
    
    %determine if this run was finished
    num_completed = sum(previous_run.trial_completed == 1);
    num_trials = length(previous_run.trial);
    
    if num_completed < num_trials
        choice = str2num(input(['\nThis subject has partially completed this list.\nPress 1 to resume that run. Press 2 to restart the run.\n'],'s'));
    else
        error(['This subject has completed this list. Please enter a different subject ID or list.']);
    end
    
    if choice == 1 || choice == 2
        trial_onset = previous_run.trial_onset;
        final_audio_filename = previous_run.final_audio_filename;
        final_audio_transcript = previous_run.final_audio_transcript;
        final_condition = previous_run.final_condition;
        final_list = previous_run.final_list;
        pressed_space_to_continue = previous_run.pressed_space_to_continue;
        trial_completed = previous_run.trial_completed;
        resume_number = previous_run.resume_number;
        
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
            
            fprintf('Resuming set %d at trial %', set, start);
        else
            fprintf('Restarting set %d', set);
            
        end
        
        
    else %input was anything other than 1 or 2
        error('Unrecognized input. Press 1 to resume, press 2 to restart. Exiting.');
    end
    
else
    % no output file for this subject for this list yet
    % run the full list
    
    % get materials for this set
    load('materials.mat')
    
    %run practice run
    if (run_number == 0)
        stimuli = materials.practice_run;
    else
        stimuli = materials.(['run' num2str(set)]);
    end
    
    NUM_STIMULI = height(stimuli);
    
    %set the start at the beginning, not resumed
    start = 1;
    current_resume_number = 0;
    
    output = stimuli; %save template to save output on
    
end




%input checks
if set > 3 || set < 0
    error('USE: U01_langloc_vJan2021(subjectID, set, run_number) -- set must be between 1 and 3')
end


%Trigger codes
ExpStart = 1;
ExpEnd = 2;
Cond = 3;
CodedWords = 4:8;
CodeMap={'0ms: fixation 200ms 13 01101',...
    '200ms: word1 500ms 1	00001',...
    '700ms: word2 500ms 2	00010',...
    '1200ms: word3 500ms 3	00011',...
    '1700ms: word4 500ms 4	00100',...
    '2200ms: word5 500ms 5	00101',...
    '2700ms: word6 500ms 6	00110',...
    '3200ms: word7 500ms 7	00111',...
    '3700ms: word8 500ms 8	01000',...
    '4200ms: word9 500ms 9	01001',...
    '4700ms: word10 500ms 10	01010',...
    '5200ms: word11 500ms 11	01011',...
    '5700ms: word12 500ms 12	01100',...
    '6200ms: fixation 200ms 14	01110',...
    '6400ms: probe 1000ms 16	10000',...
    '7400ms: extra time to answer 600ms 15	01111'};
IDValues=[13 1:12 14 16 15]';
CodedValues={'01101',...
    '00001',...
    '00010',...
    '00011',...
    '00100',...
    '00101',...
    '00110',...
    '00111',...
    '01000',...
    '01001',...
    '01010',...
    '01011',...
    '01100',...
    '01110',...
    '10000',...
    '01111'};


%Psychtoolbox setup
PsychDefaultSetup(2);

%   prepare for movie playing
oldLevel = Screen('Preference', 'Verbosity', 0);
java; %clear java cache
AssertOpenGL;
Screen('Preference', 'VisualDebugLevel',    0);
Screen('Preference', 'SuppressAllWarnings', 1);
Screen('Preference', 'TextRenderer',        0);% Setting this preference to 1 suppresses the printout of warnings.
Screen('Preference', 'SkipSyncTests',       1);

Screen('CloseAll')

screensAll = Screen('Screens'); %Get the screen numbers
screenNumber = max(screensAll); % Which screen you want to use. "1" is external monitor, "0" is this screen. use external if it is present

if(exist('materials.mat', 'file') == 0)
    prepstim(); % also need to run this if materials in excel file have changed!! otherwise should already be in the current directory
end
load ('materials.mat'); %import the materials that prepstim() creates

%define colors
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
blue = [0 0 1];

KbName('UnifyKeyNames');
spaceBar = KbName('space');
escapeKey = KbName('escape');

key_mapping = ["1", "2"];
trigger_response_keys = [KbName('a'), KbName('s')];
triggerKey = trigger_response_keys;


% Open screen.
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white); %, [0 0 640 480]

%HideCursor;

Screen('TextSize', window, 80);
Screen('TextFont', window, 'Arial');
Screen('TextStyle', window, 0);

% Wait for scanner
DrawFormattedText(window, 'Press SPACE to begin', 'center', 'center', black);
Screen('Flip', window);


while 1
    FlushEvents();
    key = GetChar();
    if key == '' % escape
        PsychPortAudio('Close');
        Screen('CloseAll');
        ShowCursor;
        error('Experiment quit using ESCAPE');
    elseif key == ' ' % space
        break
    end
    
    WaitSecs(0.001)
end

word_time = 0.400; %seconds

on = GetSecs;

stim_onsets = cell2mat(stimuli.planned_onset);
onsets = on + stim_onsets;

firstT=0;
startTask = GetSecs;
ind =1;
%go through the experiment, evaluating if condition is fixation or a list
%of words followed by a memory probe


% TRIGGER start of experiment


for i = start:NUM_STIMULI
    
    if(mod(ind, 8) == 0) %give a rest every 8 trials
        ind = 1;
        DrawFormattedText(window, 'Take a break \n\n Press the spacebar to continue', 'center', 'center', black);
        Screen('Flip', window, onsets(i));
        
        while 1
            [keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
            if keyCode(escapeKey)
                Screen('CloseAll');
                
                writetable(output, dataFile_csv, 'WriteVariableNames', true);

                WaitSecs(2);
                error('Experiment quit by pressing ESCAPE\n');
            elseif ismember(find(keyCode,1), spaceBar)
                break;
            end
            WaitSecs(0.001);
        end
        
    end
    
    pres = table2array(stimuli(i,5:16)); %words1-12 from stimuli
    
    if pres{1} == '+'       
        DrawFormattedText(window, '+', 'center', 'center', black);
        Screen('Flip', window, onsets(i));
        onset_time = GetSecs() - startTask;
        output{i, 'actual_onset'} = {onset_time};
        % 1 second fixation
    else
        %pre-stimuli fixation 200 ms
        DrawFormattedText(window, '', 'center', 'center', white);
        Screen('Flip', window,onsets(i));
        onset_time = GetSecs() - startTask;
        output{i, 'actual_onset'} = {onset_time};

        %TRIGGER first fixation (last 5 bits are ID #13)

        WaitSecs(0.200);

        %present each word, in all uppercase
        for j = 1:length(pres)

            w = char(pres(j));

            DrawFormattedText(window, upper(w), 'center', 'center', black);
            Screen('Flip', window);


            %% SEND WORD TRIGGERS HERE %%
            % each word (j) corresponds to the ID #
            % ie word3 is ID# 3 for the last 5 bits


            WaitSecs(word_time); %present each word for 500 ms
            diff = GetSecs-on-firstT;
            firstT=GetSecs-on;

            [~, ~, keyCode] = KbCheck(-1);

            if keyCode(escapeKey)
                %save all info first
                writetable(output, dataFile_csv, 'WriteVariableNames', true);

                Screen('CloseAll');
                WaitSecs(2); %time to finish saving and closing screen
                error('Experiment quit by pressing ESCAPE\n');

            end

        end

        %memory probe
        %pre-probe interval (200 ms), probe (1000 ms)and post-probe interval (600 ms)

        DrawFormattedText(window, '', 'center', 'center', white);
        Screen('Flip', window);
        %TRIGGER second fixation (last 5 bits are ID #14)


        WaitSecs(0.200); %pre-probe for 200 ms

        probe = cell2mat(table2array(stimuli(i, 'probe')));

        %set up the display of the probe
        DrawFormattedText(window, probe, 'center', 'center', blue);
        Screen('Flip', window);
        %TRIGGER probe (last 5 bits are ID #16)

        %pressed = 0;
        response = NaN;
        rt = NaN;
        response_period_start = GetSecs;

        while GetSecs < response_period_start + 1.6 %probe for 1.6 seconds (1s + post probe 0.6 s)
            [~, ~, keyCode] = KbCheck(-1);

            if ismember(find(keyCode,1), triggerKey)
                index = find(triggerKey == find(keyCode,1));
                response(1,1) = key_mapping(index); % output determined by key_mapping at top of script
                rt = GetSecs - response_period_start;

                output(i,'response') = response;
                output(i,'RT') = rt;
                %             end
            end

            if keyCode(escapeKey)
                %save all info first
                writetable(output, dataFile_csv, 'WriteVariableNames', true);

                Screen('CloseAll');
                WaitSecs(2)
                fprintf('Experiment quit by pressing ESCAPE\n');
                break;
            end

            if(GetSecs > response_period_start + 1) %don't show probe after 1 s but still allow a response

                %TRIGGER extra time to respond (last 5 bits are ID #15)

                DrawFormattedText(window, '' , 'center', 'center', white);
                Screen('Flip', window);
            end

        end
    end
    
    %save on each trial in case something goes wrong
    writetable(output, dataFile_csv, 'WriteVariableNames', true);
    
end

[keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
if keyCode(escapeKey)
    %save all info first
    writetable(output, dataFile_csv, 'WriteVariableNames', true);
    
    Screen('CloseAll');
    WaitSecs(2);
    error('Experiment quit by pressing ESCAPE\n');
end
% TRIGGER end of experiment



EntireTime = GetSecs - startTask
sca;

%clear the keyboard
KbQueueRelease();
KbReleaseWait();

end %- for the function









