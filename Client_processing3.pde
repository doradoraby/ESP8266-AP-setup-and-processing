import processing.net.*; 
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;

ToxiclibsSupport gfx;
Client port;
char[] teapotPacket = new char[14];
int serialCount = 0;
int aligned = 0;
int interval = 0;

PShape cube;
float cubeSize = 320;
float circleRad = 100;
int circleRes = 40;
float noiseMag = 1;
float[] q = new float[4];

Quaternion quat = new Quaternion(1, 0, 0, 0);

float[] gravity = new float[3];
float[] euler = new float[3];
float[] ypr = new float[3];

void setup() {
  size(900, 900, OPENGL);
  gfx = new ToxiclibsSupport(this);

  lights();
  smooth();

  port = new Client(this, "192.168.4.1", 23);
  port.write('r');

  createCube();
}

void draw() {
  if (millis() - interval > 1000) {
    port.write('r');
    interval = millis();
  }
    
  background(0);
  translate(width / 2, height / 2);
  float[] axis = quat.toAxisAngle();
  rotate(axis[0], -axis[1], axis[3], axis[2]);

  shape(cube);
  restoreCube();
  PVector pos = null;
    for (int i = 0; i < cube.getChildCount(); i++) {
      PShape face = cube.getChild(i);
      for (int j = 0; j < face.getVertexCount(); j++) {
        pos = face.getVertex(j, pos);
        pos.x += random(-noiseMag/2, +noiseMag/2);
        pos.y += random(-noiseMag/2, +noiseMag/2);
        pos.z += random(-noiseMag/2, +noiseMag/2);
        face.setVertex(j, pos.x, pos.y, pos.z);
      }

    }

    getval();

}

void getval(){
  interval = millis();
  
  while (port.available() > 0) {
    int ch = port.read();
    println(ch);
    if (aligned == 0 && ch != '$')
      return;
    aligned = 1;
    println ((char)ch);
    if ((serialCount == 1 && ch != 2)|| (serialCount == 12 && ch != '\r')|| (serialCount == 13 && ch != '\n')) {
      serialCount = 0;
      aligned = 0;
      return;
    }
    
    if (serialCount > 0 || ch == '$') {
      teapotPacket[serialCount++] = (char)ch;
      println("serialCount = "+serialCount);
      println("teapotPacket = "+teapotPacket[serialCount-1]);
      
      if (serialCount == 14) {
        serialCount = 0;
        q[0] = ((teapotPacket[2] << 8) | teapotPacket[3]) / 16384.0f;
        q[1] = ((teapotPacket[4] << 8) | teapotPacket[5]) / 16384.0f;
        q[2] = ((teapotPacket[6] << 8) | teapotPacket[7]) / 16384.0f;
        q[3] = ((teapotPacket[8] << 8) | teapotPacket[9]) / 16384.0f;
        
        for (int i = 0; i < 4; i++) if (q[i] >= 2) q[i] = -4 + q[i];
// set our toxilibs quaternion to new data
quat.set(q[0], q[1], q[2], q[3]);
/*
 // below calculations unnecessary for orientation only using toxilibs
 
 // calculate gravity vector
 gravity[0] = 2 * (q[1]*q[3] - q[0]*q[2]);
 gravity[1] = 2 * (q[0]*q[1] + q[2]*q[3]);
 gravity[2] = q[0]*q[0] - q[1]*q[1] - q[2]*q[2] + q[3]*q[3];
 
 // calculate Euler angles
 euler[0] = atan2(2*q[1]*q[2] - 2*q[0]*q[3], 2*q[0]*q[0] + 2*q[1]*q[1] - 1);
 euler[1] = -asin(2*q[1]*q[3] + 2*q[0]*q[2]);
 euler[2] = atan2(2*q[2]*q[3] - 2*q[0]*q[1], 2*q[0]*q[0] + 2*q[3]*q[3] - 1);
 
 // calculate yaw/pitch/roll angles
 ypr[0] = atan2(2*q[1]*q[2] - 2*q[0]*q[3], 2*q[0]*q[0] + 2*q[1]*q[1] - 1);
 ypr[1] = atan(gravity[0] / sqrt(gravity[1]*gravity[1] + gravity[2]*gravity[2]));
 ypr[2] = atan(gravity[1] / sqrt(gravity[0]*gravity[0] + gravity[2]*gravity[2]));
 
 // output various components for debugging
 //println("q:\t" + round(q[0]*100.0f)/100.0f + "\t" + round(q[1]*100.0f)/100.0f + "\t" + round(q[2]*100.0f)/100.0f + "\t" + round(q[3]*100.0f)/100.0f);
 //println("euler:\t" + euler[0]*180.0f/PI + "\t" + euler[1]*180.0f/PI + "\t" + euler[2]*180.0f/PI);
 //println("ypr:\t" + ypr[0]*180.0f/PI + "\t" + ypr[1]*180.0f/PI + "\t" + ypr[2]*180.0f/PI);
 */
}
}}
  
}




void restoreCube() {

  // Rotation of faces is preserved, so we just reset them

  // the same way as the "front" face and they will stay

  // rotated correctly

  for (int i = 0; i < 6; i++) {

    PShape face = cube.getChild(i);

    restoreFaceWithHole(face);

  }

}




void createCube() {

  cube = createShape(GROUP);  




  PShape face;




  // Create all faces at front position

  for (int i = 0; i < 6; i++) {

    face = createShape();

    createFaceWithHole(face);

    cube.addChild(face);

  }




  // Rotate all the faces to their positions




  // Front face - already correct

  face = cube.getChild(0);




  // Back face

  face = cube.getChild(1);

  face.rotateY(radians(180));




  // Right face

  face = cube.getChild(2);

  face.rotateY(radians(90));




  // Left face

  face = cube.getChild(3);

  face.rotateY(radians(-90));




  // Top face

  face = cube.getChild(4);

  face.rotateX(radians(90));




  // Bottom face

  face = cube.getChild(5);

  face.rotateX(radians(-90));

}




void createFaceWithHole(PShape face) {

  face.beginShape(POLYGON);

  face.stroke(255, 0, 0);

  face.fill(255);




  // Draw main shape Clockwise

  face.vertex(-cubeSize/2, -cubeSize/2, +cubeSize/2);

  face.vertex(+cubeSize/2, -cubeSize/2, +cubeSize/2);

  face.vertex(+cubeSize/2, +cubeSize/2, +cubeSize/2);

  face.vertex(-cubeSize / 2, +cubeSize / 2, +cubeSize / 2);




  // Draw contour (hole) Counter-Clockwise

  face.beginContour();

  for (int i = 0; i < circleRes; i++) {

    float angle = TWO_PI * i / circleRes;

    float x = circleRad * sin(angle);

    float y = circleRad * cos(angle);

    float z = +cubeSize/2;

    face.vertex(x, y, z);

  }

  face.endContour();




  face.endShape(CLOSE);

}




void restoreFaceWithHole(PShape face) {

  face.setVertex(0, -cubeSize/2, -cubeSize/2, +cubeSize/2);

  face.setVertex(1, +cubeSize/2, -cubeSize/2, +cubeSize/2);

  face.setVertex(2, +cubeSize/2, +cubeSize/2, +cubeSize/2);

  face.setVertex(3, -cubeSize/2, +cubeSize/2, +cubeSize/2);

  for (int i = 0; i < circleRes; i++) {

    float angle = TWO_PI * i / circleRes;

    float x = circleRad * sin(angle);

    float y = circleRad * cos(angle);

    float z = +cubeSize/2;

    face.setVertex(4 + i, x, y, z);

  }

}