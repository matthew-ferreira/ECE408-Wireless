%WiMax Simulation

%Rate_ID, inputs 0-6
% 0: BPSK 1/2
% 1: QPSK 1/2
% 2: QPSK 3/4
% 3: 16-QAM 1/2
% 4: 16-QAM 3/4
% 5: 64-QAM 2/3
% 6: 64-QAM 3/4
Rate_ID = 1;

n = ((Rate_ID+1) * 96 - 8); %number of bits to be transmitted
num_Iters = 100;

G = 1/16; %ratio of prefix time
SNR = 0:1:8;
ber = zeros(num_Iters,length(SNR));

for k = 1:length(SNR)
    disp(['Running: SNR = ', num2str(SNR(k))])
    for j = 1:num_Iters
        transmit_data = randi([0,1], 1, n);
        
        %Randomization, see 8.3.3.1 of 802.16-2017
        randomized_data = randomizer(transmit_data);
        
        %RS encoding
        rs_encoded = rs_encode(randomized_data, Rate_ID);
        
        %CC
        conv_coded = convolutional_coder(rs_encoded, Rate_ID);
        
        %interleaving
        interleaved = interleaver(conv_coded,384,Rate_ID);
        
        %symbol mapping
        mapped_syms = sym_map(interleaved,Rate_ID);
        
        %modulation
        signal = ofdm_mod(mapped_syms',G);

        % TODO insert channel
        rx = awgn(signal,SNR(k),'measured');

        %demodulation
        unmodded_syms = ofdm_demod(rx,G);
        
        %demapping
        unmapped_syms = sym_demap(unmodded_syms,Rate_ID);
        
        %deinterleaver
        deinterleaved = deinterleaver(unmapped_syms,384,Rate_ID);
        
        %convolutional decoder
        deconv = convolutional_decoder(deinterleaved,Rate_ID);
        
        %rs decoder
        decoded = rs_decode(deconv,Rate_ID);
        
        %unrandomize
        received_data = randomizer(decoded);

        [n1,r1] = symerr(received_data,transmit_data);
        ber(j,k) = r1;
    end
end
ber1 = mean(ber);
semilogy(SNR,ber1)
xlabel('SNR')
ylabel('BER')
title('Bit Error Rate vs SNR')

