extends Node3D

@export var rotation_speed: float = 10.0
@export var change_interval: float = 2.0

var target_rotation: Vector3
var timer: float = 0.0

func _ready() -> void:
	randomize()
	target_rotation = Vector3(
		randf_range(-rotation_speed, rotation_speed),
		randf_range(-rotation_speed, rotation_speed),
		randf_range(-rotation_speed, rotation_speed)
	)

func _process(delta: float) -> void:
	timer += delta
	if timer >= change_interval:
		timer = 0.0
		target_rotation = Vector3(
			randf_range(-rotation_speed, rotation_speed),
			randf_range(-rotation_speed, rotation_speed),
			randf_range(-rotation_speed, rotation_speed)
		)

	rotation_degrees += target_rotation * delta
