%% --------------------- User Parameters ---------------------
fs            = 1000;          % Sampling rate [Hz]
Vref          = 3.0;           % ADC reference voltage [V]
ADC_bits      = 10;            % ADC resolution [bits]
ADC_max       = 2^ADC_bits - 1;% Max ADC code (e.g., 1023 for 10-bit)
trim_seconds  = [];            % [] = use full length, or e.g., 10 to keep first 10 s
use_notch_50  = true;          % Apply 50 Hz notch
use_notch_100 = true;          % Apply 100 Hz notch (harmonic)

% Band-pass for surface EMG (typical)
bp_f1 = 20;                    % Lower half-power frequency [Hz]
bp_f2 = 150;                   % Upper half-power frequency [Hz]

% Moving window settings
rms_win_s   = 1.0;             % RMS window length [s]
power_win_s = 1.0;             % Power smoothing window length [s]

% Spectral settings
spec_winN   = 1024;            % Spectrogram window length (samples)
spec_ovlp   = 0.75;            % Spectrogram overlap fraction
spec_nfft   = 1024;            % Spectrogram NFFT
welch_winN  = 1024;            % Welch window length (samples)
welch_ovlp  = 0.5;             % Welch overlap fraction
welch_nfft  = 2048;            % Welch NFFT

%% --------------------- File Selection ----------------------
% GUI file picker (TXT/CSV/DAT)
[file, path] = uigetfile( ...
    {'*.txt;*.csv;*.dat','EMG files (*.txt, *.csv, *.dat)'; '*.*','All files (*.*)'}, ...
    'Select EMG data file');
if isequal(file,0)
    error('Aborted: no file selected.');
end
filename = fullfile(path, file);

%% --------------------- Load & Validate ---------------------
assert(isfile(filename), 'File does not exist: %s', filename);

x_counts = readmatrix(filename);
x_counts = x_counts(~isnan(x_counts));
x_counts = double(x_counts(:));           % ensure double column vector

% Report out-of-range samples (instead of silently clipping)
n_oor = sum(x_counts < 0 | x_counts > ADC_max);
if n_oor > 0
    warning('%d samples outside ADC range [0, %d]. They will be clipped.', n_oor, ADC_max);
end
x_counts = min(max(x_counts, 0), ADC_max);

% Convert ADC codes to volts
x_v = (x_counts / ADC_max) * Vref;

% Remove DC bias (EMG should be centered around 0 V after analog offset)
x_v = x_v - median(x_v);

% Optional trimming
N = numel(x_v);
if ~isempty(trim_seconds)
    N = min(N, round(trim_seconds * fs));
    x_v = x_v(1:N);
else
    N = numel(x_v);
end
t = (0:N-1).' / fs;

%% --------------------- Filtering ---------------------------
% Zero-phase band-pass (Butterworth via designfilt)
bp = designfilt('bandpassiir', ...
    'FilterOrder', 4, ...
    'HalfPowerFrequency1', bp_f1, ...
    'HalfPowerFrequency2', bp_f2, ...
    'SampleRate', fs);
x_bp = filtfilt(bp, x_v);

% Notch filters for power-line interference (PL = 50 Hz)
x_f = x_bp;
if use_notch_50
    d50 = designfilt('bandstopiir','FilterOrder', 2, ...
        'HalfPowerFrequency1', 49,'HalfPowerFrequency2', 51, ...
        'SampleRate', fs);
    x_f = filtfilt(d50, x_f);
end
if use_notch_100
    d100 = designfilt('bandstopiir','FilterOrder', 2, ...
        'HalfPowerFrequency1', 99,'HalfPowerFrequency2', 101, ...
        'SampleRate', fs);
    x_f = filtfilt(d100, x_f);
end

%% --------------------- Time-Domain Plot --------------------
figure(1); clf
plot(t, x_f); grid on
title('EMG Signal')
xlabel('Time [s]'); ylabel('Amplitude [V]');

