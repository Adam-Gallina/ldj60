extends GunController
class_name GunInventory

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
@export_category('UI')
@onready var _recycle_label : Label = get_node('%RecycleLabel')
var _curr_recycle : GunModule = null

@export_category('')

@onready var anim : AnimationPlayer = $AnimationPlayer

@export var BaseAmmo = 10
@onready var _curr_ammo = BaseAmmo
@export var ShotRate = .25
var _can_shoot : bool = true
@export var ReloadRate = 1.

@onready var _ammo_label = get_node('%AmmoLabel')
@onready var _max_ammo_label = get_node('%MaxAmmoLabel')

func _ready() -> void:
	set_base_module(load('res://Gun/Modules/basic_clip_module.tscn').instantiate())

	add_to_inventory(load('res://Gun/Modules/basic_muzzle_module.tscn').instantiate())
	add_to_inventory(load('res://Gun/Modules/basic_muzzle_module.tscn').instantiate())
	
	update_recycle_text(null)

func fire():
	if _can_shoot:
		super()

		_can_shoot = false

		_curr_ammo -= 1
		_update_ammo()

		if _curr_ammo <= 0:
			await reload()
		else:
			await get_tree().create_timer(ShotRate).timeout
		_can_shoot = true

func reload():
	_can_shoot = false
	await get_tree().create_timer(ReloadRate).timeout
	_curr_ammo = BaseAmmo
	_update_ammo()
	_can_shoot = true

func _update_ammo():
	_ammo_label.text = str(_curr_ammo)
	_max_ammo_label.text = str(BaseAmmo)

func add_to_inventory(module:GunModule):
	Inventory.append(module)
	module.hover_changed.connect(_on_module_hovered)
	if module.get_parent() != null:
		module.get_parent().remove_child(module)

	if inventory_open:
		_gun_pivot.add_child(module)
		module.position = Vector3.DOWN.rotated(Vector3.LEFT, PI / 8 * (Inventory.size()-1))


func toggle_inventory():
	inventory_open = not inventory_open
	if inventory_open:
		anim.play('swap_inventory')
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		#get_tree().paused = false
		anim.play_backwards('swap_inventory')
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_reset_cam(.1)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'swap_inventory':
		if inventory_open:
			#get_tree().paused = true
			for i in range(Inventory.size()):
				_gun_pivot.add_child(Inventory[i])
				Inventory[i].position = Vector3.DOWN.rotated(Vector3.LEFT, PI / 8 * i)
		else:
			update_recycle_text(null)
			for m in Inventory:
				_gun_pivot.remove_child(m)

		_update_gun_arrows(CurrGun, inventory_open)

func _update_gun_arrows(module:GunModule, display:bool):
	for m in module.NextModules:
		if m == null: continue
		_update_gun_arrows(m, display)
	
	module.set_arrows(display, true)

				
func _process(_delta: float) -> void:
	if not inventory_open:
		_cam_active = false
		return

	_cam_active = Input.is_action_pressed('Inventory Camera')

	if Input.is_action_just_pressed('Select'):
		if _curr_hover != null:
			_curr_drag = _curr_hover
			_curr_drag.set_mouse_areas(false)

			update_recycle_text(_curr_drag)
	elif Input.is_action_just_released('Select'):
		if _curr_drag != null:
			if _curr_connector != null:
				add_module_to_connector(_curr_drag, _curr_connector, _curr_connector_module)
			else:
				remove_module_from_connector(_curr_drag)

			_curr_drag.set_mouse_areas(true)
			_curr_hover = _curr_drag
			_curr_drag = null
			update_recycle_text(null)
	
	if _curr_drag != null:
		if _curr_connector != null:
			_curr_drag.global_position = _curr_connector.global_position
			_curr_drag.global_basis.z = _curr_connector.global_basis.z
		else:
			var pos = get_mouse_ray()
			if pos != Vector3.ZERO: 
				_curr_drag.global_position = pos
				_curr_drag.basis.z = Vector3.FORWARD

	if Input.is_action_just_pressed('Interact'):
		if _curr_recycle != null:
			PlayerStats.Bolts += _curr_recycle.get_module_value()

			if _curr_recycle.PreviousModule != null:
				remove_module_from_connector(_curr_recycle)
			Inventory.erase(_curr_recycle)

			_curr_recycle.queue_free()
			_curr_recycle = null


func _on_module_hovered(module:GunModule, hovered:bool):
	if hovered:
		if _curr_hover != null and _curr_hover.PreviousModule == null:
			_curr_hover.set_arrows(false)
		_curr_hover = module
		_curr_hover.set_arrows(true)

		if _curr_drag == null: update_recycle_text(_curr_hover)
	elif _curr_hover == module:
		if _curr_hover.PreviousModule == null:
			_curr_hover.set_arrows(false)
		else:
			_curr_hover.set_arrows(true, true)
		_curr_hover = null

		if _curr_drag == null: update_recycle_text(null)

func _on_module_connector_hovered(module:GunModule, connector:Area3D, hovered:bool):
	if hovered: 
		_curr_hover = module
		_curr_connector = connector
		_curr_connector_module = module

		if _curr_drag == null: update_recycle_text(_curr_hover)
	else:
		if _curr_hover == module: 
			_curr_hover = null

			if _curr_drag == null: update_recycle_text(null)
		if _curr_connector == connector:
			_curr_connector = null
			_curr_connector_module = null


func add_module_to_connector(module:GunModule, connector:Area3D, connector_module:GunModule):
	if module.PreviousModule == null:
		module.connector_hover_changed.connect(_on_module_connector_hovered)
	
	if super(module, connector, connector_module):
		Inventory.erase(module)

		connector_module.set_arrows(true, true)
		module.set_arrows(true, true)

		BaseAmmo += module.AmmoMod
		ShotRate *= module.FireRateMod
		_update_ammo()
		
func remove_module_from_connector(module:GunModule):
	var prev_module : GunModule = null
	if module.PreviousModule != null:
		module.connector_hover_changed.disconnect(_on_module_connector_hovered)
		Inventory.append(module)
		prev_module = module.PreviousModule
		
	module.get_parent().remove_child(module)
	_gun_pivot.add_child(module)
	module.basis.z = Vector3.FORWARD

	BaseAmmo -= module.AmmoMod
	ShotRate /= module.FireRateMod
	_update_ammo()

	super(module)

	if prev_module != null: prev_module.set_arrows(true, true)
		
func set_base_module(module:ClipModule):
	if CurrGun != null:
		CurrGun.connector_hover_changed.disconnect(_on_module_connector_hovered)
	
	super(module)
	remove_child(module) # Hacky but shrug

	CurrGun.connector_hover_changed.connect(_on_module_connector_hovered)
	_inventory_pivot.add_child(CurrGun)


func update_recycle_text(module:GunModule):
	if module == null or not module.CanRecycle:
		_curr_recycle = null
		_recycle_label.hide()
		return

	_curr_recycle = module
	_recycle_label.show()
	_recycle_label.text = 'Press E to recycle for {0} bolts'.format([module.get_module_value()])



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
