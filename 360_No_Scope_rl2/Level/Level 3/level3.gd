extends Node2D

const bullet_scene: PackedScene = preload("res://Assets/Rockstar Studios/New Character Design/character_body_2d.tscn")

func _ready():
	var player = get_node("MC")
	var ai = player.get_node_or_null("AI")
	if ai:
		ai.player = player
		ai.enemy = get_node("TextureRect/Enemy2")
		call_deferred("_setup_ai_mode")

func _setup_ai_mode():
	var player = get_node("MC")
	var ai = player.get_node("AI")
	if ai.control_mode == 2:
		player.ai_controlled = true
	elif ai.control_mode == 3:
		player.ai_controlled = true

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")

func _on_restart_pressed():
	get_tree().reload_current_scene()


func _on_mc_shoot(pos):
	var bullet = bullet_scene.instantiate()
	$Bullets2.add_child(bullet)
	bullet.position = pos + Vector2(-50, -140)


func _on_enemy_1_enemy_died():
	print("we got the signal")
