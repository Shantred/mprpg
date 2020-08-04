extends Node

var last_update = -1
var players = {}
var mobs = {}
var cached_player = load("res://Player.tscn")
var cached_woe = load("res://WallOfEYes.tscn")
var my_peer = null
var my_info = { name = "teent" }

onready var node_players = $world/players
onready var world_mobs = $world/mobs

func _ready():
	print("Connecting to server...")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", 1337)
	
	get_tree().set_network_peer(peer)
	print("My id is: " + str(get_tree().get_network_unique_id()))
	
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
	#print("Target timestamp: (" + str(target_timestamp) + ")")
	
	for peerId in players:
		var keys = players[peerId].updates.keys()
		#print("There are " + str(keys.size()) + " keys")
		for i in range(0, keys.size()):
			#print("Current key: " + str(keys[i]))
			if keys[i] > target_timestamp:
				#print("Key is greater than the target timestamp")
				
				var percent = float(target_timestamp - keys[i-1]) / 50
				
				players[peerId].position.x = lerp(players[peerId].updates[keys[i-1]].position.x, players[peerId].updates[keys[i]].position.x, percent)
				players[peerId].position.y = lerp(players[peerId].updates[keys[i-1]].position.y, players[peerId].updates[keys[i]].position.y, percent)
				#if peerId == get_tree().get_network_unique_id():
					#print("moving me to X:" + str(players[peerId].position.x) + " Y: " + str(players[peerId].position.y))
				players[peerId].node.set_position(players[peerId].position)
	
				players[peerId].velocity = lerp(players[peerId].updates[keys[i-1]].velocity, players[peerId].updates[keys[i]].velocity, percent)
				players[peerId].node.velocity = players[peerId].velocity
				break
				
				
	# Handle actions for the current user
	var playerId = get_tree().get_network_unique_id()
	var player = players[playerId].node
	
	
	# When attacking, client-side we perform the attack immediately and do a raycast
	# to see if we do damage. We use this ONLY to trigger animations on the attacked
	# entity.
	if !player.is_attacking():
		if Input.is_action_pressed("ui_select"):
			player.attack()
			rpc_id(1, "player_attack", get_tree().get_network_unique_id())
			
	
			
	# Simple movement for now, no prediction. Just tell the server we are currently moving.
	if Input.is_action_just_pressed("ui_right"):
		print("Sending command to go right!")
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
	players[id].updates[OS.get_ticks_msec()] = { position = pos, velocity = velocity }
	
	
	# Only keep the last 10 updates
	while len(players[id].updates) > 10:
		#print("Deleting keys")
		players[id].updates.erase(players[id].updates.keys()[0])
		

remote func mu(updateId, mobId, pos, vel):
	# Mobs must be loaded before we can accept an update
	if (mobs.size() > 0):
		print("Received update on mob " + str(mobId))
		print(str(mobs))
		
		mobs[mobId].position = pos
		mobs[mobId].velocity = vel
	
remote func mobload(mobs):
	print(str(mobs))
	print(mobs)
	for mob in mobs:
		var node_enemy = cached_woe.instance()
		mobs[mob].node = node_enemy
		node_enemy.set_position(mobs[mob].position)
		node_enemy.show()
		node_enemy.set_process(true)

	
		$world.add_child(node_enemy)
		
remote func player_joined(id, info):
	print("Player joined: " + str(id))
	
	
	var node_player = cached_player.instance()
	info.node = node_player
	info.updates = {}
	
	var pos = Vector2(info.position.x, info.position.y)
	node_player.set_position(pos)
	node_player.name = info.name
	
	# If the player is the current player, attach our Camera2D object to it
	if id == get_tree().get_network_unique_id():
		var playerCamera = Camera2D.new()
		playerCamera.make_current()
		node_player.add_child(playerCamera)
		
		
		
		
	
	node_players.add_child(node_player)
	
	
	players[id] = info

remote func player_leaving(id):
	print("Callback: player_leaving(" + str(id)+")")
	players[id].node.queue_free()
	players.erase(id)
