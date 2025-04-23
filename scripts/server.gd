extends Node

@onready var main_menu = $Menu
@onready var table =$table 
@onready var spawner=$MultiplayerSpawner
var player_positions=[Transform3D(Basis(Vector3.LEFT,PI/4),Vector3(1.8,0,2.1)),Transform3D(Basis(Vector3.LEFT,PI/4),Vector3(-1.8,0,2.1)),Transform3D(Basis(Vector3.UP,PI/2)*Basis(Vector3.LEFT,PI/4),Vector3(3.6,0,0)),Transform3D(Basis(Vector3.UP,PI)*Basis(Vector3.LEFT,PI/4),Vector3(-1.8,0,-2.1)),Transform3D(Basis(Vector3.UP,PI)*Basis(Vector3.LEFT,PI/4),Vector3(1.8,0,-2.1))]
var active_players={}

@onready var player=preload("res://scenes/hand.tscn")
const PORT = 5005
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	spawner.spawn_function=add_player
	
func _on_host_button_pressed():
	main_menu.hide()
	table.show()
	enet_peer.create_server(PORT,5)
	multiplayer.multiplayer_peer = enet_peer
	spawner.spawn([$Menu/Name.text,multiplayer.get_unique_id()])
	upnp_setup()

func _on_join_button_pressed():
	main_menu.hide()
	table.show()
	enet_peer.create_client('localhost', PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.connected_to_server.connect(func(): request_spawn.rpc_id(1,[$Menu/Name.text,multiplayer.get_unique_id()]))
		
@rpc("any_peer","call_local")
func request_spawn(data:Array):
	if multiplayer.is_server():
		var player_name:String=data[0]
		var peer_id:int=data[1]
		if player_name not in active_players.keys():
			spawner.spawn(data)
		else:
			CardCount.local_player_update([player_name,peer_id])
			CardCount.transfer_card_data.rpc_id(peer_id,CardCount.mutual_card_info)
			CardCount.update_players.rpc_id(peer_id,CardCount.player_info)
			reset_authority(active_players[player_name].get_path(),peer_id)
			
func reset_authority(node_path:String,new_owner:int):
	if not multiplayer.is_server(): return
	var changing_hand=get_node(node_path)
	changing_hand.reset_authority.rpc(new_owner)
	var cards=CardCount.mutual_card_info[changing_hand.name].map(func(card_path): return get_node(card_path))
	for card in cards:
		card.reset_authority.rpc(new_owner)
	
func add_player(data:Array):
	var player_name:String=data[0]
	var peer_id:int=data[1]
	var Player:Hand=player.instantiate()
	Player.player_id = peer_id
	Player.name=player_name
	Player.global_transform=player_positions.pop_front()
	CardCount.local_player_update(data)
	active_players[player_name]=Player
	return Player
		
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
