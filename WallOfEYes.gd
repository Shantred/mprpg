extends KinematicBody2D

export var MaxHealth = 10
var currentHealth = 10


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
