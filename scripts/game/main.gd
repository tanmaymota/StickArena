extends Node2D

enum Phase { START, ROUND_INTRO, FIGHT, TIME_UP, ROUND_DRAW, ROUND_END, MATCH_END, PAUSED }
enum MenuView { MAIN, MODE_SELECT, PRACTICE_OPPONENT, STAGE_SELECT, SETTINGS, CONTROLS }

const PLAYER_1_SPAWN := Vector2(240, 450)
const PLAYER_2_SPAWN := Vector2(912, 450)
const ARENA_2_PLAYER_1_SPAWN := Vector2(430, 450)
const ARENA_2_PLAYER_2_SPAWN := Vector2(722, 450)
const EMPTY_WIN_COLOR := Color(0.33, 0.37, 0.45)
const PLAYER_1_COLOR := Color(0.96, 0.82, 0.49)
const PLAYER_2_COLOR := Color(0.35, 0.75, 1.0)
const SHAKE_DURATION := 0.12
const SHAKE_PIXELS := 5.0
const WEAPON_FLOOR_Y := 600.0
const WEAPON_DROP_GRAVITY := 1800.0
const WEAPON_PICKUP_DELAY := 0.45
const WEAPON_LAVA_RESPAWN_DELAY := 3.0
const LAVA_PLATFORM_WIDTH := 440.0
const LAVA_TOP_Y := 610.0
const ROUND_DURATION := 60.0
const TIME_UP_DISPLAY_DURATION := 0.9
const DRAW_DISPLAY_DURATION := 0.75
const CPU_REACTION_DELAYS := [0.30, 0.25, 0.20]
const CPU_BLOCK_CHANCES := [0.30, 0.50, 0.70]
const CPU_ATTACK_CHANCES := [0.55, 0.72, 0.90]
const CPU_SPECIAL_CHANCES := [0.35, 0.65, 0.92]
const SPECIAL_CHARGE_DURATION := 0.38
const SPECIAL_PROJECTILE_SPEED := 850.0

@onready var player_1: Fighter = $Player1
@onready var player_2: Fighter = $Player2
@onready var player_1_health: ProgressBar = $HUD/Player1Health
@onready var player_2_health: ProgressBar = $HUD/Player2Health
@onready var player_1_super: ProgressBar = $HUD/Player1Super
@onready var player_2_super: ProgressBar = $HUD/Player2Super
@onready var player_1_wins: Array[ColorRect] = [$HUD/Player1Win1, $HUD/Player1Win2]
@onready var player_2_wins: Array[ColorRect] = [$HUD/Player2Win1, $HUD/Player2Win2]
@onready var round_label: Label = $HUD/RoundLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var player_2_label: Label = $HUD/Player2Label
@onready var match_message: Label = $HUD/MatchMessage
@onready var start_screen: Control = $HUD/StartScreen
@onready var start_text: Label = $HUD/StartScreen/StartText
@onready var stage_select_screen: Control = $HUD/StageSelectScreen
@onready var stage_select_text: Label = $HUD/StageSelectScreen/StageSelectText
@onready var main_menu_screen: Control = $HUD/MainMenuScreen
@onready var main_menu_text: Label = $HUD/MainMenuScreen/MainMenuText
@onready var settings_screen: Control = $HUD/SettingsScreen
@onready var settings_volume_slider: HSlider = $HUD/SettingsScreen/VolumeSlider
@onready var settings_volume_text: Label = $HUD/SettingsScreen/VolumeText
@onready var settings_shake_text: Label = $HUD/SettingsScreen/ShakeText
@onready var controls_screen: Control = $HUD/ControlsScreen
@onready var controls_text: Label = $HUD/ControlsScreen/ControlsText
@onready var match_end_screen: Control = $HUD/MatchEndScreen
@onready var match_end_text: Label = $HUD/MatchEndScreen/MatchEndText
@onready var pause_screen: Control = $HUD/PauseScreen
@onready var pause_text: Label = $HUD/PauseScreen/PauseText
@onready var weapon_pickup: Area2D = $WeaponPickup
@onready var floor_visual: Polygon2D = $Arena/Floor/FloorVisual
@onready var floor_collision: CollisionShape2D = $Arena/Floor/CollisionShape2D
@onready var player_1_weapon_indicator: Label = $HUD/Player1WeaponIndicator
@onready var player_2_weapon_indicator: Label = $HUD/Player2WeaponIndicator

var phase: Phase = Phase.START
var menu_view: MenuView = MenuView.MAIN
var selected_main_menu_option := 0
var selected_settings_option := 0
var selected_pause_option := 0
var master_volume_percent := 80
var screen_shake_enabled := true
var round_number := 1
var player_1_round_wins := 0
var player_2_round_wins := 0
var phase_time := 0.0
var round_time_remaining := ROUND_DURATION
var round_timer_running := false
var last_timer_second := -1
var timer_pulse_tween: Tween
var selected_mode_option := 1
var selected_practice_opponent := 0
var selected_stage := 0
var single_player_mode := false
var practice_mode := false
var practice_dummy_opponent := false
var practice_restore_player_1 := 0.0
var practice_restore_player_2 := 0.0
var up_was_pressed := false
var down_was_pressed := false
var left_was_pressed := false
var right_was_pressed := false
var cpu_difficulty := 1
var cpu_reaction_time := 0.0
var cpu_attack_time := 0.0
var cpu_attack_delay := 0.0
var cpu_attack_pending := false
var cpu_jump_time := 0.0
var cpu_jump_decision_time := 0.0
var cpu_block_time := 0.0
var cpu_backoff_time := 0.0
var ai_rng := RandomNumberGenerator.new()
var special_blasts: Array[Area2D] = []
var player_1_meter_glow: Tween
var player_2_meter_glow: Tween
var intro_showing_fight := false
var enter_was_pressed := false
var restart_was_pressed := false
var pause_was_pressed := false
var phase_before_pause: Phase = Phase.START
var shake_time := 0.0
var hit_audio: AudioStreamPlayer
var end_audio: AudioStreamPlayer
var special_fire_audio: AudioStreamPlayer
var special_hit_audio: AudioStreamPlayer
var weapon_holder: Fighter
var weapon_falling := false
var weapon_velocity_y := 0.0
var weapon_pickup_lock := 0.0
var weapon_lava_respawn_time := 0.0
var recent_dropper: Fighter
var dropper_left_area := true
var camera: Camera2D
var effects: Node2D
var post_material: ShaderMaterial
var ko_zoom_time := 0.0
var tint_time := 0.0
var particle_texture: GradientTexture2D
var visual_rng := RandomNumberGenerator.new()
var sky_gradient: Gradient
var skyline_shapes: Array[Polygon2D] = []
var floor_material: ShaderMaterial
var floor_line: Line2D
var lava_surfaces: Array[Polygon2D] = []
var lava_bases: Array[Polygon2D] = []
var lava_glows: Array[Polygon2D] = []
var lava_embers: Array[CPUParticles2D] = []
var lava_backdrop_shapes: Array[CanvasItem] = []
var lava_visual_time := 0.0


func _ready() -> void:
	player_1.opponent = player_2
	player_2.opponent = player_1
	player_1.health_changed.connect(_on_player_1_health_changed)
	player_2.health_changed.connect(_on_player_2_health_changed)
	player_1.super_meter_changed.connect(_on_player_1_super_meter_changed)
	player_2.super_meter_changed.connect(_on_player_2_super_meter_changed)
	player_1.special_requested.connect(begin_special_charge)
	player_2.special_requested.connect(begin_special_charge)
	player_1.defeated.connect(_on_fighter_defeated)
	player_2.defeated.connect(_on_fighter_defeated)
	player_1.hit_landed.connect(_play_hit_sound)
	player_2.hit_landed.connect(_play_hit_sound)
	player_1.weapon_dropped.connect(_on_weapon_dropped)
	player_2.weapon_dropped.connect(_on_weapon_dropped)
	player_1.visual_hit.connect(_on_visual_hit)
	player_2.visual_hit.connect(_on_visual_hit)
	player_1.dust_requested.connect(_on_dust)
	player_2.dust_requested.connect(_on_dust)
	player_1.damage_number_requested.connect(show_damage_number)
	player_2.damage_number_requested.connect(show_damage_number)
	setup_visuals()
	ai_rng.randomize()
	setup_audio()
	update_health_bar(player_1_health, Fighter.MAX_HEALTH)
	update_health_bar(player_2_health, Fighter.MAX_HEALTH)
	setup_super_meter_bar(player_1_super, player_1.fighter_color)
	setup_super_meter_bar(player_2_super, player_2.fighter_color)
	update_super_meter_bar(player_1_super, player_1.super_meter, player_1.fighter_color, true)
	update_super_meter_bar(player_2_super, player_2.super_meter, player_2.fighter_color, false)
	update_win_indicators()
	player_1.stop_fighting()
	player_2.stop_fighting()
	start_screen.hide()
	stage_select_screen.hide()
	main_menu_screen.show()
	match_end_screen.hide()
	weapon_pickup.hide()
	update_weapon_indicators()
	pause_screen.hide()
	match_message.text = ""
	update_round_timer_display(false)
	settings_volume_slider.value = master_volume_percent
	setup_master_volume()
	settings_volume_slider.value_changed.connect(_on_master_volume_changed)
	update_main_menu()
	update_settings_screen()
	update_controls_screen()
	update_start_screen()
	update_pause_screen()
	restart_was_pressed = Input.is_key_pressed(KEY_R)
	pause_was_pressed = Input.is_key_pressed(KEY_ESCAPE)


