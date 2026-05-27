extends Node

var pot_label: Label
var message_label: Label
var timer_label: Label
var stealtimer_label: Label
var action_bar: Control
var steal_overlay: ColorRect
var overlay_container: VBoxContainer
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
var poker_hands_image: TextureRect
var poker_hands_toggle: Button

var player_panel: Array = []
var player_hand_nodes: Array = []
var community_nodes: Array = []

var difficulty_label: Label

func build_ui():
	var game = get_parent()
	var theme = Theme.new()
	theme.default_font = Globals.ui_font
	game.theme = theme

	var bg = ColorRect.new()
	bg.color = Color("482c1c")
	bg.size = game.get_viewport_rect().size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(bg)

	var table = TextureRect.new()
	table.texture = load("res://asset/felt_green.jpg")
	table.stretch_mode = TextureRect.STRETCH_SCALE
	table.size = Vector2(3500,1000)
	table.position = Vector2(40,40)
	table.scale = Vector2(.33,.33)
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.modulate = Color(0.65, 1.0, 0.65)
	game.add_child(table)

	pot_label = Label.new()
	pot_label.text = "Pot: 0"
	pot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pot_label.add_theme_font_size_override("font_size", 26)
	pot_label.add_theme_color_override("font_color", Color.WHITE)
	pot_label.position = Vector2(375, 220)
	pot_label.size = Vector2(140, 40)
	pot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(pot_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.position = Vector2(273, 275)
	message_label.size = Vector2(350, 40)
	message_label.z_index = 9
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(message_label)

	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color", Color.ORANGE)
	timer_label.position = Vector2(378, 410)
	timer_label.size = Vector2(140, 30)
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(timer_label)

	var comm_bg = ColorRect.new()
	comm_bg.color = Color(0.0, 0.0, 0.0, 0.169)
	comm_bg.position = Vector2(657, 300)
	comm_bg.size = Vector2(200, 140)
	comm_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(comm_bg)

	community_nodes = []
	for i in range(2):
		var card = make_card_sprite()
		card.visible = false
		game.add_child(card)
		community_nodes.append(card)

	var ab_bg = NinePatchRect.new()
	ab_bg.texture = Globals.grey_bevel_normal
	ab_bg.patch_margin_left = 4
	ab_bg.patch_margin_top = 4
	ab_bg.patch_margin_right = 4
	ab_bg.patch_margin_bottom = 4
	ab_bg.position = Vector2(25, 630)
	ab_bg.size = Vector2(400, 100)
	game.add_child(ab_bg)

	action_bar = Control.new()
	action_bar.position = Vector2(32, 640)
	action_bar.size = Vector2(602, 80)
	action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(action_bar)

	var btn_x = 0
	fold_button = make_button("Fold", Vector2(btn_x, 0), "Quit hand")
	action_bar.add_child(fold_button)
	btn_x += 130

	checkcall_button = make_button("Check", Vector2(btn_x, 0), "Call: Match bet. Check: pass turn")
	action_bar.add_child(checkcall_button)
	btn_x += 130

	raise_button = make_button("Raise", Vector2(btn_x, 0), "Bet more")
	action_bar.add_child(raise_button)
	btn_x += 130

	allin_button = make_button("All In", Vector2(btn_x, 0),"")

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
	bet_slider.value = 50
	bet_slider.value_changed.connect(_on_bet_slider_changed)
	_style_slider(bet_slider)
	action_bar.add_child(bet_slider)

	bet_value_label = Label.new()
	bet_value_label.position = Vector2(370, 40)
	bet_value_label.size = Vector2(80, 40)
	bet_value_label.add_theme_font_size_override("font_size", 20)
	bet_value_label.add_theme_color_override("font_color", Color.BLACK)
	bet_value_label.text = "50"
	bet_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_bar.add_child(bet_value_label)

	discard_button = make_button("Discard Selected", Vector2(0, 40), "Select cards first!")
	discard_button.visible = false
	action_bar.add_child(discard_button)

	for i in range(get_parent().NUM_PLAYERS):
		var panel = VBoxContainer.new()
		panel.position = get_parent().PLAYER_POSITIONS[i]
		panel.size = Vector2(210, 180)
		panel.add_theme_constant_override("separation", 2)
		game.add_child(panel)

		var name_label = Label.new()
		name_label.text = game.player_names[i]
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		if i != 0:
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)

		var chip_label = Label.new()
		chip_label.text = "Chips: %d" % get_parent().STARTING_CHIPS
		chip_label.add_theme_font_size_override("font_size", 20)
		chip_label.add_theme_color_override("font_color", Color.YELLOW)
		if i != 0:
			chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(chip_label)

		var hand_container = HBoxContainer.new()
		hand_container.add_theme_constant_override("separation", get_parent().CARD_GAP)
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
	info_label.position = Vector2(140, 470)
	info_label.size = Vector2(616, 80)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(info_label)

	end_label = Label.new()
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 28)
	end_label.add_theme_color_override("font_color", Color.GOLD)
	end_label.position = Vector2(210, 200)
	end_label.size = Vector2(476, 200)
	end_label.z_index = 10
	end_label.visible = false
	end_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(end_label)

	new_round_button = make_button("New Round", Vector2(130, 40),"")
	new_round_button.visible = false
	action_bar.add_child(new_round_button)

	deal_button = make_button("Deal", Vector2(260, 40),"")
	deal_button.visible = false
	action_bar.add_child(deal_button)

	var steal_layer = CanvasLayer.new()
	steal_layer.layer = 1
	steal_layer.name = "StealLayer"
	game.add_child(steal_layer)

	steal_overlay = ColorRect.new()
	steal_overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	steal_overlay.size = game.get_viewport_rect().size
	steal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	steal_overlay.visible = false
	steal_layer.add_child(steal_overlay)

	overlay_container = VBoxContainer.new()
	overlay_container.position = Vector2(238, 100)
	overlay_container.size = Vector2(420, 300)
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

	steal_confirm_button = make_button("Confirm Steal", Vector2(0, 0),"")
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
	stealtimer_label.position = Vector2(378, 340)
	stealtimer_label.size = Vector2(140, 30)
	stealtimer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#game.add_child(stealtimer_label)

	var history_bg = NinePatchRect.new()
	history_bg.texture = Globals.grey_bevel_normal
	history_bg.patch_margin_left = 4
	history_bg.patch_margin_top = 4
	history_bg.patch_margin_right = 4
	history_bg.patch_margin_bottom = 4
	history_bg.position = Vector2(854, 550)
	history_bg.size = Vector2(252, 250)
	history_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(history_bg)

	history_container = VBoxContainer.new()
	history_container.position = Vector2(858, 556)
	history_container.size = Vector2(244, 238)
	history_container.add_theme_constant_override("separation", 2)
	history_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(history_container)

	poker_hands_image = TextureRect.new()
	poker_hands_image.texture = load("res://asset/Poker-Hands.png")
	poker_hands_image.stretch_mode = TextureRect.StretchMode.STRETCH_TILE
	poker_hands_image.scale = Vector2(.42,.42)
	poker_hands_image.position = Vector2(525, 50)
	poker_hands_image.size = Vector2(210, 500)
	poker_hands_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poker_hands_image.visible = false
	poker_hands_image.z_index = 5
	game.add_child(poker_hands_image)

	poker_hands_toggle = make_button("Hand Ranking", Vector2(1029, 10),"")
	poker_hands_toggle.pressed.connect(_toggle_poker_hands)
	game.add_child(poker_hands_toggle)

	game.move_child(action_bar, game.get_child_count() - 1)

