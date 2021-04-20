txt_dir=sprintf('./U01_langloc_audio_vFeb2021/stimuli_txt/');
json_dir=sprintf('./U01_langloc_audio_vFeb2021/stimuli_alignment/');
txt_files=dir(strcat(txt_dir,'/*.txt'));
txt_files=sort(arrayfun(@(x) sprintf('%s/%s',txt_files(x).folder,txt_files(x).name),1:length(txt_files),'uni',false))';
field_names={'case','endOffset','startOffset','word','start','end'};

for k=2:length(txt_files)
    txt_f=txt_files{k};
    stim_string=fileread((txt_f));
    json_struct=struct;
    json_strct.transcript=stim_string;
    stim_parts=strsplit(stim_string);
    assert(length(stim_parts)==12);
    words=struct;
    for kk=1:length(stim_parts)
        words(kk,1).alignedWord=stim_parts{kk};
        words(kk,1).case='fail';
        words(kk,1).start=0;
        words(kk,1).end=0;
        words(kk,1).startOffset=0;
        words(kk,1).endOffset=0;
    end 
    json_strct.words=words;
    
    JSONFILE_fix_name=strrep(txt_f,'.txt','.json');
    JSONFILE_fix_name=strrep(JSONFILE_fix_name,'stimuli_txt','stimuli_alignment')
    fid=fopen(JSONFILE_fix_name,'w+') ;
    encodedJSON = jsonencode(json_strct); 
    fprintf(fid, encodedJSON);
end