func _physics_process(delta: float) -> void:
	if phase == Phase.PAUSED:
		return
	update_special_blasts(delta)
	if weapon_holder != null:
		return
	if not weapon_pickup.visible:
		if selected_stage == 1 and weapon_lava_respawn_time > 0.0:
			weapon_lava_respawn_time = maxf(weapon_lava_respawn_time - delta, 0.0)
			if weapon_lava_respawn_time <= 0.0 and phase == Phase.FIGHT:
				spawn_weapon()
		return

	if weapon_falling:
		weapon_velocity_y += WEAPON_DROP_GRAVITY * delta
		weapon_pickup.position.y = minf(weapon_pickup.position.y + weapon_velocity_y * delta, WEAPON_FLOOR_Y)
		if (
			selected_stage == 1 and weapon_pickup.position.y >= LAVA_TOP_Y
			and (weapon_pickup.position.x < Fighter.LAVA_PLATFORM_LEFT or weapon_pickup.position.x > Fighter.LAVA_PLATFORM_RIGHT)
		):
			lose_weapon_to_lava()
			return
		if weapon_pickup.position.y >= WEAPON_FLOOR_Y:
			weapon_falling = false
	weapon_pickup_lock = maxf(weapon_pickup_lock - delta, 0.0)
	if phase != Phase.FIGHT or weapon_falling or weapon_pickup_lock > 0.0:
		return

	var overlapping_bodies := weapon_pickup.get_overlapping_bodies()
	if recent_dropper != null and not overlapping_bodies.has(recent_dropper):
		dropper_left_area = true
	for body in overlapping_bodies:
		var fighter := body as Fighter
		if fighter == null or not fighter.can_fight or fighter.is_defeated:
			continue
		if fighter == recent_dropper and not dropper_left_area:
			continue
		weapon_holder = fighter
		fighter.equip_weapon()
		weapon_pickup.hide()
		update_weapon_indicators()
		break


func _process(delta: float) -> void:
	update_lava_visuals(delta)
	var restart_pressed := Input.is_key_pressed(KEY_R)
	if restart_pressed and not restart_was_pressed:
		get_tree().reload_current_scene()
		return
	restart_was_pressed = restart_pressed

	var pause_pressed := Input.is_key_pressed(KEY_ESCAPE)
	var escape_just_pressed := pause_pressed and not pause_was_pressed
	if escape_just_pressed:
		if phase == Phase.START:
			if menu_view == MenuView.MODE_SELECT:
				show_menu_view(MenuView.MAIN)
			elif menu_view == MenuView.PRACTICE_OPPONENT:
				show_menu_view(MenuView.MODE_SELECT)
			elif menu_view == MenuView.STAGE_SELECT:
				show_menu_view(MenuView.PRACTICE_OPPONENT if practice_mode else MenuView.MODE_SELECT)
			elif menu_view != MenuView.MAIN:
				show_menu_view(MenuView.MAIN)
		else:
			toggle_pause()
	pause_was_pressed = pause_pressed
	var up_pressed := Input.is_key_pressed(KEY_UP)
	var down_pressed := Input.is_key_pressed(KEY_DOWN)
	var left_pressed := Input.is_key_pressed(KEY_LEFT)
	var right_pressed := Input.is_key_pressed(KEY_RIGHT)
	var enter_pressed := Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	var up_just_pressed := up_pressed and not up_was_pressed
	var down_just_pressed := down_pressed and not down_was_pressed
	var left_just_pressed := left_pressed and not left_was_pressed
	var right_just_pressed := right_pressed and not right_was_pressed
	var enter_just_pressed := enter_pressed and not enter_was_pressed
	up_was_pressed = up_pressed
	down_was_pressed = down_pressed
	left_was_pressed = left_pressed
	right_was_pressed = right_pressed
	enter_was_pressed = enter_pressed
	if phase == Phase.PAUSED:
		process_pause_menu(up_just_pressed, down_just_pressed, enter_just_pressed)
		return
	update_practice_recovery(delta)

	update_camera(delta)
	tint_time = maxf(tint_time - delta, 0.0)
	post_material.set_shader_parameter("impact", tint_time / 0.16)
	update_cpu(delta)
	keep_cpu_on_safe_platform()
	update_special_charges(delta)
	if round_timer_running and (phase == Phase.FIGHT or (phase == Phase.ROUND_INTRO and intro_showing_fight)):
		update_round_timer(delta)
		if phase == Phase.TIME_UP:
			return

	if phase == Phase.START:
		process_start_menu(up_just_pressed, down_just_pressed, left_just_pressed, right_just_pressed, enter_just_pressed)

	if phase != Phase.ROUND_INTRO and phase != Phase.ROUND_END and phase != Phase.TIME_UP and phase != Phase.ROUND_DRAW:
		return

	phase_time -= delta
	if phase_time > 0.0:
		return

	if phase == Phase.TIME_UP:
		if player_1.health == player_2.health:
			phase = Phase.ROUND_DRAW
			phase_time = DRAW_DISPLAY_DURATION
			match_message.text = "DRAW!"
		else:
			var winner_number := 1 if player_1.health > player_2.health else 2
			announce_round_winner(winner_number)
	elif phase == Phase.ROUND_DRAW:
		start_round()
	elif phase == Phase.ROUND_END:
		round_number += 1
		start_round()
	elif not intro_showing_fight:
		intro_showing_fight = true
		match_message.text = "FIGHT!"
		phase_time = 0.7
		round_timer_running = not practice_mode
	else:
		match_message.text = ""
		phase = Phase.FIGHT
		player_1.can_fight = true
		player_2.can_fight = true


func toggle_pause() -> void:
	if phase == Phase.PAUSED:
		phase = phase_before_pause
		pause_screen.hide()
		player_1.set_physics_process(true)
		player_2.set_physics_process(true)
		for effect: Node in effects.get_children():
			var particles := effect as CPUParticles2D
			if particles != null:
				particles.speed_scale = 1.0
		set_special_blasts_paused(false)
	elif phase == Phase.ROUND_INTRO or phase == Phase.FIGHT or phase == Phase.TIME_UP or phase == Phase.ROUND_DRAW or phase == Phase.ROUND_END:
		phase_before_pause = phase
		phase = Phase.PAUSED
		shake_time = 0.0
		camera.offset = Vector2.ZERO
		if timer_pulse_tween != null and timer_pulse_tween.is_running():
			timer_pulse_tween.kill()
		timer_pulse_tween = null
		timer_label.scale = Vector2.ONE
		player_1.set_physics_process(false)
		player_2.set_physics_process(false)
		pause_screen.show()
		selected_pause_option = 0
		update_pause_screen()
		for effect: Node in effects.get_children():
			var particles := effect as CPUParticles2D
			if particles != null:
				particles.speed_scale = 0.0
		set_special_blasts_paused(true)


func process_pause_menu(up_pressed: bool, down_pressed: bool, enter_pressed: bool) -> void:
	if up_pressed:
		selected_pause_option = posmod(selected_pause_option - 1, 3)
		update_pause_screen()
	if down_pressed:
		selected_pause_option = posmod(selected_pause_option + 1, 3)
		update_pause_screen()
	if not enter_pressed:
		return
	match selected_pause_option:
		0:
			toggle_pause()
		1:
			get_tree().reload_current_scene()
		2:
			return_to_main_menu()


func return_to_main_menu() -> void:
	clear_special_blasts()
	cancel_special_charges()
	for effect: Node in effects.get_children():
		effect.queue_free()
	phase = Phase.START
	phase_before_pause = Phase.START
	phase_time = 0.0
	round_timer_running = false
	shake_time = 0.0
	ko_zoom_time = 0.0
	tint_time = 0.0
	camera.offset = Vector2.ZERO
	post_material.set_shader_parameter("impact", 0.0)
	player_1.set_physics_process(true)
	player_2.set_physics_process(true)
	player_1.reset_for_round(PLAYER_1_SPAWN)
	player_2.reset_for_round(PLAYER_2_SPAWN)
	player_2.is_cpu_controlled = false
	player_2.is_dummy = false
	player_1.practice_mode = false
	player_2.practice_mode = false
	apply_stage_visuals(0)
	player_1_round_wins = 0
	player_2_round_wins = 0
	round_number = 1
	single_player_mode = false
	practice_mode = false
	practice_dummy_opponent = false
	practice_restore_player_1 = 0.0
	practice_restore_player_2 = 0.0
	player_2_label.text = "PLAYER 2"
	weapon_holder = null
	weapon_falling = false
	weapon_pickup.hide()
	match_message.text = ""
	round_label.text = "Round 1"
	round_time_remaining = ROUND_DURATION
	update_round_timer_display(false)
	update_win_indicators()
	update_weapon_indicators()
	match_end_screen.hide()
	pause_screen.hide()
	stage_select_screen.hide()
	show_menu_view(MenuView.MAIN)


