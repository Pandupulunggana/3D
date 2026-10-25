extends Node


const SAVE_PATH = "user://savegame.json"


func save_game() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("Save gagal: Player tidak ditemukan")
		return

	var data := {
		"player": player.get_save_data()
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save gagal: " + str(FileAccess.get_open_error()))
		return

	file.store_string(JSON.stringify(data, "\t"))
	print("Game tersimpan di ", ProjectSettings.globalize_path(SAVE_PATH))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("Load gagal: belum ada file save")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Load gagal: " + str(FileAccess.get_open_error()))
		return

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Load gagal: file save rusak")
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("Load gagal: Player tidak ditemukan")
		return

	player.load_save_data(data["player"])
	print("Game berhasil di-load")
