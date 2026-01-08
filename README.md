# Using-EMG-signals-to-control-a-prosthetic-hand
This project demonstrates how electromyographic (EMG) signals can be used to control a prosthetic hand. The software acquires raw EMG data from surface electrodes, processes it in real time using digital filters, and translates the extracted muscle activity into control commands for servo motors.

# EMG_Without_Filtration.ino
This program reads raw EMG values from the analog input without any filtering, applies a simple threshold (600) as a basic envelope detector, and streams the raw samples over the USB serial port for monitoring. It also contains example logic that would drive five servos to 180° when activity is detected and return them to 0° after 1.3 s of inactivity, but this can be treated as demonstration code if no servos are connected. The loop is paced with a 500 µs delay (≈2 kHz sampling cadence), and timing measurements are printed when debugging is enabled.

# EMG_Signal_Analysis.m
This MATLAB script provides a complete pipeline for surface EMG (electromyography) signal analysis. It allows the user to select a data file via a file picker, converts raw ADC samples to voltages, removes DC bias, and applies band-pass and optional notch filtering to clean the signal. The script computes basic statistics such as mean, variance, RMS, and displays moving RMS and power over time. It also includes frequency-domain analysis using FFT and spectrograms, as well as a histogram of signal amplitudes. Additionally, it extracts common EMG features. The tool is designed for fast exploration of EMG data in both time and frequency domains.

# emg_data.txt
Raw EMG signal measured on the forearm using surface electrodes, sampled at 1000 Hz with a 10-bit ADC (0–1023). The file is provided as example input data for testing and demonstration of the analysis script.

# Characteristics of the EMG signal

The measured signal was processed and analyzed in MATLAB.

EMG signal waveform:
<p align="center">
  <img width="665" height="528" alt="Zrzut ekranu 2026-01-8 o 17 10 59" src="https://github.com/user-attachments/assets/2efaeb84-0875-43fc-85f3-856888a598fd" />
</p>

EMG signal spectrum:
<p align="center">
  <img width="665" height="528" alt="Zrzut ekranu 2026-01-8 o 17 11 14" src="https://github.com/user-attachments/assets/44ade454-6b77-4ebf-a75d-a00a6f684af8" />
</p>

EMG signal spectrogram:
<p align="center">
  <img width="665" height="528" alt="Zrzut ekranu 2026-01-8 o 17 11 23" src="https://github.com/user-attachments/assets/a8fa7efd-5419-479c-a50f-952b61b4cf14" />
</p>
