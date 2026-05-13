extends Control

const NUM_PLAYERS = 4
const STARTING_CHIPS = 1000
const ANTE_PERCENT = 0.05
const MAX_BET_PERCENT = 0.10
const STEAL_TIMER = 15.0
const CARD_W = 88
const CARD_H = 124
const CARD_GAP = -30
const PLAYER_POSITIONS = [
	Vector2(650, 555),
	Vector2(30, 280),
	Vector2(650, 40),
	Vector2(1150, 280)
]

var player_names: Array = ["You", "CPU 1", "CPU 2", "CPU 3"]
var player_chips: Array = []
var player_hands: Array = []
var player_folded: Array = []
var player_bets: Array = []
var player_is_human: Array = [true, false, false, false]
var player_panel: Array = []
var player_hand_nodes: Array = []

var pot: int = 0
var community_cards: Array = []
var community_nodes: Array = []

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

var pot_label: Label
var message_label: Label
var timer_label: Label
var stealtimer_label: Label
var action_bar: Control
var steal_overlay: Control
var overlay_container: Control
var left_player_label: Label
var overlay_timer: Label
var overlay_hand: HBoxContainer
var new_round_button: Button
var deal_button: Button
var fold_button: Button
var checkcall_button: Button
var raise_button: Button
var allin_button: Button
var discard_button: Button
var steal_confirm_button: Button
var bet_amt_label: Label
var bet_slider: HSlider
var bet_value_label: Label
var info_label: Label
var end_label: Label
var history_container: VBoxContainer

func _ready():
	randomize()
	build_ui()
	start_game()

func _on_discard_pressed():
	discard_button.visible = false

func _on_new_round_pressed():
	new_round_button.visible = false

