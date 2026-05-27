extends Node

enum Suit {
	CLUBS = 0,
	DIAMONDS = 1,
	HEARTS = 2,
	SPADES = 3
}

var playing := false
var sudden_death := false

const SUIT_SYMBOL = {
	Suit.CLUBS: "♣",
	Suit.DIAMONDS: "♦",
	Suit.HEARTS: "♥",
	Suit.SPADES: "♠"
}

const SUIT_NAME = {
	Suit.CLUBS: "Clubs",
	Suit.DIAMONDS: "Diamonds",
	Suit.HEARTS: "Hearts",
	Suit.SPADES: "Spades"
}

const RANK_NAME = {
	2: "2", 3: "3", 4: "4", 5: "5", 6: "6", 7: "7", 8: "8",
	9: "9", 10: "10", 11: "J", 12: "Q", 13: "K", 14: "A"
}

enum HandType {
	HIGH_CARD,
	PAIR,
	TWO_PAIR,
	THREE_OF_KIND,
	STRAIGHT,
	FLUSH,
	FULL_HOUSE,
	FOUR_OF_KIND,
	STRAIGHT_FLUSH,
	ROYAL_FLUSH
}

const HAND_NAME = {
	HandType.HIGH_CARD: "High Card",
	HandType.PAIR: "Pair",
	HandType.TWO_PAIR: "Two Pair",
	HandType.THREE_OF_KIND: "Three of a Kind",
	HandType.STRAIGHT: "Straight",
	HandType.FLUSH: "Flush",
	HandType.FULL_HOUSE: "Full House",
	HandType.FOUR_OF_KIND: "Four of a Kind",
	HandType.STRAIGHT_FLUSH: "Straight Flush",
	HandType.ROYAL_FLUSH: "Royal Flush"
}

const CARD_W = 88
const CARD_H = 124
const SHEET_COLS = 5

var suit_atlases: Dictionary = {}
var card_back: Texture2D
var grey_bevel_normal: Texture2D
var grey_bevel_hover: Texture2D
var grey_bevel_pressed: Texture2D
var ui_font: FontFile

func _ready():
	load_textures()

func load_textures():
	for s in [Suit.CLUBS, Suit.DIAMONDS, Suit.HEARTS, Suit.SPADES]:
		var path = "res://asset/Cards/%s - Top Down 88x124.png" % SUIT_NAME[s]
		suit_atlases[s] = load(path)
	card_back = load("res://asset/Cards/Back - Top Down 88x124.png")
	grey_bevel_normal = load("res://asset/grey_bevel_normal.png")
	grey_bevel_hover = load("res://asset/grey_bevel_hover.png")
	grey_bevel_pressed = load("res://asset/grey_bevel_pressed.png")
	ui_font = load("res://asset/fonts/VT323-Regular.ttf")

func rank_to_sheet_idx(rank: int) -> int:
	if rank == 14:
		return 0
	return rank - 1

func get_card_region(suit: int, rank: int) -> Rect2:
	var idx = rank_to_sheet_idx(rank)
	var col = idx % SHEET_COLS
	var row = idx / SHEET_COLS
	return Rect2(col * CARD_W, row * CARD_H, CARD_W, CARD_H)

func make_card_texture(suit: int, rank: int) -> AtlasTexture:
	var at = AtlasTexture.new()
	at.atlas = suit_atlases[suit]
	at.region = get_card_region(suit, rank)
	return at

func make_card_back_texture() -> AtlasTexture:
	var at = AtlasTexture.new()
	at.atlas = card_back
	at.region = Rect2(0, 0, CARD_W, CARD_H)
	return at

func card_name(suit: int, rank: int) -> String:
	return "%s%s" % [RANK_NAME[rank], SUIT_SYMBOL[suit]]

func make_deck() -> Array:
	var deck = []
	for suit in range(4):
		for rank in range(2, 15):
			deck.append({suit = suit, rank = rank})
	deck.shuffle()
	return deck
