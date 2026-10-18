extends Node3D
class_name BulletBase

var curr_stats : BulletStats
var velocity = Vector3.ZERO

@onready var _hitscan : RayCast3D = $HitscanRayCast

@onready var _tracer_line : LineMesh3D = $LineMesh3D
@export var MaxTracerLength = 2.

@export var SparkEffect : PackedScene


func launch(spawn_pos:Vector3, spawn_dir:Vector3, stats:BulletStats):
	curr_stats = stats
	global_position = spawn_pos
	look_at(spawn_pos + spawn_dir)
	velocity = spawn_dir * curr_stats.speed


func _physics_process(delta: float) -> void:
	var d : Vector3 = velocity * delta
	global_position += d

	var dist = d.length()
	_tracer_line.display_line([
		Vector3.ZERO,
		Vector3.BACK * min(dist, MaxTracerLength)
	])

	if _hitscan.is_colliding():
		_handle_raycast_collision(_hitscan.get_collider(), _hitscan.get_collision_point())
	_hitscan.position = Vector3.BACK * dist
	_hitscan.target_position = Vector3.FORWARD * dist
	

func _handle_raycast_collision(collision:Node, pos:Vector3):
	if collision is Area3D:
		if collision.collision_layer & Constants.DamageableLayer > 0:
			var hit = collision.get_parent()
			if hit is BotModuleBase:
				hit.damage(curr_stats.damage)
				spawn_sparks(pos)
			elif hit is PlayerController:
				hit.damage(curr_stats.damage)
			elif hit is GunModule and hit._controller == null:
				# Technically robots can pick up stuff...it's a feature not a bug
				get_parent().get_node('Player').Gun.add_to_inventory(hit)
				spawn_sparks(pos)
			despawn()
	else:
		spawn_sparks(pos)
		despawn()


func spawn_sparks(pos:Vector3 = Vector3.ZERO):
	if SparkEffect == null: return
	if pos == Vector3.ZERO: pos = global_position

	var effect : EffectController = SparkEffect.instantiate()
	get_parent().add_child(effect)
	effect.global_position = pos

	effect.play_once()


func despawn():
	queue_free()



class BulletStats:
	var speed : float = 0
	var damage : float = 0
	var scene : PackedScene

	func _init(base_speed:float, base_damage:float, bullet_scene:PackedScene) -> void:
		speed = base_speed
		damage = base_damage
		scene = bullet_scene

	func clone():
		return BulletStats.new(speed, damage, scene)
