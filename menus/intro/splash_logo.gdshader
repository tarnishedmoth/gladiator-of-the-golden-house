shader_type canvas_item;

void fragment() {
	COLOR.rg = vec2(0.7);
	COLOR.b = 1.0;
	float mask1 = sin((UV.y - TIME) * 4.0) * 0.3 + 0.6;
	float mask2 = sin((SCREEN_UV.x - TIME) * 45.0) * 0.25 + 1.4;
	float scanlines_factor = pow((sin((SCREEN_UV.y - TIME / 15.0) * 150.0) * 0.5 + 0.5), 2.5) * mask1 * mask2;

	float fresnel_factor = pow(0.0, 5);
	
	COLOR.a *= pow(scanlines_factor + fresnel_factor, 0.33);
}