extends Node

@export var lifetime_seconds: float = 30.0
@export var random_seconds: float = 10

func _ready():
	
	var lifetime = randf_range(lifetime_seconds-random_seconds, lifetime_seconds+random_seconds)
	await get_tree().create_timer(lifetime).timeout
	queue_free()
