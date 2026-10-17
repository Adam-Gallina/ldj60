extends RigidBody3D
class_name BulletBase

var _curr_speed = 0
func get_speed() -> float: return _curr_speed
func set_speed(new_speed:float): _curr_speed = new_speed

var _curr_damage = 0
func get_damage() -> float: return _curr_damage
func set_damage(new_damage:float): _curr_damage = new_damage


func launch(spawn_pos:Vector3, spawn_dir:Vector3):
	global_position = spawn_pos
	look_at(spawn_pos + spawn_dir)
	linear_velocity = _curr_speed * spawn_dir


func _on_body_entered(body: Node) -> void:
	print('Splatted ', body.name, ' for ', _curr_damage)
	queue_free()
