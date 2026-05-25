extends Control

var game: Node
var difficulty_btns: Array = []

func _ready() -> void:
	game = get_node("/root/Game")
	build_ui()

func build_ui():
	var canvas = $CanvasLayer

	var bg = ColorRect.new()
	bg.offset_right = 1600
	bg.offset_bottom = 800
	bg.color = Color(0.31422675, 0.43944678, 0.14869595, 1)
	canvas.add_child(bg)

	var font = load("res://asset/fonts/VT323-Regular.ttf")
	var bevel = load("res://asset/grey_bevel_normal.png")

	var title_shadow = RichTextLabel.new()
	title_shadow.offset_left = 400
	title_shadow.offset_top = 32
	title_shadow.offset_right = 1200
	title_shadow.offset_bottom = 92
	title_shadow.add_theme_color_override("default_color", Color(0.45291597, 0.22542924, 0.07002995, 1))
	title_shadow.add_theme_font_override("normal_font", font)
	title_shadow.add_theme_font_size_override("normal_font_size", 48)
	title_shadow.bbcode_enabled = true
	title_shadow.text = "[center]Settings[/center]"
	title_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(title_shadow)

	var title = RichTextLabel.new()
	title.offset_left = 400
	title.offset_top = 30
	title.offset_right = 1200
	title.offset_bottom = 90
	title.add_theme_color_override("default_color", Color(1, 0.8682245, 0.7563993, 1))
	title.add_theme_font_override("normal_font", font)
	title.add_theme_font_size_override("normal_font_size", 48)
	title.bbcode_enabled = true
	title.text = "[center]Settings[/center]"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(title)

	var back_btn = Button.new()
	back_btn.z_index = 7
	back_btn.offset_left = 27
	back_btn.offset_top = 25
	back_btn.offset_right = 147
	back_btn.offset_bottom = 70
	back_btn.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	back_btn.add_theme_font_override("font", font)
	back_btn.add_theme_font_size_override("font_size", 28)
	var empty = StyleBoxEmpty.new()
	back_btn.add_theme_stylebox_override("normal", empty)
	back_btn.text = "  Back  "
	back_btn.pressed.connect(_on_back_pressed)
	canvas.add_child(back_btn)

	var back_bevel = NinePatchRect.new()
	back_bevel.z_index = -1
	back_bevel.offset_left = 1
	back_bevel.offset_top = 1
	back_bevel.offset_right = 121
	back_bevel.offset_bottom = 46
	back_bevel.texture = bevel
	back_bevel.patch_margin_left = 4
	back_bevel.patch_margin_top = 4
	back_bevel.patch_margin_right = 4
	back_bevel.patch_margin_bottom = 4
	back_btn.add_child(back_bevel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(500, 160)
	vbox.size = Vector2(600, 500)
	vbox.add_theme_constant_override("separation", 30)
	canvas.add_child(vbox)

	_add_setting_row(vbox, "Discard/Steal Rounds:", _build_discard_toggle())
	_add_setting_row(vbox, "Speed:", _build_speed_buttons())
	_add_setting_row(vbox, "Music:", _build_music_toggle())
	vbox.add_child(_build_difficulty_row())

	_on_difficulty_changed(0)

func _add_setting_row(parent: VBoxContainer, label_text: String, control: Control):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hbox.add_theme_constant_override("separation", 20)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.size = Vector2(250, 40)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_override("font", load("res://asset/fonts/VT323-Regular.ttf"))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(control)

	parent.add_child(hbox)

func _build_discard_toggle() -> Control:
	var btn = CheckButton.new()
	btn.text = "1 Round"
	btn.add_theme_font_override("font", load("res://asset/fonts/VT323-Regular.ttf"))
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.toggled.connect(_on_discard_toggled.bind(btn))
	return btn

func _on_discard_toggled(enabled: bool, btn: CheckButton):
	game.discard_steal_rnds = [1, 2] if enabled else [1]
	btn.text = "2 Rounds" if enabled else "1 Round"

func _build_speed_buttons() -> Control:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var speeds = [0.5, 1.0, 1.5]
	var font = load("res://asset/fonts/VT323-Regular.ttf")
	var bevel = load("res://asset/grey_bevel_normal.png")
	var bevel_hover = load("res://asset/grey_bevel_hover.png")
	var bevel_pressed = load("res://asset/grey_bevel_pressed.png")
	for s in speeds:
		var btn = Button.new()
		btn.z_index = 2
		btn.text = "%.1fx" % s
		btn.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 24)
		var empty_sb = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_sb)
		btn.pressed.connect(_on_speed_pressed.bind(s))
		hbox.add_child(btn)

		var bevel_npr = NinePatchRect.new()
		bevel_npr.z_index = -1
		bevel_npr.offset_right = 80
		bevel_npr.offset_bottom = 40
		bevel_npr.texture = bevel
		bevel_npr.patch_margin_left = 4
		bevel_npr.patch_margin_top = 4
		bevel_npr.patch_margin_right = 4
		bevel_npr.patch_margin_bottom = 4
		btn.add_child(bevel_npr)

		btn.mouse_entered.connect(func():
			bevel_npr.texture = bevel_hover
		)
		btn.mouse_exited.connect(func():
			bevel_npr.texture = bevel
		)
	return hbox

