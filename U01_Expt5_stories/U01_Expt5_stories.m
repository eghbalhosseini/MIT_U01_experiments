%%% This experiment plays audio of a story while showing a fixation screen.
% There are two silent fixations of 10 seconds at the beginning and end of
% the story.

% Questions follow the story. 'A' is used to select A and 'S' is used to select B.

% There should be a folder called 'stimuli' in the current directory that
% stores all of the audio files (10 stories) that this scripts accesses
%
% For MGH studies, only stories 2,4,5,6,7,8,9 are available
% all stories should be run and story 5 should be run twice (on different days)

%%% Author: Idan Blank (based on codes by Eyal Decther, Jason Fischer)
%%% Edit: Alex Paunov: added Tree stim: auditory, verbal, meaningful, non-social
%%% Edit: Alex Paunov: added Jeanne stim (dialogue): auditory, verbal, meaningful, social
%%% Edit: Alex Paunov: fixed IPS issue: auditory, verbal, meaningful, social
%%% Edit: Hannah Small: fixation durations to be 12 seconds for the aphasia
%%% Edit: Hannah Small: modified to all naturalistic stories for ECOG data
%%% collection -- 01/10/2020

% Date: 12/23/2020


%%% subjID =  subject id
function U01_Expt5_stories(cfg)

subjID = cfg.SUBJECT;
run = cfg.RUN_ID;
send_triggers = cfg.SEND_TRIGGERS; %false when testing without actual trigger machine

StoryOrder = [5,2,8,4,7,6,9,5]; %hardcoding story order 
storynum = StoryOrder(run);
rootDir=cfg.PATH_LOG;

dataDir = [cfg.PATH_LOG filesep];
dataFile_mat = cfg.MAT_FILENAME;
dataFile = cfg.EVENT_FILENAME;

%% Initialize Variables

%Trigger codes
Audio =     2;
Fixation =  3;
Question =  4;
Response =  5;

% Create empty structure.
TrialStruct = struct();
if(send_triggers)
    TrialStruct = Setup_DAQ_Stim(TrialStruct);
end


%check parameters
if ischar(subjID) == 0
    error('subj_ID must be a string')
end

possible_stories = [2,4,5,6,7,8,9];

if ~ismember(storynum,possible_stories)
    error('storynum must be one of these values: 2,4,5,6,7,8,9');
end


stimDir = [pwd() filesep 'stimuli' filesep];       % path to where the stimuli are saved
theFile = [num2str(storynum) '_48000.wav']; %use 48 kH version to play nice with PsychPortAudio
expt_name = 'U01_Expt5_stories';

%these two arrays correspond to each other

key_mapping = ['a', 'b'];
trigger_response_keys = [KbName('1!'), KbName('2@')];

%% Check that the stimulus exists %%
if ~exist([stimDir, theFile],'file')
    disp(['Warning: ', stimDir, theFile, ' is missing.'])
    return
end

%% Durations %%
pretrialFixDur = 1;  % in seconds
posttrialFixDur = 1; % in seconds

%% Other variables %%
KbName('UnifyKeyNames');
fixationSize = 2;   % in degrees
pixPerDeg = 60;     % pixels per degree
stimFontSize = .8;  % in degrees
screenNum = 0;
escapeKey = KbName('ESCAPE');
%escapeKey = KbName('esc');


%% generate stimulus sets %%
stimulusSet = {};

pretrial_stim = struct();
pretrial_stim.type = 'pretrial';
stimulusSet{end+1} = pretrial_stim;


audio_stim = struct();
audio_stim.file = [stimDir, theFile];
audio_stim.type = 'audio';
stimulusSet{end+1} = audio_stim;


posttrial_stim = struct();
posttrial_stim.type = 'posttrial';
stimulusSet{end+1} = posttrial_stim;



%final_stim = struct();
%final_stim.type = 'end run';
%stimulusSet{end+1} = final_stim;

nStimuli = length(stimulusSet);

%% Create / open a file for saving the results %%
timing = zeros(nStimuli,1); % timing of different events in the experiment

if exist(dataFile_mat,'file')
    overwrite = input('A file is already saved with this name. Overwrite? (y/n): ','s');
    if overwrite == 'y' %do nothing
    else %anything besides 'y', input new name
        run = input('Enter a new run number: ','s');
    end
end

fid = fopen(dataFile, 'a');


%% Initialize Window %%
%   prepare for movie playing
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

GREY = 0.6;

[windowPtr,rect]=PsychImaging('OpenWindow',screenNumber, GREY); %, [0 0 640 640]

priorityLevel = MaxPriority(windowPtr);
Priority(priorityLevel);
Screen('TextFont',windowPtr, 'Helvetica');
Screen('TextSize',windowPtr, stimFontSize*pixPerDeg);

