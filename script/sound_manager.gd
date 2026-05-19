extends Node

const PLAYER_COUNT = 6

var _players: Array[AudioStreamPlayer] = []

var _card_slide: Array[AudioStream] = []
var _card_place: Array[AudioStream] = []
var _card_shove: Array[AudioStream] = []
var _card_shuffle: Array[AudioStream] = []
var _card_fan: Array[AudioStream] = []
var _pack_open: Array[AudioStream] = []
var _pack_take_out: Array[AudioStream] = []
var _chip_lay: Array[AudioStream] = []
var _chips_collide: Array[AudioStream] = []
var _chips_handle: Array[AudioStream] = []
var _chips_stack: Array[AudioStream] = []
var _win: Array[AudioStream] = []

func _ready():
	for i in range(PLAYER_COUNT):
		var p = AudioStreamPlayer.new()
		p.name = ("&AudioPlayer%d" % i)
		add_child(p)
		_players.append(p)
	_load_sounds()

func _load_group(base: String, count: int) -> Array[AudioStream]:
	var arr: Array[AudioStream] = []
	for i in range(1, count + 1):
		var path = "%s-%d.ogg" % [base, i]
		arr.append(load(path))
	return arr

func _load_sounds():
	_card_slide = _load_group("res://asset/Audio/card-fan", 2)
	_card_place = _load_group("res://asset/Audio/card-place", 4)
	_card_shove = _load_group("res://asset/Audio/card-shove", 4)
	_card_shuffle = [load("res://asset/Audio/shuffleandbridge.wav")]
	_card_fan = _load_group("res://asset/Audio/card-fan", 2)
	_pack_open = _load_group("res://asset/Audio/cards-pack-open", 2)
	_pack_take_out = _load_group("res://asset/Audio/cards-pack-take-out", 2)
	_chip_lay = _load_group("res://asset/Audio/chip-lay", 3)
	_chips_collide = _load_group("res://asset/Audio/chips-collide", 4)
	_chips_handle = _load_group("res://asset/Audio/chips-handle", 6)
	_chips_stack = _load_group("res://asset/Audio/chips-stack", 6)
	_win = [load("res://asset/Audio/win.wav")] 

func _get_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

func _play(sounds: Array[AudioStream], vol_db: float = 0.0):
	if sounds.is_empty():
		return
	var p = _get_player()
	p.stream = sounds[randi() % sounds.size()]
	p.volume_db = vol_db
	p.play()
	
func play_win(vol_db: float = 0.0):
	_play(_win, 5)

func play_card_slide(vol_db: float = 0.0):
	_play(_card_slide, vol_db)

func play_card_place(vol_db: float = 0.0):
	_play(_card_place, vol_db)

func play_card_shove(vol_db: float = 0.0):
	_play(_card_shove, vol_db)

func play_card_shuffle(vol_db: float = 0.0):
	_play(_card_shuffle, vol_db)

func play_card_fan(vol_db: float = 0.0):
	_play(_card_fan, vol_db)

func play_pack_open(vol_db: float = 0.0):
	_play(_pack_open, vol_db)

func play_pack_take_out(vol_db: float = 0.0):
	_play(_pack_take_out, vol_db)

func play_chip_lay(vol_db: float = 0.0):
	_play(_chip_lay, vol_db)

func play_chips_collide(vol_db: float = 0.0):
	_play(_chips_collide, vol_db)

func play_chips_handle(vol_db: float = 0.0):
	_play(_chips_handle, vol_db)

func play_chips_stack(vol_db: float = 0.0):
	_play(_chips_stack, vol_db)
