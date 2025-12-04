#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif
#include <Servo.h>
#define TIMING_DEBUG 1
#define SensorInputPin A0

Servo myServos[5];

static int Threshold = 600;

unsigned long timeStamp;
unsigned long timeBudget;
unsigned long lastEMGSignalTime = 0;
const int EMGSignalTimeout = 1300;

void setup() {
    Serial.begin(115200);

    myServos[0].attach(9);
    myServos[1].attach(10);
    myServos[2].attach(11);
    myServos[3].attach(12);
    myServos[4].attach(13);

    timeBudget = 1000;
}

void loop() {
    timeStamp = micros();
    int Value = analogRead(SensorInputPin);
    int envelope = (Value > Threshold) ? Value : 0;
    timeStamp = micros() - timeStamp;

    if (TIMING_DEBUG) {
        Serial.print("Raw Data: ");
        Serial.println(Value);
    }

    if (envelope > Threshold) {
        for (int i = 0; i < 5; i++) {
            myServos[i].write(180);
        }
        lastEMGSignalTime = millis();
    } else {
        if (millis() - lastEMGSignalTime > EMGSignalTimeout) {
            for (int i = 0; i < 5; i++) {
                myServos[i].write(0);
            }
        }
    }

    delayMicroseconds(500);
}