func _on_speed_pressed(val: float):
	game.time_scale = val

func _build_music_toggle() -> Control:
	var btn = CheckButton.new()
	btn.button_pressed = true
	btn.text = "On"
	btn.add_theme_font_override("font", load("res://asset/fonts/VT323-Regular.ttf"))
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.toggled.connect(_on_music_toggled)
	return btn

func _on_music_toggled(enabled: bool):
	Globals.music = enabled

func _build_difficulty_row() -> Control:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hbox.add_theme_constant_override("separation", 20)

	var lbl = Label.new()
	lbl.text = "CPU Difficulty:"
	lbl.size = Vector2(250, 40)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_override("font", load("res://asset/fonts/VT323-Regular.ttf"))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	btn_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var font = load("res://asset/fonts/VT323-Regular.ttf")
	var bevel = load("res://asset/grey_bevel_normal.png")
	var bevel_hover = load("res://asset/grey_bevel_hover.png")
	var bevel_pressed = load("res://asset/grey_bevel_pressed.png")
	var labels = ["Easy", "Medium", "Hard"]
	for idx in 3:
		var btn = Button.new()
		btn.z_index = 3
		btn.text = labels[idx]
		btn.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 24)
		var empty_sb = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_sb)
		btn.pressed.connect(_on_difficulty_changed.bind(idx))
		btn_hbox.add_child(btn)

		var bevel_npr = NinePatchRect.new()
		bevel_npr.z_index = -1
		bevel_npr.offset_right = 80
		bevel_npr.offset_bottom = 40
		bevel_npr.texture = bevel
		bevel_npr.patch_margin_left = 4
		bevel_npr.patch_margin_top = 4
		bevel_npr.patch_margin_right = 4
		bevel_npr.patch_margin_bottom = 4
		btn.add_child(bevel_npr)

		btn.mouse_entered.connect(func():
			bevel_npr.texture = bevel_hover
		)
		btn.mouse_exited.connect(func():
			bevel_npr.texture = bevel
		)
		difficulty_btns.append(btn)
	hbox.add_child(btn_hbox)

	return hbox

func _on_difficulty_changed(idx: int = 0):
	for i in 3:
		var bevel = difficulty_btns[i].get_child(0) as NinePatchRect
		bevel.texture = load("res://asset/grey_bevel_pressed.png") if i == idx else load("res://asset/grey_bevel_normal.png")
	if game and game.has_method("_on_difficulty_changed"):
		game._on_difficulty_changed(idx)

func _show():
	$CanvasLayer.visible = true

func _on_back_pressed():
	$CanvasLayer.visible = false
