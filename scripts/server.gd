extends Node

@onready var main_menu = $Menu
@onready var table =$table 
@onready var spawner=$MultiplayerSpawner
var player_positions=[Vector3(1.8,0,2.1),Vector3(-1.8,0,2.1),Vector3(-1.8,0,-2.1),Vector3(1.8,0,-2.1),Vector3(3.2,0,0)]
var active_players={}
@onready var player=preload("res://scenes/hand.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
		
func _ready():
	spawner.spawn_function=add_player
	
func _on_host_button_pressed():
	main_menu.hide()
	table.show()
	enet_peer.create_server(PORT,5)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(func(id): spawner.spawn([$Menu/Name.text,id]))
	#multiplayer.peer_disconnected.connect(remove_player)
	spawner.spawn([$Menu/Name.text,multiplayer.get_unique_id()])
	upnp_setup()

func _on_join_button_pressed():
	main_menu.hide()
	table.show()
	enet_peer.create_client('localhost', PORT)
	multiplayer.multiplayer_peer = enet_peer
	if $Menu/Name.text not in active_players.keys():
		spawner.spawn([$Menu/Name.text,multiplayer.get_unique_id()])
	else:
		active_players[$Menu/Name.text].set_multiplayer_authority(multiplayer.get_unique_id(),true)
		

func add_player(data:Array):
	var player_name:String=data[0]
	print_debug(player_name)
	var peer_id:int=data[1]
	var Player:Hand=player.instantiate()
	Player.name = str(peer_id)
	Player.position=player_positions.pop_front()
	active_players[player_name]=Player
	return Player
		
#func remove_player(peer_id):
	#var Player = get_node_or_null(str(peer_id))
	#if Player:
		#player_positions.append(Player.position)
		#Player.queue_free()

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

