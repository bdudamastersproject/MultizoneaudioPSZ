% White noise = input
xr=randn(48000*20, 1);

x=lowpass(xr, 1000, 48000);

% Allocate values
L=16384;
I_w=8192;
inStep=30;
clear("conv_block");
clear("block_lms_offline");
clear("conv_blockW");
clear("conv_blockY");
signal_length=length(x);

totalW=zeros(ceil(signal_length/L), 256);
totalE=zeros(ceil(signal_length/L),1);

% IRdesired=IRdesireddummy;
% IRsecondary=IRsecondarydummy;
% align signals in time
[IRdesired, IRsecondary]=alignsignals(IRdesireddummy, IRsecondarydummy);
% IRdesired=IRdesireddummy;
% IRsecondary=IRsecondarydummy;
% reserve memory
d = 1;                                       
noise = d*randn(8192, 1);
noiseprocessed=0.0008*noise;
IRsecondary=IRsecondary+noiseprocessed;
inBuffer = zeros(L,1);
desiredBlock = zeros(L,1);
outY = zeros(L,1);

% (a*f)/x=0.01   f=x*0.01/a

output_lms_Y = zeros((length(x)+I_w-1),1);

nob_rem=rem(signal_length,L);
no_blocks = signal_length/L - (nob_rem/L);

% desired is plant response filtered by inut signal
tic
desired=filter(IRdesired, 1, x);
for fc = 0:(no_blocks-1)
        inBuffer(1:L)=x((L*fc+1):(L*(fc+1)));
        desiredBlock(1:L)=desired((L*fc+1):(L*(fc+1)));
%       Input filtered by plant model  
        [filteredInBuffer]=conv_block(inBuffer, IRsecondary);
%       lms
        [outE, outW] = block_lms_offline(filteredInBuffer,desiredBlock, inStep, I_w);
% convolve the output of W with filtered in buffer
        outY=conv_blockY(filteredInBuffer, outW);
        output_lms_Y((L*fc+1):(L*(fc+1)))=outY(1:L);
%         collect total error mean 
    if(fc>0)
         totalE(fc)=mean(abs(outE));
    end

end
toc
% figure('units','normalized','outerposition',[0 0 1 1])
% tiledlayout(3,1)

% Top plot
nexttile
% plot(desired)
hold on;
plot(db(totalE));
grid on;
grid minor;
set(gca,'fontname','Times')
xlabel('Time (blocks)','Fontsize',23)
ylabel('LMS error (dB)','Fontsize',23)
title('Frame-LMS error')

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