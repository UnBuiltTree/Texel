extends PanelContainer

var fps_history: Array[float] = []
var frame_ms_history: Array[float] = []
var tick_history: Array[bool] = []

@onready var debug_label: Label = $VBoxContainer/DebugLabel
@onready var graph_fps: TextureRect = $VBoxContainer/Graph_FPS
@onready var graph_frame: TextureRect = $VBoxContainer/Graph_Frame

var graph_width := 200
var graph_height := 40

var time_accum := 0.0

func _ready():
	visible = false
	set_process_input(true)
	set_process(true)

func _input(event):
	if event.is_action_pressed("ui_debug_menu"):
		visible = !visible

func _process(delta):
	if !visible:
		return

	time_accum += delta

	var tick_now := false
	if time_accum >= 1.0:
		tick_now = true
		time_accum = 0.0

	_update_debug_text(delta, tick_now)
	_update_graph_fps()
	_update_graph_frame()


func _update_debug_text(delta, tick_now):
	var fps = Engine.get_frames_per_second()
	var frame_ms = delta * 1000.0

	fps_history.append(fps)
	frame_ms_history.append(frame_ms)
	tick_history.append(tick_now)

	if fps_history.size() > graph_width:
		fps_history.pop_front()
		frame_ms_history.pop_front()
		tick_history.pop_front()

	# VRAM
	var vram_used = float(RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED
	)) / (1024.0 * 1024.0)

	debug_label.text = "FPS: %d\nFrame time: %.2f ms\nVRAM Used: %.1f MB" % [
		fps, frame_ms, vram_used
	]


func _update_graph_fps():
	var img = Image.create(graph_width, graph_height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0.4))

	for x in range(fps_history.size()):
		var fps_val = fps_history[x]
		var y = int(clamp((1.0 - (fps_val / 120.0)) * graph_height, 0, graph_height - 1))

		for yy in range(y, graph_height):
			img.set_pixel(x, yy, Color(0,1,0,0.7))

		if tick_history[x]:
			for yy in range(graph_height):
				img.set_pixel(x, yy, Color(1,1,1,0.3))

	graph_fps.texture = ImageTexture.create_from_image(img)


func _update_graph_frame():
	var img = Image.create(graph_width, graph_height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0.4))

	for x in range(frame_ms_history.size()):
		var ms_val = frame_ms_history[x]
		var y = int(clamp((ms_val / 20.0) * graph_height, 0, graph_height - 1))

		for yy in range(graph_height - y, graph_height):
			img.set_pixel(x, yy, Color(1,0,0,0.7))

		if tick_history[x]:
			for yy in range(graph_height):
				img.set_pixel(x, yy, Color(1,1,1,0.3))

	graph_frame.texture = ImageTexture.create_from_image(img)
