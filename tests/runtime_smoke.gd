extends SceneTree

var failed_checks := 0


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var packed_scene := load("res://scenes/game/main.tscn") as PackedScene
	if packed_scene == null:
		check("main scene loads", false)
		quit(1)
		return
	var game := packed_scene.instantiate()
	root.add_child(game)
	await process_frame
	check("main menu is shown at launch", game.menu_view == 0 and game.main_menu_screen.visible)
	game.process_start_menu(false, false, false, false, true)
	check("Play opens mode select", game.menu_view == 1 and game.start_screen.visible)
	game.selected_mode_option = 4
	game.process_start_menu(false, false, false, false, true)
	check("Practice opens opponent select", game.menu_view == 2 and game.practice_mode)
	game.selected_practice_opponent = 3
	game.process_start_menu(false, false, false, false, true)
	check("dummy choice opens stage select", game.menu_view == 3 and game.player_2.is_dummy)
	game.process_start_menu(false, false, false, true, false)
	check("stage selector switches arenas", game.selected_stage == 1)
	game.selected_stage = 0

	var p1 = game.player_1
	var p2 = game.player_2
	p2.is_dummy = false
	p1.can_fight = true
	p2.can_fight = true
	p1.position = Vector2(300.0, 450.0)
	p2.position = Vector2(350.0, 450.0)
	p2.health = Fighter.MAX_HEALTH
	p2.hitstun_time = 0.0
	p2.velocity = Vector2.ZERO
	p2.take_hit(1.0, Fighter.ATTACK_DAMAGE)
	check("normal punch applies 20 damage", p2.health == 80)
	check("damage number label is created", has_damage_label(game, "-20"))

	p2.health = Fighter.MAX_HEALTH
	p2.hitstun_time = 0.0
	p2.velocity = Vector2.ZERO
	Input.action_press("player_2_block")
	p2.take_hit(1.0, Fighter.ATTACK_DAMAGE)
	Input.action_release("player_2_block")
	check("blocked punch applies 5 chip damage", p2.health == 95)
	check("blocked punch has no knockback", p2.velocity == Vector2.ZERO)

	p2.health = Fighter.MAX_HEALTH
	p2.hitstun_time = 0.0
	p1.attack_cooldown = 0.0
	p1.facing_direction = 1.0
	p1.perform_attack()
	var health_after_first_punch: int = p2.health
	p1.perform_attack()
	check("unarmed attack uses 20 damage", health_after_first_punch == 80)
	check("attack cooldown prevents immediate repeat", p2.health == health_after_first_punch)

	game.spawn_weapon()
	p1.equip_weapon()
	game.weapon_holder = p1
	game.weapon_pickup.hide()
	p1.attack_cooldown = 0.0
	p2.health = Fighter.MAX_HEALTH
	p2.hitstun_time = 0.0
	p2.velocity = Vector2.ZERO
	p1.perform_attack()
	check("weapon can be equipped", p1.has_weapon and not game.weapon_pickup.visible)
	check("armed attack applies 35 damage", p2.health == 65)
	p1.health = Fighter.MAX_HEALTH
	p1.hitstun_time = 0.0
	p1.take_hit(-1.0, Fighter.ATTACK_DAMAGE)
	check("taking a hit disarms the weapon holder", not p1.has_weapon and game.weapon_holder == null and game.weapon_pickup.visible)
	p1.health = Fighter.MAX_HEALTH
	p1.hitstun_time = 0.0
	p2.health = Fighter.MAX_HEALTH
	p2.hitstun_time = 0.0

	p2.hitstun_time = 0.0
	p2.health = Fighter.MAX_HEALTH
	p2.take_special_hit(1.0)
	check("unblocked special applies 40 damage", p2.health == 60)

	p2.health = Fighter.MAX_HEALTH
	p2.hitstun_time = 0.0
	Input.action_press("player_2_block")
	p2.take_special_hit(1.0)
	Input.action_release("player_2_block")
	check("blocked special applies 10 chip damage", p2.health == 90)

	game.phase = 2
	p1.can_fight = true
	p1.is_defeated = false
	p1.set_super_meter(Fighter.MAX_SUPER_METER)
	game.begin_special_charge(p1)
	game.update_special_charges(1.0)
	check("full meter fires a special projectile", game.special_blasts.size() == 1 and game.has_active_special_blast(p1))
	check("firing a special consumes the meter", p1.super_meter == 0)
	var fired_blast: Area2D = game.special_blasts[0]
	var has_projectile_trail := false
	for blast_child: Node in fired_blast.get_children():
		if blast_child is CPUParticles2D:
			has_projectile_trail = true
	check("special projectile includes a particle trail", has_projectile_trail)
	p1.set_super_meter(Fighter.MAX_SUPER_METER)
	game.fire_special_blast(p1)
	check("only one projectile per fighter can be active", game.special_blasts.size() == 1)
	game.remove_special_blast(fired_blast)

	p1.health = Fighter.MAX_HEALTH
	p1.arena_two_enabled = true
	p1.take_lava_damage()
	check("lava tick applies 10 damage", p1.health == 90)
	check("lava damage number label is created", has_damage_label(game, "-10"))
	game.selected_stage = 1
	game.apply_stage_visuals(1)
	check("Arena 2 enables lava-stage fighter physics", p1.arena_two_enabled and p2.arena_two_enabled)
	game.spawn_weapon()
	p1.equip_weapon()
	game.weapon_holder = p1
	p1.position = Vector2(300.0, 450.0)
	p1.health = Fighter.MAX_HEALTH
	p1.hitstun_time = 0.0
	p1.take_hit(1.0, Fighter.ATTACK_DAMAGE)
	check("weapon dropped into lava is hidden and scheduled to respawn", not game.weapon_pickup.visible and game.weapon_lava_respawn_time > 0.0)
	game.selected_stage = 0
	game.apply_stage_visuals(0)
	check("Arena 1 restores non-lava fighter physics", not p1.arena_two_enabled and not p2.arena_two_enabled)

	game.practice_mode = true
	game.selected_mode_option = 4
	game.practice_dummy_opponent = true
	p2.is_dummy = true
	p2.is_cpu_controlled = false
	game.start_selected_mode()
	check("Practice hides timer", not game.timer_label.visible)
	check("Practice starts without timer", not game.round_timer_running)
	check("dummy does not move or attack", p2.get_move_direction() == 0.0 and not p2.is_attack_pressed())
	game.phase = 2
	p1.can_fight = true
	p2.can_fight = true
	p2.health = Fighter.MAX_HEALTH
	p2.hitstun_time = 0.0
	p2.take_hit(1.0, Fighter.MAX_HEALTH)
	check("Practice KO schedules recovery", is_equal_approx(game.practice_restore_player_2, 1.0))
	game.update_practice_recovery(1.01)
	check("Practice restores KO fighter to full health", p2.health == Fighter.MAX_HEALTH and p2.can_fight)
	check("Practice KO does not award a round", game.player_1_round_wins == 0 and game.phase == 2)

	game.selected_stage = 1
	game.apply_stage_visuals(1)
	p2.is_cpu_controlled = true
	p2.position.x = Fighter.LAVA_PLATFORM_RIGHT - 10.0
	p2.cpu_move_direction = 0.0
	p2.velocity.x = 120.0
	game.keep_cpu_on_safe_platform()
	check("CPU is steered inward at the Arena 2 platform edge", p2.cpu_move_direction == -1.0 and p2.velocity.x <= 0.0)
	p2.is_cpu_controlled = false
	game.selected_stage = 0
	game.apply_stage_visuals(0)

	game.practice_mode = false
	game.selected_mode_option = 3
	p2.is_dummy = false
	game.start_selected_mode()
	check("normal match shows its timer", game.timer_label.visible)
	game.phase_time = 0.01
	game.intro_showing_fight = false
	game._process(0.02)
	check("normal timer starts at FIGHT", game.round_timer_running and game.intro_showing_fight)

	p1.health = Fighter.MAX_HEALTH
	p2.health = Fighter.MAX_HEALTH
	game.phase = 2
	game.round_time_remaining = 0.05
	game.round_timer_running = true
	game.update_round_timer(0.1)
	check("timer reaches TIME_UP at zero", game.phase == 3 and not game.round_timer_running)
	game._process(1.0)
	check("equal-health timeout is a draw without a round win", game.phase == 4 and game.player_1_round_wins == 0 and game.player_2_round_wins == 0)

	p1.health = 70
	p2.health = 30
	game.phase = 2
	game.round_time_remaining = 0.05
	game.round_timer_running = true
	game.update_round_timer(0.1)
	game._process(1.0)
	check("higher health wins a timeout round", game.player_1_round_wins == 1)

	game.player_1_round_wins = 0
	game.player_2_round_wins = 0
	game.phase = 2
	game.announce_round_winner(1)
	game.announce_round_winner(1)
	check("two round wins end the match", game.phase == 6 and game.match_end_screen.visible)

	game.phase = 2
	game.toggle_pause()
	check("Esc pause state can be entered", game.phase == 7 and game.pause_screen.visible)
	game.toggle_pause()
	check("pause state can be resumed", game.phase == 2 and not game.pause_screen.visible)

	print("RUNTIME_SMOKE_SUMMARY: %d passed, %d failed" % [get_check_count() - failed_checks, failed_checks])
	await create_timer(1.2).timeout
	game.queue_free()
	await process_frame
	quit(1 if failed_checks > 0 else 0)


var completed_checks := 0


func check(description: String, passed: bool) -> void:
	completed_checks += 1
	if passed:
		print("PASS: " + description)
	else:
		failed_checks += 1
		push_error("FAIL: " + description)


func get_check_count() -> int:
	return completed_checks


func has_damage_label(game: Node, text: String) -> bool:
	for child: Node in game.effects.get_children():
		if child is Label and child.text == text:
			return true
	return false
