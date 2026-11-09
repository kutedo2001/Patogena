class_name Materiales
## Ajustes de materiales al cargar modelos glTF: el vidrio y los plásticos
## translúcidos se sustituyen por materiales propios (una capa, reflejo suave)
## para que no blanqueen lo que hay dentro (sangre, ADN, líquidos).

static var _cache := {}

static func ajustar(raiz: Node) -> void:
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m == null:
				continue
			var nombre := m.resource_name
			if nombre.begins_with("vidrio") or nombre.begins_with("cristal"):
				mi.set_surface_override_material(i, _vidrio(m, 0.16))
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			elif nombre.begins_with("caldo"):
				mi.set_surface_override_material(i, _caldo(m))
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			elif nombre.begins_with("liq_") or nombre.begins_with("liquido"):
				mi.set_surface_override_material(i, _liquido(m))
			elif nombre.begins_with("polipropileno"):
				mi.set_surface_override_material(i, _vidrio_plastico(m))
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _vidrio(base: Material, alfa: float) -> StandardMaterial3D:
	var clave := "%s_%f" % [base.resource_name, alfa]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	# el vidrio real casi no difunde luz: albedo oscuro y solo reflejos (si no, blanquea lo de dentro)
	var c: Color = (base as BaseMaterial3D).albedo_color if base is BaseMaterial3D else Color.WHITE
	m.albedo_color = Color(c.r * 0.08, c.g * 0.08, c.b * 0.08, alfa)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.render_priority = 1          # el vidrio se dibuja después de lo que contiene
	m.roughness = 0.12
	m.metallic_specular = 0.5
	m.rim_enabled = true
	m.rim = 0.55
	m.rim_tint = 0.6
	_cache[clave] = m
	return m

## Líquidos: reflejo bajo para que el color se vea profundo (sangre roja, no rosa).
static func _liquido(base: Material) -> Material:
	var clave := "liq_" + base.resource_name
	if _cache.has(clave):
		return _cache[clave]
	var m: StandardMaterial3D = (base as StandardMaterial3D).duplicate()
	m.metallic_specular = 0.5
	m.roughness = 0.35
	_cache[clave] = m
	return m

## Plástico translúcido (eppendorf): algo lechoso pero sin tapar el contenido.
static func _vidrio_plastico(base: Material) -> StandardMaterial3D:
	var clave := "pp_" + base.resource_name
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.62, 0.58, 0.32)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.roughness = 0.3
	m.metallic_specular = 0.4
	_cache[clave] = m
	return m

## Caldo de cultivo: translúcido para que se vea el agitador, con algo de brillo propio.
static func _caldo(base: Material) -> StandardMaterial3D:
	var clave := "caldo_" + base.resource_name
	if _cache.has(clave):
		return _cache[clave]
	var b := base as StandardMaterial3D
	var m := StandardMaterial3D.new()
	var c := b.albedo_color
	m.albedo_color = Color(c.r, c.g, c.b, minf(c.a, 0.72))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = 0
	m.roughness = 0.3
	m.metallic_specular = 0.15
	m.emission_enabled = true
	m.emission = b.emission if b.emission_enabled else c
	m.emission_energy_multiplier = 0.5 * minf(c.a / 0.72, 1.0)
	_cache[clave] = m
	return m
