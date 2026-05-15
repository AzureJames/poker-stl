extends HBoxContainer


func _on_button_pressed() -> void:
	get_parent().get_parent().get_parent().call_deferred('start_game')
	get_parent().get_parent().visible = !get_parent().get_parent().visible


func _on_button_3_pressed() -> void:
	get_tree().quit()
