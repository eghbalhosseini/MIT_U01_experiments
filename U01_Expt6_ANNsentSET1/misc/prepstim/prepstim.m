% We will divide the sentences into 4 runs of 50 sentences each. 
% I think we should “fix" the sets so that the sentences are always split 
% into 4 sets in the same way. I also suggest that we create one random 
% order of sentences for each set and use that for everyone (we can vary 
% the order of runs across participants). At the end of each run, I would 
% like to repeat two of the sentences from the run (again, always the same
% across participants). Finally, I would like to embed 4 nonword strings 
% into each run.

% Let’s have the structure of each run be:
% 
% [10 sentences] [nonword string] [10 sentences] [nonword string] 
% [10 sentences] [nonword string] [10 sentences] [nonword string]
% [10 sentences] [2 repeat sentences, both from the first subset]

%generate materials for the auditory task
rootDir = pwd();
opts = detectImportOptions('final_stimuli.xlsx');
data = readtable('final_stimuli.xlsx','DataRange','A2','VariableNamesRange','A1');

STIMULI_AUDIO = '/stimuli/';

nonword_idx = strcmp(data.condition, 'nonword');
nonwords = data(nonword_idx,:);

sentence_idx = strcmp(data.condition,'sentence');
sentences = data(sentence_idx,:);

NUM_NONWORDS = height(nonwords);
NUM_SENTENCES = height(sentences);

NUM_STIMULI = NUM_NONWORDS + NUM_SENTENCES;

%% Check that the audio exists %%
for i = 1:NUM_STIMULI
    current_filename = char(table2array(data(i,'filename')))
    theFile = [rootDir STIMULI_AUDIO current_filename];
    if ~exist(theFile,'file')
        disp(['Warning: ', theFile, ' is missing.'])
        return
    end
end

%create random order of ids
sentence_order = [1:NUM_SENTENCES];
sentence_order = sentence_order(randperm(length(sentence_order)))'; %shuffled ID order

nonword_order = [1:NUM_NONWORDS];
nonword_order = nonword_order(randperm(length(nonword_order)))'; %shuffled ID order

sentence_batch_counter = 1;
sentence_counter = 1;
nonword_counter = 1;

all_stimuli = data;
all_stimuli(:,:) = 0;

% follow this pattern: [10 sentences] [nonword string] ... [10 sentences]
for i = 1:NUM_STIMULI
    %
    if sentence_batch_counter <= 10
        currentID = sentence_order(sentence_counter,1);
        sentence_batch_counter = sentence_batch_counter + 1;
        sentence_counter = sentence_counter + 1;
        all_stimuli(i,:) = sentences(currentID,:);
    else
        currentID = nonword_order(nonword_counter,1);
        nonword_counter = nonword_counter + 1;
        all_stimuli(i,:) = nonwords(currentID,:);
        sentence_batch_counter = 1;
    end
    
    
end

%split into four lists (for the 4 runs)


%add the 2 repeat sentences (from the first 10 sentences) at the end of
%each of the 4 lists



materials = struct;


save('materials.mat', 'materials')