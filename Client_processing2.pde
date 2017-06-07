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




//import gifAnimation.*;

import java.util.Iterator;

ArrayList<Part> parts;

float w = 500;

float h = 500;

PVector g = new PVector(0, .2);




float noiseoff=0;

//GifMaker gifExport;

color bgc = #212121;

color c1 = #61A523; 

color c2 = #C164B0;

float coloroff=random(255);

boolean record=false;




void setup() {

  size(500, 500, P2D);

  smooth();

  background(bgc);

  frameRate(25);

  parts = new ArrayList();

  myClient = new Client(this, "192.168.4.1", 23); 

  //  gifExport = new GifMaker(this, "export.gif");

  //  gifExport.setRepeat(0);  

  //createParticles();

}




void getval(){

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




Part paint(float x, float y, float dx, float dy, float size, Part parent, boolean bymouse) {

  float tx = x;

  float ty = y;




  float t=15+random(20);

  //color c = lerpColor(c1, c2, random(1)); 

  coloroff++;

  if (coloroff>255) {

    coloroff=0;

  }

  colorMode(HSB);

  color c = color(coloroff, 155, 255); 

  Part p = new Part(tx, ty, size, c);

  if (!bymouse) {

    p.c=parent.c;

  }




  p.velocity.x=0;

  p.velocity.y=0;

  

  

  

   

  if (dy == 0 && dx == 0) {

     dx=random(1)-.5; 

     dy=random(1)-.5;

  }

  p.acceleration.x=dx;

  p.acceleration.y=dy; 

  p.or_a.x = dx;

  p.or_a.y = dy;

  p.par=parent;

    

  parts.add(p);

  return p;

}

int fr = 0;

Part lastp=null;




void draw() {

if (myClient.available() > 0) {

  getval();

  noStroke();

  fill(bgc, 125);

  rectMode(CORNER);

  rect(0, 0, width, height);

  //background(bgc);




    lastp = paint(width/2 + q[0], height/2 + q[1], q[2]*20, q[3]*20, random(30), lastp, true);

    //paint(mouseX, mouseY, (pmouseX-mouseX)*-.1, (pmouseY-mouseY)*-.1, random(9), lastp, true);




  updateParticles();

  }

}










void rotate2D(PVector v, float theta) {

  float xTemp = v.x;

  v.x = v.x*cos(theta) - v.y*sin(theta);

  v.y = xTemp*sin(theta) + v.y*cos(theta);

}




void updateParticles() {

  if (parts.size()>0) {

    noiseoff+=.1;

    int s = parts.size()-1;

    //PVector prevpos = parts.get(parts.size()-1).position;

    for (int i = s; i >= 0; i--) {

      Part p = (Part) parts.get(i);      

      p.update();




      //      prevpos = p.position;

      //p.render();

      if (p.life<0) {

        parts.remove(p);

      }    

      if (p.life<.9 && p.spawned<25 && parts.size()<650 && p.life>.5) {

        p.spawned++;

        if (random(1)>.9) {

          //paint(p.position.x, p.position.y, random(10)-5, random(10)-5, random(5)-2, p);

          PVector dir = p.or_a;

          dir.normalize();

          rotate2D(dir, radians(random(45)-22.5));

          

          dir.mult(3);

          Part np = paint(p.position.x, p.position.y,dir.x, dir.y, p.size*.9, p, false);

          np.spawned=p.spawned;

        }

      }

      stroke(p.c, 5+p.life*255);

     // strokeWeight(noise(i+noiseoff)*3);

      //line(p.position.x, p.position.y, par.x, prevpos.y);

      if (p.par!=null) {

        line(p.position.x, p.position.y, p.par.position.x, p.par.position.y);

      }

      p.render();

    }

  

  }




}

/*

void keyPressed() {

  if (key == 's') {

    saveFrame("images/screen_#####.png");

  }




  if (key == 'a') {

    background(bgc);

    parts = new ArrayList();




    //createParticles();

  }

}

*/

class Part {

  Part par=null;

  float spawned = 0;

  float life = 1;

  float maxspeed=10;

  float r=random(360);

  // float g=1.8;

  PVector position = new PVector(0, 0);

  PVector velocity = new PVector(0, 0);

  PVector acceleration = new PVector(0, 0);

  PVector or_a = new PVector(0, 0);

  float size = 10;

  color c;

  float min_d = 5;

  Part nei = null;




  Part(float x, float y, float size, color c) {

    position.x=x;

    position.y=y;

    this.size = size;

    this.c=c;

    

  }

  void update() {

    life-=.01;




    velocity.add(acceleration);




    velocity.limit(15);

    // size=random(5);

    velocity.mult(.95);

    position.add(velocity);




    acceleration.mult(0);

  }

  void render() {    

    pushMatrix();

    translate(position.x, position.y);

    rotate(radians(r));

    //    r+=size;

    //stroke(c);

    //    line(-velocity.x, -velocity.y, 0, 0);

    //line(nei.position.x-position.x, nei.position.y-position.y, 0, 0);

    noStroke();




    fill(c, 5+life*255);

    //fill(c);

    rectMode(CENTER);

    rect(0, 0, size, size);




    //ellipse(0, 0, size*2, size*2);

    stroke(c, 3+life*255);

    noFill();

    //    ellipse(0, 0, size*5, size*5);




    popMatrix();

  }

  void applyForce(PVector force) {

    acceleration.add(force);

  }

}