%% Load stimulus %%

[y, freq] = audioread([stimDir, theFile]);
wavedata = y';
nrchannels = size(wavedata,1); % Number of rows == number of channels
audioDur = length(y)/freq;
InitializePsychSound; % Perform basic initialization of the sound driver:
pahandle = PsychPortAudio('Open', [], [], 1, [], nrchannels);
% Open the default audio device [], with default mode [] (==Only playback),
% and a required latencyclass of zero 0 == no low-latency mode, as well as
% a frequency of freq and nrchannels sound channels.
% This returns a handle to the audio device:
PsychPortAudio('FillBuffer', pahandle, wavedata);
% Fill the audio playback buffer with the audio data 'wavedata':

%% Load questions
data = readtable('Natural_Stories_Questions_Answers.xlsx');

storyNumbers = data{:, 'StoryNum'};
questions = data{:, 'Question'};
answerA = data{:, 'AnswerA'};
answerB = data{:, 'AnswerB'};
correctAnswer = data{:, 'CorrectAnswer'};

pres_questions = [];
pres_answersA = [];
pres_answersB = [];
pres_correctAnswers = [];

done = 0;

for i = 1:length(storyNumbers)
    j = i;
    index = 0;
    while (storyNumbers(j,1) == storynum)
        index = index + 1;
        pres_questions{index,1} = questions{j,:};
        pres_answersA{index,1} = answerA{j,:};
        pres_answersB{index,1} = answerB{j,:};
        pres_correctAnswers{index,1} = correctAnswer{j,:};
        done = 1;
        j = j+1;
    end
    
    if(done == 1)
        break;
    end
end


%% Wait for trigger %%

DrawFormattedText(windowPtr, 'You will listen to a story and then answer questions about the story. \n\nPress SPACE to begin', 'center', 'center', 0);
Screen('Flip', windowPtr);

% while 1
%     FlushEvents();
%     key = GetChar();
%     if key == '' % escape
%         PsychPortAudio('Close');
%         Screen('CloseAll');
%         ShowCursor;
%         error('Experiment quit using ESCAPE');
%     elseif key == ' ' % space
%         break
%     end
%     WaitSecs(0.001);
% end

[~, keyCode] = KbWait([], 2);
if any(ismember(find(keyCode),escapeKey))
    Screen('CloseAll');
    ShowCursor;
    error('Experiment quit using ESCAPE');
end

%% Experiment %%
expStartTime = GetSecs();
tic

current = 0;        % current event in stimulusSet
moveToNext = 1;     % move to next event?
checkTiming = 0;    % check how much time has passed

