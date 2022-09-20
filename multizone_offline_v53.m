% Multizone v3 - one PZ, one desired, 14 speakers


% FxLMS block - is there a paper?
% Fdomain - https://www.sciencedirect.com/science/article/pii/S0888327018307015
% delay free rescalling algorithm
% https://www.ingentaconnect.com/contentone/ince/incecp/2020/00000261/00000006/art00090
% try removing delay
% reduce step size significantly


% Program Start - 2 sound zones - BZ and DZ
% Assign Variables
% LN - number of speakers (L in paper)
LN=4;
% S - number of programs
S=1;
% MN - number of microphones (K in paper)
MN=4;
% White noise - input
% xr=randn(1000000, S);
% x=lowpass(xr, 1000, 48000);
% savex=x;
% 
% x=savex;
fs11= 48e3;  
f11= 80;  
nCyl=1680;  
t11=0:1/fs11:nCyl*1/f11;  
x=sin(2*pi*f11*t11);  

signal_length=length(x);
% IR choice (4 mics 4 loudspeakers in this case)
% IR=IRbase(:, [1 4 5 8], [1 7 8 14]);
IRbase1=IRbase(:, :, :);
IR=IRbase1(:, [1 4 5 8], [1 7 8 14]);

% IR(:,1,1)=circshift(IR(:,1,1), 6, 1);
% IR(1:6, 1, 1)=0;
% 
% IR(:,1,2)=circshift(IR(:,1,2), 2, 1);
% IR(1:2, 1, 2)=0;
% 
% IR(:,3,4)=circshift(IR(:,3,4), 1, 1);
% IR(1:1, 3,4)=0;
% 
% IR(:,4,3)=circshift(IR(:,4,3), 8, 1);
% IR(1:8, 4,3)=0;
% 
% IR(:,2,4)=circshift(IR(:,2,4), 7, 1);
% IR(1:7, 2,4)=0;
% 
% IR(:,4,4)=circshift(IR(:,4,4), 3, 1);
% IR(1:3, 4,4)=0;
% 
% IR(:,3,1)=circshift(IR(:,3,1), 5, 1);
% IR(1:5, 3,1)=0;
% 
% IR(:,2,2)=circshift(IR(:,2,2), 7, 1);
% IR(1:7, 2,2)=0;
% add random delay for different IRs 2-3 sample delays
% IRbasecircd=circshift(IRbase, 100, 1);
IRplantModel=IRbase1(:, [1 4 5 8], [1 7 8 14]);
% use a long I_w
% try to lowpass it more
% see the error as a function of frequency
% should see low error at low frequencies
% see what happens at the ears


% desired is plant response filtered by input signal
% desired(signal_length, MN);
desired=zeros(signal_length, MN);
desired(:, 1)=filter(IRplantModel(:,1,4), 1, x);
desired(:, 2)=filter(IRplantModel(:,2,4), 1, x);
% desired(:, 3)=filter(IRplantModel(:,3,4), 1, x);
% desired(:, 4)=filter(IRplantModel(:,4,4), 1, x);
% shouldn't change plant model


% do nfft of the error
% [1] 00000...0 - [I_w].... [I_w+3] 00000......1 I_w+4
% force this 00000000001 W
% L - block length (frame)
L=8192;
% I_w - tap length
I_w=6000;
% L is given by I_w + number of averages + 1
% buffer size depends on latency and cpu speed
% freq resolution - filter cant change signals 
% inStep - convergence rate
% put different tic tocs to calcualte real life time
% future work - classic FxLMS performance against BFxLMS
inStep=0.1;
desireddelay=ceil(0.45*I_w);
drms1=rms(desired(:,1));
drms2=rms(desired(:,2));
drms=(drms1+drms2)/2;
desired(:,:)=circshift(desired, desireddelay, 1);
desired(1:desireddelay, :)=0;
% Memory clearance
clear("convBlockMultiModelv2");
clear("convBlockMultiTruev2");
clear("convBlockMultiMicv2p3");
clear("convBlockMultiY");
clear("blockLmsOfflineMultiv4p1");





