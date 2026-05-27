extends Control

const NUM_PLAYERS = 4
const STARTING_CHIPS = 1000

const ANTE_PERCENT = 0.05
const MAX_BET = 100
const STEAL_TIMER = 22.0
const RELEASE_MODE := true
const CARD_GAP = -30
const PLAYER_POSITIONS = [
	Vector2(455, 555),
	Vector2(21, 280),
	Vector2(455, 40),
	Vector2(905, 280)
]

var discard_steal_rnds = [1]
var player_names: Array = ["You", "CPU 1", "CPU 2", "CPU 3"]
var player_chips: Array = []
var player_hands: Array = []
var player_folded: Array = []
var player_bets: Array = []
var player_is_human: Array = [true, false, false, false]
var player_ai: Array = [null, null, null, null]

var pot: int = 0
var community_cards: Array = []

var current_state: String = ""
var current_bet: int = 0
var call_amount: int = 0
var min_raise: int = 0
var max_raise: int = 0
var last_raiser: int = -1
var players_in_round: Array = []
var dealer_idx: int = 0
var action_prompt: String = ""

var discard_selected: Array = []
var steal_choice: int = -1

var deck: Array = []
var time_scale = .2
var sudden_death_round := 0

func _ready():
	randomize()
	$UIManager.build_ui()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		$StartMenu.visible = !$StartMenu.visible

func _reset_game():
	sudden_death_round = 0
	player_chips = []
	player_hands = []
	player_folded = []
	player_bets = []
	for i in range(NUM_PLAYERS):
		player_chips.append(STARTING_CHIPS)
		player_hands.append([])
		player_folded.append(false)
		player_bets.append(0)
	$UIManager.end_label.visible = false
	$UIManager.update_chip_labels()
	for i in range(NUM_PLAYERS):
		$ChipManager.setup_player_pile(i, player_chips[i])
	$ChipManager.clear_all()
	$ChipManager.update_pot(0)
	$UIManager.pot_label.text = "Pot: 0"
	$UIManager.announce("")

func start_game():
	sudden_death_round = 0
	player_chips = []
	player_hands = []
	player_folded = []
	player_bets = []
	for i in range(NUM_PLAYERS):
		player_chips.append(STARTING_CHIPS)
		player_hands.append([])
		player_folded.append(false)
		player_bets.append(0)
	$UIManager.update_chip_labels()
	for i in range(NUM_PLAYERS):
		$ChipManager.setup_player_pile(i, player_chips[i])
	if time_scale == null: time_scale = 1.0
	if RELEASE_MODE: await get_tree().create_timer(0.9 * time_scale).timeout
	play_round()

func _only_one_active() -> bool:
	var count = 0
	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			count += 1
	return count <= 1

func play_round():
	for i in range(NUM_PLAYERS):
		if player_ai[i]:
			player_ai[i].new_round()
	Globals.playing = true
	await clear_hands()
	await deal_phase()
	ante_phase()
	if _only_one_active():
		await showdown_phase()
		await round_end()
		return
	await betting_round()
	if _only_one_active():
		await showdown_phase()
		await round_end()
		return
	await flop_phase(1)
	await betting_round()
	if _only_one_active():
		await showdown_phase()
		await round_end()
		return

	for round in discard_steal_rnds:
		await discard_phase()
		await betting_round()
		if _only_one_active():
			await showdown_phase()
			await round_end()
			return
		await steal_phase()

	await flop_phase(2)
	await showdown_phase()
	await round_end()

func clear_hands():
	$UIManager.announce("New round...")
	for i in range(NUM_PLAYERS):
		player_hands[i] = []
		player_folded[i] = false
		player_bets[i] = 0
		$UIManager.clear_hand_display(i)
	pot = 0
	community_cards = []
	for node in $UIManager.community_nodes:
		node.visible = false
	$UIManager.pot_label.text = "Pot: 0"
	community_cards.clear()
	$UIManager.update_chip_labels()
	$ChipManager.clear_all()
	for i in range(NUM_PLAYERS):
		$ChipManager.setup_player_pile(i, player_chips[i])
	$SoundManager.play_card_shuffle()
	if RELEASE_MODE: await get_tree().create_timer(0.9 * time_scale).timeout
	%Dealer.visible = true

