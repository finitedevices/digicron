const DISPLAY_CELL_WIDTH = 5;
const DISPLAY_CELL_HEIGHT = 7;
const DISPLAY_COLUMNS = 8;
const DISPLAY_PIXELS_PER_DOT = 4;
const DISPLAY_CELL_HORIZONTAL_PADDING = 16;

const BUTTON_LAYOUT = [
    "7",    "8",    "9",    "÷ M",
    "4",    "5",    "6",    "× S",
    "1",    "2",    "3",    "− ▲",
    "0 C",  ".",    "=",    "+ ▼"
];

var display = document.querySelector("#display");
var buttonsContainer = document.querySelector("#buttons");

for (var i = 0; i < BUTTON_LAYOUT.length; i++) {
    var text = BUTTON_LAYOUT[i].split(" ")[0];
    var secondaryText = BUTTON_LAYOUT[i].split(" ")[1] ?? "";
    var container = document.createElement("div");
    var button = document.createElement("button");
    var label = document.createElement("span");
    var secondaryLabel = document.createElement("span");

    button.ariaRoleDescription = text;
    label.innerHTML = text;
    secondaryLabel.innerHTML = secondaryText;

    (function(i) {
        button.addEventListener("pointerdown", function() {
            Module.input_set(0x10 | i);
        });
    })(i);

    container.append(label, button, secondaryLabel);

    buttonsContainer.append(container);
}

function renderDisplayData(data) {
    var context = document.querySelector("#display").getContext("2d");

    display.width = (DISPLAY_CELL_WIDTH * DISPLAY_COLUMNS * DISPLAY_PIXELS_PER_DOT) + ((DISPLAY_COLUMNS - 1) * DISPLAY_CELL_HORIZONTAL_PADDING);
    display.height = DISPLAY_CELL_HEIGHT * DISPLAY_PIXELS_PER_DOT;

    for (var column = 0; column < DISPLAY_COLUMNS; column++) {
        for (var cellY = 0; cellY < DISPLAY_CELL_HEIGHT; cellY++) {
            for (var cellX = 0; cellX < DISPLAY_CELL_WIDTH; cellX++) {
                var cellByte = data[(column * DISPLAY_CELL_WIDTH) + cellX];

                context.fillStyle = ((cellByte >> cellY) & 0b1) ? "#00ff00" : "#ffffff22";

                context.fillRect(
                    (column * DISPLAY_CELL_WIDTH * DISPLAY_PIXELS_PER_DOT) + (column * DISPLAY_CELL_HORIZONTAL_PADDING) + (cellX * DISPLAY_PIXELS_PER_DOT),
                    cellY * DISPLAY_PIXELS_PER_DOT,
                    DISPLAY_PIXELS_PER_DOT - 1,
                    DISPLAY_PIXELS_PER_DOT - 1
                );
            }
        }
    }

    requestAnimationFrame(function() {
        Module.display_render();
    });
}

Module.onRuntimeInitialized = function() {
    console.log("Runtime initialised");

    Module.display_render();

    document.addEventListener("pointerup", function() {
        Module.input_set(0x00);
    });
};