func process_start_menu(up_pressed: bool, down_pressed: bool, left_pressed: bool, right_pressed: bool, enter_pressed: bool) -> void:
	match menu_view:
		MenuView.MAIN:
			if up_pressed:
				selected_main_menu_option = posmod(selected_main_menu_option - 1, 3)
				update_main_menu()
			if down_pressed:
				selected_main_menu_option = posmod(selected_main_menu_option + 1, 3)
				update_main_menu()
			if enter_pressed:
				match selected_main_menu_option:
					0:
						show_menu_view(MenuView.MODE_SELECT)
					1:
						show_menu_view(MenuView.SETTINGS)
					2:
						show_menu_view(MenuView.CONTROLS)
		MenuView.MODE_SELECT:
			if up_pressed:
				selected_mode_option = posmod(selected_mode_option - 1, 5)
				update_start_screen()
			if down_pressed:
				selected_mode_option = posmod(selected_mode_option + 1, 5)
				update_start_screen()
			if enter_pressed:
				practice_mode = selected_mode_option == 4
				if practice_mode:
					selected_practice_opponent = 0
					show_menu_view(MenuView.PRACTICE_OPPONENT)
				else:
					practice_dummy_opponent = false
					show_menu_view(MenuView.STAGE_SELECT)
		MenuView.PRACTICE_OPPONENT:
			if up_pressed:
				selected_practice_opponent = posmod(selected_practice_opponent - 1, 4)
				update_practice_opponent_screen()
			if down_pressed:
				selected_practice_opponent = posmod(selected_practice_opponent + 1, 4)
				update_practice_opponent_screen()
			if enter_pressed:
				practice_dummy_opponent = selected_practice_opponent == 3
				single_player_mode = not practice_dummy_opponent
				cpu_difficulty = selected_practice_opponent if single_player_mode else 1
				player_2.is_cpu_controlled = single_player_mode
				player_2.is_dummy = practice_dummy_opponent
				player_2_label.text = "CPU" if single_player_mode else "DUMMY"
				show_menu_view(MenuView.STAGE_SELECT)
		MenuView.STAGE_SELECT:
			if left_pressed or right_pressed:
				selected_stage = 1 - selected_stage
				update_stage_select_screen()
			if enter_pressed:
				start_selected_mode()
		MenuView.SETTINGS:
			if up_pressed:
				selected_settings_option = posmod(selected_settings_option - 1, 2)
				update_settings_screen()
			if down_pressed:
				selected_settings_option = posmod(selected_settings_option + 1, 2)
				update_settings_screen()
			if left_pressed or right_pressed:
				if selected_settings_option == 0:
					var direction := 1 if right_pressed else -1
					settings_volume_slider.value = clampf(settings_volume_slider.value + direction * 5.0, 0.0, 100.0)
				else:
					screen_shake_enabled = not screen_shake_enabled
					settings_shake_text.text = "%sScreen Shake: %s" % ["▶ " if selected_settings_option == 1 else "   ", "ON" if screen_shake_enabled else "OFF"]
					if not screen_shake_enabled:
						shake_time = 0.0
						camera.offset = Vector2.ZERO
					update_settings_screen()
		MenuView.CONTROLS:
			pass


func start_selected_mode() -> void:
	start_screen.hide()
	stage_select_screen.hide()
	main_menu_screen.hide()
	if not practice_mode:
		single_player_mode = selected_mode_option < 3
		cpu_difficulty = selected_mode_option if single_player_mode else 1
		player_2.is_cpu_controlled = single_player_mode
		player_2.is_dummy = false
		player_2_label.text = "CPU" if single_player_mode else "PLAYER 2"
	player_1.practice_mode = practice_mode
	player_2.practice_mode = practice_mode
	apply_stage_visuals(selected_stage)
	reset_cpu_decisions()
	start_round()


func show_menu_view(view: MenuView) -> void:
	menu_view = view
	main_menu_screen.visible = view == MenuView.MAIN
	start_screen.visible = view == MenuView.MODE_SELECT or view == MenuView.PRACTICE_OPPONENT
	stage_select_screen.visible = view == MenuView.STAGE_SELECT
	settings_screen.visible = view == MenuView.SETTINGS
	controls_screen.visible = view == MenuView.CONTROLS
	if view == MenuView.MAIN:
		update_main_menu()
	elif view == MenuView.MODE_SELECT:
		update_start_screen()
	elif view == MenuView.PRACTICE_OPPONENT:
		update_practice_opponent_screen()
	elif view == MenuView.STAGE_SELECT:
		update_stage_select_screen()
	elif view == MenuView.SETTINGS:
		update_settings_screen()
	elif view == MenuView.CONTROLS:
		update_controls_screen()


func update_main_menu() -> void:
	var options := ["Play", "Settings", "Controls"]
	var lines := ""
	for index in range(options.size()):
		lines += ("▶ " if index == selected_main_menu_option else "   ") + options[index] + "\n"
	main_menu_text.text = "%s\n\nUp / Down to select   •   Enter to confirm" % lines.strip_edges()


func update_stage_select_screen() -> void:
	var arena_1 := "[ Arena 1 ]" if selected_stage == 0 else "  Arena 1  "
	var arena_2 := "[ Arena 2 ]" if selected_stage == 1 else "  Arena 2  "
	var return_text := "Esc to return to opponent select" if practice_mode else "Esc to return to mode select"
	stage_select_text.text = "CHOOSE STAGE\n\n%s       %s\n\nLeft / Right to choose   •   Enter to confirm\n%s" % [arena_1, arena_2, return_text]


func apply_stage_visuals(stage_index: int) -> void:
	var arena_two := stage_index == 1
	var platform_width := LAVA_PLATFORM_WIDTH if arena_two else 1152.0
	var floor_visual_half_width := LAVA_PLATFORM_WIDTH * 0.5 if arena_two else 1100.0
	var floor_shape := floor_collision.shape as RectangleShape2D
	floor_shape.size = Vector2(platform_width, floor_shape.size.y)
	floor_visual.polygon = PackedVector2Array([
		Vector2(-floor_visual_half_width, -40.0),
		Vector2(floor_visual_half_width, -40.0),
		Vector2(floor_visual_half_width, 500.0),
		Vector2(-floor_visual_half_width, 500.0)
	])
	player_1.arena_two_enabled = arena_two
	player_2.arena_two_enabled = arena_two
	for surface: Polygon2D in lava_surfaces:
		surface.visible = arena_two
	for embers: CPUParticles2D in lava_embers:
		if arena_two:
			embers.emitting = true
			embers.show()
		else:
			embers.emitting = false
			embers.hide()
	if stage_index == 0:
		sky_gradient.colors = PackedColorArray([Color("#101526"), Color("#35566b"), Color("#c39276")])
		for building: Polygon2D in skyline_shapes:
			var layer := int(building.get_meta("stage_layer", 0))
			building.color = Color("#263b50") if layer == 0 else Color("#192b3c")
		floor_material.set_shader_parameter("arena_two", false)
		floor_line.default_color = Color("#dbad6b")
		floor_line.points = PackedVector2Array([Vector2(-576.0, -40.0), Vector2(576.0, -40.0)])
	else:
		sky_gradient.colors = PackedColorArray([Color("#100a10"), Color("#48202a"), Color("#c3542f")])
		for building: Polygon2D in skyline_shapes:
			var layer := int(building.get_meta("stage_layer", 0))
			building.color = Color("#30191d") if layer == 0 else Color("#1c1219")
		floor_material.set_shader_parameter("arena_two", true)
		floor_line.default_color = Color("#e76b36")
		floor_line.points = PackedVector2Array([Vector2(-LAVA_PLATFORM_WIDTH * 0.5, -40.0), Vector2(LAVA_PLATFORM_WIDTH * 0.5, -40.0)])
	for backdrop_shape: CanvasItem in lava_backdrop_shapes:
		backdrop_shape.visible = arena_two
	weapon_lava_respawn_time = 0.0


func update_settings_screen() -> void:
	settings_volume_text.text = "%sMaster Volume: %d%%" % ["▶ " if selected_settings_option == 0 else "   ", master_volume_percent]
	settings_shake_text.text = "%sScreen Shake: %s" % ["▶ " if selected_settings_option == 1 else "   ", "ON" if screen_shake_enabled else "OFF"]
	settings_volume_slider.value = master_volume_percent


func update_controls_screen() -> void:
	controls_text.text = "PLAYER 1\nMove: A / D    Jump: W or Space\nAttack: F    Block: S    Special: G\n\nPLAYER 2\nMove: Left / Right    Jump: Up\nAttack: O    Block: Down    Special: P\n\nPRACTICE ONLY\nM fills Player 1 super meter    N fills Player 2 meter\n\nMATCH\nEnter: Confirm / Begin    Esc: Pause    R: Restart\n\nEsc to go back"


