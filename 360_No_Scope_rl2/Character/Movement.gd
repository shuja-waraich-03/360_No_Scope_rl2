extends CharacterBody2D



@export var speed : float =  200.0
@export var jump_velocity : float = -200.0

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var Death_sfx = $Death_sfx

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false
var can_shoot : bool = true
var dead : bool = false
var flying : bool = false
var ai_controlled : bool = false

signal shoot(pos: Vector2)


func _physics_process(delta):
	if (not dead):# Add the gravity.
		if(not flying):
			if not is_on_floor():
				velocity.y += gravity * delta
				was_in_air = true
			else:
				if was_in_air == true:
					land()
				was_in_air = false

	# Skip keyboard input when AI is controlling
	if not ai_controlled:
		# Handle jump. # spin = jump
		if Input.is_action_just_pressed("spin"):
			if is_on_floor():
				spin()

		if Input.is_action_just_pressed("shoot") and can_shoot and not flying:
			shoot.emit(global_position)
			can_shoot = false
			$CooldownTimer.start()

		# Get the input direction and handle the movement/deceleration.
		if not dead:
			direction = Input.get_vector("left", "right", "ui_up", "ui_down")
			if direction and not flying:
				velocity.x = direction.x * speed
			else:
				velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	update_animation()
	
	
func update_animation():
	if not animation_locked:
		if direction.x != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")
		if not is_on_floor():
			animated_sprite.play("fall _spin")
			animation_locked = true
			
func spin():
	velocity.y = jump_velocity
	animated_sprite.play("spin")
	animation_locked = true
	
func land():
	animated_sprite.play("idle")
	animation_locked = false

func _on_animated_sprite_2d_animation_finished():
	if(animated_sprite.animation == "idle"):
		animation_locked = false
		

func _on_cooldown_timer_timeout():
	can_shoot = true

func killMC():
	pass
	dead = true
	can_shoot = false
	velocity.y = 0
	velocity.x = 0
	if not ai_controlled:
		animated_sprite.play("death")
		Death_sfx.play()
		await animated_sprite.animation_finished
		queue_free()
	

func fly():
	if not dead:
		flying = true
		velocity.y = -500
		pass
		animated_sprite.play("spin")
		
