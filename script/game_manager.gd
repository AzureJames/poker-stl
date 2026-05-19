extends Control

const NUM_PLAYERS = 4
const STARTING_CHIPS = 1000
const ANTE_PERCENT = 0.05
const MAX_BET = 65
const STEAL_TIMER = 21.0
const CARD_W = 88
const CARD_H = 124
const RELEASE_MODE := true
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
var player_ai: Array = [null, null, null, null]
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
var difficulty_slider: HSlider
var difficulty_label: Label
var info_label: Label
var end_label: Label
var history_container: VBoxContainer
var poker_hands_image: TextureRect
var poker_hands_toggle: Button

func _ready():
	randomize()
	build_ui()

func _on_discard_pressed():
	discard_button.visible = false

func _on_new_round_pressed():
	new_round_button.visible = false

func _reset_game():
	player_chips = []
	player_hands = []
	player_folded = []
	player_bets = []
	for i in range(NUM_PLAYERS):
		player_chips.append(STARTING_CHIPS)
		player_hands.append([])
		player_folded.append(false)
		player_bets.append(0)
	end_label.visible = false
	update_chip_labels()
	for i in range(NUM_PLAYERS):
		$ChipManager.setup_player_pile(i, player_chips[i])
	$ChipManager.clear_all()
	$ChipManager.update_pot(0)
	pot_label.text = "Pot: 0"
	_announce("")

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
	pot_label.add_theme_font_size_override("font_size", 26)
	pot_label.add_theme_color_override("font_color", Color.WHITE)
	pot_label.position = Vector2(530, 220)
	pot_label.size = Vector2(200, 40)
	pot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pot_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.position = Vector2(390, 275)
	message_label.size = Vector2(500, 40)
	message_label.z_index = 9
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
	bet_amt_label.add_theme_font_size_override("font_size", 20)
	bet_amt_label.add_theme_color_override("font_color", Color.BLACK)
	bet_amt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_bar.add_child(bet_amt_label)

	bet_slider = HSlider.new()
	bet_slider.position = Vector2(110, 40)
	bet_slider.size = Vector2(250, 40)
	bet_slider.min_value = 5
	bet_slider.max_value = 50
	bet_slider.step = 5
	bet_slider.value = 5
	bet_slider.value_changed.connect(_on_bet_slider_changed)
	action_bar.add_child(bet_slider)

	bet_value_label = Label.new()
	bet_value_label.position = Vector2(370, 40)
	bet_value_label.size = Vector2(80, 40)
	bet_value_label.add_theme_font_size_override("font_size", 20)
	bet_value_label.add_theme_color_override("font_color", Color.BLACK)
	bet_value_label.text = "0"
	bet_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_bar.add_child(bet_value_label)

	var diff_label = Label.new()
	diff_label.text = "CPU:"
	diff_label.position = Vector2(20, 20)
	diff_label.size = Vector2(40, 30)
	diff_label.add_theme_font_size_override("font_size", 18)
	diff_label.add_theme_color_override("font_color", Color.WHITE)
	diff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(diff_label)

	difficulty_slider = HSlider.new()
	difficulty_slider.position = Vector2(65, 20)
	difficulty_slider.size = Vector2(130, 30)
	difficulty_slider.min_value = 0
	difficulty_slider.max_value = 2
	difficulty_slider.step = 1
	difficulty_slider.tick_count = 3
	difficulty_slider.value = 0
	difficulty_slider.value_changed.connect(_on_difficulty_changed)
	add_child(difficulty_slider)

	difficulty_label = Label.new()
	difficulty_label.position = Vector2(200, 20)
	difficulty_label.size = Vector2(60, 30)
	difficulty_label.add_theme_font_size_override("font_size", 18)
	difficulty_label.add_theme_color_override("font_color", Color.WHITE)
	difficulty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(difficulty_label)
	_on_difficulty_changed(0)

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
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		if i != 0:
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)

		var chip_label = Label.new()
		chip_label.text = "Chips: %d" % STARTING_CHIPS
		chip_label.add_theme_font_size_override("font_size", 20)
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
		bet_label.add_theme_font_size_override("font_size", 20)
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
	info_label.add_theme_font_size_override("font_size", 20)
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

	var steal_layer = CanvasLayer.new()
	steal_layer.layer = 1
	steal_layer.name = "StealLayer"
	add_child(steal_layer)

	steal_overlay = ColorRect.new()
	steal_overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	steal_overlay.size = get_viewport_rect().size
	steal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	steal_overlay.visible = false
	steal_layer.add_child(steal_overlay)

	overlay_container = VBoxContainer.new()
	overlay_container.position = Vector2(340, 100)
	overlay_container.size = Vector2(600, 300)
	overlay_container.add_theme_constant_override("separation", 10)
	overlay_container.visible = false
	steal_layer.add_child(overlay_container)

	var ol_title = Label.new()
	ol_title.text = "STEAL A CARD!"
	ol_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ol_title.add_theme_font_size_override("font_size", 28)
	ol_title.add_theme_color_override("font_color", Color.RED)
	ol_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_container.add_child(ol_title)

	left_player_label = Label.new()
	left_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_player_label.add_theme_font_size_override("font_size", 20)
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
	stealtimer_label.add_theme_font_size_override("font_size", 20)
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

	poker_hands_image = TextureRect.new()
	poker_hands_image.texture = load("res://asset/Poker-Hands.png")
	poker_hands_image.stretch_mode = TextureRect.StretchMode.STRETCH_TILE
	poker_hands_image.scale = Vector2(.42,.42)
	poker_hands_image.position = Vector2(750, 50)
	poker_hands_image.size = Vector2(300, 500)
	poker_hands_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poker_hands_image.visible = false
	poker_hands_image.z_index = 5
	add_child(poker_hands_image)

	poker_hands_toggle = make_button("Hands", Vector2(1470, 10))
	poker_hands_toggle.pressed.connect(_toggle_poker_hands)
	add_child(poker_hands_toggle)

	move_child(action_bar, get_child_count() - 1)

