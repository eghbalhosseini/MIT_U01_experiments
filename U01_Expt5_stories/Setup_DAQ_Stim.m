function TrialStruct = Setup_DAQ_Stim( TrialStruct )
% Utility function to setup communication between the Cash Lab rig's
% parallel port and PsychToolbox.
% Depends on the "io64" MEX library.
% Also depends on you knowing where the parallel ports are in your machine.

if strcmp(getenv('COMPUTERNAME'),'PRESENTATION1')
    portAddress = hex2dec('2000'); % cashlap presentation laptop
    disp('I think Im doing triggers on the laptop');
elseif strcmp(getenv('COMPUTERNAME'),'SPIKEWAVE4')
    portAddress = hex2dec('C010'); % White rig
    disp('I think Im doing triggers on the white rig');
elseif strcmp(getenv('COMPUTERNAME'),'STORMTROOPER-PC') %stormtrooper
    portAddress = hex2dec('EFF8'); % stormtrooper
    disp('I think Im doing triggers on the Stormtrooper');  
elseif strcmp(getenv('COMPUTERNAME'),'ENTERPRISE-PC') %Enterprise
    portAddress = hex2dec('B010'); % Enterprise
    disp('I think Im doing triggers on the Enterprise');   
elseif strcmp(getenv('COMPUTERNAME'),'DESKTOP-VASDQ79') %Enterprise
    portAddress = hex2dec('D010'); % Enterprise
    disp('I think Im doing triggers on Streaky');
elseif strcmp(getenv('COMPUTERNAME'),'PRESENTATION') %Enterprise
    portAddress = hex2dec('D010'); % PRESENTATION
    disp('I think Im doing triggers on the PRESENTATION computer');
elseif strcmp(getenv('COMPUTERNAME'),'CASHLAB-PC') %
    portAddress = hex2dec('D010');   % Cashlab presentation LPT3 again;
    disp('I think Im doing triggers on the CASHLAB-PC, another computer');
elseif strcmp(getenv('COMPUTERNAME'),'TASKSLITTLEPC01') %Enterprise
    portAddress = hex2dec('D010'); % PRESENTATION
    disp('I think Im doing triggers on the TASKSLITTLEPC01 computer');
elseif strcmp(getenv('COMPUTERNAME'),'PRESENTATION-4')
    portAddress = hex2dec('DFF8'); % Presentation 4 computer
    disp('I think Im doing triggers on the Presentation 4 computer');    
else
    portAddress = hex2dec('DCF8');   % Cashlab presentation LPT3;
    disp('I think Im doing triggers on the main rig');
end

% Initialize the io64 library.
portObj = io64;
portStatus = io64(portObj);

if portStatus > 0
    error(['Parallel port driver init failed with error ' num2str(portStatus)]);
end

% Zero the lines.
io64(portObj,portAddress,0);

% Save these in the trial struct.
TrialStruct.portObj = portObj;
TrialStruct.portAddress = portAddress;

%% Send initial trigger.
% Setup trigger code.
PortIdx = 0;

StimTrig = 7;
TriggerCode = zeros(1,8);
TriggerCode(StimTrig) = 1;
% Send initial trigger.
SendTrigger( TrialStruct, TriggerCode )
WaitSecs(0.5);
% Turn off trigger.
TriggerCode(StimTrig) = 0;
SendTrigger( TrialStruct, TriggerCode )