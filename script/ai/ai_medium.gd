class_name AIMedium
extends AIBase

func randomize_personality():
	aggro = 0.35 + randf() * 0.3
	looseness = 0.35 + randf() * 0.3
	bluff = 0.08 + randf() * 0.1

func get_betting_action(hand: Array, community: Array, pot: int,
	player_bet: int, current_bet: int, player_chips: int,
	turn_count: int, max_bets: int) -> Dictionary:

	var call_amt = max(0, current_bet - player_bet)
	var strength = _eval_strength(hand, community)
	var pot_for_bet = pot + player_bet
	var max_bet =  min(max_bets, player_chips)
	var can_raise = turn_count < 4

	var raise_thresh = 0.7 - aggro * 0.3
	var semi_thresh = 0.4 - aggro * 0.25

	if can_raise and (strength > raise_thresh or (strength > semi_thresh and randf() > 0.45)):
		var amt = min(max_bet, max(call_amt, int(max_bet * (0.2 + randf() * 0.2))))
		amt = max(1, int(amt))
		amt = min(amt, player_chips)
		amt = min(amt, 100 - player_bet)
		return {"action": "raise", "amount": amt}
	elif can_raise and strength < 0.35 and randf() > 1.0 - bluff:
		var amt = max(1, int(max_bet * (0.15 + randf() * 0.15)))
		amt = min(amt, player_chips)
		amt = min(amt, 100 - player_bet)
		return {"action": "raise", "amount": amt}
	elif strength > 0.2 - looseness * 0.15 or randf() > 0.3:
		return {"action": "call", "amount": call_amt}
	else:
		return {"action": "fold", "amount": 0}

func get_steal_choice(own_hand: Array, target_hand: Array) -> int:
	if target_hand.is_empty():
		return -1

	var own_ranks = {}
	var own_suits = {}
	for c in own_hand:
		own_ranks[c.rank] = own_ranks.get(c.rank, 0) + 1
		own_suits[c.suit] = own_suits.get(c.suit, 0) + 1

	var best = 0
	var best_score = -999
	for i in range(target_hand.size()):
		var c = target_hand[i]
		var score = 0

		if own_ranks.has(c.rank):
			var count = own_ranks[c.rank]
			if count == 1: score += 8
			elif count == 2: score += 12

		var suit_count = own_suits.get(c.suit, 0)
		if suit_count >= 3: score += 5
		elif suit_count >= 2: score += 2

		score += c.rank

		for r in own_ranks.keys():
			if abs(r - c.rank) == 1:
				score += 3
				break

		if score > best_score:
			best_score = score
			best = i

	return best

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
	var strength = 0.1

	var high_card_bonus = 0.0
	if ranks.size() > 0:
		high_card_bonus = (ranks[0] - 2) / 14.0 * 0.1

	if quads > 0: strength = 0.95
	elif trips > 0 and pairs > 0: strength = 0.9
	elif has_flush: strength = 0.85
	elif has_straight: strength = 0.75
	elif trips > 0: strength = 0.65 + high_card_bonus
	elif pairs >= 2: strength = 0.45 + high_card_bonus
	elif pairs == 1: strength = 0.3 + high_card_bonus
	else: strength = 0.1 + high_card_bonus

	return strength

func _check_straight(ranks: Array) -> bool:
	var unique = []
	for r in ranks:
		if !unique.has(r):
			unique.append(r)
	unique.sort()
	unique.reverse()

	if unique.size() < 5:
		return false

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