func ante_phase():
	$UIManager.announce("Ante phase...")
	for i in range(NUM_PLAYERS):
		if player_chips[i] < 20:
			player_folded[i] = true
			if player_is_human[i]: time_scale = 0.5
			$UIManager.player_panel[i].name_label.add_theme_color_override("font_color", Color.GRAY)
			$UIManager.update_hand_display(i)
			$SoundManager.play_card_shove()
			$ChipManager.update_player_pile(i, player_chips[i])
			$UIManager.announce("%s folds" % player_names[i])
		var ante = min(20, player_chips[i])
		player_chips[i] -= ante
		pot += ante
		$UIManager.player_panel[i].bet_label.text = "Ante: %d" % ante
		$ChipManager.add_pot_contribution(i, ante)
	$UIManager.pot_label.text = "Pot: %d" % pot
	$UIManager.update_chip_labels()
	for i in range(NUM_PLAYERS):
		$ChipManager.update_player_pile(i, player_chips[i])
	$ChipManager.update_pot(pot)
	$SoundManager.play_chips_stack()
	if RELEASE_MODE: await get_tree().create_timer(1.8 * time_scale).timeout

func build_deck():
	deck = []
	for suit in range(4):
		for rank in range(2, 15):
			deck.append({suit = suit, rank = rank})
	deck.shuffle()

