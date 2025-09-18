%% =============== clear & setup path =================================================================================================
clearvars                                % clear all previous data in MATLAB workspace
clc                                      % clear MATLAB command window
close all                                % close all previously opened figures and graphs

% =====================================================================================================================================
% ================================                  demodulation of LoraWAN packet                     ================================
% =====================================================================================================================================
%% print parameters
set(0,'DefaultFigureWindowStyle','docked');
set(0,'DefaultAxesFontSize', 20);
set(0,'DefaultTextFontSize', 20);
set(0,'DefaultlineLineWidth', 1.5);

%% LoRa parameters
BW = 125e3;
SF = 8;
Fc = 868.1e6;
Fs = 2*BW;
symbol_time = 2^SF/BW;
symbols_per_frame = 1;
sp_per_frame = 5*BW;
nb_frame = 5;

% plutoSDR receiver
rxPluto = sdrrx('Pluto',...
           'RadioID','usb:0',...
           'CenterFrequency',Fc,...
           'GainSource','AGC Slow Attack',...
           'BasebandSampleRate',Fs,...
           'SamplesPerFrame',sp_per_frame,...
           'OutputDataType','double');

for counter = 1:nb_frame
    signal = rxPluto();
end

% save signal_lora_4p.mat;

%% Recorded signal import
% load signal_lora_1p.mat;

%% Signal channelization (DDC)
n = length(signal);                    % length of recorded signal
f0 = (-n/2:n/2-1)*(Fs/n);               % 0-centered frequency range
t0 = 0:1/Fs:length(signal)/Fs-1/Fs;    % time range

figure
plot(t0*1e3,abs(signal));
title('Scope of Baseband signal');
xlabel('time [ms]');
ylabel('amplitude [volt]');
grid on;

figure
Z0 = 50;
ycur = signal/(2*Z0);
plot(t0*1e3,10e3*(abs(ycur)));
title('Scope of Baseband signal');
xlabel('time [ms]');
ylabel('current [mA]');
grid on;

figure
y = fftshift(fft(signal));          % FFT of signal and shift values        
ypow = (abs(y).^2)/(2*Z0)/n;                % 0-centered power
plot(1e-3*f0,10*log10(ypow)+30);
title('Spectrum of Basband Signal');
xlabel('frequency [kHz]');
ylabel('power [dBm]');
grid on;

figure
periodogram(signal,hamming(n),[],Fs,'centered','power');
grid on;
  
%% Chirp generation
f0 = -BW/2;
f1 = BW/2;
t = 0:1/Fs:symbol_time - 1/Fs;

upChirp = chirp(t, f0, symbol_time, f1, 'linear');
upChirp = repmat(upChirp,1,10);

%% Signal synchronization and cropping
% Find the start of the signal
[corr, lag] = xcorr(signal, upChirp);
corrThresh = max(abs(corr))/4;
cLag = find(abs(corr) > corrThresh, 1);
signalStartIndex = abs(lag(cLag)) + 9*symbol_time*Fs;
signalEndIndex = round(signalStartIndex + symbols_per_frame*symbol_time*Fs);
 
% Synchronize SFD
symbol_offset = 0.25; % 12.25 to skip preamble and SFD
signalStartIndex = round(signalStartIndex + symbol_offset*symbol_time*Fs);
%signal = signal(signalStartIndex:signalEndIndex);
clear lag corr

%% De-chirping
upChirp = repmat(upChirp,1,ceil(length(signal)/length(upChirp)));
upChirp = upChirp(1:length(signal));
signal = signal';
de_chirped = signal.*conj(upChirp);

%% Spectrogram computation
% To create a spectrogram 'grid' of symbols, these are the parameters.
signal3 = de_chirped;
Nfft = 2^SF; % 128
window_length = Nfft; % same as symbol_time*Fs;
[sig, f, t] = spectrogram(signal3, blackman(window_length), 0, Nfft, Fs);

%% Bit extraction
[~, symbols] = max(abs(sig));
symbols = mod(symbols - round(mean(symbols(1:8))), 2^SF);
bits =  dec2base(symbols, 2);
