extends CharacterBody3D
class_name BotController

enum AIState {
	wander,
	chase,
	investigate,
	attack,
	reposition
}

@export var Health = 18.
@onready var _curr_health = Health

@export var Torso : BotModuleBase

@export_category('Navigation')
@onready var _nav_agent : NavigationAgent3D = $NavigationAgent3D
var _target : Node3D

@export var NoticeDistance = 6.
@export var NoticeAngle = 75.
@onready var _notice_angle_rad = deg_to_rad(NoticeAngle)
@export var WatchDistance = 15.

@export var WanderSpeed = 6.
@export var ChaseSpeed = 8.

@export var WanderRadius = 10.
@export var WanderDelayMin = 1.
@export var WanderDelayMax = 1.
@export var TurnSpeed = 180.
@onready var _turn_speed_rad = deg_to_rad(TurnSpeed)

var _state = AIState.wander

@export_category('Combat')
@export var MinAttackRange = 3
@export var MaxAttackRange = 5

@export var CurrGun : GunController
@export var AttackCooldown = .5
var _next_attack = 0

@export_category('')

@onready var _eye_raycast = $PlayerRayCast3D

func _ready() -> void:
	_nav_agent.velocity_computed.connect(_on_velocity_calculated)
	_nav_agent.navigation_finished.connect(_on_navigation_finished)

	_nav_agent.max_speed = WanderSpeed	
	_on_navigation_finished()


func _physics_process(delta: float) -> void:
	if _state == AIState.attack:
		_nav_agent.set_velocity(Vector3.ZERO)
		velocity = Vector3.ZERO
		_process_rotation(global_position.direction_to(_target.global_position), delta)
	elif _state == AIState.wander or _state == AIState.chase or _state == AIState.reposition:
		var next_pos : Vector3 = _nav_agent.get_next_path_position()
		var next_v : Vector3 = global_position.direction_to(next_pos) * _nav_agent.max_speed
		_nav_agent.set_velocity(next_v)
		_process_rotation(next_v, delta)

	_process_ai(delta)

func _process_rotation(dir:Vector3, delta: float):
	var ang = basis.z.signed_angle_to(dir, Vector3.UP)
	var dang = ang * _turn_speed_rad * delta
	rotation.y += ang if dang > ang else dang

func _process_ai(delta:float):
	# Stop attacking if out of range or lost line of sight
	if _state == AIState.attack:
		if global_position.distance_to(_target.global_position) > MaxAttackRange:
			_state = AIState.chase
		else:
			_eye_raycast.target_position = global_position.direction_to(_target.global_position)
			_eye_raycast.force_raycast_update()

			if _eye_raycast.is_colliding():
				_state = AIState.chase
			else:
				_process_attack(delta)


	# Attack if in range, or start investigating if target lost
	if _state == AIState.chase:
		var dist = global_position.distance_to(_target.global_position)
		if dist <= MinAttackRange:
			_state = AIState.attack
			_next_attack = AttackCooldown
		elif dist > WatchDistance:
			_state = AIState.investigate
		else:
			_nav_agent.set_target_position(_target.global_position)

	# Wait to find a target
	if _state == AIState.wander or _state == AIState.investigate:
		for actor in get_tree().get_nodes_in_group('Actor'):
			var dist = global_position.distance_to(actor.global_position)
			var ang = basis.z.angle_to(global_position.direction_to(actor.global_position))
			if actor is PlayerController:
				if ang <= _notice_angle_rad and dist < NoticeDistance:
					_eye_raycast.target_position = global_position.direction_to(actor.global_position)
					_eye_raycast.force_raycast_update()

					if not _eye_raycast.is_colliding(): _start_chase(actor)
			elif actor is BotController:
				if actor == self: continue
				if ang > _notice_angle_rad: continue
				if dist > NoticeDistance: continue

				if actor._state == AIState.chase: _start_chase(actor._target)

func _process_attack(delta:float):
	_next_attack -= delta

	if _next_attack <= 0:
		CurrGun.fire()
		_next_attack = AttackCooldown

func _on_velocity_calculated(safe_v : Vector3):
	velocity = safe_v
	move_and_slide()

func _on_navigation_finished():
	if _state == AIState.investigate:
		_state = AIState.wander
		_nav_agent.max_speed = WanderSpeed	
	
	if _state == AIState.wander:
		await get_tree().create_timer(randf_range(WanderDelayMin, WanderDelayMax)).timeout
		if _state == AIState.wander:
			_nav_agent.set_target_position(_get_random_position())


func _start_chase(target:Node3D):
	_state = AIState.chase
	_nav_agent.set_target_position(target.global_position)
	_nav_agent.max_speed = ChaseSpeed
	_target = target

func _get_random_position() -> Vector3:
	var pos = global_position + Vector3.FORWARD.rotated(Vector3.UP, randf_range(-PI, PI)) * randf_range(0, WanderRadius)
	return NavigationServer3D.map_get_closest_point(_nav_agent.get_navigation_map(), pos)



func damage(amount: float):
	_curr_health -= amount

	if _curr_health <= 0:
		death()

func death():
	if Torso != null and not Torso.is_queued_for_deletion():
		Torso.death()

	queue_free()


func _on_module_destroyed(module:BotModuleBase):
	module.death()

	if module == Torso:
		death()
