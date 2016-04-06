/******************************************************************
*                                                                 *
* OpenFlexure Microscope: Optics unit (single small lens version) *
*                                                                 *
* This is part of the OpenFlexure microscope, an open-source      *
* microscope and 3-axis translation stage.  It gets really good   *
* precision over a ~10mm range, by using plastic flexure          *
* mechanisms.                                                     *
*                                                                 *
* (c) Richard Bowman, January 2016                                *
* Released under the CERN Open Hardware License                   *
*                                                                 *
******************************************************************/

use <utilities.scad>;
use <cameras/picam_push_fit.scad>;
use <cameras/C270_mount.scad>;
use <dovetail.scad>;

//camera = "C270";
camera = "picamera";

///picamera lens
lens_outer_r=3.04+0.2; //outer radius of lens (plus tape)
lens_aperture_r=2.2; //clear aperture of lens
lens_t=3.0; //thickness of lens
objective_parfocal_distance = 44.5; //rough guess!
//*/
sample_z = 70; //height of the sample above the bottom of the microscope
shoulder_z = sample_z - parfocal_distance; //bottom of lens
top = lens_z + lens_t; //top of the mount
bottom = -10; //nominal distance from PCB to microscope bottom (was 8, increased to 10)
dt_bottom = -2; //where the dovetail starts (<0 to allow some play)
d = 0.05;
//neck_h=h-dovetail_h;
small_neck_r=max( (body_r+lens_aperture_r)/2, lens_outer_r+1.5);

// The camera parameters depend on what camera we're using,
// sorry about the ugly syntax, but I couldn't find a neater way.
camera_angle = (camera=="picamera"?45:
               (camera=="C270"?-45:0));
camera_h = (camera=="picamera"?24:
           (camera=="C270"?53:0));
camera_shift = (camera=="picamera"?2.4:
               (camera=="C270"?(45-53/2):0));

// This needs to match the microscope body (NB this is for the 
// standard-sized version, not the LS version)
objective_clip_w = 10;

$fn=24;

module lighttrap_cylinder(r1,r2,h,ridge=1.5){
    //A "cylinder" made up of christmas-tree-like cones
    //good for trapping light in an optical path
    //r1 is the outer radius of the bottom
    //r2 is the inner radius of the top
    //NB for a straight-sided cylinder, r2==r1-ridge
    n_cones = floor(h/ridge);
    cone_h = h/n_cones;
    
	for(i = [0 : n_cones - 1]){
        p = i/(n_cones - 1);
		translate([0, 0, i * cone_h - d]) 
			cylinder(r1=(1-p)*r1 + p*(r2+ridge),
					r2=(1-p)*(r1-ridge) + p*r2,
					h=cone_h+2*d);
    }
}
module trylinder(r=1, flat=1, h=d, center=false){
    //A fade between a cylinder and a triangle.
    hull() for(a=[0,120,240]) rotate(a)
        translate([0,flat/sqrt(3),0]) cylinder(r=r, h=h, center=center);
}
module camera(){
    //This creates a cut-out for the camera we've selected
    if(camera=="picamera"){
        picam_push_fit();
    }else{
        C270(beam_r=5,beam_h=6+d);
    }
}

module optical_path(lens_aperture_r, lens_z){
    union(){
        rotate(camera_angle) translate([0,0,bottom]) camera();
        // //camera
        translate([0,0,bottom+6]) lighttrap_cylinder(r1=5, r2=lens_aperture_r, h=lens_z-bottom-6+d); //beam path
        translate([0,0,lens_z]) cylinder(r=lens_aperture_r,h=2*d); //lens
    }
}

module camera_mount_body(body_r, dt_top, objective_clip_y, neck_r, neck_z){
    dt_h=dt_top-dt_bottom;
    union(){
        difference(){
            // This is the main body of the mount
            sequential_hull(){
                rotate(camera_angle) translate([0,camera_shift,bottom]) cube([25,camera_h,d],center=true);
                rotate(camera_angle) translate([0,camera_shift,bottom+1.5]) cube([25,camera_h,d],center=true);
                rotate(camera_angle) translate([0,camera_shift,bottom+4]) cube([25-5,camera_h,d],center=true);
                translate([0,0,dt_bottom]) hull(){
                    cylinder(r=body_r,h=d);
                    translate([0,objective_clip_y,0]) cube([objective_clip_w,4,d],center=true);
                }
                translate([0,0,dt_bottom]) cylinder(r=body_r,h=d);
                translate([0,0,dt_top]) cylinder(r=body_r,h=d);
                translate([0,0,neck_z]) cylinder(r=neck_r,h=d);
                //translate([0,0,top]) cylinder(r=neck_r,h=d);
            }
            
            // flatten the cylinder for the dovetail
            reflect([1,0,0]) translate([3,objective_clip_y-0.5,dt_bottom]){
                cube(999);
            }
			
        }
        // add the dovetail
        translate([0,objective_clip_y,dt_bottom]){
            dovetail_m([14,2,dt_h],waist=dt_h-15);
        }
    }
}

/////////// Cover for camera board //////////////
module picam_cover(){
    // A cover for the camera PCB, slips over the bottom of the camera
    // mount.
    start_y=-12+2.4;//-3.25;
    l=-start_y+12+2.4; //we start just after the socket and finish at 
    //the end of the board - this is that distance!
    difference(){
        union(){
            //base
            translate([-15,start_y,-4.3]) cube([25+5,l,4.3+d]);
            //grippers
            reflect([1,0,0]) translate([-15,start_y,0]){
                cube([2,l,4.5-d]);
                hull(){
                    translate([0,0,1.5]) cube([2,l,3]);
                    translate([0,0,4]) cube([2+2.5,l,0.5]);
                }
            }
        }
        translate([0,0,-1]) picam_pcb_bottom();
        //chamfer the connector edge for ease of access
        translate([-999,start_y,0]) rotate([-135,0,0]) cube([9999,999,999]);
    }
} 



module optics_module_single_lens(){
    union(){
        difference(){
            camera_mount_body(body_r=8, dt_top=27, objective_clip_y=6, neck_r, neck_z);
            optical_path();
        }
    }
}

//optics_module_single_lens();
//picam_cover();
