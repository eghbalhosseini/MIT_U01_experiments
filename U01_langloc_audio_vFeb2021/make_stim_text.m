clear all 
close all 
root_dir='/Users/eghbalhosseiniasl1/MyCodes/MIT_U01_experiments/U01_langloc_audio_vFeb2021'
write_dir='stimuli_txt'
materials=load(sprintf('%s/%s',root_dir,'materials.mat'))
materials=materials.materials;
runs=fieldnames(materials);
for run=runs'
    run_dat=materials.(run{1})
    file_names=run_dat.audiofile;
    strings=run_dat.stim_transcript;
    for k=1:size(file_names,1)
        file_name=strrep(file_names{k},'.wav','.txt')
        string=strings{k};
        fileID = fopen(sprintf('%s/%s/%s',root_dir,write_dir,file_name),'w');
        fprintf(fileID,'%s',string);
        fclose(fileID)
    end 
    
end 