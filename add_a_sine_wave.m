clear all ;
close all ;
%stim_type='nonword';
sound_dir=sprintf('./U01_langloc_audio_vFeb2021/stimuli/');
addpath('/Users/eghbalhosseini/MyCodes/fmri_DNN/pereira_243_auditory')
% order the files 
wav_files=dir(strcat(sound_dir,'/*.wav'));
wave_files=sort(arrayfun(@(x) sprintf('%s/%s',wav_files(x).folder,wav_files(x).name),1:length(wav_files),'uni',false))';
match=cellfun(@(x) regexp(x,strcat('stimuli','/\d*'),'match'),wave_files,'uni',false );
file_order=cell2mat(cellfun(@(x) str2num(erase(x{1},strcat('stimuli','/'))),match,'uni',false ));
[~,sort_id]=sort(file_order);
wave_files=wave_files(sort_id);

frequency = 96;  % Frequency of the sinusoid in Hz



%
for idx=1:length(wave_files)
    wav_file=wave_files{idx};
    
   [wave_full,Fs]=audioread(wav_file);
   duration = length(wave_full)/Fs;  % Duration of the signal in seconds
   % Time vector
   sampleRate = Fs;  % Sample rate in Hz
   t = 0:1/sampleRate:duration-1/sampleRate;
   x = sin(2*pi*frequency*t)';
   wave_analytic = hilbert(wave_full);
   x_analytic = hilbert(x);
% Compute the envelope of the signal
    wav_envelope = abs(wave_analytic);
    x_envelope=abs(x_analytic);
    figure;
    plot(wave_full)
    hold on 
    plot(wave_full+x*mean(wav_envelope))
    wave_sine=wave_full+x*mean(wav_envelope);
    soundsc(wave_full,Fs)
    soundsc(wave_sine,Fs)
    spectrogram(wave_full,Fs)
    h=SpectrogramDisplay(wave_sine,Fs,'freqRange',[1,500]);
    
end 
