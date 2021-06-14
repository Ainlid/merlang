extends Node2D

onready var timer_tick = $timer_tick
onready var timer_end = $timer_end
var duration_min = 30.0
var duration_max = 120.0
var endless = false

var sample
onready var file_dialog = $interface/load_menu/file_dialog
onready var file_name = $interface/load_menu/filename

onready var play_button = $interface/play_button
var playing = false

var rng
var rng_seed

var grain = preload("res://grain/grain.tscn")

var offsets = []
var offsets_num = 8
var offset_random = 0.5

var interval_current = 0.0
var intervals = []
var intervals_num = 4
var interval_min = 0.25
var interval_max = 4.0
var interval_random = 0.5

var volume = 0.0
var volume_min = -6.0
var volume_max = 0.0

var pitches = []
var pitches_num = 8
var pitch_min = -8.0
var pitch_max = 8.0
var pitch_random = 0.5

var size = 1
var size_min = 1
var size_max = 4

onready var seed_box = $interface/seed_menu/box

onready var audio_record = $audio_record
onready var record_button = $interface/record_button
onready var save_path_label = $interface/save_menu/path_label

var effect
var recording

onready var master_volume_label = $interface/master_volume_label
onready var master_volume_slider = $interface/master_volume_slider

func _ready():
	randomize()
	rng = RandomNumberGenerator.new()
	_set_master_volume(0.0)
	_randomize_seed()

	play_button.disabled = true

	effect = AudioServer.get_bus_effect(0, 0)
	save_path_label.text = OS.get_executable_path().get_base_dir() + "/recording.wav"

func _set_seed(value):
	rng_seed = value
	rng.seed = value

func _generate_offsets():
	offsets = []
	for n in offsets_num:
		var new_offset = rng.randf_range(0.0, sample.get_length())
		offsets.append(new_offset)

func _randomize_seed():
	var new_seed = randi()
	rng.seed = new_seed
	seed_box.value = new_seed
	_generate_params()

func _generate_params():
	intervals = []
	for n_int in intervals_num:
		intervals.append(rng.randf_range(interval_min, interval_max))
	interval_current = intervals[rng.randi_range(0, intervals_num - 1)]
	for n_pit in pitches_num:
		pitches.append(rng.randi_range(pitch_min, pitch_max))
	timer_end.wait_time = rng.randf_range(duration_min, duration_max)

func _set_master_volume(value):
	AudioServer.set_bus_volume_db(0, value)
	master_volume_label.text = "Master volume: " + str(value) + " dB"

func _load_pressed():
	_play_stop()
	file_dialog.popup()

func _file_selected(path):
	var file = File.new()
	if file.file_exists(path):
		file.open(path, file.READ)
		var buffer = file.get_buffer(file.get_len())
		var new_sample = AudioStreamSample.new()
		new_sample.format = AudioStreamSample.FORMAT_16_BITS      
		new_sample.data = buffer
		new_sample.stereo = true
		new_sample.mix_rate = 44100
		sample = new_sample
		file_name.text = str(path.get_file())
		file.close()
	play_button.disabled = false

func _play_pressed():
	if !playing:
		_play_start()
	else:
		_play_stop()

func _play_start():
	_set_seed(rng_seed)
	_generate_offsets()
	timer_tick.wait_time = interval_current
	timer_tick.start()
	if !endless:
		timer_end.start()
	playing = true
	play_button.text = "Stop"

func _play_stop():
	timer_tick.stop()
	playing = false
	play_button.text = "Play"

func _endless_toggle(button_pressed):
	endless = button_pressed

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

func _randomize_params():
	var interval_chance = rng.randf()
	if interval_chance < interval_random:
		intervals[rng.randi_range(0, intervals_num - 1)] = rng.randf_range(interval_min, interval_max)

	var offset_chance = rng.randf()
	if offset_chance < offset_random:
		offsets[rng.randi_range(0, offsets_num - 1)] = rng.randf_range(0, sample.get_length())

	var pitch_chance = rng.randf()
	if pitch_chance < pitch_random:
		pitches[rng.randi_range(0, pitches_num - 1)] = rng.randi_range(pitch_min, pitch_max)

func _tick():
	interval_current = intervals[rng.randi_range(0, intervals_num - 1)]
	timer_tick.wait_time = interval_current
	_spawn_grain()
	_randomize_params()

func _spawn_grain():
	var spawn_chance = rng.randf() * 100.0
	var new_grain = grain.instance()
	add_child(new_grain)
	new_grain.sample = sample
	new_grain.offset = offsets[rng.randi_range(0, offsets_num - 1)]
	var new_pitch = pitches[rng.randi_range(0, 7)]
	var pitch_conv = pow(2.0, new_pitch / 12.0)
	new_grain.pitch = pitch_conv
	new_grain.volume = rng.randf_range(volume_min, volume_max)
	new_grain.size = interval_current * rng.randi_range(size_min, size_max)
	new_grain._grain_play()

func _quit_pressed():
	get_tree().quit()
