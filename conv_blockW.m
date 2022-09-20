function [outBuffer] = conv_blockW(inBuffer, inFilterIR)
persistent tail;
L=length(inBuffer);
N=length(inFilterIR);
x=ceil(log2(L+N-1));
nfft=2^x;
if isempty(tail)
        tail = zeros(nfft, 1);
end
inBufferFreq=fft(inBuffer, nfft);
inFilterFreq=fft(inFilterIR, nfft);
% do partial multi
convTempFreq=inBufferFreq(1:((nfft+2)/2)).*inFilterFreq(1:((nfft+2)/2));
convTempTime=ifft(convTempFreq, nfft, "symmetric");
convTempTime=convTempTime+tail;
outBuffer=convTempTime(1:L);
tail(1:nfft-L)=convTempTime(L+1:end);