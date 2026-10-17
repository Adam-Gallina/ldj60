extends Node3D
class_name GunModule
signal hover_changed(module:GunModule, hovered:bool)
signal connector_hover_changed(module:GunModule, connector:Area3D, hovered:bool)

@export var ModuleWidth : int = 1
@export var ModuleHeight : int = 1

@export var NextModules : Array[GunModule] = []
@export var Connectors : Array[Area3D] = []
var PreviousModule : GunModule

func get_next_module(connector:Area3D) -> GunModule:
	if not connector in Connectors:
		printerr('Trying to lookup module with invalid connector ', connector)
		return null
		
	return NextModules[Connectors.find(connector)]

func set_next_module(module:GunModule, connector:Area3D) -> bool:
	if not connector in Connectors:
		printerr(name, ': Trying to add ', module.name, ' to invalid connector ', connector)
		return false

	module.get_parent().remove_child(module)
	get_parent().add_child(module)
	module.global_position = connector.global_position
	module.global_basis.z = connector.global_basis.z
	
	NextModules[Connectors.find(connector)] = module
	module.PreviousModule = self
	return true

func remove_next_module(module:GunModule) -> bool:
	if not module in NextModules: return false

	NextModules[NextModules.find(module)] = null
	module.PreviousModule = null

	return true

@onready var _mouse_area = $Area3D

@export var BulletSpeedMod = 0.
@export var BulletDamageMod = 0.

var _controller : GunController

func set_controller(controller: GunController): _controller = controller

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



func process_bullet(bullet:BulletBase):
	if (BulletSpeedMod != 0):
		bullet.set_speed(bullet.get_speed() + BulletSpeedMod)
	if (BulletDamageMod != 0):
		bullet.set_damage(bullet.get_damage() + BulletDamageMod)


	for i in range(NextModules.size()):
		# TODO: this will explode with multiple outputs
		if NextModules[i] == null:
			_controller.get_bullet_parent().add_child(bullet)
			bullet.launch(Connectors[i].global_position, -Connectors[i].global_basis.z)
		else:
			NextModules[i].process_bullet(bullet)


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
