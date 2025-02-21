shader_type canvas_item;
uniform float healthPercentage : hint_range(0.0, 1.0);
uniform vec4 barColour=vec4(0.22,0.22,0.22,1.0);
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR=barColour;
	if ((UV.x+UV.y*0.03)<1.03)
	{
		COLOR=vec4(0.1,0.1,0.1,1.0);
	}
	if ((UV.x+UV.y*0.03)<healthPercentage+mix(0.03,0.0,healthPercentage))
	{
		COLOR=vec4(181.0/255.0,36.0/255.0,70.0/255.0,1.0);
	}
	
	if ((UV.x+UV.y*0.03)>1.0)
	{
		COLOR=vec4(1.0,1.0,1.0,0.0);
	}
	if ((UV.x+UV.y*0.03)<0.03)
	{
		COLOR=vec4(1.0,1.0,1.0,0.0);
	}
	
}

void light() {
	// Called for every pixel for every light affecting the CanvasItem.
}