func update_pause_screen() -> void:
	var options := ["Resume", "Restart", "Main Menu"]
	var lines := ""
	for index in range(options.size()):
		lines += ("▶ " if index == selected_pause_option else "   ") + options[index] + "\n"
	pause_text.text = "PAUSED\n\nP1: G super   •   P2: P super\n%s\nUp / Down: select   •   Enter: confirm\nEsc: resume   •   R: restart" % lines.strip_edges()


func setup_master_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var volume_ratio := float(master_volume_percent) / 100.0
		AudioServer.set_bus_mute(master_bus, volume_ratio <= 0.0)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(volume_ratio, 0.0001)))


func _on_master_volume_changed(value: float) -> void:
	master_volume_percent = roundi(value)
	setup_master_volume()
	settings_volume_text.text = "%sMaster Volume: %d%%" % ["▶ " if selected_settings_option == 0 else "   ", master_volume_percent]


func start_round() -> void:
	clear_special_blasts()
	cancel_special_charges()
	phase = Phase.ROUND_INTRO
	phase_time = 1.0
	intro_showing_fight = false
	round_time_remaining = ROUND_DURATION
	round_timer_running = false
	practice_restore_player_1 = 0.0
	practice_restore_player_2 = 0.0
	last_timer_second = -1
	timer_label.scale = Vector2.ONE
	update_round_timer_display(false)
	reset_cpu_decisions()
	var player_1_spawn := ARENA_2_PLAYER_1_SPAWN if selected_stage == 1 else PLAYER_1_SPAWN
	var player_2_spawn := ARENA_2_PLAYER_2_SPAWN if selected_stage == 1 else PLAYER_2_SPAWN
	player_1.reset_for_round(player_1_spawn)
	player_2.reset_for_round(player_2_spawn)
	spawn_weapon()
	if practice_mode:
		round_label.text = "PRACTICE"
		timer_label.hide()
		match_message.text = "PRACTICE"
	else:
		round_label.text = "Round %d" % round_number
		timer_label.show()
		match_message.text = "ROUND %d" % round_number


func spawn_weapon() -> void:
	weapon_holder = null
	weapon_falling = false
	weapon_velocity_y = 0.0
	weapon_pickup_lock = 0.0
	weapon_lava_respawn_time = 0.0
	recent_dropper = null
	dropper_left_area = true
	var spawn_left := 390.0 if selected_stage == 1 else 350.0
	var spawn_right := 762.0 if selected_stage == 1 else 802.0
	weapon_pickup.position = Vector2(randf_range(spawn_left, spawn_right), WEAPON_FLOOR_Y)
	weapon_pickup.show()
	update_weapon_indicators()


func _on_weapon_dropped(fighter: Fighter) -> void:
	if weapon_holder != fighter:
		return
	weapon_holder = null
	weapon_pickup.position = Vector2(
		clampf(fighter.position.x, 30.0, 1122.0),
		minf(fighter.position.y - 20.0, WEAPON_FLOOR_Y)
	)
	if selected_stage == 1 and (
		weapon_pickup.position.x < Fighter.LAVA_PLATFORM_LEFT
		or weapon_pickup.position.x > Fighter.LAVA_PLATFORM_RIGHT
	):
		lose_weapon_to_lava()
		update_weapon_indicators()
		return
	weapon_velocity_y = 0.0
	weapon_falling = true
	weapon_pickup_lock = WEAPON_PICKUP_DELAY
	recent_dropper = fighter
	dropper_left_area = false
	weapon_pickup.show()
	update_weapon_indicators()


func lose_weapon_to_lava() -> void:
	weapon_pickup.hide()
	weapon_falling = false
	weapon_velocity_y = 0.0
	weapon_pickup_lock = 0.0
	weapon_lava_respawn_time = WEAPON_LAVA_RESPAWN_DELAY


func update_weapon_indicators() -> void:
	player_1_weapon_indicator.visible = player_1.has_weapon
	player_2_weapon_indicator.visible = player_2.has_weapon


func _on_player_1_health_changed(current_health: int) -> void:
	update_health_bar(player_1_health, current_health)


func _on_player_2_health_changed(current_health: int) -> void:
	update_health_bar(player_2_health, current_health)


func show_damage_number(amount: int, at: Vector2) -> void:
	if amount <= 0:
		return
	var damage_label := Label.new()
	damage_label.text = "-%d" % amount
	damage_label.position = at - Vector2(42.0, 18.0)
	damage_label.size = Vector2(84.0, 36.0)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	damage_label.add_theme_font_size_override("font_size", 26)
	damage_label.add_theme_color_override("font_color", Color("#fff1b8"))
	damage_label.add_theme_color_override("font_outline_color", Color("#17111a"))
	damage_label.add_theme_constant_override("outline_size", 5)
	damage_label.z_index = 20
	effects.add_child(damage_label)
	var float_tween := create_tween().set_parallel(true)
	float_tween.tween_property(damage_label, "position:y", damage_label.position.y - 48.0, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	float_tween.tween_property(damage_label, "modulate:a", 0.0, 0.72).set_delay(0.18)
	float_tween.chain().tween_callback(damage_label.queue_free)


func _on_player_1_super_meter_changed(value: int) -> void:
	update_super_meter_bar(player_1_super, value, player_1.fighter_color, true)


func _on_player_2_super_meter_changed(value: int) -> void:
	update_super_meter_bar(player_2_super, value, player_2.fighter_color, false)


func setup_super_meter_bar(bar: ProgressBar, tint: Color) -> void:
	bar.min_value = 0.0
	bar.max_value = Fighter.MAX_SUPER_METER
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.12, 0.18)
	background.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", background)
	update_super_meter_bar(bar, 0, tint, bar == player_1_super)


func update_super_meter_bar(bar: ProgressBar, value: int, tint: Color, player_one: bool) -> void:
	bar.value = value
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint.lightened(0.15)
	fill.set_corner_radius_all(5)
	fill.shadow_color = tint
	fill.shadow_size = 6 if value >= Fighter.MAX_SUPER_METER else 0
	bar.add_theme_stylebox_override("fill", fill)
	var glow_tween: Tween = player_1_meter_glow if player_one else player_2_meter_glow
	if value >= Fighter.MAX_SUPER_METER:
		if glow_tween == null or not glow_tween.is_running():
			glow_tween = create_tween().set_loops()
			glow_tween.tween_property(fill, "shadow_size", 13, 0.4).set_trans(Tween.TRANS_SINE)
			glow_tween.tween_property(fill, "shadow_size", 6, 0.4).set_trans(Tween.TRANS_SINE)
	else:
		if glow_tween != null and glow_tween.is_running():
			glow_tween.kill()
		glow_tween = null
	if player_one:
		player_1_meter_glow = glow_tween
	else:
		player_2_meter_glow = glow_tween


func update_health_bar(bar: ProgressBar, current_health: int) -> void:
	bar.value = current_health
	var fill := StyleBoxFlat.new()
	if current_health > 60:
		fill.bg_color = Color(0.22, 0.78, 0.36)
	elif current_health > 30:
		fill.bg_color = Color(0.96, 0.78, 0.19)
	else:
		fill.bg_color = Color(0.91, 0.24, 0.23)
	bar.add_theme_stylebox_override("fill", fill)
	fill.set_corner_radius_all(8)

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.15, 0.18, 0.24)
	background.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", background)
	update_leader_glow()


func update_win_indicators() -> void:
	for index in range(2):
		player_1_wins[index].color = PLAYER_1_COLOR if index < player_1_round_wins else EMPTY_WIN_COLOR
		player_2_wins[index].color = PLAYER_2_COLOR if index < player_2_round_wins else EMPTY_WIN_COLOR
	update_leader_glow()


func _on_fighter_defeated(fighter: Fighter) -> void:
	if practice_mode and phase == Phase.FIGHT:
		if fighter == player_1:
			practice_restore_player_1 = 1.0
		else:
			practice_restore_player_2 = 1.0
		spawn_burst(fighter.global_position + Vector2(0, -25), "ko", fighter.fighter_color)
		return
	if phase != Phase.FIGHT:
		return

	clear_special_blasts()
	cancel_special_charges()
	spawn_burst(fighter.global_position + Vector2(0, -25), "ko", fighter.fighter_color)
	ko_zoom_time = 0.45
	tint_time = 0.16
	round_timer_running = false
	player_1.stop_fighting()
	player_2.stop_fighting()
	var winner_number := 1
	if fighter == player_1:
		winner_number = 2
	announce_round_winner(winner_number)


