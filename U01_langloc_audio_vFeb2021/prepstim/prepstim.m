% This script preps the stimuli from the materials in an excel file
% 3 sets of 40 trials each (20 S, 20 N)
% 
% This should not be run again - HS 12/23/2020
%create the data structure to hold the stimuli and conditions
materials = struct;

num_sets = 3;
num_trials_per_set = 40;
num_conds = 2;

%store all data from excel file in stimuli (using the nonwords that were
%re-spelled to make them easier to recognize)
data = readtable('all_stimuli_Feb2021_re-spelled.xlsx');
%need make sure to not have the ?paired? sentences and nonword strings appear in the same run.
% To select a probe word, we should use the ?same? word/nonword for the 
% paired stimuli: 30 pairs should have a correct probe, the other 30 pairs
% ? should have a wrong probe. For the correct probes, we should stick to 
% nouns, verbs, adjectives, and adverbs (so stay away from function words)
% ?and the corresponding nonword in the corresponding nonword string ?and 
% have 10 pairs have the probe come from the first 4 words, 10 pairs have 
% the probe come from the second 4 words, and 10 from the last 4 words. 
% 
% We can use the same set of probes as wrong probes by just pairing them 
% with the other stimuli (maybe across runs).

%function words: in, the, a, to, but, an, and, for, not, even?, after?

% 1. determine order (pseudorandom) and assign stimuli to runs
% 2. assign probe_condition within condition in each run (1/2 match, 1/2 not match),
% pseudo random order
% 3. within each probe_conditions, assign probe_source_condition (1-4, 5-8, 9-12)
% 4. generate matching probes, saving the probe_source_index
% 5. copy over the probe_condition, probe_source_condition, and
% probe_source_index to the nonwords
% 6. generate non-word matching probes, using the probe_source_index
% 7. assign nonwords, rotated by one run so as to not have the 'paired'
% sentence and nonword in the same run
% 8. assign non-matching probes by rotating the matching words back one
% run, so that we are using the same set of probes as wrong probes in a
% different run

