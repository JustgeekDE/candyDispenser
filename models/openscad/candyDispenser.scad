use <MCAD/involute_gears.scad>
use <MCAD/servos.scad>

module tube(diameter, length) {
  radius = diameter / 2;
  linear_extrude(height = length)
  circle(r = radius);
}

module donut(diameter, height, precision=$fn) {
  rotate_extrude(convexity = 10, $fn=precision)
  translate([diameter/2, 0, 0])
  circle(r = height, $fn=precision);
}


module hollowTube(innerDiameter, outerDiameter, length) {
  difference(){
    tube(outerDiameter, length);
    translate([0,0,-5])
    tube(innerDiameter, length+10);

  }
}
module curvedSegment(innerDiameter, outerDiameter, height, angle){
  outerHull = outerDiameter + 10;
  difference(){
    hollowTube(innerDiameter*2, outerDiameter*2, height);
    union() {
      rotate([0,0,angle/2])
      translate([-outerHull, 0, -1])
      cube([2*outerHull,  outerHull,  height+2]);
      rotate([0,0,-angle/2])
      translate([-outerHull, -outerHull, -1])
      cube([2*outerHull,  outerHull,  height+2]);
    }
  }
}

module screwCutout(shaftDiameter, shaftLength, headDiameter, headLength) {
  union() {
    tube(shaftDiameter, shaftLength+0.1);
    translate([0,0,shaftLength])
    tube(headDiameter, headLength);
  }
}

module m3Cutout(length) {
  screwCutout(3.4, length, 6, 14);
}

module raspberry(diameter=2.8, length=10){
  union() {
    translate([-29,-24.5,0])
    tube(diameter, length);
    translate([29,-24.5,0])
    tube(diameter, length);
    translate([-29,24.5,0])
    tube(diameter, length);
    translate([29,24.5,0])
    tube(diameter, length);
  }

}

module gearFixationBolts(scaleFactor = 1){
  boltDiameter = 16.5;
  boltLength = 2.5+0.1;

  color("red")
  translate([0,0,-0.1])
  difference(){
    scale(scaleFactor)
    tube(boltDiameter, boltLength+0.1);

    union(){
      scale(1/scaleFactor)
      translate([0,0,-2*boltLength])
      tube(8, boltLength*5);
      translate([0,-boltDiameter,-2*boltLength])
      cube([2*boltDiameter, 2*boltDiameter, 5*boltLength]);

    }
  }
}

module gearFixationBolts2(scaleFactor = 1){
  boltDiameter = 4.25;
  boltLength = 2.5;

  color("red")
  translate([0,0,-0.1])
  for (a =[0:90:360]) {
    rotate([0,0,a]) {
      translate([0,5.5,0])
      scale(scaleFactor)
      tube(boltDiameter, boltLength+0.1);
    }
  }
}

module candyGear(thickness = 5, bolts=false, bore_diameter = 3.6) {
  gearThickness = thickness - 0.4;
  teeth          = 12;
  circular_pitch = pitchRadius * 30;
  translate([0,0,-0.2])
  union() {
    gear (
        number_of_teeth = teeth,
        circular_pitch  = circular_pitch,
        backlash        = 0.7,
        bore_diameter   = bore_diameter,
        hub_thickness   = gearThickness,
        gear_thickness  = gearThickness,
        rim_thickness   = gearThickness,
        rim_width       = 5,
        circles = 4

    );
    if(bolts == true){
      translate([0,0,gearThickness])
      rotate([0,0,180])
      gearFixationBolts(1.04);
    }
  }
}

module servoGear(bore, hub) {
  teeth          = 12;
  circular_pitch = pitchRadius * 30;
  thickness = 4;
  difference(){
    gear (
        number_of_teeth = teeth,
        circular_pitch  = circular_pitch,
        backlash        = 0.7,
        bore_diameter   = bore,
        hub_diameter    = 8,
        hub_thickness   = thickness+1,
        gear_thickness  = thickness,
        rim_thickness   = thickness,
        rim_width       = 30,
        circles = 0

    );
    color("red")
    translate([0,0,thickness-1.5])
    tube(hub, 5);
    color("lime")
    translate([0,0,-4.0])
    tube(5, 5);
  }
}

module candyPortioner(diameter, length) {
  radius = diameter / 2;

