function [outE, outW, micSignalSimulated] = blockLmsOfflineMultiv4p1(filteredinBuffer, trueIRinBuffer, desired, inStep, I_w)
% INPUTS
% filteredInBuffer - filtered input singal buffer (L*LN, MN)
% desired - desired/convoluted/recorded signal buffer of length X (L, MN)
% inStep - convergence gain
% OUTPUTS
% outE - vector of length L of Error between desired and Y
% outW - vector of updated coefficents

% Assign values and calculate number of mics and speakers
sizeFilteredInBuffer=size(filteredinBuffer);
sizeDesired=size(desired);
L=sizeDesired(1);
MN=sizeDesired(2);
LN=sizeFilteredInBuffer(1)/L;
correlationSum=0;
% slidesN - number of total slides for calculating localY and localE
slidesN=L-I_w-1;

% create persitent value holding past W coefficents
persistent localW;
% if isempty(localW)
%     localW=zeros(I_w*LN,1);
% end

if isempty(localW)
    localW=zeros(I_w*LN,1);
end
% localW(end)=1;

% Allocate memory
outW=zeros(I_w*LN, 1);
outE=zeros(L, 1);
localR=zeros(I_w, 1);
filteredinBufferSingleSpeaker=zeros(L*LN, MN);
trueIRinBufferSingleSpeaker=zeros(L*LN, MN);
micSignalSimulated=zeros(L, MN);

% p(n)=Rapprox(n)*w(n) (preconvolve for the whole block, speaker by speaker and
% collect influences for all microphones
    micSignalSimulated=convBlockMultiMicv2p3(trueIRinBuffer, localW, I_w);

for k=1:slidesN
        localR=zeros(I_w*LN, MN);    
        for s=1:LN
%       fetch single speaker Rapprox       
    filteredinBufferSingleSpeaker=filteredinBuffer((((s-1)*L+1):(s*L)), 1:MN);
%       fetch I_w long parts of localR and rearrange so that it fits
%       current slide. Do that for each speaker s and concatenante. Local R dimensions are I_w*LN by MN
    localR((((s-1)*I_w+1):(s*I_w)),1:MN)=filteredinBufferSingleSpeaker(k:I_w+k-1, 1:MN);
        end
%       d(n) 1xMN  
        localDesired=desired(I_w+k-1, 1:MN);
%       p(n) 1xMN 
        localY=micSignalSimulated(I_w+k-1, 1:MN);
%       e(n) = d(n) - p(n)  
        localE=localDesired-localY;
%       sigma=sigma + Rapprox*e_transposed  
        correlationSum=correlationSum+localR*localE';
end
 
% update outW
outW=localW+2*inStep*correlationSum*(1/slidesN*LN);
% Update the W vector for the next buffer
localW=outW;
% Calculate the error to be outputed (clown mode cuz this doesn't work ;()
outE=desired-micSignalSimulated;