func build_ui():
	var theme = Theme.new()
	theme.default_font = Globals.ui_font
	self.theme = theme

	var bg = ColorRect.new()
	bg.color = Color("1a5c1a")
	bg.size = get_viewport_rect().size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var viewport = get_viewport_rect().size
	var table = TextureRect.new()
	table.texture = load("res://asset/felt_green.jpg")
	table.stretch_mode = TextureRect.STRETCH_TILE
	table.size = Vector2(3500,1000)
	table.position = Vector2(200,100)
	table.scale = Vector2(.33,.33)
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.modulate = Color(0.65, 1.0, 0.65)
	add_child(table)

	pot_label = Label.new()
	pot_label.text = "Pot: 0"
	pot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pot_label.add_theme_font_size_override("font_size", 24)
	pot_label.add_theme_color_override("font_color", Color.WHITE)
	pot_label.position = Vector2(560, 250)
	pot_label.size = Vector2(200, 40)
	pot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pot_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.position = Vector2(390, 290)
	message_label.size = Vector2(500, 40)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message_label)

	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color", Color.ORANGE)
	timer_label.position = Vector2(540, 410)
	timer_label.size = Vector2(200, 30)
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timer_label)

	var comm_bg = ColorRect.new()
	comm_bg.color = Color(0, 0, 0, 0.3)
	comm_bg.position = Vector2(738, 322)
	comm_bg.size = Vector2(240, 140)
	comm_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(comm_bg)

	community_nodes = []
	for i in range(2):
		var card = make_card_sprite()
		card.visible = false
		add_child(card)
		community_nodes.append(card)

	community_cards = []

	var ab_bg = NinePatchRect.new()
	ab_bg.texture = Globals.grey_bevel_normal
	ab_bg.patch_margin_left = 4
	ab_bg.patch_margin_top = 4
	ab_bg.patch_margin_right = 4
	ab_bg.patch_margin_bottom = 4
	ab_bg.position = Vector2(50, 630)
	ab_bg.size = Vector2(410, 100)
	add_child(ab_bg)

	action_bar = Control.new()
	action_bar.position = Vector2(60, 640)
	action_bar.size = Vector2(860, 80)
	action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(action_bar)

	var btn_x = 0
	fold_button = make_button("Fold", Vector2(btn_x, 0))
	action_bar.add_child(fold_button)
	btn_x += 130

	checkcall_button = make_button("Check", Vector2(btn_x, 0))
	action_bar.add_child(checkcall_button)
	btn_x += 130

	raise_button = make_button("Raise", Vector2(btn_x, 0))
	action_bar.add_child(raise_button)
	btn_x += 130

	allin_button = make_button("All In", Vector2(btn_x, 0))
	#action_bar.add_child(allin_button)

	bet_amt_label = Label.new()
	bet_amt_label.text = "Bet Amt:"
	bet_amt_label.position = Vector2(0, 40)
	bet_amt_label.size = Vector2(100, 40)
	bet_amt_label.add_theme_font_size_override("font_size", 18)
	bet_amt_label.add_theme_color_override("font_color", Color.BLACK)
	bet_amt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_bar.add_child(bet_amt_label)

	bet_slider = HSlider.new()
	bet_slider.position = Vector2(110, 40)
	bet_slider.size = Vector2(250, 40)
	bet_slider.min_value = 1
	bet_slider.max_value = 100
	bet_slider.step = 5
	bet_slider.value_changed.connect(_on_bet_slider_changed)
	action_bar.add_child(bet_slider)

	bet_value_label = Label.new()
	bet_value_label.position = Vector2(370, 40)
	bet_value_label.size = Vector2(80, 40)
	bet_value_label.add_theme_font_size_override("font_size", 18)
	bet_value_label.add_theme_color_override("font_color", Color.BLACK)
	bet_value_label.text = "0"
	bet_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_bar.add_child(bet_value_label)

	discard_button = make_button("Discard & Draw", Vector2(0, 40))
	discard_button.visible = false
	action_bar.add_child(discard_button)

	for i in range(NUM_PLAYERS):
		var panel = VBoxContainer.new()
		panel.position = PLAYER_POSITIONS[i]
		panel.size = Vector2(300, 180)
		panel.add_theme_constant_override("separation", 2)
		add_child(panel)

		var name_label = Label.new()
		name_label.text = player_names[i]
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		if i != 0:
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)

		var chip_label = Label.new()
		chip_label.text = "Chips: %d" % STARTING_CHIPS
		chip_label.add_theme_font_size_override("font_size", 18)
		chip_label.add_theme_color_override("font_color", Color.YELLOW)
		if i != 0:
			chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(chip_label)

		var hand_container = HBoxContainer.new()
		hand_container.add_theme_constant_override("separation", CARD_GAP)
		hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(hand_container)

		var bet_label = Label.new()
		bet_label.text = ""
		bet_label.add_theme_font_size_override("font_size", 18)
		bet_label.add_theme_color_override("font_color", Color.WHITE)
		if i != 0:
			bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bet_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bet_label)

		player_panel.append({
			panel = panel,
			name_label = name_label,
			chip_label = chip_label,
			hand_container = hand_container,
			bet_label = bet_label
		})
		player_hand_nodes.append([])

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_label.position = Vector2(200, 470)
	info_label.size = Vector2(880, 80)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_label)

	end_label = Label.new()
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 28)
	end_label.add_theme_color_override("font_color", Color.GOLD)
	end_label.position = Vector2(300, 200)
	end_label.size = Vector2(680, 200)
	end_label.visible = false
	end_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(end_label)

	new_round_button = make_button("New Round", Vector2(130, 40))
	new_round_button.visible = false
	action_bar.add_child(new_round_button)

	deal_button = make_button("Deal", Vector2(260, 40))
	deal_button.visible = false
	action_bar.add_child(deal_button)

	steal_overlay = ColorRect.new()
	steal_overlay.color = Color(0, 0, 0, 0.7)
	steal_overlay.size = get_viewport_rect().size
	steal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	steal_overlay.visible = false
	add_child(steal_overlay)

	overlay_container = VBoxContainer.new()
	overlay_container.position = Vector2(340, 200)
	overlay_container.size = Vector2(600, 300)
	overlay_container.add_theme_constant_override("separation", 10)
	overlay_container.visible = false
	add_child(overlay_container)

	var ol_title = Label.new()
	ol_title.text = "STEAL A CARD!"
	ol_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ol_title.add_theme_font_size_override("font_size", 28)
	ol_title.add_theme_color_override("font_color", Color.RED)
	ol_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_container.add_child(ol_title)

	left_player_label = Label.new()
	left_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_player_label.add_theme_font_size_override("font_size", 18)
	left_player_label.add_theme_color_override("font_color", Color.WHITE)
	left_player_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_container.add_child(left_player_label)

	overlay_hand = HBoxContainer.new()
	overlay_hand.add_theme_constant_override("separation", 5)
	overlay_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_container.add_child(overlay_hand)

	steal_confirm_button = make_button("Confirm Steal", Vector2(0, 0))
	steal_confirm_button.visible = false
	overlay_container.add_child(steal_confirm_button)

	overlay_timer = Label.new()
	overlay_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_timer.add_theme_font_size_override("font_size", 20)
	overlay_timer.add_theme_color_override("font_color", Color.ORANGE)
	overlay_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_container.add_child(overlay_timer)

	stealtimer_label = Label.new()
	stealtimer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stealtimer_label.add_theme_font_size_override("font_size", 18)
	stealtimer_label.add_theme_color_override("font_color", Color.ORANGE)
	stealtimer_label.position = Vector2(540, 340)
	stealtimer_label.size = Vector2(200, 30)
	stealtimer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stealtimer_label)

	var history_bg = NinePatchRect.new()
	history_bg.texture = Globals.grey_bevel_normal
	history_bg.patch_margin_left = 4
	history_bg.patch_margin_top = 4
	history_bg.patch_margin_right = 4
	history_bg.patch_margin_bottom = 4
	history_bg.position = Vector2(1220, 550)
	history_bg.size = Vector2(360, 250)
	history_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(history_bg)

	history_container = VBoxContainer.new()
	history_container.position = Vector2(1226, 556)
	history_container.size = Vector2(348, 238)
	history_container.add_theme_constant_override("separation", 2)
	history_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(history_container)

	move_child(action_bar, get_child_count() - 1)

