extends Node2D

# The world is a container for all objects in a particular scene.
# For now, there is only one world, but we may need to split these up
# and reorganize later.

# World exists on both server and client, with the server being authoritative
# over the contents on both.


onready var mobs_node = $mobs
var mobs = {}
var players = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	var children = mobs_node.get_children()
	if children.size() > 0:
		for child in children:
			print(str(child))
			add_mob(child)
	
func add_mob(mob):
	var props = {}
	
	# We store velocity and position in the top level of the dictionary and use it
	# as a reference to update the node later.
	props.velocity = Vector2()
	props.position = mob.position
	props.node = mob
	mobs[mob.get_instance_id()] = props
	
func get_mobs():
	return mobs
	
