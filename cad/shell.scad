include <BOSL/constants.scad>
include <BOSL/beziers.scad>
use <BOSL/transforms.scad>
use <BOSL/shapes.scad>

$fn = 50;

eps = 0.1;

outer_width = 40;
outer_length = 40;
outer_height = 10;
corner_fillet = 5;
corner_z_curvature = 4;
wall_thickness = 1.5;
face_thickness = 1.5;

button_width = 3;
button_length = 2.5;
button_clearance = 0.5;
button_fillet = 1;
button_margin_top = 12;
button_margin_bottom = 8;
button_margin_sides = 6;
button_label_size = 2.25;
button_label_depth = 1;
button_label_offset = 3.25;

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
    0, 0, 2, 0
];

module outer_shell() {
    difference() {
        zscale(1 / corner_z_curvature) cuboid(
            [outer_width, outer_length, outer_height * corner_z_curvature],
            align = V_TOP,
            fillet = corner_fillet,
            edges = EDGES_X_ALL + EDGES_Y_ALL + EDGES_Z_ALL
        );

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

        up(outer_height - face_thickness - eps) button_cutouts();
    }
}

function sel_font(text) = text == "↕" || text == "↵" ? "DejaVu Sans" : "Arimo";

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

module x_cutout(level) {
    down(eps / 2) right(((level * outer_width) - (outer_width / 2)) + eps) cuboid(
        [outer_width + eps, outer_length + eps, outer_height + eps],
        align = V_TOP + V_RIGHT
    );
}

difference() {
    outer_shell();

    x_cutout(1);
}