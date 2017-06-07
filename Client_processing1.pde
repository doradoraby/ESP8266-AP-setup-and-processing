//Raven Kwok aka Guo, Ruiwen
//ravenkwok.com
//vimeo.com/ravenkwok
//flickr.com/photos/ravenkwok

import processing.net.*; 
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;

Client myClient; 
byte[] byteBuffer = new byte[4];
float valAxis[]=new float[9];
//byte[] byteBuffer = new byte[10];
int count=0;

char[] teapotPacket = new char[14];
int serialCount = 0;
int synced = 0;
int interval = 0;
float[] q = new float[4];
Quaternion quat = new Quaternion(1, 0, 0, 0);


ArrayList<Particle> pts;
PFont f;

void setup() {
  size(1000, 1000, P2D);
  smooth();
  frameRate(30);
  colorMode(HSB);
  rectMode(CENTER);

  pts = new ArrayList<Particle>();
  myClient = new Client(this, "192.168.4.1", 23);

  //f = createFont("Calibri", 24, true);

  background(255);
}

void getVal(){
  interval = millis();
  
  while (myClient.available() > 0) {
    int ch = myClient.read();

    if (synced == 0 && ch != '$')
      return;
    synced = 1;
    println ((char)ch);
    if ((serialCount == 1 && ch != 2)|| (serialCount == 12 && ch != '\r')|| (serialCount == 13 && ch != '\n')) {
      serialCount = 0;
      synced = 0;
      return;
    }
    
    if (serialCount > 0 || ch == '$') {
      teapotPacket[serialCount++] = (char)ch;
      
      if (serialCount == 14) {
        serialCount = 0;
        q[0] = ((teapotPacket[2] << 8) | teapotPacket[3]) / 16384.0f;
        q[1] = ((teapotPacket[4] << 8) | teapotPacket[5]) / 16384.0f;
        q[2] = ((teapotPacket[6] << 8) | teapotPacket[7]) / 16384.0f;
        q[3] = ((teapotPacket[8] << 8) | teapotPacket[9]) / 16384.0f;
        
        for (int i = 0; i < 4; i++)
          if (q[i] >= 2)
            q[i] = -4 + q[i];

       // quat.set(q[0], q[1], q[2], q[3]);
      }
    }
  }
}
  


void draw() {
  if (myClient.available() > 0) {
    getVal();
   // background(255);

    for (int i=0;i<10;i++) {
     
     float sum_1 = int(q[0]*2000);
     float sum_2 = int(q[1]*1200);
      if(sum_1<0){sum_1 = sum_1 *-1;}
      if(sum_2<0){sum_2 = sum_2 *-1;}
      
      println("q[0] = "+sum_1);
      println("q[1] = "+sum_2);
      
      Particle newP = new Particle(sum_1, sum_2, i+pts.size(), i+pts.size());
      pts.add(newP);
    }


  for (int i=0; i<pts.size(); i++) {
    Particle p = pts.get(i);
    p.update();
    p.display();
  }

  for (int i=pts.size()-1; i>-1; i--) {
    Particle p = pts.get(i);
    if (p.dead) {
      pts.remove(i);
    }
  }
}
}


class Particle{
  PVector loc, vel, acc;
  int lifeSpan, passedLife;
  boolean dead;
  float alpha, weight, weightRange, decay, xOffset, yOffset;
  color c;
  
  Particle(float x, float y, float xOffset, float yOffset){
    loc = new PVector(x,y);
    
    float randDegrees = random(360);
    vel = new PVector(cos(radians(randDegrees)), sin(radians(randDegrees)));
    vel.mult(random(5));
    
    acc = new PVector(0,0);
    lifeSpan = int(random(30, 90));
    decay = random(0.75, 0.9);
    if(q[2]<0){q[2] = q[2]*-1;}
    if(q[3]<0){q[3] = q[3]*-1;}
   // if(valAxis[8]<0){valAxis[8] = valAxis[8]*-1;}
  
    c = color(q[2]*150,q[3]*150,210);
    println(q[2]*150);
    println(q[3]*150);
    weightRange = random(3,50);
    
    this.xOffset = xOffset;
    this.yOffset = yOffset;
  }
  
  void update(){
    if(passedLife>=lifeSpan){
      dead = true;
    }else{
      passedLife++;
    }
    
    alpha = float(lifeSpan-passedLife)/lifeSpan * 70+50;
    weight = float(lifeSpan-passedLife)/lifeSpan * weightRange;
    
    acc.set(0,0);
    
    float rn = (noise((loc.x+frameCount+xOffset)*0.01, (loc.y+frameCount+yOffset)*0.01)-0.5)*4*PI;
    float mag = noise((loc.y+frameCount)*0.01, (loc.x+frameCount)*0.01);
    PVector dir = new PVector(cos(rn),sin(rn));
    acc.add(dir);
    acc.mult(mag);
    
    float randDegrees = random(360);
    PVector randV = new PVector(cos(radians(randDegrees)), sin(radians(randDegrees)));
    randV.mult(0.5);
    acc.add(randV);
    
    vel.add(acc);
    vel.mult(decay);
    vel.limit(3);
    loc.add(vel);
  }
  
  void display(){
    strokeWeight(weight+1.5);
    noStroke();
    //stroke(0, alpha);
    point(loc.x, loc.y);
    
    strokeWeight(weight);
    stroke(c);
    point(loc.x, loc.y);
  }
}