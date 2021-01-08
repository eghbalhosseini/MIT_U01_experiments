
audio_files = 'sentences/*.m4a';
d= dir(audio_files)


%sort by date created -- earliest is first
[~,idx] = sort([d.datenum],'descend');
d = d(idx)

d_files=transpose(arrayfun(@(x) {strcat(d(x).folder,filesep,d(x).name)}, 1:length(d)));

for i=1:length(d_files)
    [y,Fs] = audioread(d_files{i});
    new_filename = strcat("renamed_sentences/sentence_",string(i), ".wav");
    audiowrite(new_filename,y,Fs);
end
