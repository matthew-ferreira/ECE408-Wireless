
frmLen = 100;       % frame length
numPackets = 1000;  % number of packets
EbNo = 0:2:30;      % Eb/No varying to 30 dB
N = 2;              % maximum number of Tx antennas
M = 4;              % maximum number of Rx antennas

bpskMod     = comm.BPSKModulator;
bpskDemod   = comm.BPSKDemodulator('OutputDataType','double');

% Create comm.OSTBCEncoder and comm.OSTBCCombiner System objects
ostbcEnc    = comm.OSTBCEncoder;
ostbcComb   = comm.OSTBCCombiner;
ostbcComb_2 = comm.OSTBCCombiner('NumReceiveAntennas',2);

% Create two comm.AWGNChannel System objects for one and two receive
% antennas respectively. Set the NoiseMethod property of the channel to
% 'Signal to noise ratio (Eb/No)' to specify the noise level using the
% energy per bit to noise power spectral density ratio (Eb/No). The output
% of the BPSK modulator generates unit power signals; set the SignalPower
% property to 1 Watt.
awgn1Rx = comm.AWGNChannel(...
    'NoiseMethod', 'Signal to noise ratio (Eb/No)', ...
    'SignalPower', 1);
awgn2Rx = clone(awgn1Rx);
awgn4Rx = clone(awgn1Rx);

hChan = comm.MIMOChannel('PathGainsOutputPort',true);

% Create comm.ErrorRate calculator System objects to evaluate BER.
errorCalc1 = comm.ErrorRate;
errorCalc2 = comm.ErrorRate;
errorCalc3 = comm.ErrorRate;
errorCalc4 = comm.ErrorRate;
errorCalc5 = comm.ErrorRate;

%seed the random number generator for reproducable results
s = rng(55408);

% Pre-allocate variables
H = zeros(frmLen, N, M);
ber_noDiver     = zeros(3,length(EbNo));
ber_Alamouti    = zeros(3,length(EbNo));
ber_MaxRatio    = zeros(3,length(EbNo));
ber_Alamouti_2  = zeros(3,length(EbNo));
ber_MaxRatio_2  = zeros(3,length(EbNo));
%%

% Set up a figure for visualizing BER results
fig = figure; 
grid on;
ax = fig.CurrentAxes;
hold(ax,'on');

ax.YScale = 'log';
xlim(ax,[EbNo(1), EbNo(end)]);
ylim(ax,[1e-6 1]);
xlabel(ax,'Eb/No (dB)');
ylabel(ax,'BER'); 
fig.NumberTitle = 'off';
fig.Renderer = 'zbuffer';
fig.Name = 'Transmit vs. Receive Diversity';
title(ax,'Transmit vs. Receive Diversity');
set(fig, 'DefaultLegendAutoUpdate', 'off');
fig.Position = figposition([15 50 25 30]);

