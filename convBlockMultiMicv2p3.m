function [micSignalSimulated] = convBlockMultiMicv2p3(trueIRinBuffer, localW, I_w)
% micSignalSimulated to be of size L,MN
% L*LN, MN
persistent tail;
sizeTrueInBuffer=size(trueIRinBuffer);
lengthW=length(localW);
N=I_w;
LN=lengthW/I_w;
L=sizeTrueInBuffer(1)/LN;
MN=sizeTrueInBuffer(2);

micSignalSimulated=zeros(L, MN);
x=ceil(log2(L+N-1));
nfft=2^x;

if isempty(tail)
        tail = zeros(nfft, LN*MN);
end
flippedWSingleSpeaker=zeros(I_w, 1);


% do convolutions vector by vector, then collect influences of each mic for
% all speakers, then do the same for mic 2, 3...k. 

% k - mic counter
inFilterFreq=zeros(nfft,LN);
for smic=1:LN
% fetch speaker s from the local W (same for all mics)
flippedWSingleSpeaker=flip(localW(((smic-1)*I_w+1):(smic*I_w)));
% you can obtain the localWs for all mics at once not everytime repeat it

% go to freq domain with the single W speaker
inFilterFreq(:,smic)=fft(flippedWSingleSpeaker, nfft);

end 




for k = 1:MN
%     s - speaker counter
    for s=1:LN 
%         tail two dimensional, one t=dimension time other dimension
%         speakers mics concatenanted
tailPositioner=LN*(k-1)+s;    

% deal with buffered signal for mic k and speaker s do the fft
inBufferFreq=fft(trueIRinBuffer((((s-1)*L+1):(s*L)), k), nfft);

convTempFreq=inBufferFreq(1:((nfft+2)/2)).*inFilterFreq(1:((nfft+2)/2),s);

% size(convTempFreq)
convTempTime=ifft(convTempFreq, nfft, "symmetric");

% save tail for particular s and k 
convTempTime=convTempTime+tail(:,tailPositioner);

% collect influences on a microphone k from speakers 1, 2, 3, .... s
micSignalSimulated(:, k)=micSignalSimulated(:,k) + convTempTime(1:L);

% save the tail
tail(1:nfft-L, tailPositioner)=convTempTime(L+1:end);
    end
end     
% previous






