#include "I2Cdev.h"
#include "MPU9250_9Axis_MotionApps41.h"
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
#include "Wire.h"
#endif


MPU9250 mpu;
#define OUTPUT_TEAPOT // processing
#define INTERRUPT_PIN 14 



bool dmpReady = false; // set true if DMP init was successful
uint8_t mpuIntStatus; // holds actual interrupt status byte from MPU
uint8_t devStatus; // return status after each device operation (0 = success, !0 = error)
uint16_t packetSize; // expected DMP packet size (default is 42 bytes)
uint16_t fifoCount; // count of all bytes currently in FIFO
uint8_t fifoBuffer[64]; // FIFO storage buffer



Quaternion q; // [w, x, y, z] quaternion container
VectorInt16 aa; // [x, y, z] accel sensor measurements
VectorInt16 aaReal; // [x, y, z] gravity-free accel sensor measurements
VectorInt16 aaWorld; // [x, y, z] world-frame accel sensor measurements
VectorFloat gravity; // [x, y, z] gravity vector
float euler[3]; // [psi, theta, phi] Euler angle container
float ypr[3]; // [yaw, pitch, roll] yaw/pitch/roll container and gravity vector

// packet structure for InvenSense teapot demo

uint8_t teapotPacket[14] = { '$', 0x02, 0, 0, 0, 0, 0, 0, 0, 0, 0x00, 0x00, '\r', '\n' };

// ================================================================

// === INTERRUPT DETECTION ROUTINE ===

// ================================================================

volatile bool mpuInterrupt = false; // indicates whether MPU interrupt pin has gone high




void dmpDataReady() {

  mpuInterrupt = true;

}




extern "C" {

#include "user_interface.h"

}




#include <ESP8266WiFi.h>

#include <WiFiClient.h>

#include <EEPROM.h>

#include <string.h>




#define MAX_SRV_CLIENTS 6

WiFiServer server(23);

WiFiClient serverClients[MAX_SRV_CLIENTS];

WiFiClient client;




char Name[32] = "PUPPYWORLD"; // Standard name part

char ID[8] ; // buffer of ID of the ESP8266 ID




IPAddress myIP;

int connected = 0 ;




const char *ssid = "SOFTAP";

const char *password = "123456789";




void setup() {




  Serial.begin(9600);

  itoa(ESP.getChipId(), ID, 10); // get ID of ESP

  // Convert ID to constant Char

  for (int i = 0; i < 8; i ++)

  {

    Name[i + 12] = ID[i];

  }




  wifi_station_disconnect();

  wifi_set_opmode(0x02); // SETTING IT TO AP MODE




  const char *ssid = Name;

  WiFi.softAP(ssid, password, 8, 0);

  myIP = WiFi.softAPIP();

  Serial.print("AP IP address: ");

  Serial.println(myIP);




  server.begin();

  server.setNoDelay(false);

  Serial.println("TCP Server Setup done");

  delay(5000);




#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE

  Wire.begin();

  Wire.setClock(400000); // 400kHz I2C clock. Comment this line if having compilation difficulties

#elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE

  Fastwire::setup(400, true);

#endif

 




  while (!Serial);

  Serial.println(F("Initializing I2C devices..."));

  mpu.initialize();




  // verify connection

  Serial.println(F("Testing device connections..."));

  Serial.println(mpu.testConnection() ? F("MPU9250 connection successful") : F("MPU9250 connection failed"));

  Serial.println(F("Initializing DMP..."));

  devStatus = mpu.dmpInitialize();

  

  mpu.setXGyroOffset(220);

  mpu.setYGyroOffset(76);

  mpu.setZGyroOffset(-85);

  mpu.setZAccelOffset(1788); // 1688 factory default for my test chip

  if (devStatus == 0) {

    Serial.println(F("Enabling DMP...")); // turn on the DMP, now that it's ready

    mpu.setDMPEnabled(true); // enable Arduino interrupt detection    

    Serial.println(F("Enabling interrupt detection (Arduino external interrupt 0)..."));

    attachInterrupt(digitalPinToInterrupt(INTERRUPT_PIN), dmpDataReady, RISING);

    mpuIntStatus = mpu.getIntStatus();  // set our DMP Ready flag so the main loop() function knows it's okay to use it   

    Serial.println(F("DMP ready! Waiting for first interrupt..."));

    dmpReady = true;    

    packetSize = mpu.dmpGetFIFOPacketSize(); // get expected DMP packet size for later comparison

  } else {    

    Serial.print(F("DMP Initialization failed (code "));

    Serial.print(devStatus);

    Serial.println(F(")"));

  }

}




void loop() {

  uint8_t i;

  //check if there are any new clients

  if (server.hasClient()) {

    connected = 0;

    for (i = 0; i < MAX_SRV_CLIENTS; i++) { //find free/disconnected spot     

      if (!serverClients[i] || !serverClients[i].connected()) {

        if (serverClients[i]) serverClients[i].stop();

        serverClients[i] = server.available();

        Serial.print("New client: "); Serial.println(i);

        continue;

      }

      connected ++;

    }  

    Serial.print("Connected clients = ");

    Serial.println(connected);   

    WiFiClient serverClient = server.available(); //no free/disconnected spot so reject  

    serverClient.stop();

  }

 

  for (i = 0; i < MAX_SRV_CLIENTS; i++) {

    if (serverClients[i] && serverClients[i].connected()) {

      while (1) {       

        if (!dmpReady) return; // if programming failed, don't try to do anything        

        while (!mpuInterrupt && fifoCount < packetSize) {

        }

                

        mpuInterrupt = false; // reset interrupt flag and get INT_STATUS byte

        mpuIntStatus = mpu.getIntStatus();

        

        fifoCount = mpu.getFIFOCount();// get current FIFO count




        

        if ((mpuIntStatus & 0x10) || fifoCount == 1024) {          

          mpu.resetFIFO();// reset so we can continue cleanly

          Serial.println(F("FIFO overflow!"));          

        } else if (mpuIntStatus & 0x02) { // otherwise, check for DMP data ready interrupt (this should happen frequently)

          

          while (fifoCount < packetSize) fifoCount = mpu.getFIFOCount();// wait for correct available data length, should be a VERY short wait          

          mpu.getFIFOBytes(fifoBuffer, packetSize); // read a packet from FIFO          

          fifoCount -= packetSize;




          #ifdef OUTPUT_TEAPOT // display quaternion values in InvenSense Teapot demo format:   //jiwon                 

               sendTeapotPacket(i);  //jiwon

          #endif  //jiwon

        }//else if ends

      }//while ends

    }//if ends

  }//for ends

  

}//loop() ends







void sendTeapotPacket(int i) { //jiwon

  teapotPacket[2] = fifoBuffer[0];

  teapotPacket[3] = fifoBuffer[1];

  teapotPacket[4] = fifoBuffer[4];

  teapotPacket[5] = fifoBuffer[5];

  teapotPacket[6] = fifoBuffer[8];

  teapotPacket[7] = fifoBuffer[9];

  teapotPacket[8] = fifoBuffer[12];

  teapotPacket[9] = fifoBuffer[13];




  for(int j=0; j<14; j++){  //jiwon

    serverClients[i].write((char *)&teapotPacket[j], 1);  //jiwon

  } 

  teapotPacket[11]++; // packetCount, loops at 0xFF on purpose

}//send TeapotPacket

