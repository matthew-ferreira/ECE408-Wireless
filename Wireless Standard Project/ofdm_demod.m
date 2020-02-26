function output = ofdm_demod(input, G)
    N = 256;
    redundancy = length(input)*G/(1+G);
    
    ofdmdemodulator = comm.OFDMDemodulator;
    ofdmdemodulator.FFTLength = N;
    ofdmdemodulator.NumGuardBandCarriers = [28;27];
    ofdmdemodulator.CyclicPrefixLength = redundancy;
    
    symbols = ofdmdemodulator(input);
    
    pilots = symbols([13, 38, 63, 88, 114, 139, 164, 189]);
    output = symbols([1:12,14:37,39:62,64:87,89:100,102:113,115:138,...
        140:163,165:188,190:end]);
    
    %symbols = fft(signal,N)./sqrt(N);
    
    %pilots = [symbols(41) symbols(66) symbols(91) symbols(116)...
        %symbols(142) symbols(167) symbols(192) symbols(217)];
    
    %output = [symbols(29:40) symbols(42:65) symbols(67:90) symbols(92:115)...
        %symbols(117:128) symbols(130:141) symbols(143:166) symbols(168:191)...
        %symbols(193:216) symbols(218:229)];
    
    % TODO: channel estimation based on pilot values
end