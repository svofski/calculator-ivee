//
// (Hopefully) printable key frame to be used with dome switches
//

$fn=32;

unit = 2.54;
eps = 0.01;
wall = 1;

cover_thicc = 1.6;

pitch = 6;    // button pitch in units
base = 4;     // button side in units

button_inside_h = 0.6;
pcb_h = 1.6;
button_yofs = 0.6;    // height of the dome switch
gap = 0.3;
pushrod_r = 0.9;  // central push rod
pushrod_h = 0.4;  // push rod length

spring_h = 0.8;

button_base_h = button_inside_h + pcb_h;
cage_height = button_yofs + spring_h + pushrod_h;

nkeys_x = 4;
nkeys_y = 4;

module singlecage(sx=pitch, sy=pitch, height=cage_height)
{
    width = sx * unit;
    depth = sy * unit;

    difference() {
        cube([width, depth, height]);

        translate([wall * 0.5, wall * 0.5,-eps])
            cube([width - wall, depth - wall, height + wall]);
    }
}

module outercage()
{
  width = unit * pitch * nkeys_x;
  depth = unit * pitch * nkeys_y;
  translate([-wall, -wall, 0])
    difference() {
      cube([width + 2 * wall, depth + 2 * wall, cage_height]);
      translate([wall, wall, -eps]) cube([width, depth, cage_height + 2 * eps]);
    }

  cylinder(h=cage_height + pcb_h, r = 0.6);
  translate([width, depth, 0])
      cylinder(h=cage_height + pcb_h, r = 0.6);
}

module cagehole()
{
    sz = base * unit + 2 * gap;
    ofs = (unit * pitch - sz) / 2;

    translate([wall, wall, 0])
    translate([ofs,ofs,-eps]) cube([sz, sz, 10]);
}

module coverplate()
{
  width = unit * pitch * nkeys_x;
  depth = unit * pitch * nkeys_y;
  translate([-wall, -wall, cage_height + 0.1])
    difference() {
        cube([width + 2 * wall, depth + 2 * wall, cover_thicc]);

        union() {
            for (y = [0:nkeys_y - 1]) translate([0, y * unit * pitch, 0]) 
            {
                for (x = [0:nkeys_x - 1]) translate([x * unit * pitch, 0, 0])
                {
                    cagehole();
                }
            }
        }
    }
}


module button(sx=base, sy=base, base_h=button_base_h, top_h1=2, top_h2=1, withbottom=1)
{
    width = sx * unit;
    depth = sy * unit;
    depth2 = (sy - 2) * unit;

    if (withbottom)
    {
        // pushrod
        translate([width/2, depth/2, 0]) cylinder(r = pushrod_r, h = pushrod_h);
    }

    intersection()  {
      union() {
          // base
          if (withbottom) {
              translate([0, 0, pushrod_h]) cube([width, depth, base_h]);
          }

          width2 = width - 0.25;

          // prism
          translate([0, 0, base_h + pushrod_h])
              hull() {
                  // prism bottom
                  cube([width, depth, eps]);
                  // prism top
                  translate([(width - width2)/2, (depth - depth2)/2 - 0.25, top_h1]) 
                      cube([width2, depth2, eps]);
                  // back slope should be almost flat
                  translate([0, depth-eps, 0]) cube([width, eps, top_h1 - top_h2]);
              }
      }

      translate([width/2, depth/2, 0]) cylinder(r = width/2 * sqrt(1.9), h = 5);

    }
}

// squiggly springs: unprintable at this scale
module spring()
{
    hull() {
        cylinder(r=wall/2, h=spring_h);
        translate([unit, unit/2, 0]) 
            cylinder(r=wall/2, h=spring_h);
    }
    hull() {
        translate([0, unit, 0]) 
            cylinder(r=wall/2, h=spring_h);
        translate([unit, unit/2, 0]) 
            cylinder(r=wall/2, h=spring_h);
    }
}

module spring2()
{
    translate([0, 0, button_yofs + pushrod_h]) 
    {
        translate([unit*1.2, wall/4, 0])
        {
            spring();
        }

        translate([pitch * unit - unit*1.2, pitch * unit - wall/4, 0])
        {
            scale([-1, -1, 1]) spring();
        }
    }
}

module squiggly_springs()
{
    spring2();
    translate([unit * pitch / 2, unit * pitch/2, 0])
        rotate([0, 0, 90]) 
        translate([-unit * pitch / 2, -unit * pitch/2, 0]) spring2();
}

// leaf springs: need to be made thicker than usable for printability
// they will have to be cut down to be thinner in post
module leaf_springs()
{
    width = unit * 2;
    depth = unit * 2;

    // the finger should be 0.8 mm high (better less), but jlcpcb requires 1.5 min
    // this will have to be filed down
    height = 1.55;     

    translate([unit * pitch / 2 - width/2, unit * pitch - depth + wall/2, button_yofs + pushrod_h])
        cube([width, depth, height]);
}

module cagebutton()
{
    singlecage();
    translate([unit * (pitch - base) / 2, unit * (pitch - base) / 2, button_yofs])
        button();

    //squiggly_springs();
    leaf_springs();
}

module allkeys()
{
    for (y = [0:nkeys_y - 1]) translate([0, y * unit * pitch, 0]) 
    {
        for (x = [0:nkeys_x - 1]) translate([x * unit * pitch, 0, 0])
        {
            cagebutton();
        }
    }
}

allkeys();
outercage();
//coverplate();

emboss_depth=1;
module buttontop()
{
    translate([unit * (pitch - base) / 2, unit * (pitch - base) / 2, button_yofs])
    difference() {
        translate([0,0,eps]) button(withbottom=0);
        scale([2, 1.01, 1]) translate([-1, -0.005, -emboss_depth]) button(withbottom=0);
    }
}

module buttontops()
{
    for (y = [0:nkeys_y - 1]) translate([0, y * unit * pitch, 0]) 
    {
        for (x = [0:nkeys_x - 1]) translate([x * unit * pitch, 0, 0])
        {
            buttontop();
        }
    }
}

// this is insanely slow and produces buggy meshes anyway
//module emboss()
//{
//    color([1,0,1])
//        translate([0,0,0.1]) {
//            intersection() {
//                buttontops();
//                //linear_extrude(15) import("botones-emboss.svg");
//                import("text-stl.stl");
//            }
//        }
//}

//emboss();
//difference() {
//  allkeys();
//  emboss();
//}
