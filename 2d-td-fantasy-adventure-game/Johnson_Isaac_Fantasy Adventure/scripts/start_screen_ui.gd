extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Background_Music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://Johnson_Isaac_Fantasy Adventure/scenes/levels/MainGameLevel.tscn"
	)
	$Button_Sound.play()


func _on_quit_game_button_pressed() -> void:
	$QuitConfirmationDialog.popup_centered()
	$Button_Sound.play()

func _on_quit_confirmation_dialog_confirmed() -> void:
	get_tree().quit()
