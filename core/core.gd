extends Node2D

var tempo = 120.0
var interval = 1.0
onready var timer_beat = $timer_beat

var samples = []
onready var file_dialog = $interface/file_dialog

onready var play_button = $interface/play_button
var playing = false

var rng

var grain = preload("res://grain/grain.tscn")
var density = 50.0
var size_min = 1
var size_max = 16
var pitch = 0
var offset_rounding = 16.0

var tempo_random = 0.0
var density_random = 0.0
var pitch_random = 0.0

onready var tempo_label = $interface/tempo_label
onready var tempo_slider = $interface/tempo_slider

onready var density_label = $interface/density_label
onready var density_slider = $interface/density_slider

onready var pitch_label = $interface/pitch_label
onready var pitch_slider = $interface/pitch_slider

onready var size_label = $interface/size_label
onready var size_slider = $interface/size_slider

onready var tempo_random_label = $interface/tempo_random_label
onready var tempo_random_slider = $interface/tempo_random_slider

onready var density_random_label = $interface/density_random_label
onready var density_random_slider = $interface/density_random_slider

onready var pitch_random_label = $interface/pitch_random_label
onready var pitch_random_slider = $interface/pitch_random_slider

func _ready():
	rng = RandomNumberGenerator.new()

	_set_tempo(120.0)
	_set_density(50.0)
	_set_pitch(0)

	_set_tempo_random(0.0)
	_set_density_random(0.0)
	_set_pitch_random(0.0)

	play_button.disabled = true

func _set_tempo(value):
	interval = 60.0 / tempo
	timer_beat.wait_time = interval
	tempo_slider.value = value
	tempo_label.text = "Tempo: " + str(value) + " BPM"

func _set_density(value):
	density = value
	density_slider.value = value
	density_label.text = "Density: " + str(value) + "%"

func _set_pitch(value):
	pitch = value
	pitch_slider.value = value
	pitch_label.text = "Pitch: " + str(value) + " st"

func _set_tempo_random(value):
	tempo_random = value
	tempo_random_label.text = "Randomization: " + str(value) + "%"

func _set_density_random(value):
	density_random = value
	density_random_label.text = "Randomization: " + str(value) + "%"

func _set_pitch_random(value):
	pitch_random = value
	pitch_random_label.text = "Randomization: " + str(value) + "%"

func _load_pressed():
	_play_stop()
	samples = []
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

func _tick():
	_randomize_params()
	_spawn_grain()

func _randomize_params():
	var tempo_rand_chance = rng.randf() * 100.0
	if tempo_rand_chance < tempo_random:
		var new_tempo = rng.randi_range(50, 200)
		_set_tempo(new_tempo)

	var density_rand_chance = rng.randf() * 100.0
	if density_rand_chance < density_random:
		var new_density = round(rng.randf() * 100.0)
		_set_density(new_density)

	var pitch_rand_chance = rng.randf() * 100.0
	if pitch_rand_chance < pitch_random:
		_set_pitch(rng.randi_range(-6, 6))

func _spawn_grain():
	var spawn_chance = rng.randf() * 100.0
	if spawn_chance < density:
		var new_grain = grain.instance()
		add_child(new_grain)
		var sample_id = rng.randi_range(0, samples.size() - 1)
		var curr_sample = samples[sample_id]
		var new_offset = rng.randf_range(0.0, curr_sample.get_length())
		new_offset = round(new_offset * offset_rounding) / offset_rounding
		var new_pitch = pitch
		new_pitch = pow(2.0, new_pitch / 12.0)
		var new_size = interval / 4.0 * rng.randi_range(size_min, size_max)
		new_grain._grain_play(curr_sample, new_offset, new_pitch, new_size)
