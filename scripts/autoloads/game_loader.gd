extends Node

signal progress_changed(progress)
signal load_finished

var loading_screen_scene: PackedScene = preload("uid://spxfied5gfdk")
var loaded_resource: PackedScene 
var scene_path: String
var progress: Array = []
var use_sub_thread: bool = true

func _ready() -> void:
	set_process(false)

func load_scene(_scene_path: String) -> void:
	scene_path = _scene_path
	
	var new_load_screen = loading_screen_scene.instantiate()
	get_tree().root.add_child(new_load_screen)
	
	progress_changed.connect(new_load_screen._on_progress_changed)
	load_finished.connect(new_load_screen._on_load_finished)
	
	await new_load_screen.loading_screen_ready
	
	start_load()

func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(scene_path, "", use_sub_thread)
	if state == OK:
		set_process(true)
	else:
		printerr("Failed to start threaded load for: ", scene_path)

func _process(_delta: float) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	if progress.size() > 0:
		progress_changed.emit(progress[0])
	
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			printerr("Loading failed or invalid resource for scene: ", scene_path)
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(loaded_resource)
			load_finished.emit()