materials = struct();
all_conditions_met = 0;
tracker = 0;
while(~all_conditions_met)
    tracker = tracker + 1;
    fprintf("probe generations attempt %d\n", tracker);
    sentences = data(data.condition=="sentence",:);
    nonwords = data(data.condition=="nonword",:);

    %generate probe source conditions for the sentences
    probe_source = [ones([1 20]) 2*ones([1 20]) 3*ones([1 20])];
    probe_source_shuffled = probe_source(randperm(length(probe_source)))';
    sentences.probe_source_cond = probe_source_shuffled;

    %% generate the probes for sentences

    %prepare columns 
    sentences.probe_correct_source_index = zeros([60 1]);
    sentences.probe_correct = string(zeros([60 1]));


    function_words = [...
        "he","his","him",...
        "she","her",...
        "they","their",...
        "the","a","to","but","an","and","for","not",...
        "in", "even","after","of", "by", "from","as"...
        ,"at","that","on", "'d", "up","down", "could",...
        "with","about","was","who","when","he'd", "got","also","so","did", "has"];

    for i=1:height(sentences)
        conditions_met = 0;
        while(~conditions_met)
            current_probe_source_cond = sentences.probe_source_cond(i);
            probe = "";
            probe_index = 0;
            if(current_probe_source_cond == 1) % probe from word 1-4
                probe_index = randi([1 4]);
            elseif(current_probe_source_cond == 2)% probe from word 5-8
                probe_index = randi([5 8]);
            elseif(current_probe_source_cond == 3) % probe from word 9-12
                probe_index = randi([9 12]);
            end

            %split by word and get probe
            current_sentence = lower((string(sentences.stim_transcript(i))));
            split_sentence = strsplit(current_sentence, ' ');
            if(length(split_sentence)~=12)
                error("Not 12 words!");
            end
            probe = split_sentence(probe_index);

            %check conditions (no function words)
            conditions_met = 1;
            for j=1:length(function_words)
                if(strcmp(probe,function_words(j)))
                    conditions_met = 0;
                end
            end
        end

        %cleanup probe and capitalize
        probe = upper(erase(probe, ","));

        sentences.probe_correct_source_index(i) = probe_index;
        sentences.probe_correct(i) = probe;
    end

    % transfer probe info to the nonwords
    nonwords.probe_correct_source_index = sentences.probe_correct_source_index;
    nonwords.probe_source_cond = sentences.probe_source_cond;
    nonwords.probe_correct = string(zeros([60 1]));

    for i = 1:height(nonwords)
        %split by word and get probe
        current_nonwords = lower((string(nonwords.stim_transcript(i))));
        probe_index = nonwords.probe_correct_source_index(i);
        split_nonwords = strsplit(current_nonwords, ' ');
        probe = split_nonwords(probe_index);

        %cleanup probe and capitalize
        probe = upper(erase(probe, ","));

        nonwords.probe_correct(i) = probe;
    end

    % get the incorrect probes (by rotating the 3 runs)
    sentences.probe_incorrect_source_index = [sentences.probe_correct_source_index(41:60);sentences.probe_correct_source_index(1:20);sentences.probe_correct_source_index(21:40)];
    sentences.probe_incorrect = [sentences.probe_correct(41:60);sentences.probe_correct(1:20);sentences.probe_correct(21:40)];

    nonwords.probe_incorrect_source_index = [nonwords.probe_correct_source_index(41:60);nonwords.probe_correct_source_index(1:20);nonwords.probe_correct_source_index(21:40)];
    nonwords.probe_incorrect = [nonwords.probe_correct(41:60);nonwords.probe_correct(1:20);nonwords.probe_correct(21:40)];

    
    all_conditions_met = 1;
    %check incorrect probes are not in the sentence and no probes are
    %repeated
    for i=1:height(sentences)
        current_s = sentences.stim_transcript(i);
        current_s_probe = sentences.probe_incorrect(i);

        if(contains(current_s, current_s_probe,'IgnoreCase',true))
            fprintf("incorrect probe found in sentence %d\n", i);
            all_conditions_met = 0;
        end
        
        %check that there are no duplicates (all should be unique values)
        correct_probes = sentences.probe_correct;
        unique_probes = unique(correct_probes);
        
        if(length(correct_probes) ~= length(unique_probes))
            all_conditions_met = 0;
        end

%         current_n = nonwords.stim_transcript(i);
%         current_n_probe = nonwords.probe_incorrect(i);
%         
%         if(contains(current_n, current_n_probe,'IgnoreCase',true))
%             fprintf("incorrect probe found in nonwords %d\n", i);
%             all_conditions_met = 0;
%         end
    end
end

%% reorganize for splitting into runs (separate the paired sentence and
%nonwords by rotating them)
sentences = [sentences(1:20,:); sentences(21:40,:); sentences(41:60,:)];
nonwords = [nonwords(21:40,:); nonwords(41:60,:); nonwords(1:20,:)];


%% generate the pseudorandom stimuli orders
order1 = ["S","S","N"];
order2 = ["N","N","S"];

orders = cell(1,3);
sentence_tracker = 1;
nonword_tracker = 1;
for i=1:num_sets
    num_loops = floor(num_trials_per_set/6);
    for j=1:num_loops
        shuffled_order1 = order1(randperm(length(order1)));
        shuffled_order2 = order2(randperm(length(order2)));
        
        %ensuring no more than three of the same cond in a row
        orders{i} = [orders{i} shuffled_order1 shuffled_order2];
    end
    orders{i} = [orders{i} "S" "S" "N" "N"]; %finish off the order
    %% assign stimuli to runs in specified orders
    run = [];
    current_order = orders{i};
    
    for k=1:length(orders{i})
        if(strcmp(current_order{k},"S"))
            run = [run; sentences(sentence_tracker,:)];
            sentence_tracker = sentence_tracker + 1;
        elseif(strcmp(current_order{k},"N"))
            run = [run; nonwords(nonword_tracker,:)];
            nonword_tracker = nonword_tracker + 1;
        end
    end
    run_label = strcat("run", num2str(i));
    materials.(run_label) = run;

