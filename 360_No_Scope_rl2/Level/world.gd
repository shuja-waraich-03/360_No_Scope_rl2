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

func _ready():
	polygon_2d.polygon = collision_polygon_2d.polygon
	polygon_2d2.polygon = collision_polygon_2d2.polygon

	# Check if AI controller exists and set up training mode
	var player = get_node("MC")
	var ai = player.get_node_or_null("AI")
	if ai:
		is_training = true
		player.ai_controlled = true
		ai.player = player
		ai.enemy = get_node("Enemy1")
		get_node("Enemy1").training_mode = true

func _on_mc_shoot(pos):
	var bullet = bullet_scene.instantiate()
	$Bullets.add_child(bullet)
	bullet.position = pos + Vector2(-10, -170)

func _on_enemy_1_enemy_died():
	pass
	var player = get_node("MC")
	if is_training and not resetting:
		resetting = true
		# Give positive reward
		var ai = player.get_node("AI")
		ai._reward += 1.0
		# Reset the episode
		call_deferred("reset_episode")
	else:
		if player:
			player.fly()
			get_tree().change_scene_to_file("res://LevelMenu/NextLevel.tscn")
		else:
			print("found an error")

func reset_episode():
	resetting = false
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
	# Check if player fell off the map or died — give negative reward and reset
	var player = get_node_or_null("MC")
	if not resetting and player and (player.dead or player.global_position.y > 800):
		resetting = true
		var ai = player.get_node("AI")
		ai._reward -= 1.0
		call_deferred("reset_episode")

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")

func _on_restart_pressed():
	get_tree().reload_current_scene()
