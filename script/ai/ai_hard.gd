class_name AIHard
extends AIBase

var _opponent_stats: Dictionary = {}
var _seen_ranks: Dictionary = {}
var _seen_suits: Dictionary = {}
var _current_player: int = -1

func new_round():
	_opponent_stats.clear()
	_seen_ranks.clear()
	_seen_suits.clear()

func set_current_player(idx: int):
	_current_player = idx

func randomize_personality():
	aggro = 0.5 + randf() * 0.3
	looseness = 0.35 + randf() * 0.25
	bluff = 0.1 + randf() * 0.1

func _track_opponent(player_idx: int, action: String):
	if !_opponent_stats.has(player_idx):
		_opponent_stats[player_idx] = {fold = 0, call = 0, raise = 0}
	_opponent_stats[player_idx][action] += 1

func _opponent_aggro(player_idx: int) -> float:
	var s = _opponent_stats.get(player_idx)
	if !s or (s.call + s.raise + s.fold) == 0:
		return 0.5
	return float(s.raise) / float(s.call + s.raise + s.fold)

func _count_outs(hand: Array, community: Array) -> int:
	var all_cards = hand + community
	var ranks = []
	var suits = {}
	for c in all_cards:
		ranks.append(c.rank)
		suits[c.suit] = suits.get(c.suit, 0) + 1

	var rank_counts = {}
	for r in ranks:
		rank_counts[r] = rank_counts.get(r, 0) + 1

	var outs = 0
	for r in rank_counts.keys():
		if rank_counts[r] == 1:
			var remaining = 4 - _seen_ranks.get(r, 0) - rank_counts[r]
			outs += remaining
		elif rank_counts[r] == 2:
			var remaining = 4 - _seen_ranks.get(r, 0) - rank_counts[r]
			outs += remaining * 2

	for s in suits.keys():
		if suits[s] >= 3:
			var remaining = 13 - _seen_suits.get(s, 0) - suits[s]
			if remaining > 0: outs += remaining

	return outs

func get_betting_action(hand: Array, community: Array, pot: int,
	player_bet: int, current_bet: int, player_chips: int,
	turn_count: int, max_bets: int) -> Dictionary:

	for c in hand + community:
		_seen_ranks[c.rank] = _seen_ranks.get(c.rank, 0) + 1
		_seen_suits[c.suit] = _seen_suits.get(c.suit, 0) + 1

	var call_amt = max(0, current_bet - player_bet)
	var strength = _eval_strength(hand, community)
	var pot_for_bet = pot + player_bet
	var max_bet = min(max_bets, player_chips)
	var can_raise = turn_count < 4

	var pot_odds = 0.0
	if call_amt > 0:
		pot_odds = float(call_amt) / float(pot + call_amt)

	var opp_aggro = _opponent_aggro(_current_player) if _current_player >= 0 else 0.5
	var outs = _count_outs(hand, community)
	var implied = strength + (float(outs) / 47.0) * 0.3

	var raise_thresh = 0.6 - aggro * 0.3
	var draw_thresh = 0.3 - aggro * 0.25
	var can_bluff = can_raise and strength < 0.35 and opp_aggro < 0.4 and randf() > 1.0 - bluff

	var effective = strength
	if pot_odds > 0:
		effective -= pot_odds * 0.5

	# 5% chance to max bluff regardless
	if can_raise and randf() < 0.05:
		var amt = min(max_bet, player_chips)
		amt = min(amt, 100 - player_bet)
		if _current_player >= 0: _track_opponent(_current_player, "raise")
		return {"action": "raise", "amount": amt}

	# Raise to max on very strong hands (denial + pressure)
	if can_raise and strength > 0.85:
		var amt = min(max_bet, player_chips)
		amt = min(amt, 100 - player_bet)
		if _current_player >= 0: _track_opponent(_current_player, "raise")
		return {"action": "raise", "amount": amt}

	# 25% bluff on medium strength if no bet to call (last round was a check)
	if can_raise and call_amt == 0 and strength >= 0.25 and strength <= 0.55 and randf() < 0.25:
		var bet_frac = 0.25 + strength * 0.3
		var amt = min(max_bet, max(call_amt, int(pot_for_bet * bet_frac)))
		amt = max(1, int(amt))
		amt = min(amt, player_chips)
		amt = min(amt, 100 - player_bet)
		if _current_player >= 0: _track_opponent(_current_player, "raise")
		return {"action": "raise", "amount": amt}

	if can_raise and ((strength > raise_thresh) or (strength > draw_thresh and outs > 4) or (strength > 0.3 and randf() > 0.3) or can_bluff):
		var bet_frac = 0.0
		if can_bluff:
			bet_frac = 0.25 + randf() * 0.2
		elif strength > 0.6:
			bet_frac = 0.35 + strength * 0.35
		else:
			bet_frac = 0.25 + strength * 0.3

		var amt = min(max_bet, max(call_amt, int(pot_for_bet * bet_frac)))
		amt = max(1, int(amt))
		amt = min(amt, player_chips)
		amt = min(amt, 100 - player_bet)
		if _current_player >= 0: _track_opponent(_current_player, "raise")
		return {"action": "raise", "amount": amt}
	elif effective > 0.05 - looseness * 0.08 or implied > pot_odds or (strength > 0.2 - looseness * 0.15 and pot_odds < 0.3):
		if _current_player >= 0: _track_opponent(_current_player, "call")
		return {"action": "call", "amount": call_amt}
	elif call_amt == 0:
		if _current_player >= 0: _track_opponent(_current_player, "call")
		return {"action": "call", "amount": 0}
	else:
		if _current_player >= 0: _track_opponent(_current_player, "fold")
		return {"action": "fold", "amount": 0}

