clear all ;
close all ;
addpath('/Users/eghbalhosseini/MyCodes/general-audio-code/')
%stim_type='nonword';
sound_dir=sprintf('/Users/eghbalhosseini/MyCodes/MIT_U01_experiments/U01_Expt6_ANNsentSET1/stimuli/');
sound_fmri_dir=sprintf('/Users/eghbalhosseini/MyCodes/MIT_U01_experiments/U01_Expt6_ANNsentSET1/stimuli_fMRI/');

% order the files 
wav_files=dir(strcat(sound_dir,'/*.wav'));
wave_files=sort(arrayfun(@(x) sprintf('%s/%s',wav_files(x).folder,wav_files(x).name),1:length(wav_files),'uni',false))';
match=cellfun(@(x) regexp(x,'_\d*','match'),wave_files,'uni',false );
file_order=cell2mat((cellfun(@(x) str2num(erase(x{find(contains(x,digitsPattern))},'_')),match,'uni',false )));
[~,sort_id]=sort(file_order);
wave_files=wave_files(sort_id);

%% analyze the data 
for i=1:size(wave_files,1)
   % read alignment file 
   waveFile=wave_files{i};
   % read audio file 
  
   [wave_full,Fs]=audioread(waveFile);
    wave=sum(wave_full,2);
    [loudness, LRA] = integratedLoudness(wave,Fs);
    %soundsc(wave,Fs)
    aud_length=length(wave)/Fs;
    mean(wave);
    fprintf('audio length: %.4f\n',aud_length)
    if mod(aud_length,2)~=0
        multples_of_2sec=ceil(aud_length/2);
        desired_length=2*multples_of_2sec*Fs;
        actual_length=length(wave);
        padding=desired_length-actual_length;
        padd_full=repmat(mean(wave_full(end-1000:end,:),1),padding,1);
        wave_padd=vertcat(wave_full,padd_full);
        assert(mod(length(wave_padd)/Fs,2)==0)
    else
        wave_padd=wave_full;
    end 
    x=[1:length(wave_padd)]/Fs;
    f=figure(1);
    clf;
    set(f,'position',[-1818 100 1772 1200]);
    ax1=axes('position',[.01,.05,.95,.4]);
    h=plot(x,wave_padd(:,1),'k','linewidth',.5);
    ax1.YAxis.Visible='off';
    ax1.Box='off';
    ax1.XAxis.Visible='off';
    hold on 
    x=[1:length(wave_full)]/Fs;
    h=plot(x,wave_full(:,1),'r','linewidth',.5);
    %fprintf('Loudness before normalization: %.1f LUFS\n',loudness)
    ax1=axes('position',[.01,.55,.95,.4]);
     x=[1:length(wave_padd)]/Fs;
    h=plot(x,wave_padd(:,2),'k','linewidth',.5);
    ax1.YAxis.Visible='off';
    ax1.Box='off';
    ax1.XAxis.Visible='off';
    hold on 
    x=[1:length(wave_full)]/Fs;
    h=plot(x,wave_full(:,2),'b','linewidth',.5);
    pause(.5)
    
    %soundsc(wave_padd,Fs) 
    % normalize the dat 
%     [m]=wave_padd(:,1);
%     wav_range = max(m(:)) - min(m(:));
%     m01 = (m - min(m(:))) / wav_range;
%     mOut = (2-eps) * m01 - 1;
%     wave_padd(:,1)=mOut;
%     
%     [m]=wave_padd(:,2);
%     wav_range = max(m(:)) - min(m(:));
%     m01 = (m - min(m(:))) / wav_range;
%     mOut = (2-eps) * m01 - 1;
%     wave_padd(:,2)=mOut;
    
    mod_wave_path=strrep(waveFile,'norm_endfix','fmri_norm_endfix')
    mod_wave_path=strrep(mod_wave_path,sound_dir,sound_fmri_dir);
    audiowrite(mod_wave_path,wave_padd,Fs);
end 




    