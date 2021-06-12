extends Node

onready var audio = $audio
onready var timer_delete = $timer_delete

func _grain_play(sample, offset, pitch, size):
	audio.stream = sample
	audio.pitch_scale = pitch
	audio.play(offset)
	timer_delete.wait_time = size
	timer_delete.start()

func _delete():
	audio.stop()
	queue_free()
