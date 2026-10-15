extends CharacterBody2D
class_name Fighter

# These values are deliberately kept here so they are easy to adjust later.
const MOVE_SPEED: float = 300.0
const ACCELERATION: float = 2200.0
const GRAVITY: float = 1400.0
const JUMP_VELOCITY: float = -560.0
const MAX_HEALTH: int = 100
const ATTACK_DAMAGE: int = 20
const ARMED_ATTACK_DAMAGE: int = 35
const BLOCK_CHIP_DAMAGE: int = 5
const SPECIAL_DAMAGE: int = 40
const SPECIAL_CHIP_DAMAGE: int = 10
const SPECIAL_KNOCKBACK_X: float = 620.0
const SPECIAL_KNOCKBACK_Y: float = -260.0
const MAX_SUPER_METER: int = 100
const SUPER_METER_ON_LANDED_HIT: int = 25
const SUPER_METER_ON_TAKING_HIT: int = 25
const ATTACK_RANGE: float = 90.0
const ARMED_ATTACK_RANGE: float = 140.0
const ATTACK_COOLDOWN: float = 0.45
const HITSTUN_TIME: float = 0.25
const HIT_FLASH_TIME: float = 0.12
const ATTACK_POSE_TIME: float = 0.16
const KNOCKBACK_X: float = 380.0
const KNOCKBACK_Y: float = -180.0
const ARENA_LEFT: float = 17.0
const ARENA_RIGHT: float = 1135.0
const LAVA_PLATFORM_LEFT: float = 356.0
const LAVA_PLATFORM_RIGHT: float = 796.0
const LAVA_DAMAGE: int = 10
const LAVA_DAMAGE_INTERVAL: float = 0.5

signal health_changed(current_health: int)
signal defeated(fighter: Fighter)
signal hit_landed
signal weapon_dropped(fighter: Fighter)
signal visual_hit(at: Vector2, blocked: bool, big_hit: bool)
signal dust_requested(at: Vector2, landing: bool)
signal super_meter_changed(value: int)
signal special_requested(fighter: Fighter)
signal damage_number_requested(amount: int, at: Vector2)

@export var player_number: int = 1
@export var fighter_color: Color = Color(0.96, 0.82, 0.49, 1.0)

@onready var visuals: Node2D = $Visuals
@onready var head: Polygon2D = $Visuals/Head
@onready var body: Line2D = $Visuals/Body
@onready var arms: Line2D = $Visuals/Arms
@onready var legs: Line2D = $Visuals/Legs

var jump_was_pressed := false
var attack_was_pressed := false
var attack_cooldown := 0.0
var hitstun_time := 0.0
var hit_flash_time := 0.0
var attack_pose_time := 0.0
var health: int = MAX_HEALTH
var facing_direction := 1.0
var can_fight := false
var is_defeated := false
var is_dummy := false
var practice_mode := false
var arena_two_enabled := false
var lava_damage_cooldown := 0.0
var lava_recoil_time := 0.0
var has_weapon := false
var opponent: Fighter
var held_weapon: Polygon2D
var idle_time := 0.0
var walk_cycle := 0.0
var floor_shadow: Sprite2D
var shading: ShaderMaterial
var dust_time := 0.0
var pose_state := ""
var pose_elapsed := 0.0
var pose_start_arms := PackedVector2Array()
var pose_start_legs := PackedVector2Array()
var pose_start_position := Vector2.ZERO
var pose_start_rotation := 0.0
var is_cpu_controlled := false
var cpu_move_direction := 0.0
var cpu_jump_pressed := false
var cpu_attack_pressed := false
var cpu_block_pressed := false
var cpu_special_pressed := false
var super_meter := 0
var special_was_pressed := false
var special_charging := false
var special_charge_time := 0.0
var charge_orb: Polygon2D
var practice_meter_was_pressed := false


func _ready() -> void:
	configure_block_action()
	held_weapon = Polygon2D.new()
	held_weapon.polygon = PackedVector2Array([Vector2(-4, -5), Vector2(56, -5), Vector2(56, 5), Vector2(-4, 5)])
	held_weapon.color = Color(0.68, 0.43, 0.2)
	held_weapon.visible = false
	visuals.add_child(held_weapon)
	charge_orb = Polygon2D.new()
	charge_orb.polygon = make_circle_polygon(9.0, 16)
	charge_orb.position = Vector2(4, -28)
	charge_orb.color = Color(0.82, 0.96, 1.0, 0.95)
	charge_orb.visible = false
	charge_orb.z_index = 2
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	charge_orb.material = additive
	visuals.add_child(charge_orb)
	setup_fighter_style()
	set_visual_color(fighter_color)
	face_opponent()
	add_to_group("fighters")