func _toggle_poker_hands():
	poker_hands_image.visible = not poker_hands_image.visible

func announce(msg: String, _scale = null):
	if _scale != null: message_label.add_theme_font_size_override("font_size", _scale)
	else: message_label.add_theme_font_size_override("font_size", 22)
	message_label.text = msg
	if msg != "":
		add_to_history(msg)

func announce_quiet(msg: String):
	message_label.text = msg

func add_to_history(msg: String):
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

func _on_bet_slider_changed(value: float):
	bet_value_label.text = str(int(value))

func _style_slider(slider: HSlider):
	var slide_sb = StyleBoxTexture.new()
	slide_sb.texture = Globals.grey_bevel_normal
	slide_sb.texture_margin_left = 4
	slide_sb.texture_margin_top = 4
	slide_sb.texture_margin_right = 4
	slide_sb.texture_margin_bottom = 4

	var slide_hover = StyleBoxTexture.new()
	slide_hover.texture = Globals.grey_bevel_hover
	slide_hover.texture_margin_left = 4
	slide_hover.texture_margin_top = 4
	slide_hover.texture_margin_right = 4
	slide_hover.texture_margin_bottom = 4

	var fill_sb = StyleBoxTexture.new()
	fill_sb.texture = Globals.grey_bevel_pressed
	fill_sb.texture_margin_left = 4
	fill_sb.texture_margin_top = 4
	fill_sb.texture_margin_right = 4
	fill_sb.texture_margin_bottom = 4

	slider.add_theme_stylebox_override("slide", slide_sb)
	slider.add_theme_stylebox_override("grabber_area", fill_sb)
	slider.add_theme_icon_override("grabber", Globals.grey_bevel_normal)
	slider.add_theme_icon_override("grabber_highlight", Globals.grey_bevel_hover)
	slider.add_theme_constant_override("center_grabber", 0)

	slider.mouse_entered.connect(func():
		slider.add_theme_stylebox_override("slide", slide_hover)
	)
	slider.mouse_exited.connect(func():
		slider.add_theme_stylebox_override("slide", slide_sb)
	)