func deal_phase():
	if Globals.sudden_death:
		$UIManager.announce("SUDDEN DEATH!", 60)
		if RELEASE_MODE: await get_tree().create_timer(1.5 * time_scale).timeout
	$UIManager.announce("Dealing...")
	build_deck()

	var center_pos = Vector2(441, 260)

	var targets = []
	for i in range(NUM_PLAYERS):
		var panel = $UIManager.player_panel[i].panel
		targets.append(panel.position + panel.size * 0.5)

	var anim_cards = []
	for i in range(NUM_PLAYERS * 5):
		var tr = $UIManager.make_card_back_sprite()
		tr.position = Vector2(4000, 4000)
		add_child(tr)
		anim_cards.append(tr)

	for i in range(NUM_PLAYERS):
		var container = $UIManager.player_panel[i].hand_container
		var nodes = []
		for j in range(5):
			var trb = $UIManager.make_card_back_sprite()
			trb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			trb.modulate = Color(1, 1, 1, 0)
			container.add_child(trb)
			nodes.append(trb)
		$UIManager.player_hand_nodes[i] = nodes

	for round in range(5):
		for i in range(NUM_PLAYERS):
			var card_data = deck.pop_back()
			player_hands[i].append(card_data)

			var tra = anim_cards[round * NUM_PLAYERS + i]
			tra.position = center_pos - Vector2(Globals.CARD_W * 0.5, Globals.CARD_H * 0.5)

			var tween = create_tween()
			tween.tween_property(tra, "position", targets[i] - Vector2(Globals.CARD_W * 0.5, Globals.CARD_H * 0.5), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

			$SoundManager.play_card_flip()
			await get_tree().create_timer(0.14 * time_scale).timeout

	for i in range(NUM_PLAYERS):
		var nodes = $UIManager.player_hand_nodes[i]
		var hand = player_hands[i]
		if player_is_human[i]:
			for j in range(hand.size()):
				$UIManager.set_card_sprite(nodes[j], hand[j].suit, hand[j].rank)
		for node in nodes:
			node.modulate = Color(1, 1, 1, 1)

	$UIManager.announce("Cards dealt!")
	if RELEASE_MODE: await get_tree().create_timer(0.3 * time_scale).timeout

	for card in anim_cards:
		remove_child(card)
		card.queue_free()

func flop_phase(num_cards: int):
	if community_cards.size() < num_cards:
		var card = deck.pop_back()
		community_cards.append(card)
	var idx = community_cards.size() - 1
	var card_pos = Vector2(665 + idx * 89, 309) 
	$UIManager.set_community_card(idx, community_cards[idx].suit, community_cards[idx].rank, card_pos)
	$SoundManager.play_card_place()
	$UIManager.announce("Flop: %s" % Globals.card_name(community_cards[idx].suit, community_cards[idx].rank) if community_cards.size() > 0 else "")
	$UIManager.update_all_displays()
	if RELEASE_MODE: await get_tree().create_timer(2.1 * time_scale).timeout

func betting_round():
	$UIManager.announce("Betting round...")
	current_bet = 0
	call_amount = 0
	last_raiser = -1
	players_in_round = []
	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			players_in_round.append(i)

	if players_in_round.size() <= 1:
		return

	var acted = {}
	for p in players_in_round:
		acted[p] = false

	var idx = players_in_round[0]
	var round_over = false
	var turn_count = 0

	while !round_over:
		if player_folded[idx]:
			idx = (idx + 1) % NUM_PLAYERS
			continue
		if !players_in_round.has(idx):
			idx = (idx + 1) % NUM_PLAYERS
			continue

		var old_bet = current_bet

		if player_is_human[idx]:
			await human_betting_turn(idx, turn_count)
		else:
			await cpu_betting_turn(idx, turn_count)

		turn_count += 1

		if player_folded[idx]:
			players_in_round.erase(idx)
			acted.erase(idx)
			if players_in_round.size() <= 1:
				round_over = true
		else:
			acted[idx] = true
			if current_bet > old_bet:
				for p in players_in_round:
					if p != idx:
						acted[p] = false

		if !round_over:
			round_over = true
			for p in players_in_round:
				if !acted[p]:
					round_over = false
					break

		idx = (idx + 1) % NUM_PLAYERS

	$UIManager.pot_label.text = "Pot: %d" % pot
	$UIManager.announce("Betting round over")
	if RELEASE_MODE: await get_tree().create_timer(1.8 * time_scale).timeout

func human_betting_turn(player_idx: int, turn_count: int):
	$UIManager.announce("Your turn!")
	call_amount = current_bet - player_bets[player_idx]
	if call_amount < 0:
		call_amount = 0
	call_amount = mini(call_amount, player_chips[player_idx])
	var pot_for_bet = pot + player_bets[player_idx]
	max_raise = MAX_BET
	max_raise = min(max_raise, player_chips[player_idx])
	min_raise = max(1, call_amount)

	if call_amount == 0:
		$UIManager.checkcall_button.text = "Check"
	else:
		$UIManager.checkcall_button.text = "Call %d" % call_amount

	var can_raise = turn_count < 4

	$UIManager.fold_button.visible = true
	$UIManager.checkcall_button.visible = true

	var slider_min = 5
	var slider_max = 100
	var cannot_meet_call = call_amount > slider_max

	$UIManager.raise_button.visible = can_raise and !cannot_meet_call
	$UIManager.allin_button.visible = can_raise and !cannot_meet_call
	$UIManager.bet_amt_label.visible = can_raise
	$UIManager.bet_slider.visible = can_raise and !cannot_meet_call
	$UIManager.bet_value_label.visible = can_raise and !cannot_meet_call

	if can_raise:
		$UIManager.bet_slider.min_value = slider_min
		$UIManager.bet_slider.max_value = mini(slider_max, player_chips[player_idx])
		$UIManager.bet_slider.value = $UIManager.bet_slider.max_value / 2.0
		$UIManager.bet_value_label.text = str(int($UIManager.bet_slider.value))

	var action = await _wait_for_human_action()

	$UIManager.show_action_buttons(false)

	match action:
		"fold":
			if Globals.sudden_death:
				player_folded[player_idx] = true
				player_chips[player_idx] = 0
				$UIManager.player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
				$UIManager.update_hand_display(player_idx)
				$SoundManager.play_card_shove()
				$ChipManager.update_player_pile(player_idx, 0)
				$UIManager.announce("You're eliminated!", 45)
			else:
				player_folded[player_idx] = true
				$UIManager.player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
				$UIManager.update_hand_display(player_idx)
				$SoundManager.play_card_shove()
				$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
				$UIManager.announce("You folded")
				time_scale = 0.5
		"call":
			var amount = call_amount
			player_chips[player_idx] -= amount
			pot += amount
			player_bets[player_idx] += amount
			$UIManager.player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			$SoundManager.play_chip_lay()
			$ChipManager.add_pot_contribution(player_idx, amount)
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			$ChipManager.update_pot(pot)
			if call_amount == 0:
				$UIManager.announce("You checked")
			else:
				$UIManager.announce("You called")
		"raise":
			var raise_amount = int($UIManager.bet_slider.value)
			var total_bet = mini(raise_amount, player_chips[player_idx])
			if raise_amount > player_chips[player_idx]:
				$UIManager.announce("Not enough chips to raise")
				$UIManager.show_action_buttons(true)
				action = await _wait_for_human_action()
				$UIManager.show_action_buttons(false)
				match action:
					"fold":
						player_folded[player_idx] = true
						$UIManager.player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
						$UIManager.update_hand_display(player_idx)
						$SoundManager.play_card_shove()
						$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
						$UIManager.announce("You folded")
						time_scale = 0.5
					"call":
						var amt = call_amount
						player_chips[player_idx] -= amt
						pot += amt
						player_bets[player_idx] += amt
						$UIManager.player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
						$SoundManager.play_chip_lay()
						$ChipManager.add_pot_contribution(player_idx, amt)
						$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
						$ChipManager.update_pot(pot)
						if amt == 0: $UIManager.announce("You checked")
						else: $UIManager.announce("You called")
				$UIManager.update_chip_labels()
				$UIManager.pot_label.text = "Pot: %d" % pot
				if RELEASE_MODE: await get_tree().create_timer(0.9 * time_scale).timeout
				return
			player_chips[player_idx] -= total_bet
			pot += total_bet
			player_bets[player_idx] += total_bet
			current_bet = player_bets[player_idx]
			last_raiser = player_idx
			$UIManager.player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			$SoundManager.play_chips_collide()
			$ChipManager.add_pot_contribution(player_idx, total_bet)
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			$ChipManager.update_pot(pot)
			$UIManager.announce("You raised to %d" % player_bets[player_idx])

	$UIManager.update_chip_labels()
	$UIManager.pot_label.text = "Pot: %d" % pot
	if RELEASE_MODE: await get_tree().create_timer(0.9 * time_scale).timeout

func _make_click_handler(state: Dictionary, action: String) -> Callable:
	return func(): state.result = action

func _wait_for_human_action() -> String:
	var state = {result = ""}
	var buttons = [
		{btn = $UIManager.fold_button, action = "fold"},
		{btn = $UIManager.checkcall_button, action = "call"},
		{btn = $UIManager.raise_button, action = "raise"},
		{btn = $UIManager.allin_button, action = "allin"}
	]

	var connections = []
	for entry in buttons:
		var c = _make_click_handler(state, entry.action)
		entry.btn.pressed.connect(c)
		connections.append({btn = entry.btn, c = c})

	while state.result == "":
		await get_tree().process_frame

	for entry in connections:
		if entry.c.is_valid() and entry.btn.pressed.is_connected(entry.c):
			entry.btn.pressed.disconnect(entry.c)

	return state.result

func _on_difficulty_changed(value: float):
	var idx = int(value)
	var scripts = [
		preload("res://script/ai/ai_easy.gd"),
		preload("res://script/ai/ai_medium.gd"),
		preload("res://script/ai/ai_hard.gd")
	]
	for i in range(1, NUM_PLAYERS):
		if player_ai[i]:
			remove_child(player_ai[i])
			player_ai[i].queue_free()
		var ai = scripts[idx].new()
		ai.name = "AICPU%d" % i
		ai.randomize_personality()
		add_child.call_deferred(ai)
		player_ai[i] = ai
	var labels = ["Easy", "Medium", "Hard"]
	if $UIManager.difficulty_label:
		$UIManager.difficulty_label.text = labels[idx]

func cpu_betting_turn(player_idx: int, turn_count: int):
	$UIManager.announce_quiet("%s is thinking..." % player_names[player_idx])
	if RELEASE_MODE: await get_tree().create_timer(1.8 * time_scale).timeout

	player_ai[player_idx].set_current_player(player_idx)
	var decision = player_ai[player_idx].get_betting_action(
		player_hands[player_idx], community_cards, pot,
		player_bets[player_idx], current_bet, player_chips[player_idx],
		turn_count, MAX_BET
	)

	match decision.action:
		"raise":
			var raise_amt = clampi(decision.amount, 1, 130 - player_bets[player_idx])
			raise_amt = mini(raise_amt, player_chips[player_idx])
			var new_total = player_bets[player_idx] + raise_amt
			if new_total > current_bet:
				player_chips[player_idx] -= raise_amt
				pot += raise_amt
				player_bets[player_idx] = new_total
				current_bet = new_total
				last_raiser = player_idx
				$UIManager.player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
				$SoundManager.play_chips_collide()
				$ChipManager.add_pot_contribution(player_idx, raise_amt)
				$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
				$ChipManager.update_pot(pot)
				$UIManager.announce("%s raises to %d" % [player_names[player_idx], player_bets[player_idx]])
			else:
				var amount = mini(max(0, current_bet - player_bets[player_idx]), player_chips[player_idx])
				player_chips[player_idx] -= amount
				pot += amount
				player_bets[player_idx] += amount
				$UIManager.player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
				$SoundManager.play_chip_lay()
				$ChipManager.add_pot_contribution(player_idx, amount)
				$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
				$ChipManager.update_pot(pot)
				if amount == 0: $UIManager.announce("%s checks" % player_names[player_idx])
				else: $UIManager.announce("%s calls" % player_names[player_idx])
		"call":
			var amount = mini(decision.amount, player_chips[player_idx])
			player_chips[player_idx] -= amount
			pot += amount
			player_bets[player_idx] += amount
			$UIManager.player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			$SoundManager.play_chip_lay()
			$ChipManager.add_pot_contribution(player_idx, amount)
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			$ChipManager.update_pot(pot)
			if amount == 0: $UIManager.announce("%s checks" % player_names[player_idx])
			else: $UIManager.announce("%s calls" % player_names[player_idx])
		"fold":
			if Globals.sudden_death:
				var call_amt = mini(max(0, current_bet - player_bets[player_idx]), player_chips[player_idx])
				player_chips[player_idx] -= call_amt
				pot += call_amt
				player_bets[player_idx] += call_amt
				$UIManager.player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
				$SoundManager.play_chip_lay()
				$ChipManager.add_pot_contribution(player_idx, call_amt)
				$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
				$ChipManager.update_pot(pot)
				if call_amt == 0: $UIManager.announce("%s checks" % player_names[player_idx])
				else: $UIManager.announce("%s calls" % player_names[player_idx])
			else:
				player_folded[player_idx] = true
				$UIManager.player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
				$UIManager.update_hand_display(player_idx)
				$SoundManager.play_card_shove()
				$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
				$UIManager.announce("%s folds" % player_names[player_idx])

	$UIManager.update_chip_labels()
	$UIManager.pot_label.text = "Pot: %d" % pot
	if RELEASE_MODE: await get_tree().create_timer(0.6 * time_scale).timeout

func discard_phase():
	$UIManager.announce("Click on any cards you want to replace")

	var active_players = []
	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			active_players.append(i)

	for i in active_players:
		if player_is_human[i]:
			await human_discard(i)
		else:
			cpu_discard(i)

	$UIManager.announce("Draw phase")
	if RELEASE_MODE: await get_tree().create_timer(2.1 * time_scale).timeout

func human_discard(player_idx: int):
	$UIManager.announce("Click your cards to replace them!")

	var hand = player_hands[player_idx]
	var container = $UIManager.player_panel[player_idx].hand_container
	$UIManager.clear_hand_display(player_idx)

	discard_selected = []
	var card_nodes = []

	for i in range(hand.size()):
		var card = hand[i]
		var tr = $UIManager.make_card_sprite()
		$UIManager.set_card_sprite(tr, card.suit, card.rank)
		var card_idx = i
		tr.mouse_filter = Control.MOUSE_FILTER_STOP

		var click_handler = func():
			if discard_selected.has(card_idx):
				discard_selected.erase(card_idx)
				tr.modulate = Color.WHITE
			else:
				discard_selected.append(card_idx)
				tr.modulate = Color(1, 0.5, 0.5)

		tr.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				click_handler.call()
		)

		container.add_child(tr)
		card_nodes.append(tr)

	$UIManager.player_hand_nodes[player_idx] = card_nodes

	$UIManager.discard_button.visible = true
	$UIManager.discard_button.disabled = false

	$UIManager.discard_button.pressed.connect(_on_discard_pressed)

	await $UIManager.discard_button.pressed

	if $UIManager.discard_button.pressed.is_connected(_on_discard_pressed):
		$UIManager.discard_button.pressed.disconnect(_on_discard_pressed)

	var num_discard = discard_selected.size()
	discard_selected.sort()
	discard_selected.reverse()
	for idx in discard_selected:
		player_hands[player_idx].remove_at(idx)

	for _i in range(num_discard):
		if deck.size() > 0:
			player_hands[player_idx].append(deck.pop_back())

	await $UIManager.animate_new_cards(player_idx, num_discard)
	$UIManager.update_hand_display(player_idx)
	$SoundManager.play_card_slide()
	$UIManager.announce("Drew %d new cards" % num_discard)
	if RELEASE_MODE: await get_tree().create_timer(1.9 * time_scale).timeout

