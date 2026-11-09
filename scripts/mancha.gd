class_name Mancha
## Mancha en el suelo (sangre): Decal en Forward+; en Compatibility (web/móvil) no hay
## decals, así que se usa un plano casi pegado al suelo con la textura y transparencia.

static func crear(tex: Texture2D, tam: float) -> Node3D:
	if RenderingServer.get_rendering_device() != null:
		var d := Decal.new()
		d.texture_albedo = tex
		d.size = Vector3(tam, 0.4, tam)
		return d
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(tam, tam)
	m.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.35
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position.y = 0.004
	var raiz := Node3D.new()
	raiz.add_child(m)
	return raiz
