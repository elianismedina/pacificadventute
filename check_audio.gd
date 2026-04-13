extends SceneTree

func _init():
	var master_idx = AudioServer.get_bus_index("Master")
	print("Master Bus Index: ", master_idx)
	print("Master Muted: ", AudioServer.is_bus_mute(master_idx))
	print("Master Volume DB: ", AudioServer.get_bus_volume_db(master_idx))
	quit()
