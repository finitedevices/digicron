include <BOSL/constants.scad>
include <BOSL/beziers.scad>
use <BOSL/transforms.scad>
use <BOSL/shapes.scad>
use <BOSL/metric_screws.scad>

PART_NONE = 0;
PART_ALL = 1;
PART_FRONT = 2;
PART_BACK = 3;

$fn = 20;

eps = 0.2;
part = PART_ALL;

outer_width = 45;
outer_length = 45;
outer_height = 16;
corner_fillet = 5;
corner_z_curvature = 1.5;
wall_thickness = 1.5;
face_thickness = 1.5;
cut_slope = 10;
cut_height = 1.5;
cut_fillet_adjustment = -2;

display_width = 35;
display_length = 10;
display_height = 5;
display_vertical_inset = 0.5;
display_horizontal_inset = 0;
display_fillet = 2;
display_offset = 4.5;

button_width = 3;
button_length = 2.5;
button_clearance = 0.5;
button_fillet = 1;
button_margin_top = 19;
button_margin_bottom = 9;
button_margin_sides = 8;
button_label_size = 2.25;
button_label_depth = 0.75;
button_label_offset = 3.25;

switch_width = 6;
switch_length = 3;
switch_height = 4.3;

vib_motor_diameter = 10;
vib_motor_height = 3.5;
vib_motor_offset_x = -7;
vib_motor_offset_y = -14.5;

battery_width = 35;
battery_length = 25;
battery_height = 4;
battery_elevation = face_thickness + 1;
battery_offset = 3.25;

pcb_width = 40;
pcb_length = 40;
pcb_height = 1.6;
pcb_fillet = 2;
pcb_elevation = battery_elevation + battery_height + 0.5;

bolt_size = 1.6;
bolt_hole = 2;
bolt_head = 4;
bolt_recess = 1.5;
bolt_top_length = 5;
bolt_top_margin = 4.5;
bolt_bottom_length = 12;
bolt_bottom_margin = 4.5;

tab_fillet = 1;
tab_front_top_width = 2.75;
tab_front_top_length = 14;
tab_front_top_elevation = 2.5;
tab_front_top_thickness = 2.5;
tab_front_bottom_width = 7;
tab_front_bottom_length = 14;
tab_front_bottom_elevation = 8.75;
tab_front_bottom_thickness = 2.5;
tab_front_lip_length = 12;
tab_front_lip_height = 1.25;
tab_back_size = 11.25;
tab_back_height = 0.25;
tab_offset = 1;

nut_thickness = 1.5;
nut_bottom_pos = 10.75;
nut_top_pos = 4.5;

bracket_height = 1.75;

shell_gasket_inset = 1;
shell_gasket_thickness = 1;

button_labels_left = [
    "7", "8", "9", "÷",
    "4", "5", "6", "×",
    "1", "2", "3", "−",
    "0", "•", "=", "+"
];

button_labels_left_fwd_adjust = [
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 4,
    0, 3, 2, 0
];

button_labels_right = [
    " ", " ", " ", "M",
    " ", " ", " ", "S",
    " ", " ", " ", "▲",
    "C", "↕", "↵", "▼"
];

button_labels_right_fwd_adjust = [
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 1, 0
];

function sel_font(text) = text == "↕" || text == "↵" ? "DejaVu Sans" : "Arimo";

module shell_body() {
    zscale(1 / corner_z_curvature) cuboid(
        [outer_width, outer_length, outer_height * corner_z_curvature],
        align = V_TOP,
        fillet = corner_fillet,
        edges = EDGES_X_ALL + EDGES_Y_ALL + EDGES_Z_ALL
    );
}

module outer_shell() {
    difference() {
        shell_body();

        up(face_thickness) zscale(1 / corner_z_curvature) cuboid(
            [
                outer_width - (wall_thickness * 2),
                outer_length - (wall_thickness * 2),
                (outer_height - (face_thickness * 2)) * corner_z_curvature
            ],
            align = V_TOP,
            fillet = corner_fillet - wall_thickness,
            edges = EDGES_X_ALL + EDGES_Y_ALL + EDGES_Z_ALL
        );

        up(outer_height - face_thickness - eps) {
            display_cutout();

            button_cutouts();
        }
    }

    intersection() {
        union() {
            front_tabs();
            back_tabs();
        }

        shell_body();
    }
}

module shell_cut() {
    up(cut_height - eps) rounded_prismoid(
        [outer_width + eps, outer_length + eps],
        [0, 0],
        h = cut_slope,
        r = corner_fillet + cut_fillet_adjustment
    );

    down(eps) cuboid(
        [outer_width + eps, outer_length + eps, cut_height + eps],
        align = V_TOP
    );
}

module display_cutout() {
    down(eps * 2)
    fwd(
        display_offset - (outer_length / 2) + (display_length / 2)
    )
    cuboid(
        [
            display_width - (display_horizontal_inset * 2),
            display_length - (display_vertical_inset * 2),
            face_thickness + (eps * 4)
        ],
        align = V_TOP,
        fillet = display_fillet,
        edges = EDGES_Z_ALL
    );
}

