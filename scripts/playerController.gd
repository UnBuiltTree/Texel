extends CharacterBody3D

@export var jumpImpulse: float = 6.5
@export var gravity: float = -22.0

@export var groundAcceleration: float = 30.0
@export var groundSpeedLimit: float = 6.0
@export var groundFriction: float = 0.90

@export var airAcceleration: float = 500.0
@export var airSpeedLimit: float = 0.6

@export var mouseSensitivity: float = 0.1
@export var camera_path: NodePath

@export var platform_scene: PackedScene
@export var platform_lifetime: float = 30.0
@export var platform_spawn_cooldown: float = 0.2

var _next_spawn_time: float = 0.0

var cam: Camera3D
var pitch: float = 0.0
var yaw: float = 0.0

func _ready():
	cam = get_node(camera_path)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouseSensitivity
		rotation_degrees.y = yaw
		cam.rotation_degrees.y = yaw

		pitch = clamp(pitch - event.relative.y * mouseSensitivity, -89, 89)
		cam.rotation_degrees.x = pitch


func _physics_process(delta):
	velocity.y += gravity * delta

	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = jumpImpulse
		else:
			velocity.x *= groundFriction
			velocity.z *= groundFriction

	var cam_basis = global_transform.basis
	var strafe_dir = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		strafe_dir -= cam_basis.z
	if Input.is_action_pressed("move_backward"):
		strafe_dir += cam_basis.z
	if Input.is_action_pressed("move_left"):
		strafe_dir -= cam_basis.x
	if Input.is_action_pressed("move_right"):
		strafe_dir += cam_basis.x

	strafe_dir.y = 0
	strafe_dir = strafe_dir.normalized()

	var accel = groundAcceleration if is_on_floor() else airAcceleration
	var speed_limit = groundSpeedLimit if is_on_floor() else airSpeedLimit

	var current_speed = velocity.dot(strafe_dir)
	var add_speed = speed_limit - current_speed

	if add_speed > 0:
		var accel_amount = accel * delta
		if accel_amount > add_speed:
			accel_amount = add_speed
		velocity += strafe_dir * accel_amount

	move_and_slide()
	cam.global_transform.origin = global_transform.origin + Vector3(0, 0.8, 0)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var now = Time.get_ticks_msec() / 1000.0
		if now >= _next_spawn_time:
			_try_spawn_platform()
			_next_spawn_time = now + platform_spawn_cooldown


func _try_spawn_platform():
	if is_on_floor():
		return
	if velocity.y > 0:
		return

	var platform = platform_scene.instantiate()

	var spawn_pos = global_transform.origin
	spawn_pos.y -= 1.0
	platform.position = spawn_pos

	get_tree().current_scene.add_child(platform)

	_cleanup_after_delay(platform)


func _cleanup_after_delay(node):
	await get_tree().create_timer(platform_lifetime).timeout
	if is_instance_valid(node):
		node.queue_free()