  rotate([0,90,0]) {
    difference() {
      difference(){
        difference() {
          cutoutSize = (length/2) - 4;
          insetDepth = 3;
          cutoutHeight = radius + insetDepth + 1;
          tube(diameter, length);
          translate([insetDepth,0,0])
          translate([0,0,length/2])
          scale([1,(diameter/length),1])
          rotate([90,0,-90])
          rotate([0,0,45])
          cylinder(h = cutoutHeight, r1 = cutoutSize-5, r2 = cutoutSize+10, $fn = 4);
          translate([(diameter/2)-2, -diameter,-length/2])
          cube([10, diameter *2, length *2]);
        }
        gearFixationBolts(1.08);

      }
      color("white") {
        shaftLength = 25;
        translate([0,0,-shaftLength+3])
        m3Cutout(shaftLength);
        rotate([0,180,0])
        translate([0,0,-length-shaftLength+3])
        m3Cutout(shaftLength);
      }
    }
  }
}

module supportStrut(thickness, width, height, singleSupport = false) {
  strutHeight = min(width, 8);
  translate([-thickness/2, -width/2,0])
  union(){
    cube([thickness,width,height]);
    difference() {
      translate([0,(width-5)/2,strutHeight/2])
      rotate([0,-90,0])
      rotate([-90,0,0])
      union(){
        translate([0,0,0])
        cylinder(5,strutHeight,strutHeight,$fn=3);
        translate([0,thickness,0])
        cylinder(5,strutHeight,strutHeight,$fn=3);

      }
      if(singleSupport == true) {
        translate([thickness/2,-width/2,-height/2])
        cube([width*2,width*2,height*2]);
      }
    }
  }
}

module supportStrutWithHole(thickness, width, height, diameter, holeHeight, offsetFromCenter = 0, singleSupport = false) {
  difference(){
    supportStrut(thickness, width, height, singleSupport);
    translate([-thickness,offsetFromCenter,holeHeight])
    rotate([0,90,0])
    tube(diameter, 2*thickness);
  }
}

module servoStrut(thickness, width, height, diameter, holeHeight, offsetFromCenter = 0, singleSupport = false) {
  servoThickness = 2.8;
  difference(){
    supportStrutWithHole(thickness, width, height, diameter, holeHeight, offsetFromCenter, singleSupport);
    translate([-servoThickness/2,-width,holeHeight-5])
    cube([servoThickness,2*width, height]);
  }
}

module caseHook(){
  height = 12;
  width = 10;
  strength = 3;
  hookWidth = 6;
  difference(){
    union() {
      translate([-strength/2, -width/2, 0])
      cube([strength,width, height]);
      color("red")
      translate([hookWidth/5,0,height-(hookWidth/2)])
      scale([0.6,1,1])
      rotate([0,45,0])
      cube([hookWidth,width,hookWidth], center=true);
    }
    color("lime")
    translate([-strength, -width, height])
    cube([strength*2,width*2, height]);
    color("purple")
    translate([strength*-2.5, -width,0])
    cube([strength*2,width*2, height]);
  }
}


