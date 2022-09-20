function [outBuffer] = convBlockMultiModelv2(inBuffer, IRplantModel)
% Calculation of Rdash
% size of Rdash - MN x (L*S*LN) (KxMSL in paper)
% assume S=1
% outBuffer -  by 4
persistent tail;
L=length(inBuffer);
sizeIR=size(IRplantModel);
% MN - number of mics, LN - number of loudspeakers
MN=sizeIR(2);
LN=sizeIR(3);
N=sizeIR(1);
% N = length of the IR
x=ceil(log2(L+N-1));
nfft=2^x;
outBuffer=zeros(LN*L, MN);
if isempty(tail)
        tail = zeros(nfft, LN*MN);
end

for k = 1:MN
    for s=1:LN 
tailPositioner=LN*(k-1)+s;        
inBufferFreq=fft(inBuffer, nfft);
inFilterFreq=fft(IRplantModel(:, k, s), nfft);
convTempFreq=inBufferFreq(1:((nfft+2)/2)).*inFilterFreq(1:((nfft+2)/2));
convTempTime=ifft(convTempFreq, nfft, "symmetric");
convTempTime=convTempTime+tail(:,tailPositioner);
outBuffer((((s-1)*L+1):(s*L)), k)=convTempTime(1:L);
tail(1:nfft-L, tailPositioner)=convTempTime(L+1:end);
    end
end    
% do partial multi