module button_cutouts() {
    for (col = [0 : 3]) {
        for (row = [0 : 3]) {
            label_left = button_labels_left[(row * 4) + col];
            font_left = sel_font(label_left);
            label_right = button_labels_right[(row * 4) + col];
            font_right = sel_font(label_right);

            fwd(lerp(
                button_margin_top - (outer_length / 2),
                (outer_length / 2) - button_margin_bottom,
                row / 3
            ))
            right(lerp(
                button_margin_sides - (outer_width / 2),
                (outer_width / 2) - button_margin_sides,
                col / 3
            )) {
                cuboid(
                    [
                        button_width + button_clearance,
                        button_length + button_clearance,
                        face_thickness + (eps * 2)
                    ],
                    align = V_TOP,
                    fillet = button_fillet,
                    edges = EDGES_Z_ALL
                );

                left(button_label_offset)
                up(face_thickness - button_label_depth + eps)
                fwd(button_labels_left_fwd_adjust[(row * 4) + col] * 0.1)
                linear_extrude(height = button_label_depth + eps) {
                    text(
                        text = label_left,
                        size = button_label_size,
                        font = str(font_left, ":style=Bold"),
                        halign = "center",
                        valign = "center"
                    );
                }

                right(button_label_offset)
                up(face_thickness - button_label_depth + eps)
                fwd(button_labels_right_fwd_adjust[(row * 4) + col] * 0.1)
                linear_extrude(height = button_label_depth + eps) {
                    text(
                        text = label_right,
                        size = button_label_size,
                        font = str(font_right, ":style=Bold"),
                        halign = "center",
                        valign = "center"
                    );
                }
            }
        }
    }
}

module switches() {
    for (col = [0 : 3]) {
        for (row = [0 : 3]) {
            fwd(lerp(
                button_margin_top - (outer_length / 2),
                (outer_length / 2) - button_margin_bottom,
                row / 3
            ))
            right(lerp(
                button_margin_sides - (outer_width / 2),
                (outer_width / 2) - button_margin_sides,
                col / 3
            )) {
                cuboid(
                    [
                        switch_width,
                        switch_length,
                        switch_height
                    ],
                    align = V_TOP
                );
            }
        }
    }
}

module display() {
    up(pcb_elevation)
    fwd(
        display_offset - (outer_length / 2) + (display_length / 2)
    )
    cuboid(
        [
            display_width,
            display_length,
            display_height
        ],
        align = V_TOP
    );
}

module pcb() {
    up(pcb_elevation)
    cuboid(
        [pcb_width, pcb_length, pcb_height],
        align = V_TOP,
        fillet = pcb_fillet,
        edges = EDGES_Z_ALL
    );

    up(pcb_elevation + pcb_height) switches();
}

module battery() {
    up(battery_elevation)
    fwd(battery_offset)
    cuboid(
        [battery_width, battery_length, battery_height],
        align = V_TOP
    );
}

module vib_motor() {
    up(pcb_elevation - vib_motor_height)
    right(vib_motor_offset_x)
    fwd(vib_motor_offset_y)
    cyl(
        d = vib_motor_diameter,
        l = vib_motor_height,
        align = V_TOP
    );
}

module nuts() {
    for (x = [(outer_width / 2) - bolt_bottom_margin, bolt_bottom_margin - (outer_width / 2)]) {
        left(x)
        fwd((outer_length / 2) - bolt_bottom_margin)
        up(nut_bottom_pos)
        zrot(90) metric_nut(size = bolt_size, hole = false);

        left(x)
        fwd((outer_length / 2) - bolt_bottom_margin)
        up(face_thickness + tab_back_height + shell_gasket_thickness)
        zrot(90) metric_nut(size = bolt_size, hole = false);

        left(x)
        fwd(bolt_top_margin - (outer_length / 2))
        up(nut_top_pos)
        zrot(90) metric_nut(size = bolt_size, hole = false);
    }
}

module bolts() {
    for (x = [(outer_width / 2) - bolt_bottom_margin, bolt_bottom_margin - (outer_width / 2)]) {
        left(x)
        fwd((outer_length / 2) - bolt_bottom_margin)
        up(bolt_recess)
        xrot(180)
        metric_bolt(
            headtype = "socket",
            size = bolt_size,
            l = bolt_bottom_length
        );

        left(x)
        fwd(bolt_top_margin - (outer_length / 2))
        up(bolt_recess)
        xrot(180)
        metric_bolt(
            headtype = "socket",
            size = bolt_size,
            l = bolt_top_length
        );
    }
}

