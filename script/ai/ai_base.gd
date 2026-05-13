class_name AIBase
extends Node

var aggro: float = 0.5
var looseness: float = 0.5
var bluff: float = 0.1

func randomize_personality():
	pass

func get_betting_action(hand: Array, community: Array, pot: int,
	player_bet: int, current_bet: int, player_chips: int,
	turn_count: int, max_bet_percent: float) -> Dictionary:
	return {"action": "call", "amount": 0}

func get_discard_indices(hand: Array) -> Array[int]:
	return []

func get_steal_choice(own_hand: Array, target_hand: Array) -> int:
	return -1

func new_round():
	pass

func set_current_player(_idx: int):
	pass
