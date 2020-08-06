extends KinematicBody2D

export var MaxHealth = 10
var currentHealth = 10

var velocity = Vector2()

# Take hit is separate from take_damage. Take_damage is done only
# once the server verifies the hit. take_hit simply animates the attack
func take_hit():
	pass
	
	
func set_health(health):
	currentHealth = health
	if currentHealth < 0:
		currentHealth = 0
		on_death()
		
	get_node("Healthbar").SetHealth(currentHealth)
	
func take_damage(amount):
	currentHealth -= amount
	if currentHealth < 0:
		currentHealth = 0;
		on_death()
		
	get_node("Healthbar").SetHealth(currentHealth)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Idle")
	
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
	var spawner = get_parent()
	position = spawner.get_random_position(spawner.AreaRadius)
	print("Spawn radius is : " + str(spawner.AreaRadius))
	
func respawn():	
	print("Respawning")
	currentHealth = MaxHealth
	$Healthbar.SetHealth(currentHealth)
	$Healthbar.show()
	show()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Idle")
	$CollisionShape2D.disabled = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_RespawnTimer_timeout():
	respawn()


func collide():
	print("I collided")
	
func test():
	return "test success!"