func _physics_process(delta: float) -> void:
	var was_grounded := is_on_floor()
	dust_time = maxf(dust_time - delta, 0.0)
	idle_time += delta
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	hitstun_time = maxf(hitstun_time - delta, 0.0)
	attack_pose_time = maxf(attack_pose_time - delta, 0.0)
	lava_damage_cooldown = maxf(lava_damage_cooldown - delta, 0.0)
	lava_recoil_time = maxf(lava_recoil_time - delta, 0.0)
	if hit_flash_time > 0.0:
		hit_flash_time = maxf(hit_flash_time - delta, 0.0)
		if hit_flash_time == 0.0:
			set_visual_color(fighter_color)

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var jump_pressed := is_jump_pressed()
	var attack_pressed := is_attack_pressed()
	var special_pressed := is_special_pressed()
	var meter_fill_pressed := is_practice_meter_pressed()
	if meter_fill_pressed and not practice_meter_was_pressed and can_fight:
		set_super_meter(MAX_SUPER_METER)
	practice_meter_was_pressed = meter_fill_pressed
	face_opponent()

	if can_fight and hitstun_time <= 0.0 and lava_recoil_time <= 0.0:
		var move_direction := get_move_direction()
		var target_speed := move_direction * MOVE_SPEED
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)

		if jump_pressed and not jump_was_pressed and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if attack_pressed and not attack_was_pressed and attack_cooldown <= 0.0:
			perform_attack()
		if special_pressed and not special_was_pressed and super_meter >= MAX_SUPER_METER and not special_charging:
			special_requested.emit(self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)

	jump_was_pressed = jump_pressed
	attack_was_pressed = attack_pressed
	special_was_pressed = special_pressed
	if charge_orb != null:
		charge_orb.visible = special_charging
		var charge_pulse := 1.0 + sin(idle_time * 18.0) * 0.18
		charge_orb.scale = Vector2.ONE * charge_pulse

	var falling_speed := velocity.y
	move_and_slide()
	if not arena_two_enabled:
		position.x = clampf(position.x, ARENA_LEFT, ARENA_RIGHT)
	else:
		update_lava_hazard()
	face_opponent()
	if can_fight and is_on_floor() and absf(velocity.x) > 25.0:
		walk_cycle += absf(velocity.x) * delta * 0.045
	if is_on_floor() and not was_grounded and falling_speed > 80.0:
		dust_requested.emit(Vector2(global_position.x, 608.0), true)
	elif can_fight and is_on_floor() and absf(velocity.x) > 100.0 and dust_time <= 0.0:
		dust_requested.emit(Vector2(global_position.x, 608.0), false)
		dust_time = 0.15
	update_arm_pose(delta)
	update_floor_shadow()


func update_lava_hazard() -> void:
	var over_lava := position.x < LAVA_PLATFORM_LEFT or position.x > LAVA_PLATFORM_RIGHT
	if not over_lava:
		lava_damage_cooldown = 0.0
		return
	if position.y < 560.0 or not can_fight or is_defeated or lava_damage_cooldown > 0.0:
		return
	take_lava_damage()


func take_lava_damage() -> void:
	if is_defeated:
		return
	var actual_damage := mini(LAVA_DAMAGE, health)
	health -= actual_damage
	health_changed.emit(health)
	damage_number_requested.emit(actual_damage, global_position + Vector2(0, -52.0))
	lava_damage_cooldown = LAVA_DAMAGE_INTERVAL
	var inward_direction := 1.0 if position.x < LAVA_PLATFORM_LEFT else -1.0
	velocity = Vector2(inward_direction * 220.0, -380.0)
	lava_recoil_time = 0.18
	if has_weapon:
		drop_weapon()
	hit_flash_time = HIT_FLASH_TIME
	set_visual_color(Color.WHITE)
	visual_hit.emit(global_position + Vector2(0, -25.0), false, true)
	if health == 0:
		is_defeated = true
		can_fight = false
	update_arm_pose()
	if health == 0:
		defeated.emit(self)


func face_opponent() -> void:
	if opponent == null:
		facing_direction = -1.0 if player_number == 2 else 1.0
	else:
		var horizontal_gap := opponent.global_position.x - global_position.x
		if absf(horizontal_gap) > 1.0:
			facing_direction = signf(horizontal_gap)
	visuals.scale.x = facing_direction


