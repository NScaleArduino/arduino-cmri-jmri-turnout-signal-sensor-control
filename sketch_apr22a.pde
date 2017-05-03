#include <CMRI.h>
#include <SPI.h>


// Work in progress

#include <VarSpeedServo.h>

// Pin 0 = JMRI #1 = Sensor on # 101

const int SENSOR_GAP = 99;
const int ANALOG_GAP = 40;

const int ALIGN_MAIN = 75;
const int ALIGN_DIVERGENT = 120;

const int STEP_DELAY = 10;
const int NUM_TURNOUTS = 17;
const int NUM_TOGGLES = 39;
const int NUM_SENSORS = 16;


VarSpeedServo servos[NUM_TURNOUTS];

CMRI cmri;

bool CONNECTED = false;


typedef struct TURNOUT_DEF {
  int pin;
  int pos_main;
  int pos_div;
  int pos_default;
};

typedef struct TURNOUT_DATA {
  TURNOUT_DEF data;
  int alignment;
  int target_pos;
};


typedef struct TOGGLES {
  int pin;
  bool on;
};

typedef struct SENSORS {
  int pin;
};

/**
 * Each servo has 2 pins for red/green LEDs
 * 
 
 * 54 pins
 * - 0 - 17 = servos
 * - 18 - 36 = on
 * - 37 - 48 = off
 
 * 
 */


TOGGLES toggles[NUM_TOGGLES] = {
  {18, LOW},
  {19, LOW},
  {20, LOW},
  {21, LOW},
  {22, LOW},
  {23, LOW},
  {24, LOW},
  {25, LOW},
  {26, LOW},
  {27, LOW},
  
  {28, LOW},
  {29, LOW},
  {30, LOW},
  {31, LOW},
  {32, LOW},
  {33, LOW},
  {34, LOW},
  {35, LOW},
  {36, LOW},
  
  {37, LOW},
  {38, LOW},
  {39, LOW},
  {40, LOW},
  {41, LOW},
  {42, LOW},
  {43, LOW},
  {44, LOW},
  {45, LOW},
  {46, LOW},
  {47, LOW},
  {48, LOW},
};


/**f 
 * Pins 2 - 11 = 10x servos
 */

TURNOUT_DATA turnouts[NUM_TURNOUTS] = {
  {{2, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},
  {{3, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},
  {{4, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},
  {{5, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},
  {{6, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},
  {{7, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},
  {{8, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},
  {{9, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN}, 
 {{10, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{11, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{12, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{13, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{14, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{15, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{16, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{17, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
 {{18, ALIGN_MAIN, ALIGN_DIVERGENT, ALIGN_MAIN}, HIGH, ALIGN_MAIN},  
};

SENSORS sensors[16] = {
  {A0},
  {A1},
  {A2},
  {A3},
  {A4},
  {A5},
  {A6},
  {A7},
  {A8},
  {A9},
  {A10},
  {A11},
  {A12},
  {A13},
  {A14},
  {A15},
};



void setup()
{
  Serial.begin(9600, SERIAL_8N2);
  
  SPI.begin();

  for (int i = 0; i < NUM_TURNOUTS; i++) {
    servos[i].attach(turnouts[i].data.pin);

    setTurnout(i, turnouts[i].data.pos_default, true);
  }

  for (int i = 0; i < NUM_TOGGLES; i++) {
      pinMode(toggles[i].pin, OUTPUT);

      setLed(i, toggles[i].on, true);
  }
  
}

void loop()
{
    CONNECTED = true;
    
    cmri.process();
       
    for (int i = 0; i < NUM_TURNOUTS; i++) {
      setTurnout(i, getBit(turnouts[i].data.pin), false);
    }
  
    for (int i = 0; i < NUM_TOGGLES; i++) {
      setLed(i, getBit(toggles[i].pin), false);
    }

    for (int i = 0; i < NUM_SENSORS; i++) {
      //Serial.println(sensors[i].pin);
      setBit(i, analogRead(sensors[i].pin) < 300 && analogRead(sensors[i].pin) > 15 ? HIGH : LOW);
    }
}

int getBit(int pin) {
  return cmri.get_bit(pin - 2);
}

void setBit(int pin, int status) {
  cmri.set_bit(pin, status);
//if(status == HIGH){
 // Serial.println(pin);
 
 //Serial.println(status);
 //Serial.println('----');
  //}
  
}

void setLed(int id, int status, bool force){

  if (!CONNECTED) {
    status = toggles[id].on;
  }

  if (toggles[id].on == status && force == false) {
    return true;
  }
  
  toggles[id].on =  status;
    
  digitalWrite(toggles[id].pin, status);

  if (id - 2 <= 48) {
    setBit(toggles[id].pin - 2, status);

  }
}

void setTurnout(int id, byte align, bool force) {
  if (!CONNECTED) {
    align = turnouts[id].data.pos_default;
  }
  
  if (turnouts[id].alignment == align && force == false) {
    return true;
  }
  
  switch (align) {
    case HIGH:
      turnouts[id].target_pos = turnouts[id].data.pos_main;

      break;
    case LOW:
      turnouts[id].target_pos = turnouts[id].data.pos_div;

      break;
  }

  turnouts[id].alignment = align;

  servos[id].write(turnouts[id].target_pos, STEP_DELAY, false);

  //setBit(turnouts[id].data.pin - 2, turnouts[id].alignment);
 
}