func update_practice_recovery(delta: float) -> void:
	if not practice_mode or phase != Phase.FIGHT:
		return
	if practice_restore_player_1 > 0.0:
		practice_restore_player_1 = maxf(practice_restore_player_1 - delta, 0.0)
		if practice_restore_player_1 == 0.0:
			player_1.revive_from_practice()
	if practice_restore_player_2 > 0.0:
		practice_restore_player_2 = maxf(practice_restore_player_2 - delta, 0.0)
		if practice_restore_player_2 == 0.0:
			player_2.revive_from_practice()


func announce_round_winner(winner_number: int) -> void:
	round_timer_running = false
	player_1.stop_fighting()
	player_2.stop_fighting()
	if winner_number == 1:
		player_1_round_wins += 1
	else:
		player_2_round_wins += 1
	update_win_indicators()

	if player_1_round_wins == 2 or player_2_round_wins == 2:
		phase = Phase.MATCH_END
		match_message.text = ""
		match_end_text.text = "%s WINS THE MATCH\n\nPress R to rematch" % fighter_display_name(winner_number)
		match_end_screen.show()
		match_end_screen.modulate.a = 0.0
		create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).tween_property(match_end_screen, "modulate:a", 1.0, 0.3)
		end_audio.stream = make_tone(PackedFloat32Array([523.0, 659.0, 784.0]), 0.14)
	else:
		phase = Phase.ROUND_END
		phase_time = 1.6
		match_message.text = "%s WINS ROUND %d!" % [fighter_display_name(winner_number), round_number]
		end_audio.stream = make_tone(PackedFloat32Array([540.0, 360.0]), 0.16)
	end_audio.play()


func begin_special_charge(fighter: Fighter) -> void:
	if phase != Phase.FIGHT or not fighter.can_fight or fighter.is_defeated:
		return
	if fighter.super_meter < Fighter.MAX_SUPER_METER or fighter.special_charging or has_active_special_blast(fighter):
		return
	fighter.special_charging = true
	fighter.special_charge_time = SPECIAL_CHARGE_DURATION
	fighter.update_arm_pose()


func update_special_charges(delta: float) -> void:
	for fighter: Fighter in [player_1, player_2]:
		if not fighter.special_charging:
			continue
		if phase != Phase.FIGHT or not fighter.can_fight or fighter.is_defeated or fighter.hitstun_time > 0.0:
			fighter.special_charging = false
			fighter.special_charge_time = 0.0
			continue
		fighter.special_charge_time = maxf(fighter.special_charge_time - delta, 0.0)
		if fighter.special_charge_time <= 0.0:
			fire_special_blast(fighter)


func fire_special_blast(attacker: Fighter) -> void:
	if has_active_special_blast(attacker):
		attacker.special_charging = false
		return
	attacker.special_charging = false
	attacker.special_charge_time = 0.0
	attacker.set_super_meter(0)
	attacker.update_arm_pose()
	var direction := attacker.facing_direction
	var blast := Area2D.new()
	blast.name = "SuperBlastP%d" % attacker.player_number
	blast.collision_layer = 0
	blast.collision_mask = 1
	blast.monitoring = true
	blast.monitorable = false
	blast.position = attacker.global_position + Vector2(direction * 38.0, -32.0)
	blast.z_index = 7
	blast.set_meta("direction", direction)
	blast.set_meta("owner_number", attacker.player_number)
	var blast_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	blast_shape.shape = circle
	blast.add_child(blast_shape)
	var glow := Polygon2D.new()
	glow.polygon = make_circle_polygon(22.0, 20)
	glow.color = Color(attacker.fighter_color.r, attacker.fighter_color.g, attacker.fighter_color.b, 0.48)
	glow.material = additive_material()
	blast.add_child(glow)
	var core := Polygon2D.new()
	core.polygon = make_circle_polygon(11.0, 20)
	core.color = Color(0.9, 0.98, 1.0, 1.0)
	core.material = additive_material()
	blast.add_child(core)
	var trail := CPUParticles2D.new()
	trail.amount = 16
	trail.lifetime = 0.24
	trail.emitting = true
	trail.local_coords = false
	trail.direction = Vector2(-direction, 0.0)
	trail.spread = 24.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 26.0
	trail.initial_velocity_max = 82.0
	trail.scale_amount_min = 0.22
	trail.scale_amount_max = 0.58
	trail.texture = particle_texture
	var trail_ramp := Gradient.new()
	var trail_clear := attacker.fighter_color
	trail_clear.a = 0.0
	trail_ramp.colors = PackedColorArray([Color.WHITE, attacker.fighter_color, trail_clear])
	trail_ramp.offsets = PackedFloat32Array([0.0, 0.28, 1.0])
	trail.color_ramp = trail_ramp
	blast.add_child(trail)
	add_child(blast)
	blast.body_entered.connect(_on_special_blast_body_entered.bind(blast, attacker))
	special_blasts.append(blast)
	special_fire_audio.play()


func additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


func make_circle_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(sides):
		var angle := TAU * float(index) / sides
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func has_active_special_blast(fighter: Fighter) -> bool:
	for blast: Area2D in special_blasts:
		if is_instance_valid(blast) and int(blast.get_meta("owner_number", 0)) == fighter.player_number:
			return true
	return false


func update_special_blasts(delta: float) -> void:
	if phase != Phase.FIGHT:
		clear_special_blasts()
		return
	for blast: Area2D in special_blasts.duplicate():
		if not is_instance_valid(blast):
			special_blasts.erase(blast)
			continue
		var direction := float(blast.get_meta("direction", 1.0))
		blast.position.x += direction * SPECIAL_PROJECTILE_SPEED * delta
		if blast.position.x < Fighter.ARENA_LEFT - 32.0 or blast.position.x > Fighter.ARENA_RIGHT + 32.0:
			remove_special_blast(blast)


func _on_special_blast_body_entered(body: Node2D, blast: Area2D, attacker: Fighter) -> void:
	if body == attacker or not is_instance_valid(blast):
		return
	var defender := body as Fighter
	if defender == null:
		return
	special_hit_audio.play()
	shake_time = SHAKE_DURATION
	spawn_special_impact(blast.global_position, attacker.fighter_color)
	remove_special_blast(blast)
	defender.take_special_hit(float(blast.get_meta("direction", attacker.facing_direction)))


func remove_special_blast(blast: Area2D) -> void:
	special_blasts.erase(blast)
	if is_instance_valid(blast):
		blast.queue_free()


func clear_special_blasts() -> void:
	for blast: Area2D in special_blasts.duplicate():
		remove_special_blast(blast)
	special_blasts.clear()


func set_special_blasts_paused(paused: bool) -> void:
	for blast: Area2D in special_blasts:
		if not is_instance_valid(blast):
			continue
		var trail := blast.get_node_or_null("CPUParticles2D") as CPUParticles2D
		if trail != null:
			trail.speed_scale = 0.0 if paused else 1.0


func cancel_special_charges() -> void:
	for fighter: Fighter in [player_1, player_2]:
		fighter.special_charging = false
		fighter.special_charge_time = 0.0
		fighter.charge_orb.hide()
		fighter.update_arm_pose()