end

%prepare column for probe_condition
materials.run1.probe_condition = string(zeros([num_trials_per_set 1]));
materials.run2.probe_condition = string(zeros([num_trials_per_set 1]));
materials.run3.probe_condition = string(zeros([num_trials_per_set 1]));

%% assign the probe_condition to each run 
for i=1:num_sets
    conditions_met = 0;
    try_num = 1;
    while(~conditions_met)
        fprintf("Run %d, try %d\n", i, try_num);
        run_label = strcat("run", num2str(i));
        current_run = materials.(run_label);

        conditions = ["probe_correct", "probe_incorrect"];

        three_back = "NA";
        two_back = "NA";
        one_back = "NA";

        sentence_probes_present = 10;
        nonword_probes_present = 10;

        for j=1:height(current_run)
            rand_index = randperm(length(conditions));
            temp_condition = conditions(rand_index(1));

            if(strcmp(one_back, temp_condition))
                if(strcmp(two_back,temp_condition))
                    if(strcmp(three_back, temp_condition))
                        %if it matches the previous three, then switch conditions
                        final_condition = conditions(rand_index(2));
                    else
                        final_condition = temp_condition;
                    end 
                else
                    final_condition = temp_condition;
                end
            else
                final_condition = temp_condition;
            end

            materials.(run_label).probe_condition(j) = final_condition;
            materials.(run_label).run(j) = i;
            materials.(run_label).trial(j) = j;
            %update the trackers
            three_back = two_back;
            two_back = one_back;
            one_back = final_condition;

        end
        current_run = materials.(run_label);
        %check conditions
        temp_s = current_run(current_run.condition=="sentence",:);
        temp_n = current_run(current_run.condition=="nonword",:);
        
        if(sum(temp_s.probe_condition == "probe_correct") == 10 && ...
                sum(temp_n.probe_condition == "probe_correct") == 10)
            conditions_met = 1;
        else
            conditions_met = 0; %try again
        end
        
        %check that the correct probe_source_conditions are ~evenly distributed
        %within the run %20/3 = 6-7 per cond
        if(conditions_met) %only need to check if not already re-running
            temp = current_run(current_run.probe_condition=="probe_correct",:);
            sum_probe_source_cond1 = sum(temp.probe_source_cond == 1);
            sum_probe_source_cond2 = sum(temp.probe_source_cond == 2);
            sum_probe_source_cond3 = sum(temp.probe_source_cond == 3);
            
            if(sum_probe_source_cond1 < 6)
                conditions_met = 0;
            end

            if(sum_probe_source_cond2 < 6)
                conditions_met = 0;
            end

            if(sum_probe_source_cond3 < 6 )
                conditions_met = 0;
            end
        end
        
        try_num = try_num + 1;

    end
end
%% save the final probe based on the assigned probe_conditions
for i=1:num_sets
    run_label = strcat("run", num2str(i));
    for j=1:height(materials.(run_label))
        probe_condition_j = materials.(run_label).probe_condition(j);
        materials.(run_label).final_probe(j) = materials.(run_label).(probe_condition_j)(j);
        probe_source_j = strcat(materials.(run_label).probe_condition(j),"_source_index");
        materials.(run_label).final_probe_source_index(j) = materials.(run_label).(probe_source_j)(j);
    end
    
end

%% save stuff
save('materials.mat','materials');
all_runs = [materials.run1; materials.run2; materials.run3];
writetable(all_runs,'langloc_audio_all_runs.xlsx');

all_materials = [sentences; nonwords];
writetable(all_materials,'all_materials.xlsx');