func _toggle_poker_hands():
	poker_hands_image.visible = not poker_hands_image.visible

func _announce(msg: String, _scale = null):
	if _scale != null: message_label.add_theme_font_size_override("font_size", _scale)
	else: message_label.add_theme_font_size_override("font_size", 22)
	message_label.text = msg
	if msg != "":
		_add_to_history(msg)
		
func _announce_quiet(msg: String, _scale = Vector2(1,1)):
	message_label.scale = scale
	message_label.text = msg

func _add_to_history(msg: String):
	var entry = Label.new()
	entry.text = msg
	entry.add_theme_font_size_override("font_size", 19)
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

	btn.add_theme_font_size_override("font_size", 19)
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
	for i in range(NUM_PLAYERS):
		$ChipManager.setup_player_pile(i, player_chips[i])
	if RELEASE_MODE: await get_tree().create_timer(0.9).timeout
	play_round()

func play_round():
	for i in range(NUM_PLAYERS):
		if player_ai[i]:
			player_ai[i].new_round()
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
	$ChipManager.clear_all()
	for i in range(NUM_PLAYERS):
		$ChipManager.setup_player_pile(i, player_chips[i])
	$SoundManager.play_card_shuffle()
	if RELEASE_MODE: await get_tree().create_timer(0.9).timeout

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
		$ChipManager.add_pot_contribution(i, ante)
	pot_label.text = "Pot: %d" % pot
	update_chip_labels()
	for i in range(NUM_PLAYERS):
		$ChipManager.update_player_pile(i, player_chips[i])
	$ChipManager.update_pot(pot)
	$SoundManager.play_chips_stack()
	if RELEASE_MODE: await get_tree().create_timer(1.8).timeout

func build_deck():
	deck = []
	for suit in range(4):
		for rank in range(2, 15):
			deck.append({suit = suit, rank = rank})
	deck.shuffle()

