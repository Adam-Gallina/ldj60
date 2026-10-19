extends WaveContoller

@export var BotParent : Node3D

func _ready() -> void:
	Constants.WaveContoller = self
	Constants.Player = $Player
	$Label.hide()

	wave_started.connect(spawn_wave)
	#restart_waves()
	next_wave()

func next_wave():
	await get_tree().create_timer(.5).timeout
	Constants.Player.Gun.do_upgrades()
	Constants.Player.set_input(false, false)

	await Constants.Player.Gun.upgrades_complete

	var debris = get_tree().get_nodes_in_group('Debris')
	for i in range(debris.size(), 0, -1):
		debris[i-1].queue_free()

	Constants.Player.set_input(true, true)

	super()



func spawn_wave(_wave:int):
	while RemainingBots > 0:
		var bot = get_bot()
		BotParent.add_child(bot)
		bot.global_position = Vector3(
			randf_range(-15, 15),
			0,
			randf_range(-15, 15)
		)
		bot.spawn()

	await get_tree().create_timer(.5 + 1 + .5).timeout

	$Label.show()
	await get_tree().create_timer(.25).timeout
	$Label.position = Vector2i(396 + randi_range(-10, 10), 264 + randi_range(-10, 10))
	await get_tree().create_timer(.25).timeout
	$Label.position = Vector2i(396 + randi_range(-10, 10), 264 + randi_range(-10, 10))
	await get_tree().create_timer(.25).timeout
	$Label.position = Vector2i(396 + randi_range(-10, 10), 264 + randi_range(-10, 10))
	$Label.hide()
