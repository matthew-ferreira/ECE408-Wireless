clear all;close all;clc

numIter = 100; %100;
nSym = 1000;
SNR_Vec = 0:2:16;
lenSNR = length(SNR_Vec);
numTrainingSymbols = 80;

M = 2;

%chan = 1;
chan = [1 .2 .4]; %Moderate ISI
%chan = [0.227 0.460 0.688 0.460 0.227]; %Severe ISI

berVec = zeros(numIter, lenSNR);

for i = 1:numIter
    
    %these would most likely be hardcoded
    tSyms = randi([0 M-1], 1, numTrainingSymbols);
    msg = randi([0 M-1], 1, nSym-numTrainingSymbols);
    msg_sent = [tSyms msg];
    
    for j = 1:lenSNR
        if isequal(M,2)
            tx = pskmod(msg_sent,M);
        else
            tx = qammod(msg_sent,M);
        end
        
        if isequal(chan,1)
            txChan = tx;
        elseif isa(chan, 'channel.rayleigh')
            reset(chan)
            txChan = filter(chan,tx);
        else
            txChan = filter(chan,1,tx);
        end
        
        txNoisy = awgn(txChan, SNR_Vec(j), 'measured');
        
        %add equalization
        
        eq = comm.LinearEqualizer;
        eq.ReferenceTap = 1;
        
        if isequal(M,2)
            eq.Constellation = pskmod([0 1],M);
        else
            eq.Constellation = qammod(0:M-1,M);
        end
        
        %train on the first N symbols
        txEqualized = eq(txNoisy',tx(1:numTrainingSymbols)')';
        equalizedSamples = txEqualized(numTrainingSymbols+1:length(txEqualized));
        
        
        %uncomment the following for the unequalized symbols
        %equalizedSamples = txNoisy(numTrainingSymbols+1:length(txNoisy));
        
        if isequal(M,2)
            rx = pskdemod(equalizedSamples,M);
        else
            rx = qamdemod(equalizedSamples, M);
        end
        
        [~,berVec(i,j)] = biterr(msg, rx);
        
    end
end

ber = mean(berVec,1);
semilogy(SNR_Vec, ber)

%computer theoretical BER

%Note: EbNO = SNR - 10log10(bits per symbol) + 10log10(samples per symbol)
%From the matlab website

if isequal(M,2)
    berTheory = berawgn(SNR_Vec, 'psk', M, 'nondiff');
else
    berTheory = berawgn(SNR_Vec - 10*log10(log2(M)), 'qam', M);
end

if isequal(chan,1)
    hold on
    semilogy(SNR_Vec, berTheory, 'r');
    legend('BER', 'Theoretical BER')
end

xlabel('SNR')
ylabel('BER')

if isequal(M,2)
    title('BPSK')
else
    title(append(num2str(M),'-QAM'))
end