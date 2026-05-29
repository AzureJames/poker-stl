extends Control

var game: Node
var difficulty_btns: Array = []

@onready var canvas: CanvasLayer = $CanvasLayer

func _ready() -> void:
	game = get_node("/root/Game")
	difficulty_btns = [%DiffBtn0, %DiffBtn1, %DiffBtn2]

	var bevel_normal = load("res://asset/grey_bevel_normal.png")
	var bevel_hover = load("res://asset/grey_bevel_hover.png")
	for btn in [%Speed0, %Speed1, %Speed2]:
		var npr = btn.get_child(0) as NinePatchRect
		btn.mouse_entered.connect(func(): npr.texture = bevel_hover)
		btn.mouse_exited.connect(func(): npr.texture = bevel_normal)

	for btn in [%DiscardToggle, %MusicToggle]:
		var npr = btn.get_child(0) as NinePatchRect
		btn.set_meta(&"base_texture", npr.texture)
		btn.mouse_entered.connect(func():
			btn.set_meta(&"prev_texture", npr.texture)
			npr.texture = bevel_hover
		)
		btn.mouse_exited.connect(func():
			npr.texture = btn.get_meta(&"base_texture")
		)

	%Speed0.pressed.connect(_on_speed_pressed.bind(0.2))
	%Speed1.pressed.connect(_on_speed_pressed.bind(1.0))
	%Speed2.pressed.connect(_on_speed_pressed.bind(2.0))

	for btn in difficulty_btns:
		btn.pressed.connect(_on_difficulty_changed.bind(difficulty_btns.find(btn)))


func _on_discard_toggled():
	var btn = %DiscardToggle
	var bevel = btn.get_child(0) as NinePatchRect
	var is_two = btn.text == "2 Rounds"
	btn.text = "2 Rounds" if not is_two else "1 Round"
	game.discard_steal_rnds = [1, 2] if not is_two else [1]
	var tex = load("res://asset/grey_bevel_pressed.png") if not is_two else load("res://asset/grey_bevel_normal.png")
	bevel.texture = tex
	btn.set_meta(&"base_texture", tex)

func _on_speed_pressed(val: float):
	game.time_scale = val

func _on_music_toggled():
	var btn = %MusicToggle
	var bevel = btn.get_child(0) as NinePatchRect
	var is_on = btn.text == " On "
	btn.text = " Off " if is_on else " On "
	var tex = load("res://asset/grey_bevel_pressed.png") if is_on else load("res://asset/grey_bevel_normal.png")
	bevel.texture = tex
	btn.set_meta(&"base_texture", tex)
	if is_on: %Music.stop()
	else: %Music.play()

func _on_difficulty_changed(idx: int = 0):
	for i in 3:
		var bevel = difficulty_btns[i].get_child(0) as NinePatchRect
		bevel.texture = load("res://asset/grey_bevel_pressed.png") if i == idx else load("res://asset/grey_bevel_normal.png")
	if game and game.has_method("_on_difficulty_changed"):
		game._on_difficulty_changed(idx)

func _show():
	canvas.visible = true

func _on_back_pressed():
	canvas.visible = false
