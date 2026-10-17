extends Node3D
class_name GunController

@export var CurrGun : ClipModule
@onready var _gun_pivot = $GunPivot

@export_category('Inventory')
@export var Inventory : Array[GunModule] = []
@onready var _inventory_pivot = $GunPivot/InventoryPivot

var inventory_open = false

@export var ModuleMargin : float = .1

@onready var raycast : RayCast3D = $RayCast3D
var _curr_hover : GunModule
var _curr_drag : GunModule
var _curr_connector : Area3D
var _curr_connector_module : GunModule

@export_category('Camera')
@export var CamSpeed = .125
@export var MinPitch = -90.
@export var MaxPitch = 90.
var pitch:
	set(val): _inventory_pivot.rotation.x = val
	get: return _inventory_pivot.rotation.x
var yaw:
	set(val): _inventory_pivot.rotation.y = val
	get: return _inventory_pivot.rotation.y
var _cam_active = false
@export_category('')

@onready var anim : AnimationPlayer = $AnimationPlayer


func get_bullet_parent() -> Node3D: return get_parent().get_parent().get_parent().get_parent()

func _ready() -> void:
	CurrGun = load('res://Gun/Modules/basic_clip_module.tscn').instantiate()
	CurrGun.connector_hover_changed.connect(_on_module_connector_hovered)
	_inventory_pivot.add_child(CurrGun)
	CurrGun.set_controller(self)

	add_to_inventory(load('res://Gun/Modules/basic_muzzle_module.tscn').instantiate())
	add_to_inventory(load('res://Gun/Modules/basic_muzzle_module.tscn').instantiate())


func fire():
	CurrGun.process_bullet()


func add_to_inventory(module:GunModule):
	Inventory.append(module)
	module.hover_changed.connect(_on_module_hovered)

func toggle_inventory():
	inventory_open = not inventory_open
	if inventory_open:
		anim.play('swap_inventory')
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		anim.play_backwards('swap_inventory')
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_reset_cam(.1)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'swap_inventory':
		if inventory_open:
			for i in range(Inventory.size()):
				_gun_pivot.add_child(Inventory[i])
				Inventory[i].position = Vector3.DOWN.rotated(Vector3.LEFT, PI / 8 * i)
			# TODO: Init all modules on gun
		else:
			for m in Inventory:
				pass
				# TODO: Remove inventory items from gun pivot
				# TODO: Disable gun module callbacks


func _process(delta: float) -> void:
	if not inventory_open:
		_cam_active = false
		return

	_cam_active = Input.is_action_pressed('Inventory Camera')

	if Input.is_action_just_pressed('Select'):
		if _curr_hover != null:
			_curr_drag = _curr_hover
			_curr_drag.set_mouse_areas(false)
	elif Input.is_action_just_released('Select'):
		if _curr_drag != null:
			if _curr_connector != null:
				add_module_to_connector(_curr_drag, _curr_connector, _curr_connector_module)
			else:
				remove_module_from_connector(_curr_drag)

			_curr_drag.set_mouse_areas(true)
			_curr_hover = _curr_drag
			_curr_drag = null
	
	if _curr_drag != null:
		if _curr_connector != null:
			_curr_drag.global_position = _curr_connector.global_position
			_curr_drag.global_basis.z = _curr_connector.global_basis.z
		else:
			var pos = get_mouse_ray()
			if pos != Vector3.ZERO: 
				_curr_drag.global_position = pos
				_curr_drag.basis.z = Vector3.FORWARD


func _on_module_hovered(module:GunModule, hovered:bool):
	if hovered: _curr_hover = module
	elif _curr_hover == module: _curr_hover = null

func _on_module_connector_hovered(module:GunModule, connector:Area3D, hovered:bool):
	if hovered: 
		_curr_hover = module
		_curr_connector = connector
		_curr_connector_module = module
	else:
		if _curr_hover == module: 
			_curr_hover = null
		if _curr_connector == connector:
			_curr_connector = null
			_curr_connector_module = null


func add_module_to_connector(module:GunModule, connector:Area3D, connector_module:GunModule):
	if module.PreviousModule == null:
		module.connector_hover_changed.connect(_on_module_connector_hovered)
	
	if connector_module.set_next_module(module, connector):
		Inventory.erase(module)
		module.set_controller(self)

func remove_module_from_connector(module:GunModule):
	if module.PreviousModule != null:
		module.PreviousModule.remove_next_module(module)
		module.connector_hover_changed.disconnect(_on_module_connector_hovered)
		Inventory.append(module)
	
	module.get_parent().remove_child(module)
	_gun_pivot.add_child(module)
	module.basis.z = Vector3.FORWARD


func set_camera(p: float, y: float):
	yaw = y
	if p < MinPitch: p = MinPitch
	elif p > MaxPitch: p = MaxPitch
	pitch = p

func _rotate_camera(dp: float, dy: float):
	yaw += dy * CamSpeed * PI / 180
	var p = pitch * 180 / PI - dp * CamSpeed
	if p < MinPitch: p = MinPitch
	elif p > MaxPitch: p = MaxPitch
	pitch = p * PI / 180

func _input(event):
	if event is InputEventMouseMotion and _cam_active:
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

func get_mouse_ray() -> Vector3:
	var m = get_viewport().get_mouse_position()
	
	raycast.global_position = get_viewport().get_camera_3d().project_ray_origin(m)
	raycast.target_position = get_viewport().get_camera_3d().project_local_ray_normal(m) * 100
	raycast.force_raycast_update()

	if raycast.is_colliding():
		return raycast.get_collision_point()
	else:
		return Vector3.ZERO