func _on_discard_pressed():
	$UIManager.discard_button.visible = false

func cpu_discard(player_idx: int):
	$UIManager.announce("%s is discarding..." % player_names[player_idx])
	if RELEASE_MODE: await get_tree().create_timer(0.8 * time_scale).timeout

	var to_discard = player_ai[player_idx].get_discard_indices(player_hands[player_idx])

	var num_discard = mini(to_discard.size(), player_hands[player_idx].size())
	if num_discard > 0:
		to_discard.sort()
		to_discard.reverse()
		var actual_discard = 0
		for i in range(num_discard):
			var idx = to_discard[i]
			if idx < player_hands[player_idx].size():
				player_hands[player_idx].remove_at(idx)
				actual_discard += 1

		for _i in range(actual_discard):
			if deck.size() > 0:
				player_hands[player_idx].append(deck.pop_back())

		await $UIManager.animate_new_cards(player_idx, actual_discard)
		$UIManager.update_hand_display(player_idx)
		$UIManager.announce("%s drew %d cards" % [player_names[player_idx], actual_discard])
	else:
		$UIManager.update_hand_display(player_idx)
		$UIManager.announce("%s kept all cards" % player_names[player_idx])

	if RELEASE_MODE: await get_tree().create_timer(0.9 * time_scale).timeout