func make_button(text: String, pos: Vector2, txt: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(110, 40)
	if txt != "": btn.tooltip_text = txt

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
	var trt = TextureRect.new()
	trt.size = Vector2(Globals.CARD_W, Globals.CARD_H)
	trt.custom_minimum_size = Vector2(Globals.CARD_W, Globals.CARD_H)
	trt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trt.stretch_mode = TextureRect.STRETCH_SCALE
	trt.mouse_filter = Control.MOUSE_FILTER_STOP
	return trt

func make_card_back_sprite() -> TextureRect:
	var trs = make_card_sprite()
	trs.texture = Globals.make_card_back_texture()
	return trs

func set_card_sprite(tr: TextureRect, suit: int, rank: int):
	tr.texture = Globals.make_card_texture(suit, rank)

func clear_hand_display(player_idx: int):
	var container = player_panel[player_idx].hand_container
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()
	player_hand_nodes[player_idx].clear()

func update_hand_display(player_idx: int, face_up: bool = false):
	var game = get_parent()
	var container = player_panel[player_idx].hand_container
	clear_hand_display(player_idx)
	var hand = game.player_hands[player_idx]
	var nodes = []
	for i in range(hand.size()):
		var card = hand[i]
		var tr: TextureRect
		if game.player_is_human[player_idx] or face_up:
			tr = make_card_sprite()
			set_card_sprite(tr, card.suit, card.rank)
		else:
			tr = make_card_back_sprite()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(tr)
		nodes.append(tr)
	player_hand_nodes[player_idx] = nodes
	if game.player_folded[player_idx]:
		for node in nodes:
			node.modulate = Color(0.5, 0.5, 0.5, 0.5)

func update_chip_labels():
	var game = get_parent()
	for i in range(get_parent().NUM_PLAYERS):
		player_panel[i].chip_label.text = "Chips: %d" % game.player_chips[i]
		if game.player_chips[i] <= 0:
			player_panel[i].name_label.add_theme_color_override("font_color", Color.DIM_GRAY)

func update_all_displays():
	for i in range(get_parent().NUM_PLAYERS):
		update_hand_display(i, false)

func show_action_buttons(show: bool):
	fold_button.visible = show
	checkcall_button.visible = show
	raise_button.visible = show
	allin_button.visible = show
	bet_amt_label.visible = show
	bet_slider.visible = show
	bet_value_label.visible = show

func show_steal_ui(target_idx: int):
	var game = get_parent()
	steal_overlay.visible = true
	overlay_container.visible = true
	game.steal_choice = -1

	left_player_label.text = "Steal a card from %s!" % game.player_names[target_idx]

	for c in overlay_hand.get_children():
		overlay_hand.remove_child(c)
		c.queue_free()

	var hand = game.player_hands[target_idx]
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
				game.steal_choice = card_idx
				steal_confirm_button.visible = true
		)

		overlay_hand.add_child(tr)
		temp_nodes.append(tr)

	steal_confirm_button.visible = false

	stealtimer_label.text = "Time: %d" % get_parent().STEAL_TIMER
	overlay_timer.text = "Time: %d" % get_parent().STEAL_TIMER

	var elapsed = 0.0
	while game.steal_choice < 0 and elapsed < get_parent().STEAL_TIMER:
		var remaining = get_parent().STEAL_TIMER - elapsed
		stealtimer_label.text = "Time: %d" % ceil(remaining)
		overlay_timer.text = "Time: %d" % ceil(remaining)
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1

	if game.steal_choice < 0:
		game.steal_choice = 0
		announce("Time's up! You steal %s's first card." % game.player_names[target_idx])
	else:
		await steal_confirm_button.pressed

	steal_confirm_button.visible = false
	steal_overlay.visible = false
	overlay_container.visible = false

func hide_steal_ui():
	stealtimer_label.visible = false
	steal_overlay.visible = false
	overlay_container.visible = false

func animate_new_cards(player_idx: int, count: int):
	if count <= 0:
		return
	var game = get_parent()
	var center_pos = Vector2(441, 260)
	var panel = player_panel[player_idx].panel
	var target = panel.position + panel.size * 0.5
	var anim_cards = []
	for i in range(count):
		var tr = make_card_back_sprite()
		tr.position = center_pos - Vector2(Globals.CARD_W * 0.5, Globals.CARD_H * 0.5)
		game.add_child(tr)
		anim_cards.append(tr)
		var tween = create_tween()
		tween.tween_property(tr, "position", target - Vector2(Globals.CARD_W * 0.5, Globals.CARD_H * 0.5), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		game.get_node("SoundManager").play_card_flip()
		await get_tree().create_timer(0.14 * game.time_scale).timeout
	await get_tree().create_timer(0.4 * game.time_scale).timeout
	for tr in anim_cards:
		game.remove_child(tr)
		tr.queue_free()

func set_community_card(idx: int, suit: int, rank: int, pos: Vector2):
	if idx >= 0 and idx < community_nodes.size():
		set_card_sprite(community_nodes[idx], suit, rank)
		community_nodes[idx].position = pos
		community_nodes[idx].visible = true
