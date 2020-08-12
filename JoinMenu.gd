extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_JoinBtn_pressed():
	var display_name = get_node("DisplayNameField")
	var server_ip = get_node("ServerIP")
	Global.set_ip(server_ip.get_text())
	Global.set_name(display_name.get_text())
	get_tree().change_scene("res://Client.tscn")
	


func _on_CancelBtn_pressed():
	get_tree().change_scene("res://Menu.tscn")
