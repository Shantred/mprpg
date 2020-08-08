extends Node

# For a better understanding of this process and what is called when, see Game Initialization Sequence in lucid charts

const DEFAULT_PORT = 1337;
const MAX_PEERS = 10;

var delta_update = 0
var delta_interval = float(50 * 0.001)

var players = {}

var cached_player = load("res://Player.tscn")
var cached_client = load("res://Client.tscn")


var updateId = 0


onready var world_node = $world
onready var node_players = $world/players
onready var node_mobs = $world/mobs
onready var server_camera = $world/ServerCam

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Setting up signals")
	# Connect signals. Do we need a more robust way to handle this?
	if get_tree().connect("network_peer_connected", self, "player_connected") != OK:
		print("Unable to connect signal (network_peer_connected) !")
		
	if get_tree().connect("network_peer_disconnected", self, "player_disconnected") != OK:
		print("Unable to connect signal (network_peer_disconnected) !")
		
		
	start_server()
	
func start_server():
	print("Starting server on port " + str(DEFAULT_PORT))
	var host = NetworkedMultiplayerENet.new()
	var err = host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)
	
	print("Server started, listening on port " + str(DEFAULT_PORT))
	print("Id is " + str(get_tree().get_network_unique_id()))
	

	
	
func player_connected(id):
	print("Player connected!" + str(id))
	#print("First mob: " + str(world_node.get_mobs()[0].position.x));

	
func player_disconnected(id):
	for peerId in players:
		rpc_id(peerId, "player_leaving", id)
		
	players[id].node.queue_free()
	players[id].erase(id)
	
	
remote func register_player(id, info):
	print("Registering player!")
			
	
	info.position = get_spawn_position()
	info.velocity = Vector2(0,0)
	info.health = 10
	
	# Tell new client about all other clients
	for peerId in players:
		rpc_id(id, "player_joined", peerId, players[peerId])
	
	var node_player = cached_player.instance()
	info.node = node_player
	info.player_update_id = 0
	info.last_update_time = 0
	info.updates = {}
	
	var pos = Vector2(info.position.x, info.position.y)
	
	node_player.set_position(pos)
	node_player.show()
	node_player.set_process(true)
	node_player.name = info.name
	
	node_players.add_child(node_player)
	
	# Inform the client about all monsters
	rpc_id(id, "mobload",  world_node.get_mobs())
	
	players[id] = info
	
	# Tell other clients about new player
	for peerId in players:
		rpc_id(peerId, "player_joined", id, players[id])
	
	
remote func player_input(id, key, pressed):	
	if !players[id].node.is_attacking():
		if key == "left":
			players[id].velocity.x = -1 if pressed else 0
		if key == "right":
			players[id].velocity.x = 1 if pressed else 0
		if key == "up":
			players[id].velocity.y = -1 if pressed else 0
		if key == "down":
			players[id].velocity.y = 1 if pressed else 0
		
		players[id].node.set_direction(players[id].velocity)
		
remote func player_attack(id):
	print("Player attack")
	# Make sure we don't trigger an attack twice in a row.
	if !players[id].node.is_attacking():
		print("Player attacking")
		# Reset velocity to prevent unintended movement after attacks
		players[id].velocity = Vector2()
		var results = players[id].node.attack()
		if results:
			print("Player hit!")
			print(str(results.collider))
			results.collider.take_damage(3)
		
func get_spawn_position():
	var pos = Vector2(0,0)
	pos.x = rand_range(0, 500)
	pos.y = rand_range(0, 500)
	return pos

func _physics_process(delta):
	for peerId in players:
		
		# Do not update position if player is currently attacking
		if !players[peerId].node.is_attacking():
			players[peerId].position = players[peerId].node.get_position()
			var velocity = players[peerId].velocity
			if velocity.length() > 0:
				velocity = velocity.normalized() * 400
				players[peerId].velocity = velocity
				players[peerId].node.move_and_collide(velocity * delta)
			
	delta_update += delta
	while delta_update >= delta_interval:
		delta_update -= delta_interval
		broadcast_world_positions()
		
	# Controls for the server camera. Remove once no longer needed.
	var camera_velocity = Vector2()
	if Input.is_action_pressed("ui_right"):
		camera_velocity.x += 1

	if Input.is_action_pressed("ui_left"):
		camera_velocity.x -= 1
		
	if Input.is_action_pressed("ui_up"):
		camera_velocity.y -= 1
		
	if Input.is_action_pressed("ui_down"):
		camera_velocity.y += 1
		
	if camera_velocity.length() > 0:
		camera_velocity = camera_velocity.normalized() * 800
		server_camera.move_and_collide(camera_velocity * delta)
			
			
func broadcast_world_positions():
	# Update every player about every other player
	for peerId in players:
		for peerId2 in players:
			#print("player " + str(peerId2) + " position X: " + str(players[peerId2].position.x) + " Y: " + str(players[peerId2].position.y))
			#print("player " + str(peerId2) + " position X: " + str(players[peerId2].node.position.x) + " Y: " + str(players[peerId2].node.position.y))
			rpc_unreliable_id(peerId, "pu", peerId2, updateId, players[peerId2].node.position, players[peerId2].velocity)
	
	var mobs = world_node.get_mobs()
	
	for mob in mobs:
		rpc_unreliable("mu", updateId, mob, mobs[mob].node.position, mobs[mob].node.velocity, mobs[mob].node.currentHealth)
	
			
	updateId += 1
	
remote func ppu(playerId, pos, updateId):
	#print("Received update about " + str(playerId) + " update: " + str(updateId))
	if updateId > players[playerId].player_update_id:
		# Just take the player positions. We can trust them, right?
		# TODO: Track time since last update so that we can calculate expected max distance
		var lastUpdateTime = OS.get_ticks_msec()
		
		
		# Calculate the time since the last update so we can attempt to calculate how far they
		# should be able to have moved
		var timeSinceLastUpdate = lastUpdateTime - players[playerId].last_update_time
		
		# There's probably a better way to do this, but I'm dumb. Convert miliseconds to seconds
		# because that's how I know to calculate max distance.
		var tldMili = float(timeSinceLastUpdate) / float(1000.0)
		# calculate max movable distance
		print("Time since last update: " + str(timeSinceLastUpdate))
		var maxDistance = 400 * tldMili
		print("Maximum distance possible: " + str(maxDistance))
		
		players[playerId].node.position = pos
		players[playerId].updates[lastUpdateTime] = { position = pos }
		players[playerId].player_update_id = updateId
		players[playerId].last_update_time = lastUpdateTime
		
		# Only keep the last 10 updates
		while len(players[playerId].updates) > 10:
			#print("Deleting keys")
			players[playerId].updates.erase(players[playerId].updates.keys()[0])
