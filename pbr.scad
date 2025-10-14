//
// pbr.scad — Flat-panel photobioreactor with optional horizontal baffle cylinders
// Author: (your name / org)
// Usage examples:
//
// 1) View / export fluid domain without baffles (plain panel):
//    openscad -o pbr_plain.stl -D MODE=0 pbr.scad
//
// 2) Fluid domain with baffle voids (recommended for snappyHexMesh):
//    openscad -o pbr_with_baffles_voids.stl -D MODE=1 -D W=0.20 -D H=0.50 -D D=0.10 -D NB=3 -D R=0.01 pbr.scad
//
// 3) Just the baffle solids (if you want separate STL for obstacles):
//    openscad -o pbr_baffles_only.stl -D MODE=2 -D W=0.20 -D H=0.50 -D D=0.10 -D NB=5 -D R=0.01 pbr.scad
//
// Coordinates and conventions:
//  - X: width (large dimension on the face), variable W
//  - Z: height, variable H
//  - Y: depth (small thickness between large faces), variable D
//  - The flat panel is a rectangular block [0..W] x [0..D] x [0..H].
//  - Baffles are horizontal cylinders whose axes run along +Y (depth), i.e. perpendicular to the large faces.
//    Implemented by rotating cylinders so their axis aligns with Y.
//


// ---------- Parameters (can be overridden with -D on CLI) ----------

// Geometry (meters)
W0 = 0.20;                  // default width  (X)
H0 = 0.50;                  // default height (Z)
D0 = 0.10;                  // default depth  (Y)

// Baffles
NB0 = 0;                    // default number of baffles: 0, 1, 3, or 5 preferred
R0  = 0.01;                 // default baffle radius (m) — all baffles same radius

// Export mode: 0=fluid_only, 1=fluid_minus_baffles, 2=baffles_only
MODE0 = 1;

// Rendering quality for cylinders
$fn = 96;

// Read external overrides if provided (OpenSCAD: -D W=..., -D H=..., etc.)
W    = is_undef(W)    ? W0    : W;
H    = is_undef(H)    ? H0    : H;
D    = is_undef(D)    ? D0    : D;
NB   = is_undef(NB)   ? NB0   : NB;
R    = is_undef(R)    ? R0    : R;
MODE = is_undef(MODE) ? MODE0 : MODE;

// A small epsilon to avoid coplanar artifacts
eps = 1e-6;

// Margin from walls to keep baffles away from boundaries
// Choose a conservative margin relative to baffle radius and panel size
margin = max(2*R, min(W, H)/10);


// ---------- Utility functions ----------

function clamp(x, a, b) = (x < a) ? a : ((x > b) ? b : x);

// Equilateral triangle side that fits within width & height given margins
function tri_side_fit(W, H, m) = 
    // s must satisfy: s <= W-2m and (sqrt(3)/2)*s <= H-2m
    min(W - 2*m, 2*(H - 2*m)/sqrt(3));

// Side length for the centered square
function sq_side_fit(W, H, m) = min(W - 2*m, H - 2*m);

// Grid helper: rows/cols for a near-square grid to place N points
function grid_rows(N) = ceil(sqrt(N));
function grid_cols(N) = ceil(N / grid_rows(N));

// Produce up to N positions in a centered grid inside margins
function grid_positions(N, W, H, m) =
    let(
        rows = grid_rows(N),
        cols = grid_cols(N),
        sx   = (cols == 1) ? 0 : (W - 2*m) / (cols - 1),
        sz   = (rows == 1) ? 0 : (H - 2*m) / (rows - 1)
    )
    [
      for (j = [0:rows-1], i = [0:cols-1])
        if (i + j*cols < N)
          [ m + i*sx, m + j*sz ]
    ];

// Pattern generators return an array of [x,z] centers:

// 0 baffles => empty list
function positions_0() = [];

// 1 centered baffle
function positions_1(W, H) = [ [W/2, H/2] ];

// 3 as an equilateral triangle centered in the face
function positions_3(W, H, m) =
    let(
        s    = 0.9 * tri_side_fit(W, H, m),      // scale slightly to keep safe margins
        htri = s*sqrt(3)/2,
        cx   = W/2,
        cz   = H/2
    ) [
        [ cx - s/2,      cz - htri/3 ],
        [ cx + s/2,      cz - htri/3 ],
        [ cx,            cz + 2*htri/3 ]
    ];

// 5 as a centered square + center
function positions_5(W, H, m) =
    let(
        s  = 0.7 * sq_side_fit(W, H, m),
        cx = W/2,
        cz = H/2,
        a  = s/2
    ) [
        [ cx - a, cz - a ],
        [ cx + a, cz - a ],
        [ cx - a, cz + a ],
        [ cx + a, cz + a ],
        [ cx,     cz     ]
    ];

// Fallbacks for other NB values:
//  - 2: two along vertical line through center
function positions_2(W, H, m) =
    let(
        cz1 = clamp(H/2 - (H - 2*m)/4, m, H - m),
        cz2 = clamp(H/2 + (H - 2*m)/4, m, H - m)
    ) [
        [ W/2, cz1 ],
        [ W/2, cz2 ]
    ];

// 4: corners of a centered square (no center)
function positions_4(W, H, m) =
    let(
        s  = 0.7 * sq_side_fit(W, H, m),
        cx = W/2, cz = H/2, a = s/2
    ) [
        [ cx - a, cz - a ],
        [ cx + a, cz - a ],
        [ cx - a, cz + a ],
        [ cx + a, cz + a ]
    ];

// Generic N: a centered grid inside margins
function positions_generic(N, W, H, m) = grid_positions(N, W, H, m);


// Dispatcher for patterns
function baffle_positions(N, W, H, m) =
    (N <= 0) ? positions_0() :
    (N == 1) ? positions_1(W, H) :
    (N == 2) ? positions_2(W, H, m) :
    (N == 3) ? positions_3(W, H, m) :
    (N == 4) ? positions_4(W, H, m) :
    (N == 5) ? positions_5(W, H, m) :
               positions_generic(N, W, H, m);


// ---------- Geometry modules ----------

// The flat panel fluid domain: rectangular prism from (0,0,0) to (W,D,H)
module fluid_domain() {
    // Slightly expand in Y by eps to avoid coincident faces when subtracting
    translate([0, -eps, 0])
        cube([W, D + 2*eps, H], center=false);
}

// One horizontal baffle cylinder at (x,z), axis along +Y
module baffle_at(x, z, r=R, depth=D) {
    // Place cylinder centered in Y (so it spans 0..D), and at X=x, Z=z
    // Default cylinder axis is along Z; rotate -90° around X to align with Y
    translate([x, D/2, z])
        rotate([-90, 0, 0])
            cylinder(h=depth, r=r, center=true);
}

// All baffles as union
module baffles() {
    positions = baffle_positions(NB, W, H, margin);
    if (len(positions) > 0)
        union() {
            for (p = positions)
                baffle_at(p[0], p[1], R, D);
        }
}


// ---------- Top-level export selector ----------

if (MODE == 0) {
    // fluid_only
    fluid_domain();
}
else if (MODE == 1) {
    // fluid_minus_baffles (voids where baffles sit)
    difference() {
        fluid_domain();
        baffles();
    }
}
else if (MODE == 2) {
    // baffles_only
    baffles();
}
else {
    // default to fluid_minus_baffles
    difference() {
        fluid_domain();
        baffles();
    }
}