module basePlate() {
  translate([-37.5,-37.5,0])
  union(){
    translate([0,0,-2])
    cube([75,75,2.5]);
    translate([0,0,0]){

      translate([-2.5,-2.5,0]){
        translate([26,0,0]){
          difference(){
            union(){
              translate([2,0,0]){
                translate([0,60.3,0])
                supportStrut(4,7,servoHeight+2);
                translate([-2,26.8,0]) {
                  cube([11,10,servoHeight-6.5]);
                  translate([7,0,0])
                  cube([4,7,servoHeight-2.5]);
                  translate([0,0,0])
                  cube([4,7,servoHeight+2]);
                }

              }

              translate([0,33,0])
              cube([23,25,servoHeight-6.5]);
            }
            translate([0,33,7]){
              translate([-20,4,0])
              rotate([0,90,0])
              tube(5,100);
              translate([-20,21,0])
              rotate([0,90,0])
              tube(5,100);
              translate([15,40,0])
              rotate([90,0,0])
              tube(5,100);
            }
        }

        }

        translate([63,40,0])
        supportStrutWithHole(5,15,dispenserHeigth+5, diameter=3.4, holeHeight=dispenserHeigth);

        translate([12,40,0])
        supportStrutWithHole(5,15,dispenserHeigth+5, diameter=3.4, holeHeight=dispenserHeigth, singleSupport = true);
      }

      chuteWidth = 33;
      chuteStrength =2;
      chuteHeight = 15;
      translate([37.5-chuteWidth/2,0,0])
      difference(){
        union(){
          difference() {
            difference() {
              difference(){
                translate([-chuteStrength,-1,0])
                union(){
                  color("lime")
                  cube([chuteWidth+2*chuteStrength,25.2,23]);
                  color("red")
                  translate([0,24,22])
                  rotate([39.0,0,0])
                  cube([chuteWidth+2*chuteStrength,18,chuteHeight-1.4]);
                  translate([0,0,5])
                  rotate([33,0,0])
                  cube([chuteWidth+2*chuteStrength,30,chuteHeight]);
                }
                translate([0,0,5])
                union(){
                  color("purple")
                  rotate([33,0,0])
                  translate([0,-10,chuteStrength])
                  cube([chuteWidth,35.5,chuteHeight+10]);
                  color("green")
                  rotate([38.8,0,0])
                  translate([0,25,chuteStrength-2.3])
                  cube([chuteWidth,80,chuteHeight+10]);
                }
              }
              color("blue")
              translate([-20,37.5,dispenserHeigth])
              rotate([0,90,0])
              tube(dispenserDiameter+3.5,80);
            }
            color("red")
            translate([-5,-40,-5])
            rotate([-3,0,0])
            cube([chuteWidth+10,40,80]);
          }
        }
        cutoutSpacing = 3;
        cutoutWidth = (chuteWidth  - (2 * cutoutSpacing))  / 3;
        color("blue")
        translate([0,-1,0]) {
          cube([cutoutWidth,15,3]);
          translate([(1 * cutoutSpacing ) + (1  * cutoutWidth),0,0])
          cube([cutoutWidth,15,3]);
          translate([(2 * cutoutSpacing ) + (2  * cutoutWidth),0,0])
          cube([cutoutWidth,15,3]);

        }
      }

      translate([73,68,0])
      caseHook();
      translate([73,7,0])
      caseHook();
      translate([2,68,0])
      rotate([0,0,180])
      caseHook();
      translate([2,7,0])
      rotate([0,0,180])
      caseHook();
    }
  }
}

module hoodShape(height, edgeLength){
  wallStrength = 2;
  sphereDiameter = 50;
  difference(){
    rotate(a=45, v=[0,0,1])
    cylinder(h = height, r1 = edgeLength, r2 = edgeLength-5, $fn=4);
//    translate([0,0,height+(sphereDiameter-10)])
//    sphere(r=sphereDiameter);
  }
}

module bayonetCatch(innerDiameter, outerDiameter){
  union(){
    curvedSegment(innerDiameter/2, outerDiameter/2, 10, 8);
    rotate(a=-8, v=[0,0,1])
    curvedSegment(innerDiameter/2, outerDiameter/2, 4, 16);
  }
}

module hood() {
  glassDiameter = 60;
  height = 76.5;
  edgeLength = 56.5;
  sphereDiameter = 41;

    difference(){
      union(){
        difference(){
          hoodShape(height, edgeLength);
          translate([0,0,-0.1])
          scale(0.97)
          hoodShape(height, edgeLength);
        }
        translate([0,0,height-8.5])
        tube(glassDiameter+11, 8.5);
        translate([-25,-18,50])
        cube([50,36,20]);
//        tube(71, 20);

        translate([0,38.5,38])
        rotate([2.6,0,0])
        rotate([90,0,0])
        rotate([0,0,90])
        raspberry(5, 2.5);

      }
      translate([0,0,height-6])
      hollowTube(glassDiameter, glassDiameter+6, 10);
      translate([-16, -8,0])
      cube([32,16,height+10]);
    //    tube(25, height+10);
      translate([0,0,height+(sphereDiameter-12)])
      sphere(r=sphereDiameter);



      union() {
        translate([0,0,height-6])
        rotate(a=225, v=[0,0,1])
        bayonetCatch(glassDiameter, glassDiameter+12);
      }

      translate([0,0,8])
      union(){
        translate([35,0,0]){
          translate([0,25,0])
          cube([15,11,6]);
          translate([0,-36,0])
          cube([15,11,6]);
        }
        translate([-45,0,0]){
          translate([0,25,0])
          cube([15,11,6]);
          translate([0,-36,0])
          cube([15,11,6]);
        }
      }

      union() {
        translate([0,0,height-6])
        rotate(a=45, v=[0,0,1])
        bayonetCatch(glassDiameter, glassDiameter+12);
      }

      translate([0,0,50])
      rotate([0,90,0])
      translate([0,0,-35.6])
      tube(33,71.2);

      translate([-17,-50,-0.1])
      union(){
        cube([34,60,15]);
        translate([0,0,14.9])
        rotate([-90,0,0])
        translate([17,0,-30])
        difference(){
          tube(34, 50);
          translate([-18,0,-5])
          cube([36,40,60]);
        }
      }
    translate([0,42,38])
    rotate([2.6,0,0])
    rotate([90,0,0])
    rotate([0,0,90])
    raspberry(3, 20);
  }
}

