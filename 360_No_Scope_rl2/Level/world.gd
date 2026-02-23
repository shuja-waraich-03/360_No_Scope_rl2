extends Node2D

@onready var collision_polygon_2d = $StaticBody2D/CollisionPolygon2D
@onready var polygon_2d = $StaticBody2D/CollisionPolygon2D/Polygon2D

@onready var collision_polygon_2d2 = $StaticBody2D/CollisionPolygon2D2
@onready var polygon_2d2 = $StaticBody2D/CollisionPolygon2D2/Polygon2D2

const bullet_scene: PackedScene = preload("res://Assets/Rockstar Studios/New Character Design/character_body_2d.tscn")


# Starting positions for reset
var player_start_pos := Vector2(47, 211)
var enemy_start_pos := Vector2(297, 323)

var is_training := false
var resetting := false
var shots_fired := 0

func _ready():
	polygon_2d.polygon = collision_polygon_2d.polygon
	polygon_2d2.polygon = collision_polygon_2d2.polygon

	# Set up AI references, then defer mode check so Sync node can set control_mode first
	var player = get_node("MC")
	var ai = player.get_node_or_null("AI")
	if ai:
		ai.player = player
		ai.enemy = get_node("Enemy1")
		call_deferred("_setup_ai_mode")

func _setup_ai_mode():
	var player = get_node("MC")
	var ai = player.get_node("AI")
	# control_mode: 0=Inherit(Sync decides), 1=Human, 2=Training, 3=ONNX
	# When using training scene, Sync sets mode to 2 but may not have run yet.
	# Mode 0 means Sync is present and will drive training, so treat as training.
	if ai.control_mode == 0 or ai.control_mode == 2:
		is_training = true
		player.ai_controlled = true
		get_node("Enemy1").training_mode = true
	elif ai.control_mode == 3:
		player.ai_controlled = true

func _on_mc_shoot(pos):
	var bullet = bullet_scene.instantiate()
	$Bullets.add_child(bullet)
	bullet.position = pos + Vector2(-10, -170)

	# Track shots and reward only well-timed ones
	if is_training:
		var player = get_node("MC")
		var enemy = get_node("Enemy1")
		if not enemy.is_dead:
			var ai = player.get_node("AI")
			shots_fired += 1

			# Heavy penalty for every shot after the first
			if shots_fired > 1:
				ai._reward -= 0.5
				return

			var height_diff = abs(player.global_position.y - enemy.global_position.y)
			var falling = not player.is_on_floor() and player.velocity.y > 0

			if falling and height_diff < 40.0:
				ai._reward += 1.5  # Perfect one-shot timing
				print("PERFECT SHOT! height_diff: ", height_diff)
			elif falling and height_diff < 80.0:
				ai._reward += 0.4
			elif not player.is_on_floor() and height_diff < 60.0:
				ai._reward += 0.15
			elif not player.is_on_floor():
				ai._reward -= 0.1

func _on_enemy_1_enemy_died():
	pass
	var player = get_node("MC")
	if is_training and not resetting:
		resetting = true
		var ai = player.get_node("AI")
		# Massive bonus for one-shot kill
		if shots_fired == 1:
			ai._reward += 3.0
			print("ONE-SHOT KILL! shots: ", shots_fired)
		else:
			ai._reward += 1.0
			print("KILL! shots: ", shots_fired)
		# Reset the episode
		call_deferred("reset_episode")
	#else:
		#if player:
			#player.fly()
			#get_tree().change_scene_to_file("res://LevelMenu/NextLevel.tscn")
		#else:
			#print("found an error")

func reset_episode():
	resetting = false
	shots_fired = 0
	var player = get_node("MC")

	# Reset player state
	player.dead = false
	player.flying = false
	player.can_shoot = true
	player.animation_locked = false
	player.was_in_air = false
	player.velocity = Vector2.ZERO
	player.direction = Vector2.ZERO
	player.position = player_start_pos
	player.get_node("AnimatedSprite2D").play("idle")

	# Clear all bullets
	for bullet in $Bullets.get_children():
		bullet.queue_free()

	# Reset enemy in place (no respawn to avoid name conflicts)
	var enemy = get_node("Enemy1")
	enemy.is_dead = false
	enemy.position = enemy_start_pos
	enemy.velocity = Vector2.ZERO

func _physics_process(_delta):
	if not is_training:
		return
	var player = get_node_or_null("MC")
	if not player or resetting:
		return

	# Check if player died or fell off map — mild penalty so AI isn't afraid to explore
	if player.dead or player.global_position.y > 800:
		resetting = true
		var ai = player.get_node("AI")
		ai._reward -= 0.1
		call_deferred("reset_episode")
		return

	# Reward shaping — guide AI toward the cliff-jump-shoot strategy
	var enemy = get_node("Enemy1")
	if enemy.is_dead:
		return
	var ai = player.get_node("AI")

	if player.is_on_floor():
		# Penalize standing still on the ground — force exploration
		ai._reward -= 0.002
		# Reward for moving right toward the cliff
		if player.velocity.x > 0:
			ai._reward += 0.005
	else:
		# Big reward for being airborne — this is what we want
		ai._reward += 0.02
		# Even bigger bonus near enemy height
		var height_diff = abs(player.global_position.y - enemy.global_position.y)
		if height_diff < 60.0:
			ai._reward += 0.05

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")

func _on_restart_pressed():
	get_tree().reload_current_scene()