totalW=zeros(ceil(signal_length/L), 256, LN);
totalE=zeros(ceil(signal_length/L),MN);


% align signals in time (not applicable, skeleton for later)
% [IRdesired, IRsecondary]=alignsignals(IRdesireddummy, IRsecondarydummy);

% Allocate Memory
inBuffer = zeros(L,S);
desiredBlock = zeros(L,MN);
outY = zeros(L,LN);

noblocks=length(x)/L-1;
tic
for fc = 0:noblocks/3
%     tic
%     separate part for simulation and part for electronical stuff
%       fetch required x - (single x for each S)
        inBuffer(1:L)=x((L*fc+1):(L*(fc+1)));
%       Fetch desiredBlock from the long stream of desired  
        desiredBlock(1:L, 1:MN)=desired((L*fc+1):(L*(fc+1)),1:MN);
%       Input filtered by imperfect plant model  
%       buffer to be enlarged inside the func
%       preconvolve trueiR and filtered IR 
        [filteredInBuffer]=convBlockMultiModelv2(inBuffer, IRplantModel);
%       Simulated true IR signal 
        [trueIRinBuffer]=convBlockMultiTruev2(inBuffer, IR);
%         is actualy truInbuffer same as filtered lol
%       lms
        [outE, outW, outY] = blockLmsOfflineMultiv4p1(filteredInBuffer,trueIRinBuffer,desiredBlock, inStep, I_w);
%         outY=convBlockMultiY(trueIRinBuffer, outW, I_w);
%         collect total error mean 
         if(fc>0)
         totalE(fc, :)=mean(abs(outE));
         end
         
%          deal later
%          toc
end
toc

% head signal calculation













% Top plot
nexttile
% plot(desired)
hold on;
plot(db(totalE/drms));
grid on;
grid minor;
% legend('mic 1 (BZ)', 'mic 2 (BZ)', 'mic 3 (DZ)', 'mic 4 (DZ)')
legend('mic 1 (BZ)', 'mic 2 (BZ)', 'mic 3 (DZ)', 'mic 4 (DZ)')
set(gca,'fontname','Times')
xlabel('Time (blocks)','Fontsize',25)
ylabel('LMS error (dB)','Fontsize',25)
title('Frame-LMS error','Fontsize',26)


Averageerror=(totalE(:, 1)+totalE(:, 2)+totalE(:, 3)+totalE(:, 4))/4;


% Top plot
nexttile
% plot(desired)
hold on;
plot(db(Averageerror/drms));
grid on;
grid minor;
% legend('mic 1 (BZ)', 'mic 2 (BZ)', 'mic 3 (DZ)', 'mic 4 (DZ)')
set(gca,'fontname','Times')
xlabel('Time (blocks)','Fontsize',25)
ylabel('LMS error (dB)','Fontsize',25)
title('Frame-LMS error - average error for all microphones','Fontsize',26)




% figure('units','normalized','outerposition',[0 0 1 1])
% tiledlayout(3,1)
% 
% % Top plot
% nexttile
% % plot(desired)
% hold on;
% plot(db());
% grid on;
% grid minor;
% legend('1', '2', '3', '4')
% set(gca,'fontname','Times')
% xlabel('Time (samples)','Fontsize',23)
% ylabel('LMS error','Fontsize',23)
% title('Frame-LMS error')

% 
% N = L;
% Fs=48000;
% xdft = fft(outY(:, 1), 2*L);
% xdft = xdft(1:N/2+1);
% psdxBZ = (1/(Fs*N)) * abs(xdft).^2;
% psdxBZ(2:end-1) = 2*psdxBZ(2:end-1);
% freq = 0:Fs/N:Fs/2;
% 
% xdft = fft(outY(:, 3), 2*L);
% xdft = xdft(1:N/2+1);
% psdxDZ = (1/(Fs*N)) * abs(xdft).^2;
% psdxDZ(2:end-1) = 2*psdxDZ(2:end-1);
% freq = 0:Fs/N:Fs/2;
% 
% psddifference(:, 1)=psdxBZ;
% psddifference(:, 2)=psdxDZ;
% plot(freq,10*log10(psddifference))
% grid on
% title('FFT for mic 1 and 3')
% xlabel('Frequency (Hz)')
% ylabel('Power/Frequency (dB/Hz)')
% 
% % C=psdxBZ-psdxDZ;
% % plot(db(C));
% 
% 
% grid on
% title('FFT for mic 3')
% xlabel('Frequency (Hz)')
% ylabel('Power/Frequency (dB/Hz)')