func deal_phase():
	$SoundManager.play_card_slide()
	_announce("Dealing...")
	build_deck()
	for i in range(NUM_PLAYERS):
		player_hands[i] = []
		for j in range(5):
			player_hands[i].append(deck.pop_back())
		update_hand_display(i)
		if RELEASE_MODE: await get_tree().create_timer(0.25).timeout
	_announce("Cards dealt!")
	if RELEASE_MODE: await get_tree().create_timer(0.9).timeout

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
	if player_folded[player_idx]:
		for node in nodes:
			node.modulate = Color(0.5, 0.5, 0.5, 0.5)

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
	$SoundManager.play_card_place()
	_announce("Flop: %s" % Globals.card_name(community_cards[idx].suit, community_cards[idx].rank) if community_cards.size() > 0 else "")
	update_all_displays()
	if RELEASE_MODE: await get_tree().create_timer(2.1).timeout

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
	if RELEASE_MODE: await get_tree().create_timer(1.8).timeout

func human_betting_turn(player_idx: int, turn_count: int):
	_announce("Your turn!")
	call_amount = current_bet - player_bets[player_idx]
	if call_amount < 0:
		call_amount = 0
	call_amount = mini(call_amount, player_chips[player_idx])
	var pot_for_bet = pot + player_bets[player_idx]
	max_raise = MAX_BET
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
	var slider_max = 65
	var cannot_meet_call = call_amount > slider_max
	var pot_limit = pot >= 595
	
	raise_button.visible = can_raise and !cannot_meet_call and !pot_limit
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
			update_hand_display(player_idx)
			$SoundManager.play_card_shove()
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			_announce("You folded")
		"call":
			var amount = call_amount
			player_chips[player_idx] -= amount
			pot += amount
			player_bets[player_idx] += amount
			player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			$SoundManager.play_chip_lay()
			$ChipManager.add_pot_contribution(player_idx, amount)
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			$ChipManager.update_pot(pot)
			if call_amount == 0:
				_announce("You checked")
			else:
				_announce("You called")
		"raise":
			var raise_amount = int(bet_slider.value)
			var max_allowed = 130 - player_bets[player_idx]
			var total_bet = mini(raise_amount, max_allowed)
			total_bet = mini(total_bet, player_chips[player_idx])
			if pot + total_bet > 595:
				_announce("Pot limit reached")
				show_action_buttons(true)
				action = await _wait_for_human_action()
				show_action_buttons(false)
				match action:
					"fold":
						player_folded[player_idx] = true
						player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
						update_hand_display(player_idx)
						$SoundManager.play_card_shove()
						$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
						_announce("You folded")
					"call":
						var amt = call_amount
						player_chips[player_idx] -= amt
						pot += amt
						player_bets[player_idx] += amt
						player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
						$SoundManager.play_chip_lay()
						$ChipManager.add_pot_contribution(player_idx, amt)
						$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
						$ChipManager.update_pot(pot)
						if amt == 0: _announce("You checked")
						else: _announce("You called")
				update_chip_labels()
				pot_label.text = "Pot: %d" % pot
				if RELEASE_MODE: await get_tree().create_timer(0.9).timeout
				return
			player_chips[player_idx] -= total_bet
			pot += total_bet
			player_bets[player_idx] += total_bet
			current_bet = player_bets[player_idx]
			last_raiser = player_idx
			player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			$SoundManager.play_chips_collide()
			$ChipManager.add_pot_contribution(player_idx, total_bet)
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			$ChipManager.update_pot(pot)
			_announce("You raised to %d" % player_bets[player_idx])
	
	update_chip_labels()
	pot_label.text = "Pot: %d" % pot
	if RELEASE_MODE: await get_tree().create_timer(0.9).timeout

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
		add_child(ai)
		player_ai[i] = ai
	var labels = ["Easy", "Medium", "Hard"]
	difficulty_label.text = labels[idx]

