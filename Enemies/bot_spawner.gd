extends StaticBody3D
class_name BotSpawner

@export var SpawnPos : Node3D

@export var BaseSpawnRate : float = 15.
var _curr_spawn_rate : float = 0
var _next_spawn : float = 0.

@export var MinWaveSpawn = 0
var _spawning = false

func _ready() -> void:
	WaveController.wave_started.connect(_on_wave_started)
	WaveController.fast_spawn.connect(_on_fast_spawn)


func _process(delta: float) -> void:
	if not _spawning: return

	_next_spawn -= delta
	if _next_spawn <= 0:
		_next_spawn = _curr_spawn_rate

		var bot = WaveController.get_bot()
		if bot != null:
			get_parent().add_child(bot)
			bot.global_position = SpawnPos.global_position
			bot.look_at((SpawnPos.global_position - global_position) * 2)


func _on_wave_started(_wave:int):
	if _wave >= MinWaveSpawn: _spawning = true
	else: return

	_curr_spawn_rate = BaseSpawnRate * WaveController.SpawnRateModifier
	_next_spawn = _curr_spawn_rate * randf()

func _on_fast_spawn():
	_next_spawn /= 2
