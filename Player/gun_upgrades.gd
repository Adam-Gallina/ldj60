extends GunInventory
class_name GunUpgrades
signal upgrades_complete()

@export_category('Rewards')
@onready var _upgrade_ui : Control = get_node('%UpgradeUI')

@onready var _reward_anim : AnimationPlayer = get_node('%RewardAnimationPlayer')
var _doubled = false
@onready var _upgrade_button : Button = get_node('%UpgradeButton')
@onready var _bolt_label : Label = get_node('%BoltsRewardLabel')
@onready var _module_label : Label = get_node('%ModuleRewardLabel')

@export var BoltReward : PackedScene
@export var ModuleReward : PackedScene
@export var BonusRewards : Array[PackedScene]
@export var BonusPrices : Array[PackedScene]

var _curr_left_reward:RewardBase
var _curr_right_reward:RewardBase

@export var ShopRewards : Array[PackedScene]
var _purchased_rewards = 0
@export var MinShopPrice = 2.
@export var MaxShopPrice = 5.
@export var PriceScaleMod = 1.2

var _curr_shop_options : Array[RewardBase] = [null, null, null]
var _curr_shop_prices : Array[int] = [0, 0, 0]
@onready var _shop_labels = [
	get_node('%OptionOneLabel'),
	get_node('%OptionTwoLabel'),
	get_node('%OptionThreeLabel'),
]
@onready var _shop_buttons = [
	get_node('%OptionOneButton'),
	get_node('%OptionTwoButton'),
	get_node('%OptionThreeButton'),
]
@export_category('')


func _ready() -> void:
	super()
	set_upgrade_ui(false)

func do_upgrades():
	toggle_inventory()
	_doubled = false

	await anim.animation_finished

	set_upgrade_ui(true)

	_curr_left_reward = BoltReward.instantiate()
	add_child(_curr_left_reward)
	_curr_right_reward = ModuleReward.instantiate()
	add_child(_curr_right_reward)
	
	_round_end_anim()


func set_upgrade_ui(display:bool):
	_upgrade_ui.visible = display


func _round_end_anim():
	_bolt_label.text = _curr_left_reward.get_description()

	_module_label.text = _curr_right_reward.get_description()

	_reward_anim.play('DropAll')

func _on_double_pressed():
	_doubled = true
	_reward_anim.play('ReturnDouble')

func _on_collect_pressed():
	_reward_anim.play('ReturnRewards' if _doubled else 'ReturnAll')

	_curr_left_reward.collect()
	_curr_right_reward.collect()

	_refresh_shop()


func _refresh_shop():
	print(_shop_buttons)
	print(_shop_labels)
	for i in range(_curr_shop_options.size()):
		if _curr_shop_options[i] != null:
			_curr_shop_options[i].queue_free()
		
		var new_option = ShopRewards.pick_random().instantiate()
		add_child(new_option)
		print(new_option)
		_curr_shop_options[i] = new_option
		_curr_shop_prices[i] = int(randf_range(MinShopPrice, MaxShopPrice) * pow(PriceScaleMod, _purchased_rewards))
		
		_shop_labels[i].text = _curr_shop_options[i].get_description()
		_shop_buttons[i].text = '{0} Bolts'.format([_curr_shop_prices[i]])
		_shop_buttons[i].disabled = PlayerStats.Bolts < _curr_shop_prices[i]


func _on_next_round_pressed():
	set_upgrade_ui(false)
	toggle_inventory()
	upgrades_complete.emit()

func _on_upgrade_pressed() -> void:
	if _upgrade_button.text == 'Upgrade':
		_reward_anim.play('DropUpgrades')
		_upgrade_button.text = 'Close'
	else:
		_reward_anim.play('ReturnUpgrades')
		_upgrade_button.text = 'Upgrade'


func _on_buy_pressed(option: int) -> void:
	_curr_shop_options[option].collect()
	PlayerStats.Bolts -= _curr_shop_prices[option]

	_refresh_shop()
