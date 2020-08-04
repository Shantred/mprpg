extends KinematicBody2D

export var movement_speed = 400
var screen_size
var is_attacking = false;
var facing_direction = "right"
var hit_distance = 85
var player_id = 0
var velocity = Vector2()



var my_peer = null
func _ready():
	screen_size = get_viewport_rect().size
	
	
func _physics_process(delta):
	if (!is_attacking):
		if velocity.length() > 0:
			$AnimatedSprite.play("run")
		else:
			$AnimatedSprite.play("idle")
	$AnimatedSprite.flip_h = velocity.x < 0
	
	

#func _physics_process(delta):
#	var velocity = Vector2()
#	if Input.is_action_pressed("ui_right"):
#		velocity.x += 1
#		facing_direction = "right"
#	if Input.is_action_pressed("ui_left"):
#		velocity.x -= 1
#		facing_direction = "left"
#	if Input.is_action_pressed("ui_down"):
#		velocity.y += 1
#		facing_direction = "down"
#	if Input.is_action_pressed("ui_up"):
#		velocity.y -= 1
#		facing_direction = "up"
#
#	if is_attacking == false:
#		if velocity.length() > 0:
#			velocity = velocity.normalized() * movement_speed
#			$AnimatedSprite.play("run")
#		else:
#			$AnimatedSprite.play("idle")
#
#		# We flip the current animation based on velocity. The placement of this assignment
#		# means we can adjust our player's facing direction just before attacking, but also
#		# cannot adjust it WHILE attacking.	
#		$AnimatedSprite.flip_h = velocity.x < 0		
#
#	move_and_collide(velocity * delta)
#	position.x = clamp(position.x, 0, screen_size.x)
#	position.y = clamp(position.y, 0, screen_size.y)
#
#	if is_attacking == false:
#		if Input.is_action_pressed("ui_select"):
#				is_attacking = true
#				$AnimatedSprite.play("attack")
#				# On the first frame of an attack, use a raycast in the direction the user is facing
#				# to determine if we've hit an enemy
#				var space_state = get_world_2d().direct_space_state
#				var rayVector = Vector2()
#
#				# We base the distance of our raycasts on the width of the base sprite.
#				# For animated sprites, that means the first frame of idle.
#				if facing_direction == "right":
#					# We cast a full sprite width to the right. This creates a cast that is actually half a player distance
#					# away because the ray should be cast from the center of the sprite.
#					rayVector.x = position.x + hit_distance
#					rayVector.y = position.y
#				elif facing_direction == "left":
#					rayVector.x = 	position.x - hit_distance
#					rayVector.y = position.y
#				elif facing_direction == "up":
#					rayVector.x = position.x
#					rayVector.y = position.y - hit_distance
#				elif facing_direction == "down":
#					rayVector.x = position.x
#					rayVector.y = position.y + hit_distance
#
#
#				var results = space_state.intersect_ray(Vector2(position.x, position.y), rayVector, [self])
#				if results:
#					results.collider.take_damage(3)

func attack():
	if is_attacking == false:
		is_attacking = true
		$AnimatedSprite.play("attack")
		# On the first frame of an attack, use a raycast in the direction the user is facing
		# to determine if we've hit an enemy
		var space_state = get_world_2d().direct_space_state
		var ray_vector = Vector2()
		
		# We base the distance of our raycasts on the width of the base sprite.
		# For animated sprites, that means the first frame of idle.
		if facing_direction == "right":
			# We cast a full sprite width to the right. This creates a cast that is actually half a player distance
			# away because the ray should be cast from the center of the sprite.
			ray_vector.x = position.x + hit_distance
			ray_vector.y = position.y
		elif facing_direction == "left":
			ray_vector.x = 	position.x - hit_distance
			ray_vector.y = position.y
		elif facing_direction == "up":
			ray_vector.x = position.x
			ray_vector.y = position.y - hit_distance
		elif facing_direction == "down":
			ray_vector.x = position.x
			ray_vector.y = position.y + hit_distance


		var results = space_state.intersect_ray(Vector2(position.x, position.y), ray_vector, [self])
		if results:
			results.collider.take_hit()
		
		
	
func is_attacking():
	return is_attacking
	
func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "attack":
		$AnimatedSprite.play("idle")
		is_attacking = false


