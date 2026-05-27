extends Node

const ATLAS_PATH = "res://asset/Chips/Chips A Outline - Flat 64x72.png"
const CHIP_W = 48
const CHIP_H = 54

var _atlas: Texture2D

const PILE_POS: Array[Vector2] = [
	Vector2(98, 525),
	Vector2(68, 230),
	Vector2(350, 130),
	Vector2(877, 230),
]

const POT_POS = Vector2(360, 405)

const CR = {
	"TEAL": Vector2i(0, 0),
	"GREY": Vector2i(1, 0),
	"GREEN": Vector2i(2, 0),
	"BLUE": Vector2i(3, 0),
	"DARK_TEAL": Vector2i(4, 0),
}

var _piles: Array[Control] = []
var _pot_container: Control
var _pot_contributions: Array[int] = [0, 0, 0, 0]

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
	var styles = [CR.GREY, CR.TEAL, CR.GREEN, CR.BLUE]
	return styles[idx]

func _build_pile(player_idx: int, chip_count: int):
	var pile = _piles[player_idx]
	for c in pile.get_children():
		pile.remove_child(c)
		c.queue_free()
	var cr = _player_style(player_idx)
	var n = clampi(chip_count / 100 + 1, 2, 17)
	for i in range(n):
		var trc = _make_chip(cr.x, cr.y)
		trc.position = Vector2(0, -i * 5)
		pile.add_child(trc)

func _clear_pot():
	for c in _pot_container.get_children():
		_pot_container.remove_child(c)
		c.queue_free()

func setup_player_pile(player_idx: int, total_chips: int):
	_build_pile(player_idx, total_chips)

func update_player_pile(player_idx: int, total_chips: int):
	_build_pile(player_idx, total_chips)

func add_pot_contribution(player_idx: int, amount: int):
	_pot_contributions[player_idx] += amount

func update_pot(total_pot: int):
	_clear_pot()
	var count = max(2, total_pot / 10)
	var total_contrib = 0
	for c in _pot_contributions:
		total_contrib += c
	if total_contrib == 0:
		total_contrib = 1
	var chip_idx := 0
	for p_idx in range(4):
		var player_chip_count = int(count * _pot_contributions[p_idx] / total_contrib)
		for _i in range(player_chip_count):
			if chip_idx >= count:
				break
			var cr = _player_style(p_idx)
			var trpot = _make_chip(cr.x, cr.y)
			var pile = chip_idx / 8
			var chip_in_pile = chip_idx % 8
			var pile_col = pile % 6
			var pile_row = pile / 6
			trpot.position = Vector2(pile_col * 53, pile_row * 50 - chip_in_pile * 5)
			_pot_container.add_child(trpot)
			chip_idx += 1
	while chip_idx < count:
		var cr = CR.DARK_TEAL
		var trp = _make_chip(cr.x, cr.y)
		var pile = chip_idx / 8
		var chip_in_pile = chip_idx % 8
		var pile_col = pile % 6
		var pile_row = pile / 6
		trp.position = Vector2(pile_col * 53, pile_row * 50 - chip_in_pile * 5)
		_pot_container.add_child(trp)
		chip_idx += 1

func clear_all():
	_pot_contributions = [0, 0, 0, 0]
	for i in range(4):
		_build_pile(i, 0)
	_clear_pot()
