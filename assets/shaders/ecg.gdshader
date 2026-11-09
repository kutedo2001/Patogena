shader_type spatial;
render_mode unshaded;
// Monitor de constantes de la camilla: electro que corre, pulsioxímetro y barra de extracción.
uniform float t = 0.0;
uniform float pulso = 1.2;          // latidos por segundo
uniform float llenado = 0.0;        // 0..1 tubo de la extracción
uniform float encendido = 1.0;      // 0 sin paciente: línea plana
uniform vec3 c_linea = vec3(0.25, 1.0, 0.45);

float ecg(float x) {
	float f = fract(x);
	float y = 0.0;
	y += 0.08 * exp(-pow((f - 0.18) * 30.0, 2.0));          // onda P
	y -= 0.10 * exp(-pow((f - 0.28) * 90.0, 2.0));          // Q
	y += 0.85 * exp(-pow((f - 0.31) * 70.0, 2.0));          // R
	y -= 0.22 * exp(-pow((f - 0.34) * 70.0, 2.0));          // S
	y += 0.16 * exp(-pow((f - 0.55) * 18.0, 2.0));          // T
	return y;
}

float digito(vec2 p, int n) {
	// siete segmentos en una celda 0..1
	if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) return 0.0;
	int s[10] = int[](119, 36, 93, 109, 46, 107, 123, 37, 127, 111);
	int m = s[clamp(n, 0, 9)];
	float w = 0.16;
	float r = 0.0;
	if ((m & 1) != 0 && p.y > 1.0 - w && p.x > w && p.x < 1.0 - w) r = 1.0;           // arriba
	if ((m & 2) != 0 && p.x < w && p.y > 0.5 && p.y < 1.0 - w * 0.5) r = 1.0;         // arriba izq
	if ((m & 4) != 0 && p.x > 1.0 - w && p.y > 0.5 && p.y < 1.0 - w * 0.5) r = 1.0;   // arriba der
	if ((m & 8) != 0 && abs(p.y - 0.5) < w * 0.5 && p.x > w && p.x < 1.0 - w) r = 1.0; // centro
	if ((m & 16) != 0 && p.x < w && p.y < 0.5 && p.y > w * 0.5) r = 1.0;              // abajo izq
	if ((m & 32) != 0 && p.x > 1.0 - w && p.y < 0.5 && p.y > w * 0.5) r = 1.0;        // abajo der
	if ((m & 64) != 0 && p.y < w && p.x > w && p.x < 1.0 - w) r = 1.0;                 // abajo
	return r;
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	vec3 col = vec3(0.01, 0.04, 0.045);
	// rejilla
	vec2 g = fract(uv * vec2(16.0, 10.0));
	col += vec3(0.0, 0.05, 0.04) * step(0.93, max(g.x, g.y));
	// electro en la franja de arriba (0..0.68 de ancho)
	if (uv.x < 0.68 && uv.y > 0.45) {
		float x = uv.x * 2.2 - t * pulso * 0.9;
		float y = 0.62 + ecg(x) * 0.28 * encendido;
		float d = abs(uv.y - y);
		float barrido = fract(t * 0.35);
		float hueco = step(abs(uv.x / 0.68 - barrido), 0.03);
		col = mix(col, c_linea, (1.0 - smoothstep(0.004, 0.018, d)) * (1.0 - hueco));
	}
	// pulsioxímetro (curva azul) abajo a la izquierda
	if (uv.x < 0.68 && uv.y < 0.42 && uv.y > 0.08) {
		float x = uv.x * 2.2 - t * pulso * 0.9;
		float y = 0.22 + 0.1 * encendido * sin(fract(x) * 6.2831 - 1.2) * exp(-fract(x) * 1.5);
		col = mix(col, vec3(0.3, 0.7, 1.0), 1.0 - smoothstep(0.004, 0.016, abs(uv.y - y)));
	}
	// cifras: pulso (verde) y SpO2 (azul) a la derecha
	int lpm = int(pulso * 60.0 * encendido);
	vec2 q = (uv - vec2(0.72, 0.6)) / vec2(0.075, 0.28);
	float dg = digito(q, (lpm / 100) % 10) * step(100.0, float(lpm)) + digito(q - vec2(1.3, 0.0), (lpm / 10) % 10) + digito(q - vec2(2.6, 0.0), lpm % 10);
	col = mix(col, c_linea, dg);
	int sat = int(mix(0.0, 98.0, encendido) - llenado * 3.0);
	vec2 q2 = (uv - vec2(0.76, 0.22)) / vec2(0.06, 0.2);
	float ds = digito(q2, (sat / 10) % 10) + digito(q2 - vec2(1.3, 0.0), sat % 10);
	col = mix(col, vec3(0.3, 0.7, 1.0), ds);
	// barra de la extracción (rojo) al pie
	if (uv.y < 0.06 && uv.y > 0.02 && uv.x > 0.03 && uv.x < 0.97) {
		float k = (uv.x - 0.03) / 0.94;
		col = mix(vec3(0.12, 0.02, 0.02), vec3(0.85, 0.08, 0.08), step(k, llenado));
	}
	ALBEDO = col;
	EMISSION = col * 0.6;
}
