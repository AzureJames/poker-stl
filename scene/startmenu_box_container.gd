extends HBoxContainer


func _on_button_pressed() -> void:
	get_parent().get_parent().get_parent().call_deferred('start_game')
	%Music.stream = load("res://asset/Audio/poker4.mp3")
	%Music.volume_db = 0.0
	%Music.play()
	get_parent().get_parent().visible = !get_parent().get_parent().visible


func _on_button_3_pressed() -> void:
	get_tree().quit()


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/rules.tscn")
