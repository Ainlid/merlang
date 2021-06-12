extends Node2D

export var tempo = 120.0
var interval = 1.0
onready var timer_beat = $timer_beat

var samples = []
onready var file_dialog = $interface/file_dialog

onready var play_button = $interface/play_button
var playing = false

var rng

var grain = preload("res://grain/grain.tscn")
export var density = 0.5
export var size_min = 1
export var size_max = 16
export var pitches = [-6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0]

func _ready():
	rng = RandomNumberGenerator.new()

	interval = 60.0 / tempo
	timer_beat.wait_time = interval

	play_button.disabled = true

func _load_pressed():
	_play_stop()
	file_dialog.popup()

func _files_selected(paths):
	var file = File.new()
	for n in paths.size():
		if file.file_exists(paths[n]):
			file.open(paths[n], file.READ)
			var buffer = file.get_buffer(file.get_len())
			var new_sample = AudioStreamSample.new()
			new_sample.format = AudioStreamSample.FORMAT_16_BITS      
			new_sample.data = buffer
			new_sample.stereo = true
			new_sample.mix_rate = 44100
			samples.append(new_sample)
			file.close()
	play_button.disabled = false

func _play_pressed():
	if !playing:
		_play_start()
	else:
		_play_stop()

func _play_start():
	timer_beat.start()
	playing = true
	play_button.text = "Stop"

func _play_stop():
	timer_beat.stop()
	playing = false
	play_button.text = "Play"

func _spawn_grain():
	var spawn_chance = rng.randf()
	if spawn_chance < density:
		var new_grain = grain.instance()
		add_child(new_grain)
		var sample_id = rng.randi_range(0, samples.size() - 1)
		var curr_sample = samples[sample_id]
		var new_offset = rng.randf_range(0.0, curr_sample.get_length())
		var new_pitch = rng.randi_range(0, pitches.size())
		new_pitch = pow(2.0, new_pitch / 12.0)
		var new_size = interval / 4.0 * rng.randi_range(size_min, size_max)
		new_grain._grain_play(curr_sample, new_offset, new_pitch, new_size)
