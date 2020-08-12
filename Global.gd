extends Node


var server_ip = "127.0.0.1"
var display_name = "test user"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_ip(address):
	server_ip = address

func set_name(name):
	display_name = name
	
func get_ip():
	return server_ip

func get_name():
	return display_name