% contrast for single frequencies do the average of psd for all mics in one
% zone
% do dB of the ratio is called the contrast do 10 log10 (with rms is 20)

% do the error in freq psd do ratio for evey freq 
% we expect to see worse contrast 
% error as a metric (psd of the error)
% is any point in updating the plant matrix
% contrast at the ears
% not to simulate it all for the ears - see just the contrast
% see the energy at the ears
% 1. error at the error microphones#
% 2. errors at the ears
% play the signal at the ears
% play with the length of the filter - describe in the report how it
% changes
% fix few things and operate on one thigns that varies
% modelling delay plays crucial role due to causality
SignalBrightAverage=(outY(:,1)+outY(:,2))/2;
SignalDarkAverage=(outY(:,3)+outY(:,4))/2;

N = L;
Fs=48000;
xdft = fft(SignalBrightAverage, 2*L);
xdft = xdft(1:N/2+1);
psdxBZ = (1/(Fs*N)) * abs(xdft).^2;
psdxBZ(2:end-1) = 2*psdxBZ(2:end-1);
freq = 0:Fs/N:1000;

xdft = fft(SignalDarkAverage, 2*L);
xdft = xdft(1:N/2+1);
psdxDZ = (1/(Fs*N)) * abs(xdft).^2;
psdxDZ(2:end-1) = 2*psdxDZ(2:end-1);
freq = 0:Fs/N:1000;

figure;
% subplot(1,2,1)
%first plot
differenceBZDZ=psdxBZ./psdxDZ;
plot(freq,10*log10(differenceBZDZ(1:171)))
grid on
title('Acoustic contrast for frequencies 1-1000 Hz', 'Fontsize',26)
xlabel('Frequency (Hz)','Fontsize',25)
ylabel('Power Ratio (dB)', 'Fontsize',25)







% subplot(1,2,2)
% %second plot
% plot(freq,10*log10(psdxDZ(1:86)))
% grid on
% title('FFT for dark zone')
% xlabel('Frequency (Hz)')
% ylabel('Power/Frequency (dB/Hz)')











pBZ = bandpower(SignalBrightAverage); 
pDZ = bandpower(SignalDarkAverage); 











disp("bright zone energy in dB")
pBZdB=pow2db(pBZ)
disp("dark zone energy in dB")
pDZdB=pow2db(pDZ)





ContrastRatio=pBZ/pDZ;
disp("Contrast Ratio between BZ and DZ in Decibels:")
ContrastRatiodB=10*log10(ContrastRatio)



% pdifferenceDB=mag2db(pDf)
% figure('units','normalized','outerposition',[0 0 1 1])
% tiledlayout(3,1)










% %Bottom plot
% nexttile
% plot(flip(outW,1))
% grid on;
% grid minor;
% set(gca,'fontname','Times')
% xlabel('Time (samples)','Fontsize',23)
% ylabel('Amplitude','Fontsize',23)
% title('Estimated IR')

% nexttile
% plot(IRsecondary)
% hold on;
% %plot(flip(weightsNew,1))
% grid on;
% grid minor;
% set(gca,'fontname','Times')
% xlabel('Time (samples)','Fontsize',23)
% ylabel('Amplitude','Fontsize',23)
% title('seondary')
% 
% nexttile
% plot(IRdesired)
% hold on;
% %plot(flip(weightsNew,1))
% grid on;
% grid minor;
% set(gca,'fontname','Times')
% xlabel('Time (samples)','Fontsize',23)
% ylabel('Amplitude','Fontsize',23)
% title('desired')