func _find_steal_target(player_idx: int) -> int:
	for offset in range(1, NUM_PLAYERS):
		var left = (player_idx + offset) % NUM_PLAYERS
		if not player_folded[left]:
			return left
	return -1

func steal_phase():
	$UIManager.message_label.text = "STEAL PHASE!"
	$UIManager.stealtimer_label.visible = true

	for i in range(NUM_PLAYERS):
		$UIManager.update_hand_display(i, true)

	await get_tree().create_timer(0.8 * time_scale).timeout

	var steal_decisions = [-1, -1, -1, -1]
	var steal_targets = [-1, -1, -1, -1]
	var human_target = 3

	for i in range(NUM_PLAYERS):
		if player_folded[i]:
			continue
		var left_idx = _find_steal_target(i)
		if left_idx < 0:
			continue
		steal_targets[i] = left_idx
		if player_is_human[i]:
			human_target = left_idx
		else:
			steal_decisions[i] = cpu_choose_steal(i, left_idx)

	if !player_folded[0] and !player_folded[human_target]:
		steal_choice = -1
		await $UIManager.show_steal_ui(human_target)
		steal_decisions[0] = steal_choice

	var steal_info = []
	for i in range(NUM_PLAYERS):
		if steal_decisions[i] >= 0:
			var target = steal_targets[i]
			var card = player_hands[target][steal_decisions[i]]
			steal_info.append({stealer = i, suit = card.suit, rank = card.rank, target = target})

	for i in range(NUM_PLAYERS):
		if steal_decisions[i] >= 0:
			var target = steal_targets[i]
			var card = player_hands[target][steal_decisions[i]]
			player_hands[target].remove_at(steal_decisions[i])
			player_hands[i].append(card)

	$UIManager.stealtimer_label.visible = false
	$UIManager.steal_overlay.visible = false
	$UIManager.overlay_container.visible = false

	for i in range(NUM_PLAYERS):
		$UIManager.update_hand_display(i, true)

	for info in steal_info:
		var card_name = Globals.card_name(info.suit, info.rank)
		$UIManager.announce("%s stole %s from %s!" % [player_names[info.stealer], card_name, player_names[info.target]])
		if !player_is_human[info.stealer]:
			await get_tree().create_timer(3.0 * time_scale).timeout

	$UIManager.announce("Steals complete!")
	await get_tree().create_timer(0.8 * time_scale).timeout

