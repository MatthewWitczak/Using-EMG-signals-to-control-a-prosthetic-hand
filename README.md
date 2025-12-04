# Using-EMG-signals-to-control-a-prosthetic-hand
This project demonstrates how electromyographic (EMG) signals can be used to control a prosthetic hand. The software acquires raw EMG data from surface electrodes, processes it in real time using digital filters, and translates the extracted muscle activity into control commands for servo motors.

# EMG_Without_Filtration.ino
This program reads raw EMG values from the analog input without any filtering, applies a simple threshold (600) as a basic envelope detector, and streams the raw samples over the USB serial port for monitoring. It also contains example logic that would drive five servos to 180° when activity is detected and return them to 0° after 1.3 s of inactivity, but this can be treated as demonstration code if no servos are connected. The loop is paced with a 500 µs delay (≈2 kHz sampling cadence), and timing measurements are printed when debugging is enabled.

# EMG_Signal_Analysis.m
This MATLAB script provides a complete pipeline for surface EMG (electromyography) signal analysis. It allows the user to select a data file via a file picker, converts raw ADC samples to voltages, removes DC bias, and applies band-pass and optional notch filtering to clean the signal. The script computes basic statistics such as mean, variance, RMS, and displays moving RMS and power over time. It also includes frequency-domain analysis using FFT and spectrograms, as well as a histogram of signal amplitudes. Additionally, it extracts common EMG features. The tool is designed for fast exploration of EMG data in both time and frequency domains.

# emg_data.txt
Raw EMG signal measured on the forearm using surface electrodes, sampled at 1000 Hz with a 10-bit ADC (0–1023). The file is provided as example input data for testing and demonstration of the analysis script.

# EMG-Based Prosthetic Hand Control Program
The program that controls a prosthetic hand using EMG signals is available in this repository: https://github.com/MatthewWitczak/Using-EMG-signals-to-control-a-prosthetic-hand
