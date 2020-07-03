extends Node

var last_update = -1
var players = {}
var cached_player = load("res://Player.tscn")
var cached_woe = load("res://WallOfEYes.tscn")
var my_peer = null
var my_info = { name = "teent" }

onready var node_players = $camera/players

func _ready():
	print("Connecting to server...")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", 1337)
	
	get_tree().set_network_peer(peer)
	
	my_peer = peer
	
	# Connect signals
	if get_tree().connect("connected_to_server", self, "client_connected_ok") != OK:
		print("Unable to connect signal (connected_to_server) !")
		
	if get_tree().connect("connection_failed", self, "client_connected_fail") != OK:
		print("Unable to connect signal (connection_failed) !")
		
	if get_tree().connect("server_disconnected", self, "server_disconnected") != OK:
		print("Unable to connect signal (server_disconnected) !")
		
func _process(delta):
	# To mitigate latency issues we use interpolation. The idea is simple, we receive
	# position updates every TICK_DURATION (50 ms, 20 per seconds). We interpolate between
	# the last two previous updates, this way we always have smooth movements. The
	# main drawback is added latency (100 ms).
	var pos = Vector2(0,0)
	var target_timestamp = OS.get_ticks_msec() - (50 * 2)
	
	for peerId in players:
		var keys = players[peerId].updates.keys()
		for i in range(0, keys.size()):
			if keys[i] > target_timestamp:
				var percent = float(target_timestamp - keys[i-1]) / 50
				
				players[peerId].position.x = lerp(players[peerId].updates[keys[i-1]].position.x, players[peerId].updates[keys[i]].position.x, percent)
				players[peerId].position.y = lerp(players[peerId].updates[keys[i-1]].position.y, players[peerId].updates[keys[i]].position.y, percent)
				players[peerId].node.set_position(players[peerId].position)
	
				players[peerId].velocity = lerp(players[peerId].updates[keys[i-1]].velocity, players[peerId].updates[keys[i]].velocity, percent)
			break
				
				
	# Simple movement for now, no prediction. Just tell the server we are currently moving.
	if Input.is_action_just_pressed("ui_right"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "right", true)	
	if Input.is_action_just_released("ui_right"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "right", false)

	if Input.is_action_just_pressed("ui_left"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "left", true)	
	if Input.is_action_just_released("ui_left"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "left", false)
		
	if Input.is_action_just_pressed("ui_up"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "up", true)	
	if Input.is_action_just_released("ui_up"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "up", false)
		
	if Input.is_action_just_pressed("ui_down"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "down", true)	
	if Input.is_action_just_released("ui_down"):
		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "down", false)	

func client_connected_ok():
	print("client connected!")
	my_info.name = "Tester"
	rpc_id(1, "register_player", get_tree().get_network_unique_id(), my_info)
	print("Send rpc to server for connect!")
	
func server_disconnected():
	print("Server disconnected!")
	OS.alert("You have been disconnected!", "Connection Closed")
	get_tree().change_scene("res://Menu.tscn")


func client_connected_fail():
	print("Callback: client_connected_fail")
	OS.alert('Unable to connect to server!', 'Connection Failed')
	# Change to login scene
	if get_tree().change_scene("res://Menu.tscn") != OK:
		print("Unable to load login scene!")
		
# Player update
# Named "pu" to lower bandwidth. 
remote func pu(id, updateId, pos, velocity):
	# Updates are sent as unreliable rpcs. Since they can be sent in an arbitrary order, discard if it's not the
	# newest update
	if updateId < last_update:
		print("discarding update")
		return
		
	last_update = updateId
	players[id].updates[OS.get_ticks_msec] = { position = pos, velocity = velocity }
	
	# Only keep the last 10 updates
	while len(players[id].updates) > 10:
		players[id].updates.erase(players[id].updates.keys()[0])
		
remote func player_joined(id, info):
	print("Player joined: " + str(id))
	
	var node_player = cached_player.instance()
	info.node = node_player
	info.updates = {}
	
	var pos = Vector2(info.position.x, info.position.y)
	node_player.set_position(pos)
	node_player.name = info.name
	
	node_players.add_child(node_player)
	
	
	players[id] = info

remote func player_leaving(id):
	print("Callback: player_leaving(" + str(id)+")")
	players[id].node.queue_free()
	players.erase(id)
