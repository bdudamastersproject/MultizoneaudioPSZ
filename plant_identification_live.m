% Read audio noise to play with playrec
%[x, Fs]=audioread('white_noise.wav');
x=randn(1000000, 1);
% Define parameters
L=16384;
inStep=0.1;
N=8192;
record_live_control=1;
fc=0;
recordingLengthBlocks=30;
% Pre-allocate memory
inBuffer = zeros(L,1);
inBufferPlayrec = zeros(L,1);
inRecorded=zeros(L,1);
outETotal=zeros(recordingLengthBlocks,1);
% Clear persistent values for functions
clear("conv_block");
clear("conv_blockW");
clear("block_lms");

% Play and record simultaneously white noise for one block

inBuffer(1:L)=x((L*fc+1):(L*(fc+1)));
currentPageNr=playrec('playrec', inBuffer,1, L, 1);
page_complete=playrec('isFinished', currentPageNr);
while(page_complete==0)
page_complete=playrec('isFinished', currentPageNr);
end
inRecorded=playrec('getRec', currentPageNr);
% once the first block is ready and process, proceed to loop


% play and record live continously
while   record_live_control == 1
% play live white noise
%       increase the frame counter for buffer to take
        fc=fc+1;
%       load in buffer of white nosie to be played by playrec
        inBufferPlayrec(1:L)=x((L*fc+1):(L*(fc+1)));
%       start playing and recording the next page, while the "ready" one is being fed into LMS
        currentPageNr=playrec('playrec', inBufferPlayrec,1, L, 1);
       
%       check if the previous page data is processed
       
        page_complete=playrec('isFinished', currentPageNr-1);
        while(page_complete==0)
        page_complete=playrec('isFinished', currentPageNr-1);
        end
       
%       once processed, assign recorded/convoluted/desired buffer
        inRecorded=playrec('getRec', currentPageNr-1);
%       feed data from second newest page into the lms
    
        [outE, outW] = block_lms(inBuffer, inRecorded, inStep, N);
        outETotal(fc)=mean(abs(outE));
%       assign the input buffer for the block lms to be accurate for the
%       next iteration
        inBuffer=inBufferPlayrec;
%       break recording after given nubmer of samples      
        if fc==recordingLengthBlocks
        record_live_control=0;    
        end
%  

% Plot plant identification values
end
nexttile
plot(flip(outW,1))
grid on;
grid minor;
set(gca,'fontname','Times')
xlabel('Time (samples)','Fontsize',23)
ylabel('Amplitude','Fontsize',23)
title('Estimated IR')

% nexttile
% plot(IRlive)
% hold on;
% %plot(flip(weightsNew,1))
% grid on;
% grid minor;
% set(gca,'fontname','Times')
% xlabel('Time (samples)','Fontsize',23)
% ylabel('Amplitude','Fontsize',23)
% title('True IR')

figure
plot(db(outETotal))
grid on;
grid minor;
set(gca,'fontname','Times')
xlabel('Time (samples)','Fontsize',23)
ylabel('Amplitude','Fontsize',23)
title('Error LMS')