%% --------------------- Basic Statistics -------------------
x_max = max(x_f);
x_min = min(x_f);
x_mean = mean(x_f);
x_var = var(x_f);        % [V^2]
x_std = std(x_f);        % [V]
x_rms = sqrt(mean(x_f.^2));

fprintf('Max: %.6f V\nMin: %.6f V\nMean: %.6f V\nVar: %.6g V^2\nSTD: %.6f V\nRMS: %.6f V\n', ...
    x_max, x_min, x_mean, x_var, x_std, x_rms);

%% --------------------- Moving RMS & Power ------------------
rms_winN   = max(1, round(rms_win_s   * fs));
power_winN = max(1, round(power_win_s * fs));

% Moving RMS (compute via moving mean of squared signal)
x_movrms = sqrt(movmean(x_f.^2, rms_winN));

% Instantaneous power (V^2) smoothed by moving average
p_inst = x_f.^2;
p_mean = movmean(p_inst, power_winN);

figure(2); clf
yyaxis left
plot(t, x_movrms, 'LineWidth', 1); ylabel('RMS [V]'); grid on
yyaxis right
plot(t, p_mean, 'LineWidth', 1);   ylabel('Power [V^2]')
xlabel('Time [s]'); title('Moving RMS and Power');

%% --------------------- Amplitude Spectrum ------------------
% Detrend (remove mean) + window (Hann) for amplitude spectrum
xw = detrend(x_f, 0);
w  = hann(N);
xw = xw .* w;

X  = fft(xw, N);
f  = (0:floor(N/2))' * (fs/N);

% Amplitude scaling (single-sided), normalize by window coherent gain
cg = sum(w)/2;                 % coherent gain for amplitude
A  = abs(X(1:numel(f))) / cg;
A(2:end-1) = 2*A(2:end-1);     % single-sided amplitude

figure(3); clf
plot(f, A, 'LineWidth', 1); grid on
xlim([0 500])
xlabel('Frequency [Hz]'); ylabel('Amplitude [V]')
title('Amplitude Spectrum');

%% --------------------- Power Spectral Density (Welch) ------
welch_win   = hann(welch_winN);
welch_ovlpN = round(welch_ovlp * welch_winN);

[pxx, f_w] = pwelch(x_f, welch_win, welch_ovlpN, welch_nfft, fs);

figure(4); clf
plot(f_w, 10*log10(pxx), 'LineWidth', 1); grid on
xlim([0 500])
xlabel('Frequency [Hz]'); ylabel('PSD [dBV^2/Hz]')
title('Power Spectral Density');

%% --------------------- Histogram ---------------------------
figure(5); clf
histogram(x_f, 50); grid on
title('Histogram of Filtered EMG')
xlabel('Amplitude [V]'); ylabel('Count');

%% --------------------- Spectrogram -------------------------
ovl_spec = round(spec_ovlp * spec_winN);
figure(6); clf
spectrogram(x_f, hann(spec_winN), ovl_spec, spec_nfft, fs, 'yaxis');
title('EMG Spectrogram')
xlabel('Time [s]'); ylabel('Frequency [Hz]');
colorbar

%% --------------------- Optional EMG Features ---------------
% Common EMG features over 200 ms window
feat_win_s = 0.2;
featN = max(1, round(feat_win_s * fs));

MAV = movmean(abs(x_f), featN);                    % Mean Absolute Value
WL  = movsum(abs(diff([0; x_f])), featN);          % Waveform Length
ZC  = movsum([0; abs(diff(sign(x_f)))>0], featN);  % Zero Crossings (approx)

figure(7); clf
plot(t, MAV, 'DisplayName','MAV'); hold on
plot(t, WL,  'DisplayName','WL');
plot(t, ZC,  'DisplayName','ZC'); grid on
xlabel('Time [s]'); title('EMG Features')
legend('Location','best')
