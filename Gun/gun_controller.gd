extends Node3D
class_name GunController

@export var Parent : Node3D
var CurrGun : ClipModule

@onready var _reticle_raycast = $ReticleRayCast3D

@export_category('Effects')
@onready var _audio = $AudioStreamPlayer

@export var MinAudioPitch = .25
@export var MaxAudioPitch = 2.

func get_bullet_parent() -> Node3D: return Parent.get_parent()

func _ready() -> void:
	set_base_module(load('res://Gun/Modules/basic_clip_module.tscn').instantiate())
	add_module_to_connector(load('res://Gun/Modules/basic_muzzle_module.tscn').instantiate(), CurrGun.Connectors[0], CurrGun)


func fire():
	CurrGun.process_bullet()

func get_bullet_adjustment(spawn_pos:Vector3, spawn_dir:Vector3) -> Vector3:
	if not _reticle_raycast.is_colliding(): return spawn_dir

	var pos : Vector3 = _reticle_raycast.get_collision_point()
	# Make sure muzzle would not be shooting backwards
	if global_position.distance_to(pos) < global_position.distance_to(spawn_pos): return spawn_dir

	var dir : Vector3 = (pos - spawn_pos).normalized()
	# Make sure muzzle is pointing forwards
	if spawn_dir.signed_angle_to(dir, Vector3.UP) > 89: return spawn_dir

	return dir

func play_gunshot():
	var p = randf_range(MinAudioPitch, MaxAudioPitch)
	_audio.pitch_scale = p
	_audio.play()

func calc_spread_ang():
	return 10


func add_module_to_connector(module:GunModule, connector:Area3D, connector_module:GunModule):
	if connector_module.set_next_module(module, connector):
		module.set_controller(self)
		return true

	return false

func remove_module_from_connector(module:GunModule):
	if module.PreviousModule != null:
		module.PreviousModule.remove_next_module(module)

		for m in module.NextModules:
			if m != null:
				remove_module_from_connector(m)

func set_base_module(module:ClipModule):
	CurrGun = module
	CurrGun.set_controller(self)
	add_child(module)