func get_discard_indices(hand: Array) -> Array[int]:
	var rank_counts = {}
	var suit_counts = {}
	for c in hand:
		rank_counts[c.rank] = rank_counts.get(c.rank, 0) + 1
		suit_counts[c.suit] = suit_counts.get(c.suit, 0) + 1

	var to_discard: Array[int] = []
	for i in range(hand.size()):
		var c = hand[i]
		if rank_counts[c.rank] > 1:
			continue
		var flush_draw = suit_counts[c.suit] >= 3
		var straight_possible = _has_straight_draw(hand, c.rank)
		if !flush_draw and !straight_possible and c.rank < 12:
			to_discard.append(i)

	if to_discard.size() >= hand.size():
		to_discard.resize(hand.size() - 1)
	if to_discard.is_empty() and hand.size() > 0:
		to_discard = [hand.size() - 1]

	return to_discard

func get_steal_choice(own_hand: Array, target_hand: Array) -> int:
	if target_hand.is_empty():
		return -1

	var best = 0
	var best_score = -999
	var max_gain = 0

	for i in range(target_hand.size()):
		var test = own_hand.duplicate()
		test.append(target_hand[i])

		var gain = _score_hand_set(test) - _score_any_hand(own_hand)
		if gain > max_gain: max_gain = gain

		var deny = _score_denial(target_hand, i)
		var defense = _score_defense(test)

		var score = gain * 0.4 + deny * 0.3 + defense * 0.3
		if score > best_score:
			best_score = score
			best = i

	if max_gain <= 0:
		best_score = -999
		for i in range(target_hand.size()):
			var deny = _score_denial(target_hand, i)
			if deny > best_score:
				best_score = deny
				best = i

	return best

func _score_denial(hand: Array, take_idx: int) -> float:
	var remaining = []
	for i in range(hand.size()):
		if i != take_idx:
			remaining.append(hand[i])

	var before = _score_hand_set(hand)
	var after = _score_hand_set(remaining)
	return max(0, before - after)