func get_move_direction() -> float:
	if is_dummy:
		return 0.0
	if is_cpu_controlled:
		return cpu_move_direction
	var direction := 0.0
	if is_left_pressed():
		direction -= 1.0
	if is_right_pressed():
		direction += 1.0
	return direction


func is_jump_pressed() -> bool:
	if is_dummy:
		return false
	if is_cpu_controlled:
		return cpu_jump_pressed
	if player_number == 2:
		return Input.is_key_pressed(KEY_UP)

	return Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W)


func is_attack_pressed() -> bool:
	if is_dummy:
		return false
	if is_cpu_controlled:
		return cpu_attack_pressed
	if player_number == 2:
		return Input.is_key_pressed(KEY_O)
	return Input.is_key_pressed(KEY_F)


func is_block_pressed() -> bool:
	if is_dummy:
		return false
	if is_cpu_controlled:
		return cpu_block_pressed
	return Input.is_action_pressed("player_%d_block" % player_number)


func is_special_pressed() -> bool:
	if is_dummy:
		return false
	if is_cpu_controlled:
		return cpu_special_pressed
	return Input.is_key_pressed(KEY_P) if player_number == 2 else Input.is_key_pressed(KEY_G)


func is_practice_meter_pressed() -> bool:
	if not practice_mode or is_dummy or is_cpu_controlled:
		return false
	return Input.is_key_pressed(KEY_M) if player_number == 1 else Input.is_key_pressed(KEY_N)


func make_circle_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(sides):
		var angle := TAU * float(index) / sides
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func add_super_meter(amount: int) -> void:
	set_super_meter(super_meter + amount)


func set_super_meter(value: int) -> void:
	var updated_meter := clampi(value, 0, MAX_SUPER_METER)
	if updated_meter == super_meter:
		return
	super_meter = updated_meter
	super_meter_changed.emit(super_meter)


func configure_block_action() -> void:
	var action_name := "player_%d_block" % player_number
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var block_key := InputEventKey.new()
	block_key.keycode = KEY_DOWN if player_number == 2 else KEY_S
	InputMap.action_add_event(action_name, block_key)


func is_left_pressed() -> bool:
	if player_number == 2:
		return Input.is_key_pressed(KEY_LEFT)
	return Input.is_key_pressed(KEY_A)


func is_right_pressed() -> bool:
	if player_number == 2:
		return Input.is_key_pressed(KEY_RIGHT)
	return Input.is_key_pressed(KEY_D)


func perform_attack() -> void:
	if not can_fight or is_defeated or attack_cooldown > 0.0:
		return
	attack_cooldown = ATTACK_COOLDOWN
	attack_pose_time = ATTACK_POSE_TIME
	update_arm_pose()
	var attack_damage := ARMED_ATTACK_DAMAGE if has_weapon else ATTACK_DAMAGE
	var attack_range := ARMED_ATTACK_RANGE if has_weapon else ATTACK_RANGE

	for fighter_node in get_tree().get_nodes_in_group("fighters"):
		if fighter_node == self:
			continue

		var other_fighter := fighter_node as Fighter
		if other_fighter == null or other_fighter.is_defeated:
			continue

		var to_other_fighter := other_fighter.global_position - global_position
		if absf(to_other_fighter.x) > attack_range or absf(to_other_fighter.y) > 110.0:
			continue
		if to_other_fighter.x * facing_direction <= 0.0:
			continue

		if other_fighter.take_hit(facing_direction, attack_damage):
			add_super_meter(SUPER_METER_ON_LANDED_HIT)
			hit_landed.emit()
			break


func take_hit(attacker_direction: float, damage: int) -> bool:
	if is_defeated or hitstun_time > 0.0:
		return false

	var blocked := can_fight and is_block_pressed()
	var actual_damage := mini(BLOCK_CHIP_DAMAGE if blocked else damage, health)
	health -= actual_damage
	health_changed.emit(health)
	damage_number_requested.emit(actual_damage, global_position + Vector2(0, -52.0))
	add_super_meter(SUPER_METER_ON_TAKING_HIT)
	special_charging = false
	special_charge_time = 0.0
	if has_weapon:
		drop_weapon()
	if not blocked:
		velocity = Vector2(attacker_direction * KNOCKBACK_X, KNOCKBACK_Y)
		hitstun_time = HITSTUN_TIME
	hit_flash_time = HIT_FLASH_TIME
	set_visual_color(Color.WHITE)
	visual_hit.emit(global_position + Vector2(-attacker_direction * 10.0, -25.0), blocked, damage >= ARMED_ATTACK_DAMAGE and not blocked)
	if health == 0:
		is_defeated = true
		can_fight = false
	update_arm_pose()
	if health == 0:
		defeated.emit(self)
	return true


