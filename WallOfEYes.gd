extends KinematicBody2D

export var MaxHealth = 10
var currentHealth = 10

var velocity = Vector2()

var area_radius = 1200
var is_dead = false
var experience = 50

# Used when calculating respawn position. We want the area the mob spawns in to be relative
# to where they started, not where they currently are
var starting_position = Vector2()

# Take hit is separate from take_damage. Take_damage is done only
# once the server verifies the hit. take_hit simply animates the attack
func take_hit(direction):
	# Animation plays as though the monster was attacked from the left. 
	if direction == "right":
		$Sprite.flip_h = 1
	$AnimationPlayer.stop()
	$AnimationPlayer.play("hit")
	
	

	
func set_health(health):
	currentHealth = health
	
	# Handles revive client-side
	if is_dead && currentHealth > 0:
		client_revive()
	
	if currentHealth < 0:
		currentHealth = 0
	
	if currentHealth == 0 && !is_dead:
		client_death()
		
		
	get_node("Healthbar").SetHealth(currentHealth)
	
func take_damage(amount):
	currentHealth -= amount
	if currentHealth < 0:
		currentHealth = 0;
	
	if currentHealth == 0:
		on_death()
		
	get_node("Healthbar").SetHealth(currentHealth)
	
	return currentHealth == 0
func client_death():
	print("Mob died")
	is_dead = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("death")
	$CollisionShape2D.disabled = true
	$Healthbar.hide()
	
	# Show corpse for 2 seconds before hiding it
	yield(get_tree().create_timer(2), "timeout")
	hide()
	
	
	
func client_revive():
	print("mob revived")
	is_dead = false
	$Healthbar.SetHealth(currentHealth)
	$Healthbar.show()
	show()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Idle")
	$CollisionShape2D.disabled = false
	

# Called when the node enters the scene tree for the first time.
func _ready():
	starting_position = self.position
	$AnimationPlayer.play("Idle")
	currentHealth = MaxHealth
	$Healthbar.init(currentHealth)
	
func on_death():
	print("wallofeyes dead")
	$AnimationPlayer.stop()
	$AnimationPlayer.play("death")
	$RespawnTimer.start();
	$CollisionShape2D.disabled = true
	$Healthbar.hide()
	
	# Show corpse for 2 seconds before hiding it
	yield(get_tree().create_timer(2), "timeout")
	hide()
	
	# Get new position from spawner. We do this now while the collider is disabled
	position = get_random_position(area_radius)
	
	is_dead = true
	
func respawn():	
	print("Respawning")
	currentHealth = MaxHealth
	$Healthbar.SetHealth(currentHealth)
	$Healthbar.show()
	show()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Idle")
	$CollisionShape2D.disabled = false
	
	print("Health is: " + str(currentHealth))
# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_RespawnTimer_timeout():
	respawn()


func collide():
	print("I collided")
	
func test():
	return "test success!"
	
# TODO: Uhhh, this has no way to bias it to the position the mob starts in
func get_random_position(radius):
	print("Getting random position")
	var x1 = rand_range(-1, 1)
	var x2 = rand_range(-1, 1)
	while x1*x1 + x2*x2 >= 1:
		x1 = rand_range(-1, 1)
		x2 = rand_range(-1, 1)
		
	var random_position = Vector2(
		2 * x1 * sqrt (1 - x1*x1 - x2*x2),
		2 * x2 * sqrt (1 - x1*x1 - x2*x2)
	)
	
	return random_position * rand_range(0, radius)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "hit":
		$AnimationPlayer.play("Idle")
		
		


func _on_DetectionArea_body_entered(body):
	pass
