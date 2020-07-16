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


onready var camera = $Camera2D
onready var node_players = $Camera2D/players

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
	#for peerId in players:
		#rpc_id(id, "player_joined", peerId, players[peerId])
	
	var node_player = cached_player.instance()
	info.node = node_player
	
	var pos = Vector2(info.position.x, info.position.y)
	
	node_player.set_position(pos)
	node_player.show()
	node_player.set_process(true)
	node_player.name = info.name
	
	node_players.add_child(node_player)
	
	players[id] = info
	
	# Tell other clients about new player
	for peerId in players:
		rpc_id(peerId, "player_joined", id, players[id])
	
	
remote func player_input(id, key, pressed):
	print("Player " + str(id) + " pressed " + key)
	if key == "left":
		players[id].velocity.x = -1 if pressed else 0
	if key == "right":
		players[id].velocity.x = 1 if pressed else 0
	if key == "up":
		players[id].velocity.y = -1 if pressed else 0
	if key == "down":
		players[id].velocity.y = 1 if pressed else 0	
		
func get_spawn_position():
	var pos = Vector2(0,0)
	pos.x = rand_range(0, 500)
	pos.y = rand_range(0, 500)
	return pos
	
func _physics_process(delta):
	for peerId in players:
		players[peerId].position = players[peerId].node.get_position()
		var velocity = players[peerId].velocity;
		if velocity.length() > 0:
			velocity = velocity.normalized() * 400
			players[peerId].velocity = velocity
			
	delta_update += delta
	while delta_update >= delta_interval:
		delta_update -= delta_interval
		broadcast_world_positions()
			
			
func broadcast_world_positions():
	# Update every player about every other player
	for peerId in players:
		for peerId2 in players:
			rpc_unreliable_id(peerId, "pu", peerId2, updateId, players[peerId2].position, players[peerId2].velocity)
			
	updateId += 1
