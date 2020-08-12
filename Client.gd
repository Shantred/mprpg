extends Node

var last_update = -1
var players = {}
var mobs = {}
var cached_player = load("res://Player.tscn")
var cached_woe = load("res://WallOfEYes.tscn")
var my_peer = null
var my_info = { name = "none" }
var movement_update_id = 0

var delta_update = 0
var delta_interval = float(50 * 0.001)

onready var node_players = $world/players
onready var world_mobs = $world/mobs

func _ready():
	print("Connecting to server...")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(Global.get_ip(), 1337)
	
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
	#print("Mob update:")
	#print(str(mobs))
	# To mitigate latency issues we use interpolation. The idea is simple, we receive
	# position updates every TICK_DURATION (50 ms, 20 per seconds). We interpolate between
	# the last two previous updates, this way we always have smooth movements. The
	# main drawback is added latency (100 ms).
	var pos = Vector2(0,0)
	var target_timestamp = OS.get_ticks_msec() - (50 * 2)
	#print("Target timestamp: (" + str(target_timestamp) + ")")
	
	var playerId = get_tree().get_network_unique_id()
	
	for peerId in players:
		
		
		var keys = players[peerId].updates.keys()
		#print("There are " + str(keys.size()) + " keys")
		for i in range(0, keys.size()):
			#print("Current key: " + str(keys[i]))
			if keys[i] > target_timestamp:
				#print("Key is greater than the target timestamp")
				# We do not want to lerp the current player's movement, just remote players.
				if peerId != playerId:
					var percent = float(target_timestamp - keys[i-1]) / 50
					
					players[peerId].position.x = lerp(players[peerId].updates[keys[i-1]].position.x, players[peerId].updates[keys[i]].position.x, percent)
					players[peerId].position.y = lerp(players[peerId].updates[keys[i-1]].position.y, players[peerId].updates[keys[i]].position.y, percent)
					#if peerId == get_tree().get_network_unique_id():
						#print("moving me to X:" + str(players[peerId].position.x) + " Y: " + str(players[peerId].position.y))
					players[peerId].node.set_position(players[peerId].position)
		
					players[peerId].velocity = lerp(players[peerId].updates[keys[i-1]].velocity, players[peerId].updates[keys[i]].velocity, percent)
					players[peerId].node.velocity = players[peerId].velocity
					
					# We need to update the direction that the player is facing
					# We only need to do this if velocity is greater than 0. Updating
					# this way preserves facing direction even while not moving
					if players[peerId].updates[keys[i]].velocity.x != 0:
						players[peerId].node.set_direction(players[peerId].updates[keys[i]].velocity)
					
				players[peerId].node.set_health(players[peerId].updates[keys[i]].health)
				
				break
				
				
	# Handle actions for the current user
	var player = players[playerId].node
	
	
	# When attacking, client-side we perform the attack immediately and do a raycast
	# to see if we do damage. We use this ONLY to trigger animations on the attacked
	# entity.
	if !player.is_attacking():
		if Input.is_action_pressed("ui_select"):
			player.attack()
			rpc_id(1, "player_attack", get_tree().get_network_unique_id())
			
	
			
	# Simple movement for now, no prediction. Just tell the server we are currently moving.
#	if Input.is_action_just_pressed("ui_right"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "right", true)
#	if Input.is_action_just_released("ui_right"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "right", false)
#
#	if Input.is_action_just_pressed("ui_left"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "left", true)	
#	if Input.is_action_just_released("ui_left"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "left", false)
#
#	if Input.is_action_just_pressed("ui_up"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "up", true)	
#	if Input.is_action_just_released("ui_up"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "up", false)
#
#	if Input.is_action_just_pressed("ui_down"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "down", true)	
#	if Input.is_action_just_released("ui_down"):
#		rpc_id(1, "player_input", get_tree().get_network_unique_id(), "down", false)
		
		
		
func _physics_process(delta):
	var playerId = get_tree().get_network_unique_id()
	var player = players[playerId].node
	
	player.velocity = Vector2()
	
	if Input.is_action_pressed("ui_right"):
		player.velocity.x = 1
	if Input.is_action_pressed("ui_left"):
		player.velocity.x = -1
	if Input.is_action_pressed("ui_down"):
		player.velocity.y = 1
	if Input.is_action_pressed("ui_up"):
		player.velocity.y = -1
		
	if player.velocity.x != 0:
		player.set_direction(player.velocity)
	
	if player.velocity.length() > 0:
		player.velocity = player.velocity.normalized() * 400
		#print(str(player.velocity.normalized() * 400))
		#print("position before: " + str(player.position))
		#print("delta: " + str(delta))
		#print("collide param:" + str(player.velocity * delta))
		var previousPosition = player.position
		player.move_and_collide(player.velocity * delta)
		var afterMoveAndCollide = player.position
		#print("position after: " + str(player.position))
		#print("distance moved:" + str(previousPosition.distance_to(afterMoveAndCollide)))
		
	delta_update += delta
	while delta_update >= delta_interval:
		delta_update -= delta_interval
		broadcast_player_position(player.position, player.velocity)

func client_connected_ok():
	print("client connected!")
	my_info.name = Global.get_name()
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
remote func pu(id, updateId, pos, velocity, health):
	# Updates are sent as unreliable rpcs. Since they can be sent in an arbitrary order, discard if it's not the
	# newest update
	if updateId < last_update:
		return
		
	last_update = updateId
	players[id].updates[OS.get_ticks_msec()] = { position = pos, velocity = velocity, health = health }
	
	# Only keep the last 10 updates
	while len(players[id].updates) > 10:
		players[id].updates.erase(players[id].updates.keys()[0])
		

remote func mu(updateId, mobId, pos, vel, currentHealth):
	#print("Received update on mob: " + str(mobId) + "but size is " + str(mobs.size()))
	#print(str(mobs))
	# Mobs must be loaded before we can accept an update
	if (mobs.size() > 0):
		
		mobs[mobId].position = pos
		mobs[mobId].node.position = pos
		mobs[mobId].velocity = vel
		mobs[mobId].node.set_health(currentHealth)
		
# Player attack -- Another client is attacking
remote func pa(playerId):
	# The way we handle this attack may not be good enough in the long run. 
	# It solves two problems for us currently, in that it allows the player attack
	# animation to run AND eventually triggers the enemy attack animation. We may need
	# to de-couple these things once latency is involved.
	players[playerId].node.attack()

remote func mobload(mobsFromServer):
	print(str(mobsFromServer))
	for mob in mobsFromServer:
		var node_enemy = cached_woe.instance()
		var enemy = {}
		enemy.position = mobsFromServer[mob].position
		enemy.node = node_enemy
		
		mobs[mob] = enemy
		
		node_enemy.set_position(mobsFromServer[mob].position)
		node_enemy.show()
		node_enemy.set_process(true)

	
		$world.add_child(node_enemy)
		
	print("finished loading mobs:")
	print(str(mobs))
		
remote func player_joined(id, info):
	print("Player joined: " + str(id))
	
	
	var node_player = cached_player.instance()
	info.node = node_player
	info.updates = {}
	
	var pos = Vector2(info.position.x, info.position.y)
	node_player.set_position(pos)
	node_player.set_name(info.name)
	
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
	
#ppu - player position update
func broadcast_player_position(pos, vel):
	rpc_id(1, "ppu", get_tree().get_network_unique_id(), pos, vel, movement_update_id)
	movement_update_id += 1
	
# correct player position. Used for invalid position correction
remote func cpp(pos):
	players[get_tree().get_network_unique_id()].node.position = pos
