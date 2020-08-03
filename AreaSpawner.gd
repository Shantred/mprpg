extends Area2D

export (PackedScene) var MobToSpawn
export var NumberToSpawn = 1
export var AreaRadius = 300

func _ready():
	randomize()
	
	# Set radius of spawn area child
	get_node("SpawnArea").shape.radius = AreaRadius
	
	# We will pick a random position between 0 and and the radius of the spawn area
	var position = get_random_position(AreaRadius)
	
	var mob = MobToSpawn.instance()
	mob.position = position
	mob.show()
	get_parent().call_deferred("add_child", mob)

	get_parent().add_mob(mob);
	
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