func spawn_special_impact(at: Vector2, tint: Color) -> void:
	spawn_burst(at, "hit", tint.lightened(0.35))
	var ring := Line2D.new()
	var ring_points := make_circle_polygon(22.0, 28)
	ring_points.append(ring_points[0])
	ring.points = ring_points
	ring.width = 4.0
	ring.default_color = tint.lightened(0.65)
	ring.antialiased = true
	effects.add_child(ring)
	ring.global_position = at
	ring.scale = Vector2.ONE * 0.35
	var impact_tween := create_tween()
	impact_tween.set_parallel(true)
	impact_tween.tween_property(ring, "scale", Vector2.ONE * 2.1, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(ring, "modulate:a", 0.0, 0.28)
	impact_tween.chain().tween_callback(ring.queue_free)


func fighter_display_name(player_number: int) -> String:
	if player_number == 2 and single_player_mode:
		return "CPU"
	return "PLAYER %d" % player_number


func update_start_screen() -> void:
	var options := [
		"1 Player (vs CPU) — Easy",
		"1 Player (vs CPU) — Normal",
		"1 Player (vs CPU) — Hard",
		"2 Players",
		"Practice"
	]
	var menu_lines := ""
	for index in range(options.size()):
		menu_lines += ("▶ " if index == selected_mode_option else "   ") + options[index] + "\n"
	start_text.text = "CHOOSE MODE\n\n%s\nUp / Down to select   •   Enter to confirm\nEsc to go back" % menu_lines.strip_edges()


func update_practice_opponent_screen() -> void:
	var options := ["CPU — Easy", "CPU — Normal", "CPU — Hard", "Passive Dummy"]
	var menu_lines := ""
	for index in range(options.size()):
		menu_lines += ("▶ " if index == selected_practice_opponent else "   ") + options[index] + "\n"
	start_text.text = "PRACTICE OPPONENT\n\n%s\nUp / Down to select   •   Enter to confirm\nM fills P1 meter   •   N fills P2 meter\nEsc to go back" % menu_lines.strip_edges()


func reset_cpu_decisions() -> void:
	cpu_reaction_time = CPU_REACTION_DELAYS[cpu_difficulty] if single_player_mode else 0.0
	cpu_attack_time = 0.0
	cpu_attack_delay = 0.0
	cpu_attack_pending = false
	cpu_jump_time = 0.0
	cpu_jump_decision_time = 0.0
	cpu_block_time = 0.0
	cpu_backoff_time = 0.0
	player_2.cpu_move_direction = 0.0
	player_2.cpu_jump_pressed = false
	player_2.cpu_attack_pressed = false
	player_2.cpu_block_pressed = false
	player_2.cpu_special_pressed = false


func update_cpu(delta: float) -> void:
	if not single_player_mode or not player_2.is_cpu_controlled:
		return
	if phase != Phase.FIGHT or not player_2.can_fight:
		reset_cpu_decisions()
		return

	cpu_attack_time = maxf(cpu_attack_time - delta, 0.0)
	cpu_jump_time = maxf(cpu_jump_time - delta, 0.0)
	cpu_jump_decision_time = maxf(cpu_jump_decision_time - delta, 0.0)
	cpu_block_time = maxf(cpu_block_time - delta, 0.0)
	cpu_backoff_time = maxf(cpu_backoff_time - delta, 0.0)
	if cpu_attack_pending:
		cpu_attack_delay = maxf(cpu_attack_delay - delta, 0.0)
		if cpu_attack_delay <= 0.0:
			cpu_attack_pending = false
			cpu_attack_time = 0.08
	player_2.cpu_attack_pressed = cpu_attack_time > 0.0
	player_2.cpu_jump_pressed = cpu_jump_time > 0.0
	player_2.cpu_block_pressed = cpu_block_time > 0.0

	cpu_reaction_time = maxf(cpu_reaction_time - delta, 0.0)
	if cpu_reaction_time > 0.0:
		return
	cpu_reaction_time = CPU_REACTION_DELAYS[cpu_difficulty]

	var separation := player_2.position.x - player_1.position.x
	var distance := absf(separation)
	# Check specials on the CPU's normal reaction beat, before defensive decisions
	# can postpone them. Player blocking or movement does not suppress the shot.
	if (
		player_2.super_meter >= Fighter.MAX_SUPER_METER
		and distance >= 180.0 and distance <= 620.0
		and not player_2.special_charging and not has_active_special_blast(player_2)
		and ai_rng.randf() < CPU_SPECIAL_CHANCES[cpu_difficulty]
	):
		begin_special_charge(player_2)
		return

	var player_attack_range := Fighter.ARMED_ATTACK_RANGE if player_1.has_weapon else Fighter.ATTACK_RANGE
	if player_1.attack_pose_time > 0.0 and distance <= player_attack_range + 35.0:
		cpu_attack_pending = false
		cpu_attack_time = 0.0
		player_2.cpu_attack_pressed = false
		if ai_rng.randf() < CPU_BLOCK_CHANCES[cpu_difficulty]:
			cpu_block_time = 0.20
			cpu_backoff_time = 0.0
			player_2.cpu_block_pressed = true
			player_2.cpu_move_direction = 0.0
		else:
			cpu_backoff_time = 0.24
			cpu_block_time = 0.0
			player_2.cpu_block_pressed = false
			player_2.cpu_move_direction = signf(separation)
		return

	if cpu_block_time > 0.0:
		player_2.cpu_move_direction = 0.0
		return
	if cpu_backoff_time > 0.0:
		player_2.cpu_move_direction = signf(separation)
		return
	var target_x := player_1.position.x
	var seeking_weapon := false
	if weapon_holder == null and weapon_pickup.visible and not weapon_falling:
		var cpu_weapon_distance := absf(weapon_pickup.position.x - player_2.position.x)
		var player_weapon_distance := absf(weapon_pickup.position.x - player_1.position.x)
		if cpu_weapon_distance < player_weapon_distance:
			target_x = weapon_pickup.position.x
			seeking_weapon = true

	var target_gap := target_x - player_2.position.x
	var stopping_distance := 18.0
	if not seeking_weapon:
		var attack_range := Fighter.ARMED_ATTACK_RANGE if player_2.has_weapon else Fighter.ATTACK_RANGE
		stopping_distance = attack_range - 10.0
	if selected_stage == 1 and player_2.position.x < Fighter.LAVA_PLATFORM_LEFT + 24.0:
		player_2.cpu_move_direction = 1.0
	elif selected_stage == 1 and player_2.position.x > Fighter.LAVA_PLATFORM_RIGHT - 24.0:
		player_2.cpu_move_direction = -1.0
	else:
		player_2.cpu_move_direction = signf(target_gap) if absf(target_gap) > stopping_distance else 0.0

	if not seeking_weapon and distance <= (Fighter.ARMED_ATTACK_RANGE if player_2.has_weapon else Fighter.ATTACK_RANGE) and player_2.attack_cooldown <= 0.0 and not cpu_attack_pending and cpu_attack_time <= 0.0:
		if ai_rng.randf() < CPU_ATTACK_CHANCES[cpu_difficulty]:
			cpu_attack_pending = true
			cpu_attack_delay = ai_rng.randf_range(0.05, 0.15)
	if cpu_jump_decision_time <= 0.0:
		cpu_jump_decision_time = 0.55
		if player_2.is_on_floor() and ai_rng.randf() < 0.12:
			cpu_jump_time = 0.10
			player_2.cpu_jump_pressed = true


func keep_cpu_on_safe_platform() -> void:
	if selected_stage != 1 or phase != Phase.FIGHT or not player_2.is_cpu_controlled:
		return
	if player_2.hitstun_time > 0.0 or player_2.lava_recoil_time > 0.0:
		return
	if player_2.position.x < Fighter.LAVA_PLATFORM_LEFT + 24.0:
		player_2.cpu_move_direction = 1.0
		player_2.velocity.x = maxf(player_2.velocity.x, 0.0)
	elif player_2.position.x > Fighter.LAVA_PLATFORM_RIGHT - 24.0:
		player_2.cpu_move_direction = -1.0
		player_2.velocity.x = minf(player_2.velocity.x, 0.0)


func update_round_timer(delta: float) -> void:
	round_time_remaining = maxf(round_time_remaining - delta, 0.0)
	update_round_timer_display(true)
	if round_time_remaining <= 0.0:
		round_timer_running = false
		clear_special_blasts()
		cancel_special_charges()
		player_1.stop_fighting()
		player_2.stop_fighting()
		phase = Phase.TIME_UP
		phase_time = TIME_UP_DISPLAY_DURATION
		match_message.text = "TIME!"
		end_audio.stream = make_tone(PackedFloat32Array([540.0, 360.0]), 0.16)
		end_audio.play()


func update_round_timer_display(pulse: bool) -> void:
	var displayed_second := ceili(round_time_remaining)
	timer_label.text = "%02d" % displayed_second
	timer_label.add_theme_color_override(
		"font_color",
		Color("#ff5454") if displayed_second <= 10 else Color("#f4d7a7")
	)
	if pulse and displayed_second <= 10 and displayed_second != last_timer_second:
		if timer_pulse_tween != null and timer_pulse_tween.is_running():
			timer_pulse_tween.kill()
		timer_label.scale = Vector2.ONE
		timer_pulse_tween = create_tween()
		timer_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		timer_pulse_tween.tween_property(timer_label, "scale", Vector2(1.14, 1.14), 0.12)
		timer_pulse_tween.set_ease(Tween.EASE_IN_OUT)
		timer_pulse_tween.tween_property(timer_label, "scale", Vector2.ONE, 0.28)
	last_timer_second = displayed_second


func setup_audio() -> void:
	hit_audio = AudioStreamPlayer.new()
	hit_audio.volume_db = -9.0
	hit_audio.stream = make_tone(PackedFloat32Array([180.0, 95.0]), 0.045)
	add_child(hit_audio)

	end_audio = AudioStreamPlayer.new()
	end_audio.volume_db = -8.0
	add_child(end_audio)

	special_fire_audio = AudioStreamPlayer.new()
	special_fire_audio.volume_db = -6.0
	special_fire_audio.stream = make_tone(PackedFloat32Array([360.0, 580.0, 920.0]), 0.12)
	add_child(special_fire_audio)

	special_hit_audio = AudioStreamPlayer.new()
	special_hit_audio.volume_db = -5.0
	special_hit_audio.stream = make_tone(PackedFloat32Array([120.0, 210.0, 70.0]), 0.15)
	add_child(special_hit_audio)


func _play_hit_sound() -> void:
	hit_audio.play()
	shake_time = SHAKE_DURATION


# Tiny generated tones keep the prototype self-contained.
func make_tone(notes: PackedFloat32Array, note_seconds: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var samples_per_note := int(note_seconds * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(notes.size() * samples_per_note * 2)
	var phase_angle := 0.0

	for note_index in range(notes.size()):
		for sample_index in range(samples_per_note):
			var envelope := minf(1.0, float(sample_index) / 160.0)
			envelope *= minf(1.0, float(samples_per_note - sample_index) / 400.0)
			var sample := int(sin(phase_angle) * envelope * 9000.0)
			bytes.encode_s16((note_index * samples_per_note + sample_index) * 2, sample)
			phase_angle += TAU * notes[note_index] / SAMPLE_RATE

	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SAMPLE_RATE
	sound.stereo = false
	sound.data = bytes
	return sound


func setup_visuals() -> void:
	visual_rng.randomize()
	get_window().content_scale_size = Vector2i(1152, 648)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	setup_backdrop()
	setup_hud_style()
	camera = Camera2D.new()
	camera.name = "FightCamera"
	camera.position = Vector2(576, 395)
	add_child(camera)
	camera.make_current()
	effects = Node2D.new()
	effects.name = "VisualEffects"
	effects.z_index = 10
	add_child(effects)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	particle_texture = GradientTexture2D.new()
	particle_texture.gradient = fade
	particle_texture.width = 16
	particle_texture.height = 16
	particle_texture.fill = GradientTexture2D.FILL_RADIAL
	particle_texture.fill_from = Vector2(0.5, 0.5)
	particle_texture.fill_to = Vector2(1, 0.5)
	setup_lava_visuals()
	setup_post_processing()


func setup_backdrop() -> void:
	$Arena/Background.hide()
	sky_gradient = Gradient.new()
	sky_gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	sky_gradient.colors = PackedColorArray([Color("#101526"), Color("#35566b"), Color("#c39276")])
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = sky_gradient
	sky_texture.width = 4
	sky_texture.height = 512
	sky_texture.fill_from = Vector2(0, 0)
	sky_texture.fill_to = Vector2(0, 1)
	var sky := Sprite2D.new()
	sky.texture = sky_texture
	sky.centered = false
	sky.position = Vector2(-400, -400)
	sky.scale = Vector2(488, 2.75)
	sky.z_index = -30
	add_child(sky)

	# A separate seeded generator keeps decoration out of gameplay randomness.
	var scenery_rng := RandomNumberGenerator.new()
	scenery_rng.seed = 731
	for layer in range(2):
		var x := -350.0
		while x < 1550.0:
			var width := scenery_rng.randf_range(45.0, 95.0)
			var height := scenery_rng.randf_range(75.0, 235.0) * (1.0 if layer == 0 else 0.65)
			var baseline := 555.0 + layer * 32.0
			var tint := Color("#263b50") if layer == 0 else Color("#192b3c")
			var building := add_visual_rect(Rect2(x, baseline - height, width, height), tint, -20 + layer)
			building.set_meta("stage_layer", layer)
			skyline_shapes.append(building)
			if layer == 0:
				for row in range(2, int(height / 22.0)):
					if scenery_rng.randf() > 0.45:
						add_visual_rect(Rect2(x + 12, baseline - height + row * 20, 4, 7), Color(0.91, 0.71, 0.43, 0.28), -18)
			x += width + scenery_rng.randf_range(4.0, 12.0)
	add_visual_rect(Rect2(-350, 571, 1850, 5), Color("#0f2334"), -10)
	for x in range(-300, 1500, 70):
		add_visual_rect(Rect2(x, 568, 5, 42), Color("#102332"), -10)

	var floor_visual: Polygon2D = $Arena/Floor/FloorVisual
	floor_visual.polygon = PackedVector2Array([Vector2(-1100, -40), Vector2(1100, -40), Vector2(1100, 500), Vector2(-1100, 500)])
	var floor_shader := Shader.new()
	floor_shader.code = """
shader_type canvas_item;
uniform bool arena_two = false;
varying vec2 p;
void vertex() { p = VERTEX; }
void fragment() {
    float row = floor((p.y + 40.0) / 26.0);
    float seam = step(0.965, fract((p.y + 40.0) / 26.0));
    seam += step(0.985, fract((p.x + 576.0 + mod(row, 2.0) * 48.0) / 96.0));
    if (arena_two) {
        float diagonal = step(0.94, fract((p.x + p.y * 0.72) / 46.0));
        seam = max(seam, diagonal * 0.75);
    }
    float grain = fract(sin(dot(floor(p * 1.5), vec2(12.9898,78.233))) * 43758.5453);
    vec3 base_one = mix(vec3(0.19,0.22,0.27), vec3(0.07,0.10,0.15), smoothstep(-40.0,180.0,p.y));
    float stone_grain = fract(sin(dot(floor(p * 0.11), vec2(41.7, 83.3))) * 15731.743);
    vec3 base_two = mix(vec3(0.16,0.105,0.075), vec3(0.035,0.028,0.032), smoothstep(-40.0,180.0,p.y));
    base_two += (stone_grain - 0.5) * 0.035;
    vec3 base = arena_two ? base_two : base_one;
    COLOR = vec4(base + grain * 0.024 - seam * (arena_two ? 0.06 : 0.035), 1.0);
}
"""
	floor_material = ShaderMaterial.new()
	floor_material.shader = floor_shader
	floor_material.set_shader_parameter("arena_two", false)
	floor_visual.material = floor_material
	floor_line = $Arena/Floor/FloorLine
	floor_line.default_color = Color("#dbad6b")
	$Arena/Floor/FloorLine.width = 3.0
	add_visual_rect(Rect2(-350, 614, 1850, 3), Color(0.86, 0.63, 0.34, 0.18), 1)


func add_visual_rect(rect: Rect2, tint: Color, depth: int) -> Polygon2D:
	var shape := Polygon2D.new()
	shape.position = rect.position
	shape.polygon = PackedVector2Array([Vector2.ZERO, Vector2(rect.size.x, 0), rect.size, Vector2(0, rect.size.y)])
	shape.color = tint
	shape.z_index = depth
	add_child(shape)
	return shape


func setup_lava_visuals() -> void:
	for rect: Rect2 in [Rect2(0.0, LAVA_TOP_Y, Fighter.LAVA_PLATFORM_LEFT, 320.0), Rect2(Fighter.LAVA_PLATFORM_RIGHT, LAVA_TOP_Y, 1152.0 - Fighter.LAVA_PLATFORM_RIGHT, 320.0)]:
		var base := add_visual_rect(rect, Color("#51121c"), 2)
		base.color = Color.WHITE
		base.material = create_lava_material(rect.position.x)
		base.visible = false
		lava_surfaces.append(base)
		lava_bases.append(base)
		var glow := add_visual_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 110.0), Color("#e13c20"), 3)
		glow.color = Color(1.0, 0.15, 0.025, 0.22)
		glow.material = additive_material()
		glow.visible = false
		lava_surfaces.append(glow)
		lava_glows.append(glow)
		var hot_core := add_visual_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 9.0), Color("#ff9a32"), 4)
		hot_core.color = Color(1.0, 0.48, 0.1, 0.7)
		hot_core.material = additive_material()
		hot_core.visible = false
		lava_surfaces.append(hot_core)
		lava_glows.append(hot_core)
		var embers := CPUParticles2D.new()
		embers.name = "LavaEmbers"
		embers.position = Vector2(rect.position.x + rect.size.x * 0.5, LAVA_TOP_Y + 12.0)
		embers.z_index = 5
		embers.amount = 32
		embers.lifetime = 1.15
		embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		embers.emission_rect_extents = Vector2(rect.size.x * 0.45, 5.0)
		embers.direction = Vector2(0.0, -1.0)
		embers.spread = 30.0
		embers.gravity = Vector2(0.0, -24.0)
		embers.initial_velocity_min = 22.0
		embers.initial_velocity_max = 74.0
		embers.scale_amount_min = 0.18
		embers.scale_amount_max = 0.5
		embers.texture = particle_texture
		var ember_ramp := Gradient.new()
		ember_ramp.colors = PackedColorArray([Color("#fff0a3"), Color("#ff6a25"), Color(1.0, 0.14, 0.04, 0.0)])
		ember_ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		embers.color_ramp = ember_ramp
		embers.emitting = false
		embers.hide()
		add_child(embers)
		lava_embers.append(embers)
	setup_lava_backdrop()


