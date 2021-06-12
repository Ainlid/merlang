extends Node2D

var tempo = 120.0
var interval = 1.0
onready var timer_beat = $timer_beat

var samples = []
onready var file_dialog = $interface/file_dialog

onready var play_button = $interface/play_button
var playing = false

var rng
var rng_seed

var grain = preload("res://grain/grain.tscn")
var density = 50.0
var size_min = 1
var size_max = 4
var pitch = 0

var use_rounding = false
var rounding = 16.0

var tempo_random = 0.0
var density_random = 0.0
var pitch_random = 0.0

onready var tempo_label = $interface/tempo_label
onready var tempo_slider = $interface/tempo_slider

onready var density_label = $interface/density_label
onready var density_slider = $interface/density_slider

onready var pitch_label = $interface/pitch_label
onready var pitch_slider = $interface/pitch_slider

onready var rounding_label = $interface/rounding_label
onready var rounding_slider = $interface/rounding_slider

onready var tempo_random_label = $interface/tempo_random_label
onready var tempo_random_slider = $interface/tempo_random_slider

onready var density_random_label = $interface/density_random_label
onready var density_random_slider = $interface/density_random_slider

onready var pitch_random_label = $interface/pitch_random_label
onready var pitch_random_slider = $interface/pitch_random_slider

onready var seed_box = $interface/seed_box

onready var audio_record = $audio_record
onready var record_button = $interface/record_button
onready var save_path_label = $interface/save_path_label

var effect
var recording

func _ready():
	randomize()
	rng = RandomNumberGenerator.new()

	_set_tempo(120.0)
	_set_density(50.0)
	_set_pitch(0)

	_set_tempo_random(0.0)
	_set_density_random(0.0)
	_set_pitch_random(0.0)

	_set_rounding(64.0)

	_randomize_seed()

	play_button.disabled = true

	effect = AudioServer.get_bus_effect(0, 0)
	save_path_label.text = OS.get_executable_path().get_base_dir() + "/recording.wav"

func _set_seed(value):
	rng_seed = value
	rng.seed = value

func _randomize_seed():
	var new_seed = randi()
	rng.seed = new_seed
	seed_box.value = new_seed

func _set_tempo(value):
	interval = 60.0 / tempo
	timer_beat.wait_time = interval
	tempo_slider.value = value
	tempo_label.text = "Tempo: " + str(round(value)) + " BPM"

func _set_density(value):
	density = value
	density_slider.value = value
	density_label.text = "Density: " + str(round(value)) + "%"

func _set_pitch(value):
	pitch = value
	pitch_slider.value = value
	pitch_label.text = "Pitch: " + str(round(value)) + " st"

func _set_tempo_random(value):
	tempo_random = value
	tempo_random_label.text = "Randomization: " + str(value) + "%"

func _set_density_random(value):
	density_random = value
	density_random_label.text = "Randomization: " + str(value) + "%"

func _set_pitch_random(value):
	pitch_random = value
	pitch_random_label.text = "Randomization: " + str(value) + "%"

func _toggle_rounding(toggled):
	if toggled:
		use_rounding = true
		rounding_slider.editable = true
	else:
		use_rounding = false
		rounding_slider.editable = false

func _set_rounding(value):
	rounding = value
	rounding_label.text = "Rounding factor: " + str(value)

func _load_pressed():
	_play_stop()
	file_dialog.popup()

func _files_selected(paths):
	samples = []
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
	_set_seed(rng_seed)
	timer_beat.start()
	playing = true
	play_button.text = "Stop"

func _play_stop():
	timer_beat.stop()
	playing = false
	play_button.text = "Play"

func _record_pressed():
	if effect.is_recording_active():
		recording = effect.get_recording()
		effect.set_recording_active(false)
		record_button.text = "Record"
	else:
		effect.set_recording_active(true)
		record_button.text = "Stop recording"

func _save_pressed():
	var save_path = save_path_label.text
	recording.save_to_wav(save_path)

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
		var new_density = rng.randf() * 100.0
		_set_density(new_density)

	var pitch_rand_chance = rng.randf() * 100.0
	if pitch_rand_chance < pitch_random:
		var new_pitch = rng.randi_range(-6, 6)
		_set_pitch(new_pitch)

func _spawn_grain():
	var spawn_chance = rng.randf() * 100.0
	if spawn_chance < density:
		var new_grain = grain.instance()
		add_child(new_grain)
		var sample_id = rng.randi_range(0, samples.size() - 1)
		var curr_sample = samples[sample_id]
		var new_offset
		if use_rounding:
			new_offset = curr_sample.get_length() / rounding * rng.randi_range(0, rounding)
		else:
			new_offset = rng.randf_range(0.0, curr_sample.get_length())
		var new_pitch = pitch
		new_pitch = pow(2.0, new_pitch / 12.0)
		var new_size = interval * rng.randi_range(size_min, size_max)
		new_grain._grain_play(curr_sample, new_offset, new_pitch, new_size)

func _quit_pressed():
	get_tree().quit()