func _score_any_hand(cards: Array) -> float:
	if cards.size() < 2:
		return 0.0

	var suits = {}
	var ranks = []
	for c in cards:
		suits[c.suit] = suits.get(c.suit, 0) + 1
		ranks.append(c.rank)

	var rank_counts = {}
	for r in ranks:
		rank_counts[r] = rank_counts.get(r, 0) + 1

	var pairs = 0; var trips = 0; var quads = 0
	for c in rank_counts.values():
		if c == 4: quads += 1
		elif c == 3: trips += 1
		elif c == 2: pairs += 1

	var max_suit = 0
	for s in suits.values():
		if s > max_suit: max_suit = s

	ranks.sort()
	ranks.reverse()

	var s = 0.0
	if quads > 0: s = 100
	elif trips > 0 and pairs > 0: s = 90
	elif trips > 0: s = 60
	elif pairs >= 2: s = 45
	elif pairs >= 1: s = 25
	else: s = ranks[0] if ranks.size() > 0 else 0

	if max_suit >= 4: s += 15
	elif max_suit >= 3: s += 5

	return s

func _score_defense(hand: Array) -> float:
	if hand.size() <= 1:
		return 0.0

	var worst = 999
	for i in range(hand.size()):
		var test = hand.duplicate()
		test.remove_at(i)
		var s = _score_any_hand(test)
		if s < worst: worst = s

	return worst

func _score_hand_set(cards: Array) -> float:
	if cards.size() < 5:
		return 0.0

	var suits = {}
	var ranks = []
	for c in cards:
		suits[c.suit] = suits.get(c.suit, 0) + 1
		ranks.append(c.rank)
	ranks.sort()
	ranks.reverse()

	var flush = false
	for s in suits.values():
		if s >= 5: flush = true; break

	var rank_counts = {}
	for r in ranks:
		rank_counts[r] = rank_counts.get(r, 0) + 1

	var pairs = 0; var trips = 0; var quads = 0
	for c in rank_counts.values():
		if c == 4: quads += 1
		elif c == 3: trips += 1
		elif c == 2: pairs += 1

	var straight = _check_straight(ranks)

	var s = 0.0
	if quads > 0: s = 100
	elif trips > 0 and pairs > 0: s = 90
	elif flush: s = 85
	elif straight: s = 80
	elif trips > 0: s = 60
	elif pairs >= 2: s = 45
	elif pairs == 1: s = 25
	else: s = ranks[0] if ranks.size() > 0 else 0

	return s

func _has_straight_draw(hand: Array, rank: int) -> bool:
	var ranks = []
	for c in hand:
		ranks.append(c.rank)
	ranks.append(rank)
	ranks.sort()
	var consecutive = 1
	for i in range(1, ranks.size()):
		if ranks[i] - ranks[i - 1] == 1:
			consecutive += 1
			if consecutive >= 3:
				return true
		elif ranks[i] - ranks[i - 1] > 1:
			consecutive = 1
	return false

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

	var has_straight = _check_straight(ranks)

	var kicker = 0.0
	if ranks.size() > 0:
		var top = ranks[0]
		kicker = (top - 2) / 14.0 * 0.12
		if pairs == 1 or trips > 0:
			for r in ranks:
				if rank_counts[r] == 1:
					kicker += (r - 2) / 14.0 * 0.04
					break

	var strength = 0.1
	if quads > 0: strength = 0.95 + kicker * 0.05
	elif trips > 0 and pairs > 0: strength = 0.9 + kicker * 0.05
	elif has_flush: strength = 0.82 + kicker * 0.08
	elif has_straight: strength = 0.72 + kicker * 0.08
	elif trips > 0: strength = 0.6 + kicker
	elif pairs >= 2: strength = 0.4 + kicker
	elif pairs == 1: strength = 0.25 + kicker
	else: strength = 0.1 + kicker

	return clamp(strength, 0.0, 0.99)

func _check_straight(ranks: Array) -> bool:
	var unique = []
	for r in ranks:
		if !unique.has(r):
			unique.append(r)
	unique.sort()
	unique.reverse()

	var wheel = [14, 2, 3, 4, 5]
	if unique.size() >= 5:
		var has_wheel = true
		for r in wheel:
			if !unique.has(r):
				has_wheel = false
				break
		if has_wheel:
			return true

	for i in range(unique.size() - 4):
		if unique[i] - unique[i + 4] == 4:
			return true

	return false
