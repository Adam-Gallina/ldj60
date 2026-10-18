extends Node3D
class_name GunModule
signal hover_changed(module:GunModule, hovered:bool)
signal connector_hover_changed(module:GunModule, connector:Area3D, hovered:bool)

@export var ModuleWidth : int = 1
@export var ModuleHeight : int = 1

@export var NextModules : Array[GunModule] = []
@export var Connectors : Array[Area3D] = []
var PreviousModule : GunModule

@export var InputArrow : Node3D

func get_next_module(connector:Area3D) -> GunModule:
	if not connector in Connectors:
		printerr('Trying to lookup module with invalid connector ', connector)
		return null
		
	return NextModules[Connectors.find(connector)]

func set_next_module(module:GunModule, connector:Area3D) -> bool:
	if not connector in Connectors:
		printerr(name, ': Trying to add ', module.name, ' to invalid connector ', connector)
		return false

	if module.get_parent() != null:
		module.get_parent().remove_child(module)
	get_parent().add_child(module)
	module.global_position = connector.global_position
	module.global_basis.z = connector.global_basis.z
	
	var i = Connectors.find(connector)
	NextModules[i] = module
	module.PreviousModule = self

	return true

func remove_next_module(module:GunModule) -> bool:
	if not module in NextModules: return false

	var i = NextModules.find(module)
	NextModules[i] = null
	module.PreviousModule = null

	return true

@onready var _mouse_area = $Area3D

@export var BulletSpeedMod = 0.
@export var BulletDamageMod = 0.

var _controller : GunController

func set_controller(controller: GunController): 
	_controller = controller
	$Area3D.monitorable = false

func _ready() -> void:
	_mouse_area.mouse_entered.connect(_on_mouse_entered)
	_mouse_area.mouse_exited.connect(_on_mouse_exited)

	for n in NextModules:
		n.PreviousModule = self

	if Connectors.size() == 0: printerr('No connectors on Module ', name)

	for c in Connectors:
		NextModules.append(null)
		c.mouse_entered.connect(_on_mouse_entered_connector.bind(c))
		c.mouse_exited.connect(_on_mouse_exited_connector.bind(c))

	set_arrows(false)


func process_bullet(stats:BulletBase.BulletStats):
	if BulletSpeedMod != 0:
		stats.speed = stats.speed + BulletSpeedMod
	if BulletDamageMod != 0:
		stats.damage = stats.damage + BulletDamageMod


	for i in range(NextModules.size()):
		if NextModules[i] == null:
			launch_bullet(i, stats)
		else:
			NextModules[i].process_bullet(stats)

func launch_bullet(i:int, stats:BulletBase.BulletStats):
	var bullet : BulletBase = stats.scene.instantiate()
	_controller.get_bullet_parent().add_child(bullet)
	var pos = Connectors[i].global_position

	if _controller.Parent is CharacterBody3D:
		pos += _controller.Parent.velocity * get_physics_process_delta_time()

	# Need to normalize z as gun is scaled down
	var dir = _controller.get_bullet_adjustment(pos, -Connectors[i].global_basis.z.normalized())

	bullet.launch(pos, dir, stats)
	_controller.play_gunshot()

	var flash_effect : CPUParticles3D = Connectors[i].get_node('MuzzleFlashEffect')
	if flash_effect != null:
		flash_effect.emitting = true


func set_mouse_areas(active:bool):
	_mouse_area.monitoring = active
	_mouse_area.monitorable = active
	_mouse_area.input_ray_pickable = active

	for c in Connectors:
		c.monitoring = active
		c.monitorable = active
		c.input_ray_pickable = active


func _on_mouse_entered() -> void:
	hover_changed.emit(self, true)

func _on_mouse_exited() -> void:
	hover_changed.emit(self, false)

func _on_mouse_entered_connector(connector: Area3D) -> void:
	connector_hover_changed.emit(self, connector, true)

func _on_mouse_exited_connector(connector: Area3D) -> void:
	connector_hover_changed.emit(self, connector, false)


func set_arrows(display:bool, unconnected_only=false):
	for i in range(Connectors.size()):
		var arrow : Node3D = Connectors[i].get_node('Arrow')

		if unconnected_only:
			arrow.visible = display && NextModules[i] == null
		else:
			arrow.visible = display

	if InputArrow != null:
		if unconnected_only:
			$Arrow.visible = display && PreviousModule == null
		else:
			$Arrow.visible = display
