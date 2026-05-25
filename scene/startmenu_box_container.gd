extends HBoxContainer


func _on_button_pressed() -> void:
	if Globals.playing == false:
		get_parent().get_parent().get_parent().call_deferred('start_game')
		%Music.stream = load("res://asset/Audio/poker4.mp3")
		%Music.volume_db = 0.0
		if Globals.music: %Music.play()
	get_parent().get_parent().visible = !get_parent().get_parent().visible


func _on_button_3_pressed() -> void:
	get_tree().quit()


func _on_button_2_pressed() -> void:
	%Rules._show()


func _on_button_4_pressed() -> void:
	%Settings._show()
