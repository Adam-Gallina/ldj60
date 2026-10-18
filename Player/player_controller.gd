extends CharacterBody3D
class_name PlayerController

@export_category('Health')
@export var MaxHealth = 10.
@onready var _curr_health = MaxHealth

@export var HealthRegenRate = 5.
var _next_health = 0
@export var HealthRegenAmount = 2.5

@onready var _health_indicator : TextureRect = $CanvasLayer/HealthIndicator

@export_category('Movement')
@export var MoveSpeed = 10
var _disable_movement = false

@export_category('Camera')
@export var CamSpeed = .125
@export var MinPitch = -90.
@export var MaxPitch = 90.
var pitch:
	set(val): $CamParent.rotation.x = val
	get: return $CamParent.rotation.x
var yaw:
	set(val): rotation.y = val
	get: return rotation.y
var _disable_cam = false
@export var CamMod = 1.

@onready var cam: Camera3D = $CamParent/Camera3D
@onready var _screw_ray: RayCast3D = $CamParent/ScrewRayCast3D

@export_category('Combat')
@export var Gun : GunInventory

func set_input(enable_movement=true, enable_cam=true):
	_disable_movement = not enable_movement
	_disable_cam = not enable_cam

func _ready() -> void:
	_update_health_indicator()

func _process(delta):
	if not get_tree().paused:
		_next_health -= delta
	if _next_health <= 0 and _curr_health < MaxHealth:
		_next_health = HealthRegenRate
		_curr_health += HealthRegenAmount
		if _curr_health > MaxHealth: _curr_health = MaxHealth
		_update_health_indicator()

	_handle_input(delta)

	if not _disable_movement:
		velocity = _handle_movement(delta)
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	apply_floor_snap()


func _handle_movement(_delta):
	var x = Input.get_axis('Left', 'Right')
	var z = Input.get_axis('Forward', 'Back')

	var b : Basis = transform.basis
	var dir = (b.z * z + b.x * x).normalized() * MoveSpeed

	return dir

func _handle_input(_delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		if Input.is_key_pressed(KEY_SHIFT):
			get_tree().quit()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_action_just_pressed('Inventory'):
		Gun.toggle_inventory()
		set_input(not Gun.inventory_open, not Gun.inventory_open)
		

	if _disable_cam: return

	if Input.is_action_just_pressed('Select'):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#elif Input.is_action_pressed('Select'):
		else:
			Gun.fire()


func damage(amount:float):
	_curr_health -= amount
	_next_health = HealthRegenRate

	_update_health_indicator()

	if _curr_health <= 0:
		death()

func death():
	print('Yeowch!')


func _update_health_indicator():
	var t = _curr_health / MaxHealth
	_health_indicator.modulate.a = 1 - t
	return


func set_camera(p: float, y: float):
	yaw = y
	if p < MinPitch: p = MinPitch
	elif p > MaxPitch: p = MaxPitch
	pitch = p

func _rotate_camera(dp: float, dy: float):
	yaw -= dy * CamSpeed * CamMod * PI / 180
	var p = pitch * 180 / PI - dp * CamSpeed * CamMod
	if p < MinPitch: p = MinPitch
	elif p > MaxPitch: p = MaxPitch
	pitch = p * PI / 180

func _input(event):
	if event is InputEventMouseMotion and not _disable_cam:
		_rotate_camera(event.relative.y, event.relative.x)

func _reset_cam(duration:float=.5):
	var start_p = pitch
	var start_y = yaw
	var end_y = yaw# + PI
	var remaining = duration
	while remaining > 0:
		remaining -= get_process_delta_time()

		var t = 1 - remaining / duration
		pitch = start_p - start_p * t
		yaw = start_y + (end_y - start_y) * t

		await get_tree().process_frame
	
	pitch = 0
	yaw = 0