func take_special_hit(attacker_direction: float) -> bool:
	if is_defeated or hitstun_time > 0.0:
		return false
	var blocked := can_fight and is_block_pressed()
	var actual_damage := mini(SPECIAL_CHIP_DAMAGE if blocked else SPECIAL_DAMAGE, health)
	health -= actual_damage
	health_changed.emit(health)
	damage_number_requested.emit(actual_damage, global_position + Vector2(0, -52.0))
	add_super_meter(SUPER_METER_ON_TAKING_HIT)
	special_charging = false
	special_charge_time = 0.0
	if has_weapon:
		drop_weapon()
	if not blocked:
		velocity = Vector2(attacker_direction * SPECIAL_KNOCKBACK_X, SPECIAL_KNOCKBACK_Y)
		hitstun_time = HITSTUN_TIME
	hit_flash_time = HIT_FLASH_TIME
	set_visual_color(Color.WHITE)
	visual_hit.emit(global_position + Vector2(-attacker_direction * 10.0, -25.0), blocked, not blocked)
	if health == 0:
		is_defeated = true
		can_fight = false
	update_arm_pose()
	if health == 0:
		defeated.emit(self)
	return true


func blend_points(start: PackedVector2Array, target: PackedVector2Array, weight: float) -> PackedVector2Array:
	if start.size() != target.size():
		return target
	var result := PackedVector2Array()
	for index in range(target.size()):
		result.append(start[index].lerp(target[index], weight))
	return result


