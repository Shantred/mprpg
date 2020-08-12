extends KinematicBody2D

export var movement_speed = 400
export var max_health = 300
var current_health = 300
var screen_size
var is_attacking = false;
var facing_direction = "right"
var hit_distance = 85
var player_id = 0
var velocity = Vector2()
var is_dead = false
var experience = 0
var level = 1
var damage = 13



var my_peer = null

func _ready():
	screen_size = get_viewport_rect().size
	current_health = max_health
	$Healthbar.init(current_health)
	
func set_health(health):
	current_health = health
	
	# Handles revive client-side
	#if is_dead && current_health > 0:
	#	client_revive()
	
	if current_health < 0:
		current_health = 0
	
	#if current_health == 0 && !is_dead:
		#client_death()
		
		
	get_node("Healthbar").SetHealth(current_health)
	
func take_damage(amount):
	current_health -= amount
	if current_health < 0:
		current_health = 0;
	
	#if current_health == 0:
		#on_death()
		
	get_node("Healthbar").SetHealth(current_health)
	
func take_hit():
	pass
	
func _physics_process(delta):
	if (!is_attacking):
		if velocity.length() > 0:
			$AnimatedSprite.play("run")
		else:
			$AnimatedSprite.play("idle")
	
	
func get_damage():
	return damage;

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
		else:
			print("No direction to attack found");
			# Default to attacking from the right.
			ray_vector.x = position.x + hit_distance
			ray_vector.y = position.y
			
			# TODO: Use a facing_direction that is preserved based on last movement


		var results = space_state.intersect_ray(Vector2(position.x, position.y), ray_vector, [self])
		if results:
			if results.collider.has_method("take_hit"):
				results.collider.take_hit()
			return results
		else:
			return false
		
		
	
func is_attacking():
	return is_attacking
	
func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "attack":
		$AnimatedSprite.play("idle")
		is_attacking = false

func set_direction(vel):
	# facing direction is different than the sprite flip position for now
	# because we don't have back and front animations.
	# We also have this as a separate value because we need to know where to raycast
	# which may not be obvious if, say, the velocity value is 0
	if vel.x > 0:
		facing_direction = "right"
	elif vel.x < 0:
		facing_direction = "left"
	elif vel.y > 0:
		facing_direction = "down"
	elif vel.y < 0:
		facing_direction = "up"
		
	$AnimatedSprite.flip_h = velocity.x < 0
	
func set_name(name):
	$PlayerNameLabel.text = name
	
func add_experience(amount):
	experience += amount
	if experience >= level * 150:
		experience = 0
		level += 1
	
		# TODO: This is temporary, for use with very simple level ups	
		recalculate_damage()
	
func recalculate_damage():
	damage = 10 * (1 + (level * .3))
	
	
