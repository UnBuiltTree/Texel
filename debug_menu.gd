extends CanvasLayer

var all_mats: Array[ShaderMaterial] = []

@onready var panel = $PanelContainer
@onready var chk_triplanar = $PanelContainer/VBoxContainer/Check_TRIPLANAR
@onready var chk_pix_scale = $PanelContainer/VBoxContainer/Check_PIX_SCALE_TEXEL
@onready var slider_texel = $PanelContainer/VBoxContainer/Slider_TEXEL_SIZE
@onready var slider_bias = $PanelContainer/VBoxContainer/Slider_BIAS
@onready var slider_scale = $PanelContainer/VBoxContainer/Slider_TEXTURE_SCALE

@onready var post_fx_node: TextureRect = $"../../PostFX"
@onready var post_mat: ShaderMaterial = post_fx_node.material
@onready var chk_postfx_visible = $PanelContainer/VBoxContainer/Check_POST_FX
@onready var slider_hue = $PanelContainer/VBoxContainer/Slider_LEVELS_H
@onready var slider_val = $PanelContainer/VBoxContainer/Slider_LEVELS_V

var label_texel_value: Label
var label_bias_value: Label
var label_scale_value: Label
var label_hue_value: Label
var label_val_value: Label

var texel_steps = [
	1.0,
	1.0/2.0,
	1.0/3.0,
	1.0/4.0,
	1.0/5.0,
	1.0/6.0,
	1.0/8.0,
	1.0/10.0,
	1.0/12.0,
	1.0/14.0,
	1.0/16.0,
	1.0/24.0,
	1.0/32.0,
	1.0/64.0,
]

func _ready():
	panel.hide()
	_collect_materials(get_tree().current_scene)

	label_texel_value = _make_value_label(); slider_texel.add_child(label_texel_value)
	label_bias_value = _make_value_label(); slider_bias.add_child(label_bias_value)
	label_scale_value = _make_value_label(); slider_scale.add_child(label_scale_value)
	label_hue_value = _make_value_label(); slider_hue.add_child(label_hue_value)
	label_val_value = _make_value_label(); slider_val.add_child(label_val_value)

	# Connect UI signals
	chk_triplanar.toggled.connect(_on_triplanar_toggle)
	chk_pix_scale.toggled.connect(_on_pix_scale_toggle)
	chk_postfx_visible.toggled.connect(_on_postfx_toggle)
	slider_texel.value_changed.connect(_on_texel_change)
	slider_bias.value_changed.connect(_on_bias_change)
	slider_scale.value_changed.connect(_on_scale_change)
	slider_hue.value_changed.connect(_on_hue_change)
	slider_val.value_changed.connect(_on_val_change)

	_on_texel_change(slider_texel.value)
	_on_bias_change(slider_bias.value)
	_on_scale_change(slider_scale.value)
	_on_hue_change(slider_hue.value)
	_on_val_change(slider_val.value)
	_on_postfx_toggle(chk_postfx_visible.button_pressed)
	_on_pix_scale_toggle(chk_pix_scale.button_pressed)

func _input(event):
	if event.is_action_pressed("ui_debug_menu"):
		panel.visible = !panel.visible

func _make_value_label() -> Label:
	var lbl = Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(0, 22)
	lbl.anchor_left = 0
	lbl.anchor_right = 1
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl

# Collects all shader materials
func _collect_materials(node):
	if node is MeshInstance3D:
		if node.material_override and node.material_override is ShaderMaterial:
			all_mats.append(node.material_override)
		for i in range(node.get_surface_override_material_count()):
			var mat = node.get_surface_override_material(i)
			if mat is ShaderMaterial:
				all_mats.append(mat)

	for child in node.get_children():
		_collect_materials(child)

# Apply parameter to all shader materials
func _update_all(param: String, val):
	for m in all_mats:
		m.set_shader_parameter(param, val)

func _on_triplanar_toggle(b):
	_update_all("TRIPLANAR", b)

func _on_pix_scale_toggle(b):
	_update_all("PIXEL_SCALE_TEXELS", b)

func _on_texel_change(step_index: float):
	var texel_value = texel_steps[int(step_index)]
	label_texel_value.text = "%.3f" % texel_value
	_update_all("TEXEL_SIZE", texel_value)

func _on_bias_change(v):
	label_bias_value.text = "%.3f" % v
	_update_all("BIAS_STRENGTH", v)

func _on_scale_change(v):
	label_scale_value.text = "%.3f" % v
	_update_all("TEXTURE_SCALE", v)

func _on_hue_change(v):
	label_hue_value.text = "%.1f" % v
	post_mat.set_shader_parameter("LEVELS_H", v)

func _on_val_change(v):
	label_val_value.text = "%.1f" % v
	post_mat.set_shader_parameter("LEVELS_V", v)

func _on_postfx_toggle(is_on):
	post_fx_node.visible = is_on
