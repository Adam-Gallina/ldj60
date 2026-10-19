extends Node
class_name RewardBase

@export var RewardDescription : String = 'Reward!'

func get_description() -> String:
    return RewardDescription

func collect():
    pass