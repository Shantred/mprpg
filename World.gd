extends Node2D

# The world is a container for all objects in a particular scene.
# For now, there is only one world, but we may need to split these up
# and reorganize later.

# World exists on both server and client, with the server being authoritative
# over the contents on both.

var mobs = {}
var players = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func add_mob(mob):
	var info = {}
	info.name = "test"
	info.node = mob
	mobs[mob.get_instance_id()] = info
	
func get_mobs():
	return mobs
	