module bolt_cutouts() {
    for (x = [(outer_width / 2) - bolt_bottom_margin, bolt_bottom_margin - (outer_width / 2)]) {
        left(x)
        fwd((outer_length / 2) - bolt_bottom_margin)
        up(bolt_recess)
        cyl(
            d = bolt_hole,
            l = bolt_bottom_length,
            align = V_TOP
        );

        left(x)
        fwd((outer_length / 2) - bolt_bottom_margin)
        down(eps)
        cyl(
            d = bolt_head,
            d2 = bolt_hole,
            l = bolt_recess + (eps * 2),
            align = V_TOP
        );

        left(x)
        fwd(bolt_top_margin - (outer_length / 2))
        up(bolt_recess)
        cyl(
            d = bolt_hole,
            l = bolt_top_length,
            align = V_TOP
        );

        left(x)
        fwd(bolt_top_margin - (outer_length / 2))
        down(eps)
        cyl(
            d = bolt_head,
            d2 = bolt_hole,
            l = bolt_recess + (eps * 2),
            align = V_TOP
        );
    }
}

module gasket_cutouts() {
    up(face_thickness + tab_back_height) cuboid(
        [
            outer_width - (shell_gasket_inset * 2),
            outer_length - (shell_gasket_inset * 2),
            shell_gasket_thickness
        ],
        align = V_TOP,
        fillet = corner_fillet - shell_gasket_inset,
        edges = EDGES_Z_ALL
    );
}

module front_tabs() {
    for (x = [(outer_width / 2) - tab_offset, tab_offset - (outer_width / 2)]) {
        difference() {
            left(x)
            fwd(tab_offset - (outer_length / 2))
            up(tab_front_top_elevation)
            cuboid(
                [tab_front_top_width, tab_front_top_length + eps, tab_front_top_thickness],
                align = V_TOP
            );

            left(x)
            fwd(tab_offset - (outer_length / 2))
            up(tab_front_top_elevation + tab_front_lip_height)
            cuboid(
                [tab_front_top_width + eps, tab_front_lip_length, tab_front_top_thickness],
                align = V_TOP
            );
        }

        difference() {
            left(x)
            fwd((outer_length / 2) - tab_offset)
            up(tab_front_bottom_elevation)
            cuboid(
                [tab_front_bottom_width, tab_front_bottom_length + eps, tab_front_bottom_thickness],
                align = V_TOP
            );

            left(x)
            fwd((outer_length / 2) - tab_offset)
            up(tab_front_bottom_elevation + tab_front_lip_height)
            cuboid(
                [tab_front_bottom_width + eps, tab_front_lip_length, tab_front_bottom_thickness],
                align = V_TOP
            );
        }
    }
}

module back_tabs() {
    for (y = [(outer_length / 2) - tab_offset, tab_offset - (outer_length / 2)]) {
        for (x = [(outer_width / 2) - tab_offset, tab_offset - (outer_width / 2)]) {
            left(x)
            fwd(y)
            up(face_thickness)
            cuboid(
                [tab_back_size + eps, tab_back_size + eps, tab_back_height],
                align = V_TOP,
                fillet = tab_fillet,
                edges = EDGES_Z_ALL
            );
        }
    }
}

module top_bracket() {
    difference() {
        intersection() {
            fwd(tab_offset - (outer_length / 2))
            up(tab_front_top_elevation + tab_front_lip_height)
            cuboid(
                [outer_width, tab_front_lip_length, bracket_height],
                align = V_TOP
            );

            scale(1 - (eps ^ 2)) shell_body();
        }

        outer_shell();
        nuts();
        bolt_cutouts();
        vib_motor();
    }
}

module bottom_bracket() {
    difference() {
        intersection() {
            fwd((outer_length / 2) - tab_offset)
            up(tab_front_bottom_elevation + tab_front_lip_height)
            cuboid(
                [outer_width, tab_front_lip_length, bracket_height],
                align = V_TOP
            );

            scale(1 - (eps ^ 2)) shell_body();
        }

        outer_shell();
        nuts();
        bolt_cutouts();
    }
}

module x_cutout(level) {
    down(eps / 2) right(((level * outer_width) - (outer_width / 2)) + eps) cuboid(
        [outer_width + eps, outer_length + eps, outer_height + eps],
        align = V_TOP + V_RIGHT
    );
}

module y_cutout(level) {
    down(eps / 2) fwd((outer_length * level) + eps) cuboid(
        [outer_width + eps, outer_length + eps, outer_height + eps],
        align = V_TOP
    );
}

module z_cutout(level) {
    down(eps / 2) up((outer_height * level) + eps) cuboid(
        [outer_width + eps, outer_length + eps, outer_height + eps],
        align = V_TOP
    );
}

module shell(part) {
    difference() {
        union() {
            if (part == PART_FRONT) {
                difference() {
                    outer_shell();
                    shell_cut();
                }
            }

            if (part == PART_BACK) {
                intersection() {
                    outer_shell();
                    shell_cut();
                }
            }
        }

        bolt_cutouts();
        gasket_cutouts();
    }
}

module assembly() {
    if (part == PART_FRONT || part == PART_ALL) {
        shell(PART_FRONT);
    }

    if (part == PART_BACK || part == PART_ALL) {
        shell(PART_BACK);
    }

    difference() {
        pcb();
        bolt_cutouts();
    }

    top_bracket();
    bottom_bracket();

    battery();
    vib_motor();
    display();

    nuts();
    bolts();
}

difference() {
    assembly();

    x_cutout(1);
    y_cutout(1);
    z_cutout(1);
}