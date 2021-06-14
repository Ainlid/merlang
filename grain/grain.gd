extends Node

var sample
var pitch = 1.0
var volume = 0.0
var offset = 0.0
var size = 1.0

onready var audio = $audio
onready var timer_delete = $timer_delete

func _grain_play():
	audio.stream = sample
	audio.pitch_scale = pitch
	audio.volume_db = volume
	audio.play(offset)
	timer_delete.wait_time = size
	timer_delete.start()

func _delete():
	audio.stop()
	queue_free()