func cpu_choose_steal(player_idx: int, target_idx: int) -> int:
	return player_ai[player_idx].get_steal_choice(player_hands[player_idx], player_hands[target_idx])

func showdown_phase():
	$UIManager.announce("Showdown!")
	if RELEASE_MODE: await get_tree().create_timer(1.8 * time_scale).timeout

	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			$UIManager.update_hand_display(i, true)

	var active_players = []
	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			active_players.append(i)

	if active_players.size() == 1:
		var winner = active_players[0]
		player_chips[winner] += pot
		$ChipManager.update_player_pile(winner, player_chips[winner])
		$ChipManager.update_pot(0)
		$UIManager.announce("%s wins (everyone folded)!" % player_names[winner], 45)
		if player_names[winner] == "You":
			$UIManager.announce("%s win (everyone folded)!" % player_names[winner], 45)
		else:
			$UIManager.announce("%s wins (everyone folded)!" % player_names[winner], 45)
		$SoundManager.play_win()
		return

	var results = []
	for i in active_players:
		var all_cards = player_hands[i] + community_cards
		var result = evaluate_best_hand(all_cards)
		results.append({player = i, result = result})
		$UIManager.announce("%s: %s" % [player_names[i], hand_result_name(result)])
		if RELEASE_MODE: await get_tree().create_timer(1.8 * time_scale).timeout

	results.sort_custom(func(a, b): return compare_hands(a.result, b.result) > 0)

	var best = results[0]
	var tied = [best]
	for i in range(1, results.size()):
		if compare_hands(results[i].result, best.result) == 0:
			tied.append(results[i])

	if tied.size() == 1:
		var winner_idx = tied[0].player
		var cap = player_bets[winner_idx] * active_players.size()
		var winnings = min(pot, cap)
		player_chips[winner_idx] += winnings
		$ChipManager.update_player_pile(winner_idx, player_chips[winner_idx])

		var excess = pot - winnings
		if excess > 0:
			var other_players = []
			for p in active_players:
				if p != winner_idx:
					other_players.append(p)

			var other_bets_total = 0
			for p in other_players:
				other_bets_total += player_bets[p]

			if other_bets_total > 0:
				var distributed = 0
				for i in range(other_players.size() - 1):
					var p = other_players[i]
					var refund = (excess * player_bets[p]) / other_bets_total
					player_chips[p] += refund
					$ChipManager.update_player_pile(p, player_chips[p])
					distributed += refund
				var last_p = other_players[other_players.size() - 1]
				player_chips[last_p] += excess - distributed
				$ChipManager.update_player_pile(last_p, player_chips[last_p])
			else:
				var equal_share = excess / other_players.size()
				var distributed = 0
				for i in range(other_players.size() - 1):
					var p = other_players[i]
					player_chips[p] += equal_share
					$ChipManager.update_player_pile(p, player_chips[p])
					distributed += equal_share
				var last_p = other_players[other_players.size() - 1]
				player_chips[last_p] += excess - distributed
				$ChipManager.update_player_pile(last_p, player_chips[last_p])
	else:
		var share = pot / tied.size()
		for t in tied:
			player_chips[t.player] += share
			$ChipManager.update_player_pile(t.player, player_chips[t.player])
	$ChipManager.update_pot(0)

	if best.player == 0:
		$UIManager.announce("%s win with %s!" % [player_names[best.player], hand_result_name(best.result)], 45)
		$SoundManager.play_win()
	else:
		$UIManager.announce("%s wins with %s!" % [player_names[best.player], hand_result_name(best.result)], 45)
		$SoundManager.play_win()
	$UIManager.update_chip_labels()

	if Globals.sudden_death and active_players.size() >= 2:
		var worst = results[-1].player
		player_chips[worst] = 0
		$ChipManager.update_player_pile(worst, 0)
		$SoundManager.play_card_shove()
		sudden_death_round += 1
		if player_names[worst] == "You":
			$UIManager.announce("You are eliminated!", 45)
		else:
			$UIManager.announce("%s is eliminated!" % player_names[worst], 45)
		$UIManager.update_chip_labels()
		if RELEASE_MODE: await get_tree().create_timer(1.2 * time_scale).timeout