while current < nStimuli
    if moveToNext
        current = current + 1;
         switch stimulusSet{current}.type
            case 'pretrial'
                
                % send fixation trigger
                TriggerCode = zeros(1,8);
                TriggerCode(Fixation) = 1;
                if(send_triggers)
                    SendTrigger( TrialStruct, TriggerCode )
                end
                
                
                DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
                Screen('Flip',windowPtr);
                eventStart = GetSecs();
                timing(current) = eventStart;
                moveToNext = 0;
                timeLimit = pretrialFixDur;
                checkTiming = 1;
            case 'audio'
                
                % TRIGGER BEGINNING OF AUDIO
                TriggerCode = zeros(1,8);
                TriggerCode(Fixation) = 1;
                TriggerCode(Audio) = 1;
                if(send_triggers)
                    SendTrigger( TrialStruct, TriggerCode )
                end

                
                DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
                Screen('Flip',windowPtr);
                eventStart = PsychPortAudio('Start', pahandle, 1, 0, 1);
                timing(current) = eventStart;
                timeLimit = audioDur;
                moveToNext = 0;
                checkTiming = 1;
            case 'posttrial'
                PsychPortAudio('Close');
                
                % TRIGGER END OF AUDIO
                TriggerCode = zeros(1,8);
                TriggerCode(Fixation) = 1;
                TriggerCode(Audio) = 0;
                if(send_triggers)
                    SendTrigger( TrialStruct, TriggerCode )
                end
                
                
                DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
                Screen('Flip',windowPtr);
                eventStart = GetSecs();
                timing(current) = eventStart;
                moveToNext = 0;
                timeLimit = posttrialFixDur;
                checkTiming = 1;
                
        end
    end
    if checkTiming
        if (GetSecs() - eventStart) > timeLimit
            moveToNext = 1;
        else
            WaitSecs(0.001);
        end
    end
    [keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
    
    % If the user is pressing a key, then display its code number and name.
    if keyIsDown
        % Note that we use find(keyCode) because keyCode is an array; see 'help KbCheck'
        key_name = KbName(keyCode);
        if keyCode(escapeKey)
            
             newTiming = cell(length(timing),2);
            for i = 1:length(timing)
                fprintf(fid, '%s %f\n', stimulusSet{i}.type, timing(i)-expStartTime);
                newTiming{i,1} = stimulusSet{i}.type;
                newTiming{i,2} = timing(i)-expStartTime;
            end
            
            fprintf(fid,'\n');
            fclose(fid);
            timing = newTiming;
            save(dataFile_mat, 'timing');
            
            Screen('CloseAll');
            
            PsychPortAudio('Close');
            WaitSecs(2); %time for things to close before quitting
            
            error('Experiment quit by pressing ESCAPE\n');
            break
        end
    end
    
end


%% TRIGGER END OF FIXATION
TriggerCode = zeros(1,8);
TriggerCode(Fixation) = 0;
TriggerCode(Audio) = 0;
if(send_triggers)
    SendTrigger( TrialStruct, TriggerCode )
end


%% display the questions
triggerKey = trigger_response_keys;
response = strings(length(pres_questions),1);
accuracy = zeros(length(pres_questions),1);
RT = response;
item = cell(length(pres_questions),1);
for i = 1:length(pres_questions)
    WaitSecs(1);
    DrawFormattedText(windowPtr, [pres_questions{i} '\n\n1. ' ...
        pres_answersA{i} '\n\n2. ' pres_answersB{i}], 'center', 'center', 0);
    Screen('Flip', windowPtr);
    stimuli_pres = GetSecs();
    
    %TRIGGER QUESTION
    TriggerCode = zeros(1,8);
    TriggerCode(Fixation) = 0;
    TriggerCode(Audio) = 0;
    TriggerCode(Question) = 1;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
   
    
    item{i} = i;
    
    while 1
        [keyIsDown, seconds, keyCode] = KbCheck(-3);        % -3 = check input from ALL devices
        if keyCode(escapeKey)
            
            output = table(item, pres_questions, pres_answersA, pres_answersB, pres_correctAnswers, response, RT);
            writetable(output, dataFile, 'WriteVariableNames', true)
            
            newTiming = cell(length(timing),2);
            for i = 1:length(timing)
                fprintf(fid, '%s %f\n', stimulusSet{i}.type, timing(i)-expStartTime);
                newTiming{i,1} = stimulusSet{i}.type;
                newTiming{i,2} = timing(i)-expStartTime;
            end
            
            fprintf(fid,'\n');
            fclose(fid);
            timing = newTiming;
            eval(['save ', [dataDir expt_name '_story' num2str(storynum) '_' subjID '_run' num2str(run)], ' timing']);
            
            Screen('CloseAll');
            WaitSecs(2)
            error('Experiment quit by pressing ESCAPE\n');
            break;
        elseif ismember(find(keyCode,1), triggerKey)
            index = find(triggerKey == find(keyCode,1));
            response(i,1) = key_mapping(index); % output determined by key_mapping at top of script
            RT(i, 1) = seconds - stimuli_pres;
            DrawFormattedText(windowPtr, '', 'center', 'center', 0);
            Screen('Flip', windowPtr);
            break;
        end
        WaitSecs(0.001);
    end
    
    %TRIGGER RESPONSE TO QUESTION
    TriggerCode = zeros(1,8);
    TriggerCode(Fixation) = 0;
    TriggerCode(Audio) = 0;
    TriggerCode(Question) = 1;
    TriggerCode(Response) = 1;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    
    if(response(i,1) == pres_correctAnswers(i,1))
        accuracy(i,1) = 1;
    end

    output = table(item, pres_questions, pres_answersA, pres_answersB, pres_correctAnswers, response, RT, accuracy);
    writetable(output, dataFile, 'WriteVariableNames', true)
    
    %TRIGGER END
    
    TriggerCode = zeros(1,8);
    TriggerCode(Fixation) = 0;
    TriggerCode(Audio) = 0;
    TriggerCode(Question) = 0;
    TriggerCode(Response) = 0;
    if(send_triggers)
        SendTrigger( TrialStruct, TriggerCode )
    end
    
end

timing(current) = GetSecs();
fprintf('Total Run Time in Seconds: %f\n', toc);
Screen('CloseAll');

%% Save timing %%
newTiming = cell(length(timing),2);
for i = 1:length(timing)
    fprintf(fid, '%s %f\n', stimulusSet{i}.type, timing(i)-expStartTime);
    newTiming{i,1} = stimulusSet{i}.type;
    newTiming{i,2} = timing(i)-expStartTime;
end

fprintf(fid,'\n');
fclose(fid);
timing = newTiming;
save(dataFile_mat, 'timing');

Priority(0);


end %main function
