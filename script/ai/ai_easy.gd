class_name AIEasy
extends AIBase

var under_this_folds := .31
var community_local = []

func randomize_personality():
	aggro = 0.2 + randf() * 0.2
	looseness = 0.25 + randf() * 0.25
	bluff = 0.05 + randf() * 0.07

func get_betting_action(hand: Array, community: Array, pot: int,
	player_bet: int, current_bet: int, player_chips: int,
	turn_count: int, max_bets: int) -> Dictionary:

	var call_amt = max(0, current_bet - player_bet)
	var strength = _eval_strength(hand, community)
	print(strength)
	community_local = community
	var pot_for_bet = pot + player_bet
	var max_bet = min(max_bets, player_chips)
	var can_raise = turn_count < 4
	
	var raise_thresh = 0.75 - aggro * 0.3
	var semi_thresh = 0.5 - aggro * 0.25
	var call_thresh = 0.25 - looseness * 0.15

	if can_raise and (strength > raise_thresh or (strength > semi_thresh and randf() > 0.5)):
		#var amt = min(max_bet, call_amt + 1)
		#amt = max(1, int(amt))
		#amt = min(amt, player_chips)
		#amt = min(amt, 100 - player_bet)
		var amt = mini( (randi()% 20 ) + 1, player_chips)
		return {"action": "raise", "amount": amt}
	if can_raise and strength < 0.3 and randf() > 1.0 - bluff:
		return {"action": "raise", "amount": call_amt + 1}
	if strength > call_thresh:
		return {"action": "call", "amount": call_amt}
	elif call_amt == 0:
		return {"action": "call", "amount": 0}
	elif randf() < under_this_folds:
		return {"action": "fold", "amount": 0}
	else:
		return {"action": "call", "amount": call_amt}

func get_steal_choice(own_hand: Array, target_hand: Array) -> int:
	if target_hand.is_empty():
		return -1
	return randi() % target_hand.size()

func get_discard_indices(hand: Array) -> Array[int]:
	if hand.is_empty():
		return []
	if _eval_strength(hand, community_local) > .3:
		return [0,1,2,3] #dump good hand
	return [randi() % hand.size()]

func _eval_strength(hand: Array, community: Array) -> float:
	var all_cards = hand + community
	if all_cards.size() < 5:
		return 0.3

	var suits = {}
	var ranks = []
	for c in all_cards:
		suits[c.suit] = suits.get(c.suit, 0) + 1
		ranks.append(c.rank)
	ranks.sort()
	ranks.reverse()

	var has_flush = false
	for s in suits.values():
		if s >= 5:
			has_flush = true
			break

	var rank_counts = {}
	for r in ranks:
		rank_counts[r] = rank_counts.get(r, 0) + 1

	var pairs = 0
	var trips = 0
	var quads = 0
	for c in rank_counts.values():
		if c == 4: quads += 1
		elif c == 3: trips += 1
		elif c == 2: pairs += 1

	var strength = 0.1
	if quads > 0: strength = 0.95
	elif trips > 0 and pairs > 0: strength = 0.9
	elif has_flush: strength = 0.85
	elif trips > 0: strength = 0.7
	elif pairs >= 2: strength = 0.5
	elif pairs == 1: strength = 0.3

	return strength
