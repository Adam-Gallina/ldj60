extends Node

@export var BotBase : PackedScene

@export var Torsos : Array[PackedScene]
@export var Heads : Array[PackedScene]
@export var UpperArms : Array[PackedScene]
@export var Forearms : Array[PackedScene]
@export var Thighs : Array[PackedScene]
@export var Calves : Array[PackedScene]


func get_bot() -> BotController:
	var bot : BotController = BotBase.instantiate()
	var pivots : BotPivots = BotPivots.new(bot)

	add_child(bot)

	var torso = get_torso(bot)
	pivots.waist.add_child(torso)
	pivots.neck.global_position = torso.NeckPivot.global_position
	pivots.lshoulder.global_position = torso.LArmPivot.global_position
	pivots.rshoulder.global_position = torso.RArmPivot.global_position
	pivots.lthigh.global_position = torso.LLegPivot.global_position
	pivots.rthigh.global_position = torso.RLegPivot.global_position

	var head = get_head(bot)
	pivots.neck.add_child(head)

	var larm = get_upper_arm(bot)
	pivots.lshoulder.add_child(larm)
	pivots.lelbow.global_position = larm.ElbowPivot.global_position

	var lforearm = get_forearm(bot)
	pivots.lelbow.add_child(lforearm)
	pivots.lwrist.global_position = lforearm.WristPivot.global_position

	var rarm = get_upper_arm(bot, true)
	pivots.rshoulder.add_child(rarm)
	pivots.relbow.global_position = rarm.ElbowPivot.global_position

	var rforearm = get_forearm(bot)
	pivots.relbow.add_child(rforearm)
	pivots.rwrist.global_position = rforearm.WristPivot.global_position

	var lleg = get_thigh(bot)
	pivots.lthigh.add_child(lleg)
	pivots.lknee.global_position = lleg.WristPivot.global_position

	var lcalf = get_calf(bot)
	pivots.lknee.add_child(lcalf)
	pivots.lankle.global_position = lcalf.WristPivot.global_position

	var rleg = get_thigh(bot)
	pivots.rthigh.add_child(rleg)
	pivots.rknee.global_position = rleg.WristPivot.global_position

	var rcalf = get_calf(bot)
	pivots.rknee.add_child(rcalf)
	pivots.rankle.global_position = rcalf.WristPivot.global_position

	bot.Torso = torso
	torso.ChildModules = [head, larm, rarm, lleg, rleg] as Array[BotModuleBase]
	larm.ChildModules = [lforearm] as Array[BotModuleBase]
	rarm.ChildModules = [rforearm] as Array[BotModuleBase]
	lleg.ChildModules = [lcalf] as Array[BotModuleBase]
	rleg.ChildModules = [rcalf] as Array[BotModuleBase]

	remove_child(bot)

	return bot


func get_torso(bot:BotController) -> BotTorso:
	var limb = Torsos.pick_random().instantiate()

	if not limb is BotTorso:
		printerr(limb, ' is not BotTorso (', typeof(limb), ')')
		return get_torso(bot)

	limb.Controller = bot
	return limb
	
func get_head(bot:BotController) -> BotForearm:
	var limb = Heads.pick_random().instantiate()

	if not limb is BotForearm:
		printerr(limb, ' is not BotForearm/Head (', typeof(limb), ')')
		limb.queue_free()
		return get_head(bot)

	limb.Controller = bot
	return limb

func get_upper_arm(bot:BotController, r=false) -> BotArm:
	var limb = UpperArms.pick_random().instantiate()

	if not limb is BotArm:
		printerr(limb, ' is not BotArm (', typeof(limb), ')')
		return get_upper_arm(bot)

	if r:
		limb.rotation.y = PI

	limb.Controller = bot
	return limb
	
func get_forearm(bot:BotController) -> BotForearm:
	var limb = Forearms.pick_random().instantiate()

	if not limb is BotForearm:
		printerr(limb, ' is not BotForearm (', typeof(limb), ')')
		limb.queue_free()
		return get_forearm(bot)

	limb.Controller = bot
	return limb

func get_thigh(bot:BotController, r=false) -> BotForearm:
	var limb = Thighs.pick_random().instantiate()

	if not limb is BotForearm:
		printerr(limb, ' is not BotForearm/Thigh (', typeof(limb), ')')
		limb.queue_free()
		return get_thigh(bot)

	if r:
		limb.rotation.y = 180

	limb.Controller = bot
	return limb
	
func get_calf(bot:BotController) -> BotForearm:
	var limb = Calves.pick_random().instantiate()

	if not limb is BotForearm:
		printerr(limb, ' is not BotForearm/Calf (', typeof(limb), ')')
		limb.queue_free()
		return get_calf(bot)

	limb.Controller = bot
	return limb


class BotPivots:
	var waist : Node3D
	var neck : Node3D
	var lshoulder : Node3D
	var lelbow : Node3D
	var lwrist : Node3D
	var rshoulder : Node3D
	var relbow : Node3D
	var rwrist : Node3D
	var lthigh : Node3D
	var lknee : Node3D
	var lankle : Node3D
	var rthigh : Node3D
	var rknee : Node3D
	var rankle : Node3D

	func _init(bot:BotController) -> void:
		waist = bot.get_node('%WaistPivot')
		neck = bot.get_node('%NeckPivot')
		lshoulder = bot.get_node('%LShoulderPivot')
		lelbow = bot.get_node('%LElbowPivot')
		lwrist = bot.get_node('%LWristPivot')
		rshoulder = bot.get_node('%RShoulderPivot')
		relbow = bot.get_node('%RElbowPivot')
		rwrist = bot.get_node('%RWristPivot')
		lthigh = bot.get_node('%LHipPivot')
		lknee = bot.get_node('%LKneePivot')
		lankle = bot.get_node('%LAnklePivot')
		rthigh = bot.get_node('%RHipPivot')
		rknee = bot.get_node('%RKneePivot')
		rankle = bot.get_node('%RAnklePivot')
