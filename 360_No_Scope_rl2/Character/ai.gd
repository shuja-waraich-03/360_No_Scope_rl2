extends AIController2D

# References set by the training level script
var player: CharacterBody2D
var enemy: CharacterBody2D

var _reward: float = 0.0

func get_obs() -> Dictionary:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return {"obs": [0.0, 0.0, 0.0, 0.0]}

	# Relative position: enemy relative to player (normalized by screen scale)
	var rel_pos = enemy.global_position - player.global_position
	var rel_x = rel_pos.x / 720.0
	var rel_y = rel_pos.y / 560.0

	# Player state
	var vel_y = player.velocity.y / 500.0
	var on_floor = 1.0 if player.is_on_floor() else 0.0

	return {"obs": [rel_x, rel_y, vel_y, on_floor]}

func get_reward() -> float:
	var current_reward = _reward
	_reward = 0.0
	return current_reward

func get_action_space() -> Dictionary:
	return {
		"move": {
			"size": 3,
			"action_type": "discrete"
		},
		"jump": {
			"size": 2,
			"action_type": "discrete"
		},
		"shoot": {
			"size": 2,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:
	if not is_instance_valid(player) or player.dead:
		return

	# Move: 0=nothing, 1=left, 2=right
	var move_action = action["move"]
	if move_action == 1:
		player.direction = Vector2(-1, 0)
		player.velocity.x = -player.speed
	elif move_action == 2:
		player.direction = Vector2(1, 0)
		player.velocity.x = player.speed
	else:
		player.direction = Vector2.ZERO
		player.velocity.x = move_toward(player.velocity.x, 0, player.speed)

	# Jump: 0=nothing, 1=jump
	if action["jump"] == 1 and player.is_on_floor():
		player.spin()

	# Shoot: 0=nothing, 1=shoot
	if action["shoot"] == 1 and player.can_shoot and not player.flying:
		player.shoot.emit(player.global_position)
		player.can_shoot = false
		player.get_node("CooldownTimer").start()