% Loop over several EbNo points
for idx = 1:length(EbNo)
    reset(errorCalc1);
    reset(errorCalc2);
    reset(errorCalc3);
    reset(errorCalc4);
    reset(errorCalc5);

    % Set the EbNo property of the AWGNChannel System objects
    awgn1Rx.EbNo = EbNo(idx); 
    awgn2Rx.EbNo = EbNo(idx);
    awgn4Rx.EbNo = EbNo(idx);
    % Loop over the number of packets
    for packetIdx = 1:numPackets
        % Generate data vector per frame 
        data = randi([0 P-1], frmLen, 1); 
        
        % Modulate data
        modData = bpskMod(data);     

        % Alamouti Space-Time Block Encoder
        encData = ostbcEnc(modData);
        
        % Create the Rayleigh distributed channel response matrix
        %   for two transmit and four receive antennas
        H(1:N:end, :, :) = (randn(frmLen/2, N, M) + ...
                         1i*randn(frmLen/2, N, M))/sqrt(2);
        %   assume held constant for 2 symbol periods
        H(2:N:end, :, :) = H(1:N:end, :, :);
        
        % Extract parts of H to represent the channels
        H11 = H(:,1,1);
        H21 = H(:,:,1)/sqrt(2);
        H12 = squeeze(H(:,1,[1 2]));
        H22 = H(:,[1 2],[1 2])/sqrt(2);
        H14 = squeeze(H(:,1,:));
        
        % Pass through the channels
        chanOut11 = H11 .* modData;
        chanOut21 = sum(H21.* encData, 2);
        chanOut12 = H12 .* repmat(modData, 1, 2);
        chanOut14 = H14 .* repmat(modData, 1, 4);
        %chanOut22 = H22 .* repmat(modData, 1, 2);
        [chanOut22, pathGains22] = hChan(encData);
        
        % Add AWGN
        rxSig11 = awgn1Rx(chanOut11);
        rxSig21 = awgn1Rx(chanOut21);
        rxSig12 = awgn2Rx(chanOut12);
        rxSig14 = awgn4Rx(chanOut14);
        %rxSig22 = zeros(100,2,2);
        %rxSig22(:,:,1) = awgn2Rx(chanOut22(:,:,1));
        %rxSig22(:,:,2) = awgn2Rx(chanOut22(:,:,2));
        %rxSig22 = sum(rxSig22,3);
        rxSig22 = awgn2Rx(chanOut22);
              
        % Alamouti Space-Time Block Combiner
        decData   = ostbcComb(rxSig21, H21);
        %decData_2 = ostbcComb_2(rxSig22, repmat(H22,1,1,1,2));
        decData_2 = ostbcComb_2(rxSig22, squeeze(sum(pathGains22,2)));
        
        % ML Detector (minimum Euclidean distance)
        demod11 = bpskDemod(rxSig11.*conj(H11));
        demod21 = bpskDemod(decData);
        demod12 = bpskDemod(sum(rxSig12.*conj(H12), 2));
        demod14 = bpskDemod(sum(rxSig14.*conj(H14), 2));
        %demod22 = bpskDemod(sum(decData_2.*conj(squeeze(H22(:,1,:))), 2));
        demod22 = bpskDemod(decData_2);
        
        % Calculate and update BER for current EbNo value
        %   for uncoded 1x1 system
        ber_noDiver(:,idx)  = errorCalc1(data, demod11);
        %   for Alamouti coded 2x1 system
        ber_Alamouti(:,idx) = errorCalc2(data, demod21);
        %   for Maximal-ratio combined 1x2 system
        ber_MaxRatio(:,idx) = errorCalc3(data, demod12);
        
        ber_MaxRatio_2(:,idx) = errorCalc4(data, demod14);
        ber_Alamouti_2(:,idx) = errorCalc5(data, demod22);
        
    end
    
    semilogy(ax,EbNo(1:idx), ber_noDiver(1,1:idx), 'ro', ...
             EbNo(1:idx), ber_Alamouti(1,1:idx), 'gd', ...
             EbNo(1:idx), ber_MaxRatio(1,1:idx), 'bv', ...
             EbNo(1:idx), ber_MaxRatio_2(1,1:idx), 'rs', ...
             EbNo(1:idx), ber_Alamouti_2(1,1:idx), 'b^' ...
             );
    legend(ax,'No Diversity (1Tx, 1Rx)', 'Alamouti (2Tx, 1Rx)',...
           'Maximal-Ratio Combining (1Tx, 2Rx)', ...
           'Maximal-Ratio Combining (1Tx, 4Rx)', ...
           'Alamouti (2Tx, 2Rx)');
    
    drawnow;
end 
 
% Curve fitting
fitBER11 = berfit(EbNo, ber_noDiver(1,:));
fitBER21 = berfit(EbNo, ber_Alamouti(1,:));
fitBER12 = berfit(EbNo, ber_MaxRatio(1,:));
fitBER14 = berfit(EbNo, ber_MaxRatio_2(1,:));
fitBER22 = berfit(EbNo, ber_Alamouti_2(1,:));


semilogy(ax,EbNo, fitBER11, 'r', ...
        0:2:(2*(length(fitBER21)-1)), fitBER21, 'g', ...
        0:2:(2*(length(fitBER12)-1)), fitBER12, 'b', ...
        0:2:(2*(length(fitBER14)-1)), fitBER14, 'k', ...
        0:2:(2*(length(fitBER22)-1)), fitBER22, 'b');
hold(ax,'off');

rng(s);

%% References
% # S. M. Alamouti, "A simple transmit diversity technique for wireless
% communications", IEEE(R) Journal on Selected Areas in
% Communications, Vol. 16, No. 8, Oct. 1998, pp. 1451-1458.
% # V. Tarokh, H. Jafarkhami, and A.R. Calderbank, "Space-time block codes
% from orthogonal designs", IEEE Transactions on Information Theory,
% Vol. 45, No. 5, Jul. 1999, pp. 1456-1467.
% # A.F. Naguib, V. Tarokh, N. Seshadri, and A.R. Calderbank, "Space-time
% codes for high data rate wireless communication: Mismatch
% analysis", Proceedings of IEEE International Conf. on
% Communications, pp. 309-313, June 1997.
% # V. Tarokh, H. Jafarkhami, and A.R. Calderbank, "Space-time block codes
% for wireless communications: Performance results", IEEE Journal on
% Selected Areas in Communications, Vol. 17,  No. 3, Mar. 1999, pp.
% 451-460.
