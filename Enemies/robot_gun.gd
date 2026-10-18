extends GunController

func _ready() -> void:
    super()

    remove_child(_reticle_raycast)
    Parent.add_child(_reticle_raycast)
    _reticle_raycast.position = Vector3.UP * (global_position - Parent.global_position).z