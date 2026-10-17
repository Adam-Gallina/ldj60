extends GunModule
class_name ClipModule

@export var BulletScene : PackedScene

func process_bullet(bullet: BulletBase = null):
	bullet = BulletScene.instantiate()

	super(bullet)
