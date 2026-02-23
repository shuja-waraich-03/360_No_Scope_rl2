extends Node2D

const bullet_scene: PackedScene = preload("res://Assets/Rockstar Studios/New Character Design/character_body_2d.tscn")
var enemies = 2
var win = false

func _ready():
	var player = get_node("MC2")
	var ai = player.get_node_or_null("AI")
	if ai:
		ai.player = player
		ai.enemy = get_node("Enemy1")
		call_deferred("_setup_ai_mode")

func _setup_ai_mode():
	var player = get_node("MC2")
	var ai = player.get_node("AI")
	if ai.control_mode == 2:
		player.ai_controlled = true
	elif ai.control_mode == 3:
		player.ai_controlled = true

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")


func _on_restart_pressed():
	get_tree().reload_current_scene()





func _on_mc_2_shoot(pos):
	var bullet = bullet_scene.instantiate()
	$Bullets2.add_child(bullet)
	bullet.position = pos + Vector2(-10, -170)



func _on_enemy_1_enemy_died():
	print("We got to the signal")
	enemies -= 1


func _on_enemy_2_enemy_died():
	enemies -= 1
	print("we got to the second signal")
	win = true
	print("Win: ", win)
	var player = get_node("MC")
	#if player:
		#player.fly()
		
	get_tree().change_scene_to_file("res://Level/Level 3/Level3.tscn")
	#else:
		#print("found an error")
	
