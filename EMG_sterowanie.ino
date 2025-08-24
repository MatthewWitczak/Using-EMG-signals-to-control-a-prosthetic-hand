// Attached libraries
#include "Arduino.h"
#include "EMGFilters.h"
#include <Servo.h>

#define TIMING_DEBUG 1          // Set to 1 to print debug info over Serial, 0 to disable
#define SensorInputPin A0       // Analog input pin for the EMG sensor

EMGFilters myFilter;            // EMG filter chain (HP/Notch/LP as configured below)
Servo myServos[5];              // Array of 5 servos (e.g., fingers of a prosthetic hand)

// Filter configuration
int sampleRate = SAMPLE_FREQ_1000HZ;  // Sampling frequency used by the filter chain
int humFreq    = NOTCH_FREQ_50HZ;     // Mains notch frequency (50 Hz in EU)
static int Threshold = 600;           // Decision threshold for the squared (envelope) signal

// Timing and state
unsigned long timeStamp;              // Measures per-loop processing time in microseconds
unsigned long timeBudget;             // Time budget per sample (not enforced in this code)
unsigned long lastEMGSignalTime = 0;  // When the last above-threshold EMG was detected (ms)
const int EMGSignalTimeout = 1300;    // After this many ms of silence, relax the servos

void setup() {
    // Initialize EMG filter chain:
    // init(sampleRate, notchFreq, enableHPF, enableNotch, enableLPF)
    myFilter.init(sampleRate, humFreq, true, true, true);

    // Serial for debug output
    Serial.begin(115200);

    // Attach servos to output pins (adjust pins to your wiring)
    myServos[0].attach(9);
    myServos[1].attach(10);
    myServos[2].attach(11);
    myServos[3].attach(12);
    myServos[4].attach(13);

    // Compute nominal time budget per sample, in microseconds (not actively used below)
    timeBudget = 1e6 / sampleRate;
}

void loop() {
    // Start timing this iteration
    timeStamp = micros();

    // Read raw EMG sample
    int Value = analogRead(SensorInputPin);

    // Filter the sample through the EMG filter chain
    int DataAfterFilter = myFilter.update(Value);

    // Very simple envelope proxy: square the filtered signal
    // Note: sq(int) promotes internally but here we store back to int.
    int envelope = sq(DataAfterFilter);

    // Zero out small values to create a hard gate at Threshold
    envelope = (envelope > Threshold) ? envelope : 0;

    // Measure processing time for this loop iteration
    timeStamp = micros() - timeStamp;

    // Optional debug print of the squared value (our envelope proxy)
    if (TIMING_DEBUG) {
        Serial.print("Squared Data: ");
        Serial.println(envelope);
        // You could also print timeStamp if you want to profile loop latency
        // Serial.print("Loop us: "); Serial.println(timeStamp);
    }

    // If envelope exceeds Threshold, treat this as an EMG activation
    if (envelope > Threshold) {
        // Drive all servos to the "active" (grip) position
        for (int i = 0; i < 5; i++) {
            myServos[i].write(180);
        }
        // Update last time an activation was seen
        lastEMGSignalTime = millis();
    } else {
        // If no activation has been seen for EMGSignalTimeout, relax servos
        if (millis() - lastEMGSignalTime > EMGSignalTimeout) {
            for (int i = 0; i < 5; i++) {
                myServos[i].write(0);
            }
        }
    }

    delayMicroseconds(500);
}
