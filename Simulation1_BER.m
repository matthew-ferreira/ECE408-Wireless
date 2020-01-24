clear all;close all;clc

numIter = 10; %100;
nSym = 1000;
SNR_Vec = 0:2:16;
lenSNR = length(SNR_Vec);

M = 4;

chan = 1;
%chan = [1 .2 .4]; %Moderate ISI
%chan = [0.227 0.460 0.688 0.460 0.227]; %Severe ISI

berVec = zeros(numIter, lenSNR);

for i = 1:numIter
    
    msg = randi([0 log2(M*2)-1], 1, nSym*log2(M));
    
    for j = 1:lenSNR
        tx = qammod(msg,M);
        
        if isequal(chan,1)
            txChan = tx;
        elseif isa(chan, 'channel.rayleigh')
            reset(chan)
            txChan = filter(chan,tx)
        else
            txChan = filter(chan,1,tx)
        end
        
        txNoisy = awgn(txChan, SNR_Vec(j), 'measured');
        %add equalization
        
        rx = qamdemod(txNoisy, M);
        
        rxMSG = rx;
        
        [~,berVec(i,j)] = biterr(msg, rxMSG);
        
    end
end

ber = mean(berVec,1);
semilogy(SNR_Vec, ber)

%computer theoretical BER

%Note: EbNO = SNR - 10log10(bits per symbol) + 10log10(samples per symbol)
%From the matlab website

berTheory = berawgn(SNR_Vec - 10*log10(log2(M)), 'qam', M);

hold on
semilogy(SNR_Vec, berTheory, 'r');
legend('BER', 'Theoretical BER')
xlabel('SNR')
ylabel('BER')
title(append(num2str(M),'-QAM'))