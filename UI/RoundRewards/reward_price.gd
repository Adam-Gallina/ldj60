extends RewardBase

@export var Modules : Array[PackedScene]

var _module : GunModule

func _ready() -> void:
    _module = Modules.pick_random().instantiate()

func collect():
    Constants.Player.Gun.add_to_inventory(_module)
