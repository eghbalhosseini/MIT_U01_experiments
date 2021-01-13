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
data = readtable('final_stimuli.xlsx');
%,'DataRange','A2','VariableNamesRange','A1');

STIMULI_AUDIO = [filesep 'stimuli' filesep 'norm_endfix_filt_'];

nonword_idx = strcmp(data.condition, 'nonword');
nonwords = data(nonword_idx,:);

sentence_idx = strcmp(data.condition,'sentence');
sentences = data(sentence_idx,:);

NUM_NONWORDS = height(nonwords);
NUM_SENTENCES = height(sentences);

NUM_STIMULI = NUM_NONWORDS + NUM_SENTENCES;

%% Check that the audio exists %%
for stim_counter = 1:NUM_STIMULI
    current_filename = char(table2array(data(stim_counter,'filename')));
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

v_names = [string(data.Properties.VariableNames), "list"];
table_size = [224 7]; 
v_types = ["string", "string", "string", "string", "string","string","string"];

all_stimuli = table('Size',table_size,'VariableNames',v_names,'VariableType',v_types);

n_per_list = 54; %50 sentences + 4 nonwords
list_counter = 1;
list = 1;
save_two_sentences = 1;
repeat_sentences = table('Size',[2 7],'VariableNames',v_names,'VariableType',v_types);

NUM_STIMULI = NUM_STIMULI+8; %adding the repeats
stim_counter = 1;

% follow this pattern: [10 sentences] [nonword string] ... [10 sentences]
% and split into 4 lists (each lists begins and ends with 10 sentences)
while stim_counter <= NUM_STIMULI
    %update the list if necessary
    %add 2 repeats from the first 10 sentences of that list
    %reset the sentence_batch_counter
    %reset the save_two_sentences switch so we save 2 sentences in the next
    %list
    if list_counter > n_per_list
        all_stimuli(stim_counter:stim_counter+1,1:6) = repeat_sentences(1:2,1:6);
        all_stimuli(stim_counter,'list') = {list};
        all_stimuli(stim_counter+1,'list') = {list};
        stim_counter = stim_counter +2; %skip ahead since we added two this time
        list = list + 1;
        list_counter = 1;
        sentence_batch_counter = 1;
        save_two_sentences = 1;
    else
   
        if sentence_batch_counter <= 10

            %save two sentences from the first finished batch of 10
            if sentence_batch_counter == 10 && save_two_sentences
                indices = randsample(9,2,false);
                repeat_sentences(1,1:6) = all_stimuli(stim_counter-indices(1),1:6);
                repeat_sentences(2,1:6) = all_stimuli(stim_counter-indices(2),1:6);
                repeat_sentences
                save_two_sentences = 0;
            end

            currentID = sentence_order(sentence_counter,1);
            sentence_batch_counter = sentence_batch_counter + 1;
            sentence_counter = sentence_counter + 1;
            all_stimuli(stim_counter,1:6) = sentences(currentID,1:6);
            all_stimuli(stim_counter,'list') = {list};
            list_counter = list_counter + 1;
            stim_counter = stim_counter + 1;
        else
            currentID = nonword_order(nonword_counter,1);
            nonword_counter = nonword_counter + 1;
            all_stimuli(stim_counter,1:6) = nonwords(currentID,1:6);
            all_stimuli(stim_counter,'list') = {list};
            sentence_batch_counter = 1;
            list_counter = list_counter + 1;
            stim_counter = stim_counter +1;
        end
    end
    
    
end

save('all_stimuli.mat', 'all_stimuli')


