extends Control


func _on_back_pressed() -> void:
	$CanvasLayer.visible = false
func _show():
	$CanvasLayer.visible = true
