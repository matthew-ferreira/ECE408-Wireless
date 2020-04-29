% Matt Ferreira
% ECE-408 OFDM Project
% Part 2

modulation_order = 64; %options are BPSK, QPSK, 16-QAM or 64-QAM [2 4 16 64]
nPackets = 1;
nSyms = 10; %symbol periods per packet

nBits = nPackets * nSyms * 48 * log2(modulation_order);

data = randi(2, [nBits,1]) - 1;

switch(modulation_order)
    case 2
        modulator = comm.BPSKModulator;
        data_mod = modulator(data);
    case 4
        modulator = comm.QPSKModulator;
        modulator.BitInput = true;
        data_mod = modulator(data);
    case {16, 64}
        data_mod = qammod(data, modulation_order, 'InputType', 'bit');
end

nfft     = 64;
cplen    = 16;

nullIdx  = [1:6 33 64-4:64]';
pilotIdx = [12 26 40 54]';

numDataCarrs = nfft-length(nullIdx)-length(pilotIdx);
dataIn = reshape(data_mod, 48, []);

pilots = repmat(pskmod((0:3).',4),1,nSyms);

tx = ofdmmod(dataIn,nfft,cplen,nullIdx,pilotIdx,pilots);

fs = 1e-3;                                      % Hz
pathDelays = [0 1e-5 3.5e-5 12e-5];             % sec
avgPathGains = [0 -1 -1 -3];                    % dB
fD = 0;                                         % Hz

rchan = comm.RayleighChannel('SampleRate',fs, ...
    'PathDelays',pathDelays, ...
    'AveragePathGains',avgPathGains, ...
    'MaximumDopplerShift',fD);

chanEst = rchan(ones(80,1));

snr = 20; %dB
snr_lin = 10 ^ (-snr / 20);
rx = awgn(rchan(tx), snr, 'measured');

rx_syms = ofdmdemod(rx,nfft,cplen);
rx_mod = reshape(rx_syms([7:11,13:25,27:32,34:39,41:53,55:59],:),[],1);

switch(modulation_order)
    case 2
        demodulator = comm.BPSKDemodulator;
        rx_data = demodulator(rx_mod);
    case 4
        demodulator = comm.QPSKDemodulator;
        demodulator.BitOutput = true;
        rx_data = demodulator(rx_mod);
    case {16, 64}
        rx_data = qamdemod(rx_mod, modulation_order, 'OutputType', 'bit');
end

bit_errors = sum(abs(rx_data - data));
ber = bit_errors / nBits

%zero forcing
rx_zf = rx_syms./chanEst(17:end);
rx_mod = reshape(rx_zf([7:11,13:25,27:32,34:39,41:53,55:59],:),[],1);

switch(modulation_order)
    case 2
        demodulator = comm.BPSKDemodulator;
        rx_data = demodulator(rx_mod);
    case 4
        demodulator = comm.QPSKDemodulator;
        demodulator.BitOutput = true;
        rx_data = demodulator(rx_mod);
    case {16, 64}
        rx_data = qamdemod(rx_mod, modulation_order, 'OutputType', 'bit');
end

bit_errors_zf = sum(abs(rx_data - data));
ber_zf = bit_errors_zf / nBits


%MMSE
norm = conj(chanEst(17:end,:)).*chanEst(17:end,:) + snr_lin;
rx_mmse = rx_syms.*conj(chanEst(17:end))./norm;
rx_mod = reshape(rx_mmse([7:11,13:25,27:32,34:39,41:53,55:59],:),[],1);

switch(modulation_order)
    case 2
        demodulator = comm.BPSKDemodulator;
        rx_data = demodulator(rx_mod);
    case 4
        demodulator = comm.QPSKDemodulator;
        demodulator.BitOutput = true;
        rx_data = demodulator(rx_mod);
    case {16, 64}
        rx_data = qamdemod(rx_mod, modulation_order, 'OutputType', 'bit');
end

bit_errors_mmse = sum(abs(rx_data - data));
ber_mmse = bit_errors_mmse / nBits