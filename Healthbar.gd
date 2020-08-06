extends ColorRect

export var maxHealth = 10
var currentHealth = 0

func SetHealth(amount):
	currentHealth = amount
	var percentHealth =  (float(currentHealth) / maxHealth) * 100
	var health = get_node("Health")
	health.set_size(Vector2(percentHealth, health.get_size().y))
	
	
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	SetHealth(maxHealth)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