func create_lava_material(flow_offset: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float flow_offset = 0.0;
varying vec2 local_point;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), f.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		value += value_noise(p) * amplitude;
		p = p * 2.03 + vec2(7.1, 3.7);
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	local_point = VERTEX;
}

void fragment() {
	vec2 flow = local_point * 0.018 + vec2(flow_offset * 0.013, -TIME * 0.11);
	float warp = fbm(flow * 1.65);
	float heat = fbm(flow + vec2(warp * 0.72, warp * 0.38));
	vec2 cell = flow * 1.75 + vec2(warp * 0.22, 0.0);
	vec2 grid = floor(cell);
	vec2 fraction = fract(cell);
	float nearest = 10.0;
	float next_nearest = 10.0;
	float cell_random = 0.5;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 id = grid + neighbor;
			vec2 center = neighbor + vec2(hash21(id), hash21(id + 19.19)) * 0.72 + 0.14;
			float distance_to_center = length(center - fraction);
			if (distance_to_center < nearest) {
				next_nearest = nearest;
				nearest = distance_to_center;
				cell_random = hash21(id + 7.7);
			} else if (distance_to_center < next_nearest) {
				next_nearest = distance_to_center;
			}
		}
	}
	float crack_gap = next_nearest - nearest;
	float cooled_crust = smoothstep(0.075, 0.23, crack_gap);
	vec3 molten = mix(vec3(0.25, 0.012, 0.004), vec3(1.0, 0.30, 0.018), smoothstep(0.22, 0.76, heat));
	vec3 crust = mix(vec3(0.075, 0.018, 0.015), vec3(0.18, 0.045, 0.018), cell_random);
	float bright_vein = 1.0 - smoothstep(0.025, 0.10, crack_gap);
	vec3 color = mix(molten, crust, cooled_crust * 0.96);
	color += bright_vein * vec3(0.38, 0.055, 0.006) * (0.65 + heat * 0.8);
	COLOR = vec4(color, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("flow_offset", flow_offset)
	return material


func setup_lava_backdrop() -> void:
	var ridges := [
		PackedVector2Array([Vector2(0, 610), Vector2(0, 492), Vector2(38, 472), Vector2(76, 492), Vector2(116, 424), Vector2(153, 478), Vector2(193, 449), Vector2(231, 500), Vector2(273, 459), Vector2(315, 516), Vector2(356, 552), Vector2(356, 610)]),
		PackedVector2Array([Vector2(796, 610), Vector2(796, 551), Vector2(835, 517), Vector2(877, 455), Vector2(918, 498), Vector2(957, 443), Vector2(1001, 486), Vector2(1043, 418), Vector2(1085, 483), Vector2(1120, 459), Vector2(1152, 488), Vector2(1152, 610)])
	]
	for ridge_points: PackedVector2Array in ridges:
		var ridge := Polygon2D.new()
		ridge.polygon = ridge_points
		ridge.color = Color("#241317")
		ridge.z_index = -8
		ridge.visible = false
		add_child(ridge)
		lava_backdrop_shapes.append(ridge)
	for chain_x: float in [94.0, 1058.0]:
		var chain := Line2D.new()
		var links := PackedVector2Array()
		for segment in range(18):
			var center_x := chain_x + (7.0 if segment % 2 == 0 else -7.0)
			var y := 292.0 + float(segment) * 14.0
			links.append(Vector2(center_x, y))
			links.append(Vector2(chain_x, y + 7.0))
		chain.points = links
		chain.width = 4.0
		chain.default_color = Color("#74604b")
		chain.antialiased = true
		chain.z_index = -6
		chain.visible = false
		add_child(chain)
		lava_backdrop_shapes.append(chain)


func update_lava_visuals(delta: float) -> void:
	lava_visual_time += delta
	if selected_stage != 1:
		return
	for index in range(lava_glows.size()):
		var pulse := 0.72 + sin(lava_visual_time * 6.2 + float(index) * 1.4) * 0.22
		lava_glows[index].modulate.a = pulse


func setup_hud_style() -> void:
	for rect: Rect2 in [Rect2(16, 64, 372, 116), Rect2(764, 64, 372, 116)]:
		var panel := Panel.new()
		panel.position = rect.position
		panel.size = rect.size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.035, 0.06, 0.10, 0.88)
		style.set_corner_radius_all(16)
		style.set_border_width_all(1)
		style.border_color = Color(0.48, 0.65, 0.78, 0.3)
		style.shadow_color = Color(0, 0, 0, 0.3)
		style.shadow_size = 8
		panel.add_theme_stylebox_override("panel", style)
		$HUD.add_child(panel)
		$HUD.move_child(panel, 0)
	var bold := SystemFont.new()
	bold.font_names = PackedStringArray(["Arial", "DejaVu Sans"])
	bold.font_weight = 800
	for label: Label in [
		$HUD/Title, round_label, timer_label, match_message, match_end_text, pause_text,
		main_menu_text, $HUD/MainMenuScreen/MainTitle,
		stage_select_text, $HUD/StageSelectScreen/StageTitle,
		$HUD/SettingsScreen/SettingsTitle, settings_volume_text, settings_shake_text,
		$HUD/SettingsScreen/SettingsHint, $HUD/ControlsScreen/ControlsTitle, controls_text
	]:
		label.add_theme_font_override("font", bold)
		label.add_theme_color_override("font_outline_color", Color("#101b2c"))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 3)
	$HUD/Title.add_theme_color_override("font_color", Color("#f4d7a7"))
	round_label.add_theme_color_override("font_color", Color("#e5eef8"))


