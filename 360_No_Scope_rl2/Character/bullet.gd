extends CharacterBody2D

@export var speed := 450

var direction = Vector2(1,0)
var lifetime := 3.0
func change_direction():
	pass # wall hit
	direction *= -1
	$Arrow.scale.x *= -1
func bounce(x_angle, y_angle):
	pass # bounce
	direction = Vector2(x_angle, y_angle).normalized()
	$Arrow.rotation = direction.angle()
	

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	var velocity1 = direction * speed
	var collision = move_and_collide(velocity1 * delta)
	if collision:
		var hit_body = collision.get_collider()
		var normal = collision.get_normal()
		pass # arrow hit
		if hit_body.is_in_group("enemies"):
			hit_body.killEnemy()
			queue_free()
		elif hit_body.is_in_group("walls"):
			pass # normal
			if normal.y != 0:
				var x_angle = normal.x
				var y_angle = normal.y
				bounce(x_angle, y_angle)
			else:
				change_direction()
		elif hit_body is TileMap:
			change_direction()
