extends Node3D
class_name BotModuleBase

signal module_destroyed(module:BotModuleBase)

@export var Controller : BotController
@export var ChildModules : Array[BotModuleBase]

@export var Health : float = 6.
@onready var _curr_health = Health

@export var DetachScene : PackedScene
@export var DetachForceMin = 3.
@export var DetachForceMax = 6.
@export var DetachTorque = .1

func _ready() -> void:
	module_destroyed.connect(Controller._on_module_destroyed)

func damage(amount : float):
	_curr_health -= amount
	Controller.damage(amount)
	print(name, ': ', _curr_health)
	if _curr_health <= 0:
		module_destroyed.emit(self)

func detach():
	for m in ChildModules:
		if m == null or m.is_queued_for_deletion():
			continue
		m.detach()

	var rb : RigidBody3D = DetachScene.instantiate()
	Controller.get_parent().add_child(rb)

	rb.global_position = global_position
	rb.global_basis = global_basis

	var dir = Controller.global_position.direction_to(global_position)

	var player = Controller.get_parent().get_node('Player')
	if player != null:
		dir = (dir 
		+ Vector3.UP * randf_range(-1, 1)
		+ player.global_position.direction_to(global_position) * .5).normalized()

	rb.apply_impulse(dir * randf_range(DetachForceMin, DetachForceMax), global_position)
	rb.apply_torque_impulse(Vector3.FORWARD * randf_range(-DetachTorque, DetachTorque)
						 + Vector3.RIGHT * randf_range(-DetachTorque, DetachTorque))

	queue_free()


func death():
	for m in ChildModules:
		if m == null or m.is_queued_for_deletion():
			continue
		m.detach()

	queue_free()