func round_end():
	var active = 0
	var last_player = 0
	for i in range(NUM_PLAYERS):
		if player_chips[i] > 0:
			active += 1
			last_player = i

	var player_bankrupt = player_chips[0] <= 0

	if active <= 1 and player_bankrupt:
		$UIManager.end_label.text = "Game Over! %s wins!" % player_names[last_player]
		$UIManager.end_label.visible = true
	elif player_bankrupt:
		$UIManager.announce("You lose!")
		$UIManager.end_label.text = "You're out of chips! Press New Round to restart."
		$UIManager.end_label.visible = true

	var all_cpus_bankrupt = true
	for i in range(1, NUM_PLAYERS):
		if player_chips[i] > 0:
			all_cpus_bankrupt = false
			break
	if all_cpus_bankrupt:
		$UIManager.announce("Congratulations!")
		$UIManager.end_label.text = "You eliminated all opponents! Press New Round to play again."
		$UIManager.end_label.visible = true

	if Globals.sudden_death and not player_bankrupt and not all_cpus_bankrupt and sudden_death_round >= 3:
		$UIManager.announce("Sudden Death Champion!", 60)
		$UIManager.end_label.text = "You survived Sudden Death! Press New Round to play again."
		$UIManager.end_label.visible = true
		all_cpus_bankrupt = true

	for i in range(NUM_PLAYERS):
		$UIManager.player_panel[i].bet_label.text = ""

	$UIManager.new_round_button.visible = true
	$UIManager.new_round_button.pressed.connect(_on_new_round_pressed)
	await $UIManager.new_round_button.pressed
	if $UIManager.new_round_button.pressed.is_connected(_on_new_round_pressed):
		$UIManager.new_round_button.pressed.disconnect(_on_new_round_pressed)

	if player_bankrupt or all_cpus_bankrupt:
		_reset_game()

	play_round()

func _on_new_round_pressed():
	$UIManager.new_round_button.visible = false

func evaluate_best_hand(cards: Array) -> Dictionary:
	if cards.size() < 5:
		return {type = Globals.HandType.HIGH_CARD, ranks = [], score = 0}

	var best = null
	var combos = _combinations(cards, 5)
	for combo in combos:
		var result = evaluate_5(combo)
		if best == null or compare_hands(result, best) > 0:
			best = result
	return best

func _combinations(arr: Array, k: int) -> Array:
	var result = []
	var n = arr.size()
	var indices = []
	for i in range(k):
		indices.append(i)

	while true:
		var combo = []
		for i in indices:
			combo.append(arr[i])
		result.append(combo)

		var i = k - 1
		while i >= 0 and indices[i] == n - k + i:
			i -= 1
		if i < 0:
			break
		indices[i] += 1
		for j in range(i + 1, k):
			indices[j] = indices[j - 1] + 1

	return result