func setup_fighter_style() -> void:
	z_index = 5
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform bool hit_flash = false;
varying vec2 point;
void vertex() { point = VERTEX; }
void fragment() {
    float shade = mix(1.16, 0.72, smoothstep(-75.0, 40.0, point.y));
    COLOR.rgb *= hit_flash ? 1.0 : shade;
}
"""
	shading = ShaderMaterial.new()
	shading.shader = shader
	head.material = shading
	for line: Line2D in [body, arms, legs]:
		line.width = 9.0
		line.antialiased = true
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.material = shading
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.01, 0.015, 0.025, 0.7), Color(0.01, 0.015, 0.025, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 48
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	floor_shadow = Sprite2D.new()
	floor_shadow.texture = texture
	floor_shadow.z_index = -1
	add_child(floor_shadow)
	update_floor_shadow()


func update_floor_shadow() -> void:
	if floor_shadow == null:
		return
	var height := clampf((562.0 - global_position.y) / 200.0, 0.0, 1.0)
	floor_shadow.position = Vector2(0, 608.0 - global_position.y)
	floor_shadow.scale = Vector2(lerpf(0.8, 0.48, height), lerpf(0.55, 0.35, height))
	floor_shadow.modulate.a = lerpf(0.8, 0.35, height)


func stop_fighting() -> void:
	can_fight = false


func set_visual_color(tint: Color) -> void:
	head.color = tint
	body.default_color = tint
	arms.default_color = tint
	legs.default_color = tint
	if shading != null:
		shading.set_shader_parameter("hit_flash", tint == Color.WHITE)


func update_arm_pose(delta: float = 0.0) -> void:
	var walking := can_fight and is_on_floor() and absf(velocity.x) > 25.0
	var new_state := "idle"
	if is_defeated:
		new_state = "collapse"
	elif hitstun_time > 0.0:
		new_state = "recoil"
	elif special_charging:
		new_state = "charge"
	elif attack_pose_time > 0.0:
		new_state = "attack"
	elif can_fight and is_block_pressed():
		new_state = "block"
	elif walking:
		new_state = "walk"
	if new_state != pose_state:
		pose_state = new_state
		pose_elapsed = 0.0
		pose_start_arms = arms.points
		pose_start_legs = legs.points
		pose_start_position = visuals.position
		pose_start_rotation = visuals.rotation
	pose_elapsed += delta
	var stride := sin(walk_cycle) * 12.0 if walking else 0.0
	visuals.rotation = 0.0
	# Align the drawn feet with the unchanged collision body's floor contact.
	visuals.position = Vector2(0, 10.0 + (sin(idle_time * 4.0) * 2.0 if is_on_floor() and not walking else 0.0))
	legs.points = PackedVector2Array([
		Vector2(-7, 0), Vector2(-27 + stride, 34),
		Vector2(-7, 0), Vector2(15 - stride, 34)
	])

	if is_defeated:
		visuals.rotation = -facing_direction * 1.15
		visuals.position = Vector2(-facing_direction * 18.0, 25.0)
		arms.points = PackedVector2Array([Vector2(-7, -28), Vector2(-38, -30), Vector2(-7, -20), Vector2(30, -23)])
		legs.points = PackedVector2Array([Vector2(-7, 0), Vector2(-47, 20), Vector2(-7, 0), Vector2(34, 28)])
	elif hitstun_time > 0.0:
		visuals.rotation = -facing_direction * 0.25
		visuals.position = Vector2(-facing_direction * 5.0, 4.0)
		arms.points = PackedVector2Array([Vector2(-7, -28), Vector2(-35, -42), Vector2(-7, -20), Vector2(-24, -47)])
	elif special_charging:
		arms.points = PackedVector2Array([Vector2(-7, -28), Vector2(-27, -37), Vector2(-7, -20), Vector2(25, -37)])
	elif attack_pose_time > 0.0:
		var hand_x := 16.0 if has_weapon else 54.0
		arms.points = PackedVector2Array([Vector2(-7, -28), Vector2(-30, -12), Vector2(-7, -22), Vector2(hand_x, -24)])
	elif can_fight and is_block_pressed():
		arms.points = PackedVector2Array([Vector2(-7, -28), Vector2(-21, -44), Vector2(-7, -24), Vector2(15, -48)])
	else:
		arms.points = PackedVector2Array([
			Vector2(-7, -28), Vector2(-30 - stride * 0.6, -12),
			Vector2(-7, -20), Vector2(16 + stride * 0.6, -8)
		])

	# Sine easing changes only the drawn pose, never movement or hit timing.
	var transition_time := 0.1
	if pose_state == "attack" or pose_state == "recoil":
		transition_time = 0.045
	elif pose_state == "collapse":
		transition_time = 0.22
	var progress := clampf(pose_elapsed / transition_time, 0.0, 1.0)
	var blend := 0.5 - cos(progress * PI) * 0.5
	arms.points = blend_points(pose_start_arms, arms.points, blend)
	legs.points = blend_points(pose_start_legs, legs.points, blend)
	visuals.position = pose_start_position.lerp(visuals.position, blend)
	visuals.rotation = lerp_angle(pose_start_rotation, visuals.rotation, blend)

	if has_weapon:
		held_weapon.position = arms.points[3]
		if attack_pose_time > 0.0:
			var swing_progress := 1.0 - attack_pose_time / ATTACK_POSE_TIME
			held_weapon.rotation = lerpf(-1.1, 0.85, smoothstep(0.0, 1.0, swing_progress))
		elif can_fight and is_block_pressed():
			held_weapon.rotation = -0.45
		else:
			held_weapon.rotation = 0.45


func equip_weapon() -> void:
	has_weapon = true
	held_weapon.show()
	update_arm_pose()


func drop_weapon() -> void:
	if not has_weapon:
		return
	has_weapon = false
	held_weapon.hide()
	weapon_dropped.emit(self)


func reset_for_round(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	has_weapon = false
	held_weapon.hide()
	health = MAX_HEALTH
	set_super_meter(0)
	special_charging = false
	special_charge_time = 0.0
	charge_orb.hide()
	attack_cooldown = 0.0
	hitstun_time = 0.0
	hit_flash_time = 0.0
	attack_pose_time = 0.0
	idle_time = 0.0
	walk_cycle = 0.0
	dust_time = 0.0
	pose_state = ""
	is_defeated = false
	lava_damage_cooldown = 0.0
	lava_recoil_time = 0.0
	can_fight = false
	jump_was_pressed = is_jump_pressed()
	attack_was_pressed = is_attack_pressed()
	special_was_pressed = is_special_pressed()
	practice_meter_was_pressed = false
	set_visual_color(fighter_color)
	update_arm_pose(1.0)
	update_floor_shadow()
	face_opponent()
	health_changed.emit(health)


func revive_from_practice() -> void:
	if arena_two_enabled and (
		position.y > 680.0
		or position.x < LAVA_PLATFORM_LEFT
		or position.x > LAVA_PLATFORM_RIGHT
	):
		position = Vector2(430.0 if player_number == 1 else 722.0, 450.0)
	health = MAX_HEALTH
	velocity = Vector2.ZERO
	is_defeated = false
	can_fight = true
	hitstun_time = 0.0
	hit_flash_time = 0.0
	lava_damage_cooldown = LAVA_DAMAGE_INTERVAL
	lava_recoil_time = 0.0
	set_visual_color(fighter_color)
	update_arm_pose(1.0)
	health_changed.emit(health)
