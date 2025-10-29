extends Camera3D

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.1

var yaw: float = 0.0
var pitch: float = 0.0
var mouse_captured: bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	yaw = rotation_degrees.y
	pitch = rotation_degrees.x

func _input(event: InputEvent) -> void:
	# Toggle mouse capture
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_captured = !mouse_captured
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Mouse look
	elif event is InputEventMouseMotion and mouse_captured:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -89, 89)
		rotation_degrees.x = pitch
		rotation_degrees.y = yaw
		# print("yaw:", yaw, " pitch:", pitch)
		
func _process(delta: float) -> void:
	var direction := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	if Input.is_action_pressed("move_up"):
		direction += transform.basis.y
	if Input.is_action_pressed("move_down"):
		direction -= transform.basis.y

	if direction != Vector3.ZERO:
		global_position += direction.normalized() * move_speed * delta
