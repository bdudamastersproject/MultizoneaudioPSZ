function [outE, outW] = block_lms_offline(filteredinBuffer, desired, inStep, I_w)
% INPUTS
% inX - input singal buffer of length L
% desired - desired/convoluted/recorded signal buffer of length X,
% inStep - convergence gain
% OUTPUTS
% outE - vector of length L of Error between desired and Y
% outW - vector of updated coefficents

% Assign values
L=length(filteredinBuffer);
correlation_sum=0;
% slidesN - number of total slides for calculating localY and localE
slidesN=L-I_w-1;

% create persitent value holding past W coefficents
persistent localW;
if isempty(localW)
    localW=zeros(I_w,1);
end

% Allocate memory (possibly make them persistent)
% outW (I_w, MN)
outW=zeros(I_w, 1);
outE=zeros(L, 1);
localR=zeros(I_w, 1);
% obtain Y for the whole buffer (W is constant throughout the whole buffer)
% outWConvolution=conv_blockW(inBuffer, flip(localW));
% begin the loop for the LMS
% calculate local Y as if it was real - mock up of reality
micsignalsimulated=conv_blockW(filteredinBuffer, flip(localW));
for k=1:slidesN
    localR = filteredinBuffer(k:I_w+k-1, 1); 
    localDesired=desired(I_w+k-1, 1);
    localY=micsignalsimulated(I_w+k-1, 1);
    localE=localDesired-localY;
    correlation_sum=correlation_sum+localR*localE;
end



% start reading buffer later for big prop delay
% Update the W using the newly obtained correlation sum and past W
% (I_w*norm(inBuffer)^2)
outW=localW+2*inStep*correlation_sum*(1/slidesN);
% Update the W vector for the next buffer
localW=outW;
% Calculate the error to be outputed
% perfect sequence - specific signal
outE=desired-micsignalsimulated;