func cpu_betting_turn(player_idx: int, turn_count: int):
	_announce_quiet("%s is thinking..." % player_names[player_idx])
	if RELEASE_MODE: await get_tree().create_timer(1.8).timeout

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
				player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
				$SoundManager.play_chips_collide()
				$ChipManager.add_pot_contribution(player_idx, raise_amt)
				$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
				$ChipManager.update_pot(pot)
				_announce("%s raises to %d" % [player_names[player_idx], player_bets[player_idx]])
			else:
				var amount = mini(max(0, current_bet - player_bets[player_idx]), player_chips[player_idx])
				player_chips[player_idx] -= amount
				pot += amount
				player_bets[player_idx] += amount
				player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
				$SoundManager.play_chip_lay()
				$ChipManager.add_pot_contribution(player_idx, amount)
				$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
				$ChipManager.update_pot(pot)
				if amount == 0: _announce("%s checks" % player_names[player_idx])
				else: _announce("%s calls" % player_names[player_idx])
		"call":
			var amount = mini(decision.amount, player_chips[player_idx])
			player_chips[player_idx] -= amount
			pot += amount
			player_bets[player_idx] += amount
			player_panel[player_idx].bet_label.text = "Bet: %d" % player_bets[player_idx]
			$SoundManager.play_chip_lay()
			$ChipManager.add_pot_contribution(player_idx, amount)
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			$ChipManager.update_pot(pot)
			if amount == 0: _announce("%s checks" % player_names[player_idx])
			else: _announce("%s calls" % player_names[player_idx])
		"fold":
			player_folded[player_idx] = true
			player_panel[player_idx].name_label.add_theme_color_override("font_color", Color.GRAY)
			update_hand_display(player_idx)
			$SoundManager.play_card_shove()
			$ChipManager.update_player_pile(player_idx, player_chips[player_idx])
			_announce("%s folds" % player_names[player_idx])

	update_chip_labels()
	pot_label.text = "Pot: %d" % pot
	if RELEASE_MODE: await get_tree().create_timer(0.6).timeout

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
	if RELEASE_MODE: await get_tree().create_timer(0.9).timeout

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
	$SoundManager.play_card_slide()
	_announce("Drew %d new cards" % num_discard)
	if RELEASE_MODE: await get_tree().create_timer(1.9).timeout

func cpu_discard(player_idx: int):
	_announce("%s is discarding..." % player_names[player_idx])
	if RELEASE_MODE: await get_tree().create_timer(0.8).timeout

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

		_announce("%s drew %d cards" % [player_names[player_idx], actual_discard])
	else:
		_announce("%s kept all cards" % player_names[player_idx])

	update_hand_display(player_idx)
	if RELEASE_MODE: await get_tree().create_timer(0.9).timeout

func _find_steal_target(player_idx: int) -> int:
	for offset in range(1, NUM_PLAYERS):
		var left = (player_idx + offset) % NUM_PLAYERS
		if not player_folded[left]:
			return left
	return -1

func steal_phase():
	message_label.text = "STEAL PHASE!"
	stealtimer_label.visible = true
	
	for i in range(NUM_PLAYERS):
		update_hand_display(i, true)
	
	await get_tree().create_timer(0.8).timeout
	
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
		await show_steal_ui(human_target)
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
	
	stealtimer_label.visible = false
	steal_overlay.visible = false
	overlay_container.visible = false
	
	for i in range(NUM_PLAYERS):
		update_hand_display(i, true)
	
	for info in steal_info:
		var card_name = Globals.card_name(info.suit, info.rank)
		_announce("%s stole %s from %s!" % [player_names[info.stealer], card_name, player_names[info.target]])
		if !player_is_human[info.stealer]:
			await get_tree().create_timer(3.0).timeout
	
	_announce("Steals complete!")
	await get_tree().create_timer(0.8).timeout

func cpu_choose_steal(player_idx: int, target_idx: int) -> int:
	return player_ai[player_idx].get_steal_choice(player_hands[player_idx], player_hands[target_idx])

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
	
	stealtimer_label.text = "Time: %d" % STEAL_TIMER
	overlay_timer.text = "Time: %d" % STEAL_TIMER
	
	var elapsed = 0.0
	while steal_choice < 0 and elapsed < STEAL_TIMER:
		var remaining = STEAL_TIMER - elapsed
		stealtimer_label.text = "Time: %d" % ceil(remaining)
		overlay_timer.text = "Time: %d" % ceil(remaining)
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	
	if steal_choice < 0:
		steal_choice = 0
		_announce("Time's up! You steal %s's first card." % player_names[target_idx])
	else:
		await steal_confirm_button.pressed
	
	steal_confirm_button.visible = false
	steal_overlay.visible = false
	overlay_container.visible = false