func update_leader_glow() -> void:
	var score_1 := player_1_round_wins * 101 + player_1.health
	var score_2 := player_2_round_wins * 101 + player_2.health
	for index in range(2):
		var bar: ProgressBar = player_1_health if index == 0 else player_2_health
		if not bar.has_theme_stylebox_override("fill"):
			continue
		var style := bar.get_theme_stylebox("fill") as StyleBoxFlat
		var ahead := score_1 > score_2 if index == 0 else score_2 > score_1
		style.shadow_size = 9 if ahead else 0
		var glow := PLAYER_1_COLOR if index == 0 else PLAYER_2_COLOR
		glow.a = 0.32
		style.shadow_color = glow


func update_camera(delta: float) -> void:
	ko_zoom_time = maxf(ko_zoom_time - delta, 0.0)
	var left := minf(player_1.position.x, player_2.position.x)
	var right := maxf(player_1.position.x, player_2.position.x)
	var gap := right - left
	var fit_zoom := 1152.0 / (gap + 220.0)
	var desired_zoom := minf(1.10, fit_zoom)
	if ko_zoom_time > 0.0:
		desired_zoom = minf(desired_zoom * 1.07, fit_zoom)
	var zoom_value := lerpf(camera.zoom.x, desired_zoom, 1.0 - exp(-delta * 7.0))
	zoom_value = minf(zoom_value, fit_zoom)
	camera.zoom = Vector2.ONE * zoom_value
	var jump_height := maxf(562.0 - minf(player_1.position.y, player_2.position.y), 0.0)
	var target := Vector2((left + right) * 0.5, 395.0 - minf(jump_height * 0.18, 60.0))
	var half_width := 576.0 / zoom_value
	target.x = clampf(target.x, half_width - 70.0, maxf(half_width - 70.0, 1222.0 - half_width))
	camera.position = camera.position.lerp(target, 1.0 - exp(-delta * 5.0))
	# Keep the padding even while the smoothed camera catches up.
	camera.position.x = clampf(camera.position.x, right + 100.0 - half_width, left - 100.0 + half_width)
	shake_time = maxf(shake_time - delta, 0.0)
	var strength := SHAKE_PIXELS * shake_time / SHAKE_DURATION if screen_shake_enabled else 0.0
	camera.offset = Vector2(visual_rng.randf_range(-strength, strength), visual_rng.randf_range(-strength, strength))


func setup_post_processing() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var screen := ColorRect.new()
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float impact = 0.0;
void fragment() {
    vec3 c = texture(screen_texture, SCREEN_UV).rgb;
    float luminance = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(luminance), c, 1.06) * vec3(0.99, 1.015, 1.035);
    float vignette = smoothstep(0.20, 0.72, length(UV - vec2(0.5)));
    c *= 1.0 - vignette * 0.23;
    c = mix(c, vec3(1.0, 0.62, 0.25), clamp(impact, 0.0, 1.0) * 0.17);
    COLOR = vec4(c, 1.0);
}
"""
	post_material = ShaderMaterial.new()
	post_material.shader = shader
	screen.material = post_material


func _on_visual_hit(at: Vector2, blocked: bool, big_hit: bool) -> void:
	spawn_burst(at, "hit", Color("#97d9ff") if blocked else Color("#ffd18a"))
	if big_hit:
		tint_time = 0.16


func _on_dust(at: Vector2, landing: bool) -> void:
	spawn_burst(at, "land" if landing else "dust", Color(0.7, 0.73, 0.78, 0.5))


func spawn_burst(at: Vector2, kind: String, tint: Color) -> void:
	var burst := CPUParticles2D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 36 if kind == "ko" else (14 if kind == "hit" else 7)
	burst.lifetime = 0.65 if kind == "ko" else (0.35 if kind == "hit" else 0.42)
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0 if kind == "hit" or kind == "ko" else 65.0
	burst.gravity = Vector2(0, 280 if kind == "ko" else 130)
	burst.initial_velocity_min = 80.0 if kind == "hit" or kind == "ko" else 12.0
	burst.initial_velocity_max = 230.0 if kind == "ko" else (145.0 if kind == "hit" else 42.0)
	burst.scale_amount_min = 0.18 if kind == "hit" else 0.35
	burst.scale_amount_max = 0.42 if kind == "hit" else 0.9
	burst.texture = particle_texture
	var ramp := Gradient.new()
	var clear := tint
	clear.a = 0.0
	ramp.colors = PackedColorArray([tint, clear])
	burst.color_ramp = ramp
	effects.add_child(burst)
	burst.global_position = at
	burst.finished.connect(burst.queue_free)
	burst.emitting = true
