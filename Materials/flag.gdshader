shader_type canvas_item;
uniform vec4 flagColour=vec4(1.0,1.0,1.0,1.0);
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR=flagColour;
	if (0.05*sin(((UV.x*32.0+UV.y)+TIME*16.0)*0.2)>UV.y-0.05)
	{
		//if (UV.y+0.8<(sin(UV.x*16.0+UV.y+TIME*4.0)))
		COLOR=vec4(0.0,0.0,0.0,0.0);
	}
	if (0.05*sin(((UV.x*32.0+UV.y)+(TIME+1.0)*16.0)*0.2)>0.95-UV.y)
	{
		//if (UV.y+0.8<(sin(UV.x*16.0+UV.y+TIME*4.0)))
		COLOR=vec4(0.0,0.0,0.0,0.0);
	}
}

void light() {
	// Called for every pixel for every light affecting the CanvasItem.
}
