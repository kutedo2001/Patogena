shader_type spatial;
// Sangre que corre por la mirilla de una tubería: nivel según el llenado y bandas que avanzan.
uniform float llenado = 0.0;
uniform float t = 0.0;
varying float altura;
varying float largo;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	altura = (w.y - MODEL_MATRIX[3].y) / 0.055;   // -1 abajo, 1 arriba
	largo = w.x + w.z;
}
void fragment() {
	float nivel = mix(-1.0, 1.0, clamp(llenado * 1.4, 0.0, 1.0));
	if (altura > nivel) discard;
	float bandas = 0.5 + 0.5 * sin((largo - t * 0.9) * 40.0);
	ALBEDO = mix(vec3(0.24, 0.005, 0.015), vec3(0.45, 0.02, 0.03), bandas * llenado);
	ROUGHNESS = 0.25;
	SPECULAR = 0.5;
}