module containerHull(diameter, height, cornerRadius){

  union() {
    translate([0,0,cornerRadius])
    tube(diameter, height-2*cornerRadius);
    tube(diameter-2*cornerRadius, height);
    translate([0,0,height-cornerRadius])
    donut(diameter-2*cornerRadius, cornerRadius);
    translate([0,0,cornerRadius])
    donut(diameter-2*cornerRadius, cornerRadius);

  }
}

module container(){
  ringDiameter = 65;
  diameter = 76;
  height = 70;
  tubeLength = 16;

  union(){
    difference(){
      union() {
        containerHull(diameter,height,10);
        translate([0,0,-tubeLength+8])
        tube(ringDiameter, tubeLength);
      }
      translate([0,0,2])
      containerHull(diameter-4,height-4,10);
      translate([0,0,-tubeLength-10])
      tube(ringDiameter-3, tubeLength+20);
    }
    translate([0,0,-tubeLength+8]){
      curvedSegment(ringDiameter/2, ringDiameter/2+3, 3, 6);
      rotate(a=180, v=[0,0,1])
      curvedSegment(ringDiameter/2, ringDiameter/2+3, 3, 6);
    }
  }
}

module trayHull(width, height){
  intersection(){
    cube([width,width,height]);
    translate([width/2,width/2,height-2])
    scale([1,1,0.7])
    sphere(width/1.6);
  }

}

module tray(){
  width = 45;
  height = 10;
  hull = 2;

  union(){
    translate([0,width,2.7]) {
      slotWidth = 7;
      slotHeight = 2;
      slotLength = 10;
        translate([-15.5,0,0])
        cube([slotWidth,slotLength,slotHeight]);
        translate([-3.5,0,0])
        cube([slotWidth,slotLength,slotHeight]);
        translate([8.5,0,0])
        cube([slotWidth,slotLength,slotHeight]);

    }
    translate([-width/2, 0,0])
    difference() {
      trayHull(width, height);
      translate([hull/2,hull/2,hull + 0.1])
      trayHull(width-hull, height-hull);
    }
  }
}

module all(exploded = 0){
  ex = exploded;
  rotation = maxRotation * 2 * abs($t-0.5);

  translate([0,0,ex*30])
  translate([-20,0,dispenserHeigth])
  rotate([rotation,0,0])
  color("DarkGrey")
  candyPortioner(dispenserDiameter, 40);

  translate([ex*-30,0,ex*30])
  translate([-25,0,dispenserHeigth])
  rotate([180,0,0])
  rotate([rotation,0,0]){
    rotate([0,90,0])
    color("DarkOrange")
    candyGear(bolts=true);

  }

  translate([ex*-20,ex*60,0])
  color("DarkGrey")
  translate([-24.5,0,servoHeight])
  rotate([-rotation,0,0]){
    rotate([0,90,0])
    rotate([0,0,15])
    servoGear(3.0, 4.65);
    rotate([0, 90, 0])
    tube(4, 10);
  }

  translate([0,ex*40,0])
  translate([10,0,servoHeight])
  rotate([0,270,0])
  color([0.05,0.05,0.05,0.3])
  alignds420(screws=1);

  color("DimGrey")
  basePlate();


  translate([0,ex*-20,0])
  translate([0,-82,-2])
  color("DarkGrey")
  tray();


  translate([0,0,ex*120])
  translate([0,0,-2])
  color([1,0.6,0,0.3])
  hood();

  translate([0,0,ex*130])
  color([0.8,0.8,0.8,0.9])
  rotate(a=45, v=[0,0,1])
  translate([0,0,78])
  container();
}

$fn = 150;
pitchRadius = 14;
servoHeight = pitchRadius+5;
dispenserHeigth = 2*pitchRadius+servoHeight;
maxRotation = 116;
$t = 0.5;
dispenserDiameter = 30;

//all(1);
hood();
