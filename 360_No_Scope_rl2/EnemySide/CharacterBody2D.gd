extends CharacterBody2D


@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var Enemy_Death = $Enemy_Death
signal enemy_died
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead = false
var training_mode := false


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

func killEnemy():
	if is_dead:
		return
	is_dead = true
	enemy_died.emit()
	if training_mode:
		return
	animated_sprite.play("death")
	Enemy_Death.play()
	await animated_sprite.animation_finished
	queue_free()
