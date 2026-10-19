extends RewardBase

@export var BaseBoltsMin = 5
@export var BaseBoltsMax = 8
@export var BoltsMod = 2

var _reward_bolts : int

func _ready() -> void:
    _reward_bolts = randi_range(BaseBoltsMin, BaseBoltsMax) 
    _reward_bolts += BoltsMod * Constants.WaveContoller.CurrWave

    
func get_description() -> String:
    return RewardDescription.format([_reward_bolts])

func collect():
    PlayerStats.Bolts += _reward_bolts