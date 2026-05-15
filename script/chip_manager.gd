extends Node

const ATLAS_PATH = "res://asset/Chips/Chips A Outline - Flat 64x72.png"
const CHIP_W = 48
const CHIP_H = 54

var _atlas: Texture2D

const PILE_POS: Array[Vector2] = [
	Vector2(510, 565),
	Vector2(240, 230),
	Vector2(500, 130),
	Vector2(1110, 230),
]

const POT_POS = Vector2(400, 405)

const CR = {
	"TEAL": Vector2i(0, 0),
	"GREY": Vector2i(1, 0),
	"GREEN": Vector2i(2, 0),
	"BLUE": Vector2i(3, 0),
	"DARK_TEAL": Vector2i(4, 0),
}

var _piles: Array[Control] = []
var _pot_container: Control

func _ready():
	_atlas = load(ATLAS_PATH)
	for i in range(4):
		var c = Control.new()
		c.name = (&"Pile%d" % i)
		c.position = PILE_POS[i]
		add_child(c)
		_piles.append(c)
	_pot_container = Control.new()
	_pot_container.name = "PotChips"
	_pot_container.position = POT_POS
	add_child(_pot_container)

func _make_chip_tex(col: int, row: int) -> AtlasTexture:
	var at = AtlasTexture.new()
	at.atlas = _atlas
	at.region = Rect2(col * 64, row * 72, 64, 72)
	return at

func _make_chip(col: int, row: int) -> TextureRect:
	var tr = TextureRect.new()
	tr.texture = _make_chip_tex(col, row)
	tr.size = Vector2(CHIP_W, CHIP_H)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	return tr

func _player_style(idx: int) -> Vector2i:
	var styles = [CR.TEAL, CR.GREY, CR.GREEN, CR.BLUE]
	return styles[idx]

func _build_pile(player_idx: int, chip_count: int):
	var pile = _piles[player_idx]
	for c in pile.get_children():
		pile.remove_child(c)
		c.queue_free()
	var cr = _player_style(player_idx)
	var n = clampi(chip_count / 200 + 1, 2, 7)
	for i in range(n):
		var tr = _make_chip(cr.x, cr.y)
		tr.position = Vector2(0, -i * 5)
		pile.add_child(tr)

func _clear_pot():
	for c in _pot_container.get_children():
		_pot_container.remove_child(c)
		c.queue_free()

func setup_player_pile(player_idx: int, total_chips: int):
	_build_pile(player_idx, total_chips)

func update_player_pile(player_idx: int, total_chips: int):
	_build_pile(player_idx, total_chips)

func update_pot(total_pot: int):
	_clear_pot()
	var count = clampi(total_pot / 10, 2, 48)
	var colors := [CR.TEAL, CR.GREY, CR.GREEN, CR.BLUE]
	for i in range(count):
		var cr = colors[i % colors.size()]
		var tr = _make_chip(cr.x, cr.y)
		var col = i / 8
		var row = i % 8
		var heightPerChip := 5
		var rowSeperation := 60
		tr.position = Vector2(col * rowSeperation, -row * heightPerChip)
		_pot_container.add_child(tr)

func clear_all():
	for i in range(4):
		_build_pile(i, 0)
	_clear_pot()