#broke?
#func show_steal_ui(target_idx: int):
	#steal_overlay.visible = true
	#overlay_container.visible = true
	#steal_choice = -1
	#
	#left_player_label.text = "Steal a card from %s!" % player_names[target_idx]
	#
	#for c in overlay_hand.get_children():
		#overlay_hand.remove_child(c)
		#c.queue_free()
	#
	#var hand = player_hands[target_idx]
	#var temp_nodes = []
	#
	#for i in range(hand.size()):
		#var card = hand[i]
		#var tr = make_card_sprite()
		#set_card_sprite(tr, card.suit, card.rank)
		#var card_idx = i
		#tr.mouse_filter = Control.MOUSE_FILTER_STOP
		#
		#tr.gui_input.connect(func(event: InputEvent):
			#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#for n in temp_nodes:
					#n.modulate = Color.WHITE
				#tr.modulate = Color(1, 0.8, 0)
				#steal_choice = card_idx
				#steal_confirm_button.visible = true
		#)
		#
		#overlay_hand.add_child(tr)
		#temp_nodes.append(tr)
	#
	#steal_confirm_button.visible = false
	#
	#var start_ms = Time.get_ticks_msec()
	#while steal_choice < 0 and (Time.get_ticks_msec() - start_ms) < STEAL_TIMER * 1000:
		#var remaining = STEAL_TIMER - (Time.get_ticks_msec() - start_ms) / 1000.0
		#overlay_timer.text = "Time: %d" % max(0, ceil(remaining))
		#if RELEASE_MODE: await get_tree().create_timer(0.1).timeout
	#
	#if steal_choice < 0:
		#_announce("You didn't steal a card in time!")
	#
	#steal_confirm_button.visible = false
	#steal_overlay.visible = false
	#overlay_container.visible = false

func showdown_phase():
	_announce("Showdown!")
	if RELEASE_MODE: await get_tree().create_timer(1.8).timeout

	
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
		$ChipManager.update_player_pile(winner, player_chips[winner])
		$ChipManager.update_pot(0)
		_announce("%s wins (everyone folded)!" % player_names[winner], 45)
		$SoundManager.play_win()
		return
	
	var results = []
	for i in active_players:
		var all_cards = player_hands[i] + community_cards
		var result = evaluate_best_hand(all_cards)
		results.append({player = i, result = result})
		_announce("%s: %s" % [player_names[i], hand_result_name(result)])
		if RELEASE_MODE: await get_tree().create_timer(1.8).timeout
	
	results.sort_custom(func(a, b): return compare_hands(a.result, b.result) > 0)
	
	var best = results[0]
	var tied = [best]
	for i in range(1, results.size()):
		if compare_hands(results[i].result, best.result) == 0:
			tied.append(results[i])
	
	var share = pot / tied.size()
	for t in tied:
		player_chips[t.player] += share
		$ChipManager.update_player_pile(t.player, player_chips[t.player])
	$ChipManager.update_pot(0)
	
	if best.player == 0:
		_announce("%s win with %s!" % [player_names[best.player], hand_result_name(best.result)], 45)
		$SoundManager.play_win()
	else:
		_announce("%s wins with %s!" % [player_names[best.player], hand_result_name(best.result)], 45)
		$SoundManager.play_win()
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
	
	var player_bankrupt = player_chips[0] <= 0
	if player_bankrupt:
		_announce("You lose!")
		end_label.text = "You're out of chips! Press New Round to restart."
		end_label.visible = true
	
	for i in range(NUM_PLAYERS):
		player_panel[i].bet_label.text = ""
	
	new_round_button.visible = true
	new_round_button.pressed.connect(_on_new_round_pressed)
	await new_round_button.pressed
	if new_round_button.pressed.is_connected(_on_new_round_pressed):
		new_round_button.pressed.disconnect(_on_new_round_pressed)
	
	if player_bankrupt:
		_reset_game()
	
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
		if result.type == Globals.HandType.PAIR:
			name += " (%s)" % Globals.RANK_NAME.get(result.ranks[0], "?")
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