func evaluate_5(cards: Array) -> Dictionary:
	var suits = {}
	var ranks = []
	for c in cards:
		suits[c.suit] = suits.get(c.suit, 0) + 1
		ranks.append(c.rank)

	var is_flush = false
	for s in suits.values():
		if s >= 5:
			is_flush = true
			break

	ranks.sort()
	ranks.reverse()

	var is_straight = false
	var straight_high = 0
	var unique_ranks = []
	for r in ranks:
		if not unique_ranks.has(r):
			unique_ranks.append(r)
	unique_ranks.sort()

	if unique_ranks.size() >= 5:
		for i in range(unique_ranks.size() - 4):
			if unique_ranks[i] + 4 == unique_ranks[i + 4]:
				is_straight = true
				straight_high = unique_ranks[i + 4]
				break
		if !is_straight and unique_ranks.has(14):
			var wheel = true
			for r in [2, 3, 4, 5]:
				if !unique_ranks.has(r):
					wheel = false
					break
			if wheel:
				is_straight = true
				straight_high = 5

	var rank_counts = {}
	for r in ranks:
		rank_counts[r] = rank_counts.get(r, 0) + 1

	var groups = []
	for r in rank_counts.keys():
		groups.append({rank = r, count = rank_counts[r]})
	groups.sort_custom(func(a, b):
		if a.count != b.count: return a.count > b.count
		return a.rank > b.rank
	)

	var type = Globals.HandType.HIGH_CARD
	var score_ranks = []

	if is_flush and is_straight:
		if straight_high == 14:
			type = Globals.HandType.ROYAL_FLUSH
			score_ranks = [14]
		else:
			type = Globals.HandType.STRAIGHT_FLUSH
			score_ranks = [straight_high]
	elif groups[0].count == 4:
		type = Globals.HandType.FOUR_OF_KIND
		score_ranks = [groups[0].rank]
		if groups.size() > 1:
			score_ranks.append(groups[1].rank)
	elif groups[0].count == 3 and groups.size() > 1 and groups[1].count >= 2:
		type = Globals.HandType.FULL_HOUSE
		score_ranks = [groups[0].rank, groups[1].rank]
	elif is_flush:
		type = Globals.HandType.FLUSH
		score_ranks = ranks.duplicate()
	elif is_straight:
		type = Globals.HandType.STRAIGHT
		score_ranks = [straight_high]
	elif groups[0].count == 3:
		type = Globals.HandType.THREE_OF_KIND
		score_ranks = [groups[0].rank]
		for g in groups:
			if g.count == 1:
				score_ranks.append(g.rank)
	elif groups[0].count == 2 and groups.size() > 1 and groups[1].count == 2:
		type = Globals.HandType.TWO_PAIR
		score_ranks = [groups[0].rank, groups[1].rank]
		for g in groups:
			if g.count == 1:
				score_ranks.append(g.rank)
	elif groups[0].count == 2:
		type = Globals.HandType.PAIR
		score_ranks = [groups[0].rank]
		for g in groups:
			if g.count == 1:
				score_ranks.append(g.rank)
	else:
		type = Globals.HandType.HIGH_CARD
		score_ranks = ranks.duplicate()

	return {type = type, ranks = score_ranks}

func hand_result_name(result: Dictionary) -> String:
	var name = Globals.HAND_NAME[result.type]
	if !result.ranks.is_empty():
		if result.type == Globals.HandType.TWO_PAIR:
			name += " (%s)" % Globals.RANK_NAME.get(result.ranks[0], "?")
			name += " (%s)" % Globals.RANK_NAME.get(result.ranks[1], "?")
			return name
		if result.type == Globals.HandType.PAIR or result.type == Globals.HandType.THREE_OF_KIND  or result.type == Globals.HandType.FOUR_OF_KIND:
			name += " (%s)" % Globals.RANK_NAME.get(result.ranks[0], "?")
			return name
		if result.type == Globals.HandType.FLUSH:
			return name
		else:
			name += " (%s)" % _rank_str(result.ranks)
	return name

func _rank_str(ranks: Array) -> String:
	var parts = []
	for r in ranks:
		parts.append(Globals.RANK_NAME.get(r, "?"))
	return " ".join(parts)

func compare_hands(a: Dictionary, b: Dictionary) -> int:
	if a.type != b.type:
		return a.type - b.type
	var min_len = mini(a.ranks.size(), b.ranks.size())
	for i in range(min_len):
		if a.ranks[i] != b.ranks[i]:
			return a.ranks[i] - b.ranks[i]
	return 0

func mini(a: int, b: int) -> int:
	return a if a < b else b
