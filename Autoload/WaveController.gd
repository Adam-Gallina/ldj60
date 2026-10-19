extends Node
class_name WaveContoller

signal wave_started(wave_num:int)
signal fast_spawn()

var CurrWave = 0

var LivingBots : Array[BotController] = []
var RemainingBots = 0

var BaseBotCount = 6

var TotalBotsModifier = 1.
var SpawnRateModifier = 1.
var SpawnHealthModifier = 1.
var SpawnDamageModifier = 1.
var SpawnAttackSpeedModifier = 1.

func restart_waves():
    CurrWave = 0
    TotalBotsModifier = 1.
    SpawnRateModifier = 1.
    SpawnHealthModifier = 1.
    SpawnDamageModifier = 1.
    SpawnAttackSpeedModifier = 1.

    RemainingBots = BaseBotCount

    wave_started.emit(CurrWave)

func next_wave():
    CurrWave += 1

    TotalBotsModifier *= 1.2
    SpawnRateModifier *= .85
    SpawnHealthModifier *= 1.1
    SpawnAttackSpeedModifier *= 1.1

    RemainingBots = BaseBotCount * TotalBotsModifier
    
    wave_started.emit(CurrWave)


func get_bot() -> BotController:
    if RemainingBots <= 0: return null
    RemainingBots -= 1

    var bot = BotBuilder.get_bot()
    bot.destroyed.connect(_on_bot_destroyed)
    LivingBots.append(bot)

    return bot


func _on_bot_destroyed(bot:BotController):
    LivingBots.erase(bot)

    if LivingBots.size() == 0:
        if RemainingBots <= 0:
            next_wave()
        else:
            fast_spawn.emit()
