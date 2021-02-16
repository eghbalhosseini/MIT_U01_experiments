
files = dir('../stimuli/*_denoised_48000.wav');

english_durations = [];
nonsense_durations = [];

for i=1:length(files)
    [y, freq] = audioread(strcat('../stimuli/',files(i).name));
    wavedata = y';
    nrchannels = size(wavedata,1); % Number of rows == number of channels
    audioDur = length(y)/freq;
    
    if(contains(files(i).name,'English'))
        english_durations = [english_durations audioDur];
    elseif(contains(files(i).name,'Nonsense'))
        nonsense_durations = [nonsense_durations audioDur];
    end
    
end

english_mean = mean(english_durations);
english_stdev = std(english_durations);
nonsense_mean = mean(nonsense_durations);
nonsense_stdev = std(nonsense_durations);

means = [english_mean nonsense_mean];
stdevs = [english_stdev nonsense_stdev];

bar(means)
hold on
er = errorbar(means, stdevs);
er.Color = [0 0 0];
er.LineStyle = "none";

set(gca,'FontSize',20)
xticklabels(["English","Nonsense"]);
ylabel('Audio duration (seconds)');

saveas(gca, 'mean_audio_durations.png');

