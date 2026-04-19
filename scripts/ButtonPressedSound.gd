class_name ButtonPressedSound
extends AudioStreamPlayer

func play_and_await() -> void:
	play()
	await finished
