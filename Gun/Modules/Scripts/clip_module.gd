extends GunModule
class_name ClipModule

@export var BulletScene : PackedScene

func process_bullet(stats: BulletBase.BulletStats = null):
	stats = BulletBase.BulletStats.new(BulletSpeedMod, BulletDamageMod, BulletScene)

	super(stats)