func _announce(msg: String):
	message_label.text = msg
	if msg != "":
		_add_to_history(msg)

func _add_to_history(msg: String):
	var entry = Label.new()
	entry.text = msg
	entry.add_theme_font_size_override("font_size", 18)
	entry.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	history_container.add_child(entry)
	history_container.move_child(entry, 0)
	if history_container.get_child_count() > 11:
		history_container.get_child(history_container.get_child_count() - 1).queue_free()
	for i in range(1, history_container.get_child_count()):
		history_container.get_child(i).add_theme_color_override("font_color", Color.BLACK)

func make_button(text: String, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(110, 40)

	var normal_sb = StyleBoxTexture.new()
	normal_sb.texture = Globals.grey_bevel_normal
	normal_sb.texture_margin_left = 4
	normal_sb.texture_margin_top = 4
	normal_sb.texture_margin_right = 4
	normal_sb.texture_margin_bottom = 4

	var hover_sb = StyleBoxTexture.new()
	hover_sb.texture = Globals.grey_bevel_hover
	hover_sb.texture_margin_left = 4
	hover_sb.texture_margin_top = 4
	hover_sb.texture_margin_right = 4
	hover_sb.texture_margin_bottom = 4

	var pressed_sb = StyleBoxTexture.new()
	pressed_sb.texture = Globals.grey_bevel_pressed
	pressed_sb.texture_margin_left = 4
	pressed_sb.texture_margin_top = 4
	pressed_sb.texture_margin_right = 4
	pressed_sb.texture_margin_bottom = 4

	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("disabled", normal_sb)

	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.add_theme_color_override("font_disabled_color", Color("808080"))

	return btn

func make_card_sprite() -> TextureRect:
	var tr = TextureRect.new()
	tr.size = Vector2(CARD_W, CARD_H)
	tr.custom_minimum_size = Vector2(CARD_W, CARD_H)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	return tr

func make_card_back_sprite() -> TextureRect:
	var tr = make_card_sprite()
	tr.texture = Globals.make_card_back_texture()
	return tr

func set_card_sprite(tr: TextureRect, suit: int, rank: int):
	tr.texture = Globals.make_card_texture(suit, rank)

func start_game():
	player_chips = []
	player_hands = []
	player_folded = []
	player_bets = []
	for i in range(NUM_PLAYERS):
		player_chips.append(STARTING_CHIPS)
		player_hands.append([])
		player_folded.append(false)
		player_bets.append(0)
	update_chip_labels()
	await get_tree().create_timer(0.9).timeout
	play_round()

func play_round():
	await clear_hands()
	await deal_phase()
	ante_phase()
	await betting_round()
	await flop_phase(1)
	await betting_round()
	await discard_phase()
	await betting_round()
	await steal_phase()
	await flop_phase(2)
	await showdown_phase()
	await round_end()

func clear_hands():
	_announce("New round...")
	for i in range(NUM_PLAYERS):
		player_hands[i] = []
		player_folded[i] = false
		player_bets[i] = 0
		clear_hand_display(i)
	pot = 0
	community_cards = []
	for node in community_nodes:
		node.visible = false
	pot_label.text = "Pot: 0"
	community_cards.clear()
	update_chip_labels()
	await get_tree().create_timer(0.9).timeout

func clear_hand_display(player_idx: int):
	var container = player_panel[player_idx].hand_container
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()
	player_hand_nodes[player_idx].clear()

func ante_phase():
	_announce("Ante phase...")
	for i in range(NUM_PLAYERS):
		var ante = min(20, player_chips[i])
		player_chips[i] -= ante
		pot += ante
		player_panel[i].bet_label.text = "Ante: %d" % ante
	pot_label.text = "Pot: %d" % pot
	update_chip_labels()
	await get_tree().create_timer(1.8).timeout

func build_deck():
	deck = []
	for suit in range(4):
		for rank in range(2, 15):
			deck.append({suit = suit, rank = rank})
	deck.shuffle()

func deal_phase():
	_announce("Dealing...")
	build_deck()
	for i in range(NUM_PLAYERS):
		player_hands[i] = []
		for j in range(5):
			player_hands[i].append(deck.pop_back())
		update_hand_display(i)
		await get_tree().create_timer(0.25).timeout
	_announce("Cards dealt!")
	await get_tree().create_timer(0.9).timeout

func update_hand_display(player_idx: int, face_up: bool = false):
	var container = player_panel[player_idx].hand_container
	clear_hand_display(player_idx)
	var hand = player_hands[player_idx]
	var nodes = []
	for i in range(hand.size()):
		var card = hand[i]
		var tr: TextureRect
		if player_is_human[player_idx] or face_up:
			tr = make_card_sprite()
			set_card_sprite(tr, card.suit, card.rank)
		else:
			tr = make_card_back_sprite()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(tr)
		nodes.append(tr)
	player_hand_nodes[player_idx] = nodes

func flop_phase(num_cards: int):
	if community_cards.size() < num_cards:
		var card = deck.pop_back()
		community_cards.append(card)
	var idx = community_cards.size() - 1
	if idx >= 0 and idx < community_nodes.size():
		set_card_sprite(community_nodes[idx], community_cards[idx].suit, community_cards[idx].rank)
		var card_pos = Vector2(758 + idx * 120, 332)
		community_nodes[idx].position = card_pos
		community_nodes[idx].visible = true
	_announce("Flop: %s" % Globals.card_name(community_cards[idx].suit, community_cards[idx].rank) if community_cards.size() > 0 else "")
	update_all_displays()
	await get_tree().create_timer(2.1).timeout

func betting_round():
	_announce("Betting round...")
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
	
	pot_label.text = "Pot: %d" % pot
	_announce("Betting round over")
	await get_tree().create_timer(1.8).timeout

func human_betting_turn(player_idx: int, turn_count: int):
	_announce("Your turn!")
	call_amount = current_bet - player_bets[player_idx]
	if call_amount < 0:
		call_amount = 0
	var pot_for_bet = pot + player_bets[player_idx]
	max_raise = max(1, int(pot_for_bet * MAX_BET_PERCENT))
	max_raise = min(max_raise, player_chips[player_idx])
	min_raise = max(1, call_amount)
	
	if call_amount == 0:
		checkcall_button.text = "Check"
	else:
		checkcall_button.text = "Call %d" % call_amount
	
	var can_raise = turn_count < 4
	
	fold_button.visible = true
	checkcall_button.visible = true
	
	var slider_min = 5
	var slider_max = 100
	var cannot_meet_call = call_amount > slider_max
	
	raise_button.visible = can_raise and !cannot_meet_call
	allin_button.visible = can_raise and !cannot_meet_call
	bet_amt_label.visible = can_raise
	bet_slider.visible = can_raise and !cannot_meet_call
	bet_value_label.visible = can_raise and !cannot_meet_call
	
	if can_raise:
		bet_slider.min_value = slider_min
		bet_slider.max_value = slider_max
		bet_slider.value = slider_min
		bet_value_label.text = str(slider_min)
	
	var action = await _wait_for_human_action()
	
	show_action_buttons(false)
	
	match action:
		"fold":
			player_folded[player_idx] = true
			player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
			_announce("You folded")
		"call":
			var amount = call_amount
			player_chips[player_idx] -= amount
			pot += amount
			player_bets[player_idx] += amount
			player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			if call_amount == 0:
				_announce("You checked")
			else:
				_announce("You called")
		"raise":
			var raise_amount = int(bet_slider.value)
			var max_allowed = 100 - player_bets[player_idx]
			var total_bet = mini(raise_amount, max_allowed)
			player_chips[player_idx] -= total_bet
			pot += total_bet
			player_bets[player_idx] += total_bet
			current_bet = player_bets[player_idx]
			last_raiser = player_idx
			player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			_announce("You raised to %d" % total_bet)
		"allin":
			var amount = min(player_chips[player_idx], 100 - player_bets[player_idx])
			player_chips[player_idx] -= amount
			pot += amount
			player_bets[player_idx] += amount
			if player_bets[player_idx] > current_bet:
				current_bet = player_bets[player_idx]
				last_raiser = player_idx
			player_panel[player_idx].bet_label.text = "All In: %d" % player_bets[player_idx]
			_announce("You went All In!")
	
	update_chip_labels()
	pot_label.text = "Pot: %d" % pot
	await get_tree().create_timer(0.9).timeout

func show_action_buttons(show: bool):
	fold_button.visible = show
	checkcall_button.visible = show
	raise_button.visible = show
	allin_button.visible = show
	bet_amt_label.visible = show
	bet_slider.visible = show
	bet_value_label.visible = show

func _make_click_handler(state: Dictionary, action: String) -> Callable:
	return func(): state.result = action

func _wait_for_human_action() -> String:
	var state = {result = ""}
	var buttons = [
		{btn = fold_button, action = "fold"},
		{btn = checkcall_button, action = "call"},
		{btn = raise_button, action = "raise"},
		{btn = allin_button, action = "allin"}
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

func _on_bet_slider_changed(value: float):
	bet_value_label.text = str(int(value))

func cpu_betting_turn(player_idx: int, turn_count: int):
	_announce("%s is thinking..." % player_names[player_idx])
	await get_tree().create_timer(1.8).timeout
	
	var call_amt = current_bet - player_bets[player_idx]
	if call_amt < 0:
		call_amt = 0
	
	var hand_strength = evaluate_hand_strength(player_hands[player_idx], community_cards)
	var pot_for_bet = pot + player_bets[player_idx]
	var max_bet = min(int(pot_for_bet * MAX_BET_PERCENT), player_chips[player_idx])
	
	var can_raise = turn_count < 4
	
	if can_raise and (hand_strength > 0.7 or (hand_strength > 0.4 and randf() > 0.5)):
		var raise_amt = min(max_bet, max(call_amt + int(max_bet * 0.5), int(max_bet * 0.3)))
		raise_amt = max(1, int(raise_amt))
		raise_amt = min(raise_amt, player_chips[player_idx])
		raise_amt = min(raise_amt, 100 - player_bets[player_idx])
		player_chips[player_idx] -= raise_amt
		pot += raise_amt
		player_bets[player_idx] += raise_amt
		current_bet = player_bets[player_idx]
		last_raiser = player_idx
		player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
		_announce("%s raises to %d" % [player_names[player_idx], raise_amt])
	elif hand_strength > 0.2 or randf() > 0.3:
		var amount = min(call_amt, player_chips[player_idx])
		player_chips[player_idx] -= amount
		pot += amount
		player_bets[player_idx] += amount
		player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
		_announce("%s calls" % player_names[player_idx])
	else:
		player_folded[player_idx] = true
		player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
		_announce("%s folds" % player_names[player_idx])
	
	update_chip_labels()
	pot_label.text = "Pot: %d" % pot
	await get_tree().create_timer(0.6).timeout

func evaluate_hand_strength(hand: Array, community: Array) -> float:
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

func discard_phase():
	_announce("Click on any cards you want to replace")
	
	var active_players = []
	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			active_players.append(i)
	
	for i in active_players:
		if player_is_human[i]:
			await human_discard(i)
		else:
			cpu_discard(i)
	
	_announce("Draw phase")
	await get_tree().create_timer(0.9).timeout

func human_discard(player_idx: int):
	_announce("Click cards to discard, then press Discard & Draw")
	
	var hand = player_hands[player_idx]
	var container = player_panel[player_idx].hand_container
	clear_hand_display(player_idx)
	
	discard_selected = []
	var card_nodes = []
	
	for i in range(hand.size()):
		var card = hand[i]
		var tr = make_card_sprite()
		set_card_sprite(tr, card.suit, card.rank)
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
	
	player_hand_nodes[player_idx] = card_nodes
	
	discard_button.visible = true
	discard_button.disabled = false
	
	discard_button.pressed.connect(_on_discard_pressed)
	
	await discard_button.pressed
	
	if discard_button.pressed.is_connected(_on_discard_pressed):
		discard_button.pressed.disconnect(_on_discard_pressed)
	
	var num_discard = discard_selected.size()
	discard_selected.sort()
	discard_selected.reverse()
	for idx in discard_selected:
		player_hands[player_idx].remove_at(idx)
	
	for _i in range(num_discard):
		if deck.size() > 0:
			player_hands[player_idx].append(deck.pop_back())
	
	update_hand_display(player_idx)
	_announce("Drew %d new cards" % num_discard)
	await get_tree().create_timer(1.9).timeout

func cpu_discard(player_idx: int):
	_announce("%s is discarding..." % player_names[player_idx])
	await get_tree().create_timer(0.8).timeout
	
	var hand = player_hands[player_idx]
	var rank_counts = {}
	for c in hand:
		rank_counts[c.rank] = rank_counts.get(c.rank, 0) + 1
	
	var to_discard = []
	for i in range(hand.size()):
		var c = hand[i]
		if rank_counts[c.rank] == 1 and c.rank < 11:
			to_discard.append(i)
	
	if to_discard.is_empty() and hand.size() > 0:
		to_discard = [hand.size() - 1]
	
	var num_discard = mini(to_discard.size(), hand.size())
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
		
		_announce("%s drew %d cards" % [player_names[player_idx], actual_discard])
	else:
		_announce("%s kept all cards" % player_names[player_idx])
	
	update_hand_display(player_idx)
	await get_tree().create_timer(0.9).timeout

func steal_phase():
	_announce("STEAL PHASE!")
	stealtimer_label.visible = true
	
	for i in range(NUM_PLAYERS):
		update_hand_display(i, true)
	
	await get_tree().create_timer(1.8).timeout
	
	var steal_decisions = [-1, -1, -1, -1]
	var human_target = 3
	
	for i in range(NUM_PLAYERS):
		if player_folded[i]:
			continue
		var left_idx = (i + 1) % NUM_PLAYERS
		if player_folded[left_idx]:
			continue
		if player_is_human[i]:
			human_target = left_idx
		else:
			steal_decisions[i] = cpu_choose_steal(i, left_idx)
	
	if !player_folded[0] and !player_folded[human_target]:
		await show_steal_ui(human_target)
		steal_decisions[0] = steal_choice
	
	var steal_info = []
	for i in range(NUM_PLAYERS):
		if steal_decisions[i] >= 0:
			var left_idx = (i + 1) % NUM_PLAYERS
			var card = player_hands[left_idx][steal_decisions[i]]
			steal_info.append({stealer = i, suit = card.suit, rank = card.rank, target = left_idx})
	
	for i in range(NUM_PLAYERS):
		if steal_decisions[i] >= 0:
			var left_idx = (i + 1) % NUM_PLAYERS
			var card = player_hands[left_idx][steal_decisions[i]]
			player_hands[left_idx].remove_at(steal_decisions[i])
			player_hands[i].append(card)
	
	stealtimer_label.visible = false
	steal_overlay.visible = false
	overlay_container.visible = false
	
	for i in range(NUM_PLAYERS):
		update_hand_display(i, true)
	
	for info in steal_info:
		if !player_is_human[info.stealer]:
			var card_name = Globals.card_name(info.suit, info.rank)
			_announce("%s stole %s from %s!" % [player_names[info.stealer], card_name, player_names[info.target]])
			await get_tree().create_timer(3.0).timeout
	
	_announce("Steals complete!")
	await get_tree().create_timer(1.8).timeout

func cpu_choose_steal(player_idx: int, target_idx: int) -> int:
	var target_hand = player_hands[target_idx]
	if target_hand.is_empty():
		return -1
	var best_idx = 0
	var best_rank = 0
	for i in range(target_hand.size()):
		if target_hand[i].rank > best_rank:
			best_rank = target_hand[i].rank
			best_idx = i
	return best_idx

func show_steal_ui(target_idx: int):
	steal_overlay.visible = true
	overlay_container.visible = true
	steal_choice = -1
	
	left_player_label.text = "Steal a card from %s!" % player_names[target_idx]
	
	for c in overlay_hand.get_children():
		overlay_hand.remove_child(c)
		c.queue_free()
	
	var hand = player_hands[target_idx]
	var temp_nodes = []
	
	for i in range(hand.size()):
		var card = hand[i]
		var tr = make_card_sprite()
		set_card_sprite(tr, card.suit, card.rank)
		var card_idx = i
		tr.mouse_filter = Control.MOUSE_FILTER_STOP
		
		tr.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				for n in temp_nodes:
					n.modulate = Color.WHITE
				tr.modulate = Color(1, 0.8, 0)
				steal_choice = card_idx
				steal_confirm_button.visible = true
		)
		
		overlay_hand.add_child(tr)
		temp_nodes.append(tr)
	
	steal_confirm_button.visible = false
	
	var elapsed = 0.0
	while (steal_choice < 0) and elapsed < STEAL_TIMER:
		var remaining = STEAL_TIMER - elapsed
		overlay_timer.text = "Time: %d" % ceil(remaining)
		await get_tree().create_timer(0.2).timeout
		elapsed += 0.1
	
	if steal_choice < 0:
		steal_choice = randi() % hand.size()
	
	steal_confirm_button.visible = false
	steal_overlay.visible = false
	overlay_container.visible = false

func showdown_phase():
	_announce("Showdown!")
	await get_tree().create_timer(1.8).timeout
	
	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			update_hand_display(i, true)
	
	var active_players = []
	for i in range(NUM_PLAYERS):
		if !player_folded[i]:
			active_players.append(i)
	
	if active_players.size() == 1:
		var winner = active_players[0]
		player_chips[winner] += pot
		_announce("%s wins (everyone folded)!" % player_names[winner])
		return
	
	var results = []
	for i in active_players:
		var all_cards = player_hands[i] + community_cards
		var result = evaluate_best_hand(all_cards)
		results.append({player = i, result = result})
		_announce("%s: %s" % [player_names[i], hand_result_name(result)])
		await get_tree().create_timer(1.8).timeout
	
	results.sort_custom(func(a, b): return compare_hands(a.result, b.result) > 0)
	
	var best = results[0]
	var tied = [best]
	for i in range(1, results.size()):
		if compare_hands(results[i].result, best.result) == 0:
			tied.append(results[i])
	
	var share = pot / tied.size()
	for t in tied:
		player_chips[t.player] += share
	
	if best.player == 0:
		_announce("%s win with %s!" % [player_names[best.player], hand_result_name(best.result)])
	else:
		_announce("%s wins with %s!" % [player_names[best.player], hand_result_name(best.result)])
	update_chip_labels()

func round_end():
	var active = 0
	var last_player = 0
	for i in range(NUM_PLAYERS):
		if player_chips[i] > 0:
			active += 1
			last_player = i
	
	if active <= 1:
		end_label.text = "Game Over! %s wins!" % player_names[last_player]
		end_label.visible = true
		return
	
	for i in range(NUM_PLAYERS):
		player_panel[i].bet_label.text = ""
	
	new_round_button.visible = true
	new_round_button.pressed.connect(_on_new_round_pressed)
	await new_round_button.pressed
	if new_round_button.pressed.is_connected(_on_new_round_pressed):
		new_round_button.pressed.disconnect(_on_new_round_pressed)
	
	play_round()

func update_chip_labels():
	for i in range(NUM_PLAYERS):
		player_panel[i].chip_label.text = "Chips: %d" % player_chips[i]
		if player_chips[i] <= 0:
			player_panel[i].name_label.add_theme_color_override("font_color", Color.DIM_GRAY)

func update_all_displays():
	for i in range(NUM_PLAYERS):
		update_hand_display(i, false)

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
