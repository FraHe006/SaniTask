shader_type canvas_item;

uniform float SCREEN_HEIGHT = 240.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	int y_pixel = int(UV.y * SCREEN_HEIGHT);
	if (y_pixel % 2 == 0) {
		COLOR.a = 0.0;
	} else {
		COLOR.a = 0.05;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
