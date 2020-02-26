function output = ofdm_mod(input, G)
    N = 256;
    
    p1=complex(-1,0);
    p2=complex(1,0);
    pilots = [p1 p2 p1 p2 p2 p2 p1 p1]; %first frame
    g1 = complex (0,0) * ones (1,28); %lower
    g2 = complex (0,0) * ones (1,27); %upper
    DC = complex (0,0);
    
    syms = [input(1:12) pilots(1) input(13:36) pilots(2) input(37:60)...
    pilots(3) input(61:84) pilots(4) input(85:96) DC input(97:108)...
    pilots(5) input(109:132) pilots(6) input(133:156) pilots(7)...
    input(157:180) pilots(8) input(181:192)];
    
    ofdmmodulator = comm.OFDMModulator('FFTLength',N);
    ofdmmodulator.CyclicPrefixLength = N*G;
    ofdmmodulator.NumGuardBandCarriers = [28; 27];
    output = ofdmmodulator(syms');

    %sig = ifft(syms,N).*sqrt(N);
    %redundancy = length(sig)*G;
    %output = [sig(end-redundancy+1:end) sig];
end