clear all ;
close all ;
%stim_type='nonword';
sound_dir=sprintf('./U01_langloc_audio_vFeb2021/stimuli/');
json_dir=sprintf('./U01_langloc_audio_vFeb2021/stimuli_alignment/');
handfix_json_dir=sprintf('./U01_langloc_audio_vFeb2021/stimuli_alignment_handfix/');

% order the files 
wav_files=dir(strcat(sound_dir,'/*.wav'));
wave_files=sort(arrayfun(@(x) sprintf('%s/%s',wav_files(x).folder,wav_files(x).name),1:length(wav_files),'uni',false))';
match=cellfun(@(x) regexp(x,strcat('stimuli','/\d*'),'match'),wave_files,'uni',false );
file_order=cell2mat(cellfun(@(x) str2num(erase(x{1},strcat('stimuli','/'))),match,'uni',false ));
[~,sort_id]=sort(file_order);
wave_files=wave_files(sort_id);

json_file=dir(strcat(json_dir,'/*.json'));
json_files=sort(arrayfun(@(x) sprintf('%s/%s',json_file(x).folder,json_file(x).name),1:length(json_file),'uni',false))';

%json_rename_files=cellfun(@(x) strrep(x,'_align.','_denoised_48000.') ,json_files,'uni',false)

%arrayfun(@(x) movefile(json_files{x},json_rename_files{x},'f'),1:120,'uni',false)

match=cellfun(@(x) regexp(x,strcat('stimuli_alignment','/\d*'),'match'),json_files,'uni',false );
file_order=cell2mat(cellfun(@(x) str2num(erase(x{1},strcat('stimuli_alignment','/'))),match,'uni',false ));
[~,sort_id]=sort(file_order);
json_files=json_files(sort_id);
assert(length(json_files)==length(wave_files));
json_parent=json_file(1).folder;
handfix_json_dir=sprintf('%s_handfix',json_parent);
%% analyze the data 
for i=1:length(wave_files)
   % read alignment file 
   JSONFILE_fix_name= strrep(json_files{i},'.json','_handfix.json'); 
   JSONFILE_fix_name= strrep(JSONFILE_fix_name,json_parent,handfix_json_dir); 
   if ~exist(JSONFILE_fix_name)
       error('!')
        audio_align = jsondecode(fileread(json_files{i}));
   else
    
     audio_align = jsondecode(fileread(JSONFILE_fix_name));
     
   end 
   transcript=audio_align.transcript;
   words=cellfun(@(x) strcat('word_',num2str(x)),mat2cell(1:length(strsplit(transcript)),1,ones(1,length(strsplit(transcript)))),'uni',false);
   c = cell(length(words),1);
   dataIn = cell2struct(c,words);
   for word_id=1:size(audio_align.words,1)
       try  
        word_struct=audio_align.words{word_id};
       catch err 
           word_struct=audio_align.words(word_id);
       end 
        if strcmp(word_struct.case,'success')
            orig_range=[word_struct.start,word_struct.end];
            dataIn.(sprintf('word_%d',word_id))=orig_range;
        end
   end
   % read audio file 
   waveFile=wave_files{i};
   [wave_full,Fs]=audioread(waveFile);
    wave=wave_full(:,1);
    wave=sum(wave_full,2);
    
    brushAudio(wave,Fs,transcript,i,dataIn);
    waitfor(findobj('type','figure','number',1));
    fprintf('editing .json file\n');
    % fixing overlap 
    for kk=1:length(fieldnames(dataIn))-1
        if dataIn.(sprintf('word_%d',kk))(end)> dataIn.(sprintf('word_%d',kk+1))(1)
            dataIn.(sprintf('word_%d',kk+1))=[dataIn.(sprintf('word_%d',kk))(end)+0.005,dataIn.(sprintf('word_%d',kk+1))(end)];% add 1 ms
        end 
    end
    brushAudio(wave,Fs,transcript,i,dataIn);
    waitfor(findobj('type','figure','number',1));
    %audio_align = jsondecode(fileread(json_files{i}));
    word_align=audio_align.words;
    field_names={'case','endOffset','startOffset','word','start','end'};
    audio_align_fix=struct;
    audio_align_fix.transcript=audio_align.transcript;
    audio_align_fix.words=word_align;
   %
    for word_id=1:size(audio_align_fix.words,1)
       word_struct=audio_align_fix.words(word_id);
       range=dataIn.(sprintf('word_%d',word_id));
       word_struct.start=range(1);
       word_struct.end=range(2);
       word_struct.case='success';
       audio_align_fix.words(word_id)=word_struct;
    end  
    
    fid1=fopen(JSONFILE_fix_name,'w') ;
    encodedJSON = jsonencode(audio_align_fix); 
    fprintf(fid1, encodedJSON);
    fclose(fid1);
    fprintf('done!\n');
end 




    