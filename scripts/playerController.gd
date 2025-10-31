extends CharacterBody3D

@export var move_speed: float = 6.0
@export var mouse_sensitivity: float = 0.1
@export var gravity: float = 9.8
@export var jump_force: float = 6.0
@export var camera_path: NodePath

var yaw: float = 0.0
var pitch: float = 0.0
var mouse_captured: bool = true

var cam: Camera3D


func _ready():
	cam = get_node(camera_path)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	# Toggle mouse capture
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_captured = !mouse_captured

		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	
	# Mouse look
	if event is InputEventMouseMotion and mouse_captured:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -80, 80)

		rotation_degrees.y = yaw

		cam.rotation_degrees.x = pitch
		cam.rotation_degrees.y = yaw


func _physics_process(delta):
	var input_dir: Vector3 = Vector3.ZERO

	var forward = -cam.global_transform.basis.z
	var right   = cam.global_transform.basis.x

	if Input.is_action_pressed("move_forward"):
		input_dir += forward
	if Input.is_action_pressed("move_backward"):
		input_dir -= forward
	if Input.is_action_pressed("move_left"):
		input_dir -= right
	if Input.is_action_pressed("move_right"):
		input_dir += right

	input_dir.y = 0
	input_dir = input_dir.normalized()

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
		else:
			velocity.y = 0

	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.z * move_speed

	move_and_slide()

	cam.global_transform.origin = global_transform.origin + Vector3(0, 1, 0)
