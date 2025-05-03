extends Area3D
class_name Hand
var cards=[]
var card_spacing=0.125
var z_spacing=0.01
var card_scene=preload("res://scenes/CARD.tscn")
@onready var camera = $Camera3D
var camera_default
var table=null
var player_id:int
signal me_want_card(hand)
var deck_info=[]
var discard_nodes=[]
var turn_taker:String
var clicked_group='clicked_group'
var spawner
var clicking
var players=[]
var actions=0

@rpc("any_peer","call_local")
func reset_authority(new_owner:int):
	set_multiplayer_authority(new_owner,true)
	if not is_multiplayer_authority(): return
	CardCount.update_cards()
	cards=CardCount.mutual_card_info[name].map(func(path): return get_node(path))
	$TurnTaker.text=CardCount.mutual_card_info['turn_taker']
	## TODO change so its uniform for disconnection
	camera_default=camera.global_transform
	camera.current = true

func _enter_tree():
	set_multiplayer_authority(player_id)

@rpc("any_peer","call_local","reliable")
func change_turn(current_turn_taker:String):
	turn_taker=current_turn_taker
	$TurnTaker.text=turn_taker
	if multiplayer.is_server():
		CardCount.mutual_card_info['turn_taker']=current_turn_taker
		var turn_taker_id=CardCount.player_info[current_turn_taker]
		for x in range(2):
			if turn_taker_id==1:
				request_dealer(1)
			else:
				get_node('../'+turn_taker).request_dealer.rpc_id(turn_taker_id,turn_taker_id)
		
func _ready():
	CardCount.update_cards()
	spawner=get_node('../CardSpawn')
	spawner.spawn_function=add_to_hand
	if not is_multiplayer_authority(): return
	camera_default=camera.global_transform
	camera.current = true
	table=get_node_or_null('/root/Node/table/Deck')
	if multiplayer.is_server():
		for type in CardCount.card_count.keys():
			var material_dict=CardCount.card_count[type]
			for material in material_dict.keys():
				for _x in range(material_dict[material]):
					deck_info.append([material,type])
			deck_info.shuffle()
		CardCount.internal_update(deck_info,get_discard_info())
		
func deal():
	if not multiplayer.is_server(): return
	players=CardCount.player_info.keys()
	for player in players:
		for x in range(5):
			add_card_to_hand(CardCount.player_info[player])
	players.shuffle()
	turn_taker=players.front()
	for player in players:
		get_node('../'+player).change_turn.rpc_id(CardCount.player_info[player],turn_taker)
		
func shuffle_discard():
	if not multiplayer.is_server(): return
	deck_info=get_discard_info()
	for node in discard_nodes:
		node.queue_free()
	discard_nodes.clear()
	
	
@rpc("any_peer")
func request_dealer(peer_id:int):
	if cards.size()<10:
		if multiplayer.is_server():
			add_card_to_hand(peer_id)
		else:
			get_node('../'+CardCount.player_info.find_key(1)).request_dealer.rpc_id(1,peer_id)
			
@rpc("any_peer")
func add_card_to_hand(peer_id:int):
	if not multiplayer.is_server(): return
	if deck_info:
		var info=deck_info.pop_front()
		CardCount.internal_update(deck_info,get_discard_info())
		var card=spawner.spawn([info,table.global_position,peer_id])
		get_node('../'+CardCount.player_info.find_key(peer_id)).send_card.rpc_id(peer_id,card.get_path())
	else:
		shuffle_discard()
		add_card_to_hand(peer_id)
		
@rpc("any_peer","call_local")
func send_card(card_path):
	var card=get_node(card_path)
	cards.append(card)
	reorganize_cards()
	map_card_hands()
	
@rpc("authority","call_local")
func add_to_hand(data):
	var card_info=data[0]
	var start=data[1]
	var peer_id=data[2]
	var card1=card_scene.instantiate()
	card1.make_card(card_info[0],card_info[1])
	card1.name=card_info[0].get_file().get_basename()+str(Time.get_ticks_msec())
	card1.rotation.z=PI
	card1.position=start
	card1._owned=peer_id
	return card1
	
@rpc('any_peer',"call_local")
func activate_card(card_path):
	if not multiplayer.is_server(): return
	var card=get_node(card_path)
	var discard=get_node('/root/Node/table/Discard')
	card.move_to_discard(discard.global_position+Vector3(0,0.005*discard_nodes.size(),0))
	if card._mesh=="res://cards/action//passgo.tres":
		var recipient=turn_taker
		await card.tween.finished
		for x in range(2):
			# Will glitch things out if youplay more than 1 pass go at your limit
			add_card_to_hand(CardCount.player_info[recipient])
	discard_nodes.append(card)
	CardCount.internal_update(deck_info,get_discard_info())
	
func get_discard_info():
	return discard_nodes.map(func(card): return [card._mesh,card._card_type])
	
func card_exited(body):
	if not is_multiplayer_authority(): return
	if body._in_hand==self and $TurnTaker.text==CardCount.player_info.find_key(multiplayer.get_unique_id()) or body._mesh=="res://cards/action//sayno.tres":
		actions+=1
		body.play_card.rpc_id(1)
		body.change_card_visibility.rpc()
		cards.erase(body)
		reorganize_cards()	
		
@rpc("any_peer","call_local")
func reorganize_cards():
	if not is_multiplayer_authority(): return
	if cards.is_empty():
		return
	var start=cards.size()-1
	for x in range(cards.size()):
		var card_spot=to_global(Vector3(start*card_spacing,0,-z_spacing*x+0.04))
		cards[x].move_to_hand.rpc_id(1,get_path(),card_spot)
		start-=2
	map_card_hands()
	
@rpc("any_peer","call_local")
func end_turn():
	if not multiplayer.is_server(): return
	players.push_back(players.pop_front())
	turn_taker=players.front()
	for player in players:
		get_node('../'+player).change_turn.rpc_id(CardCount.player_info[player],turn_taker)
		
@rpc("any_peer","call_local")
func map_card_hands():
	if multiplayer.is_server():
		CardCount.mutual_card_info[name]=cards
	elif is_multiplayer_authority():
		CardCount.map_card_hands.rpc_id(1,name,cards.map(func(card): return '/root/Node/'+card.name))
	
func _input(event):
	if not is_multiplayer_authority(): return
	var collider
	var query
	if event is InputEventMouseButton:
		if event.button_index==1 and event.is_pressed() and not clicking:
			query=CardCount.raycast_from_mouse($Camera3D)
			if query:
				collider=query['collider']
				if collider.has_method('make_card') and not collider._clicked and collider._state!=Card._states.discard:
					clicking=query['collider']
					clicking.click.rpc(multiplayer.get_unique_id())
					clicking.add_to_group(clicked_group)
		elif event.button_index==1 and not event.is_pressed():
			clicking=false
			for card in get_tree().get_nodes_in_group(clicked_group):
				card.unclick.rpc()
	if actions>=3 or (event.is_action_pressed("start") and $TurnTaker.text==name):
		actions=0
		get_node('../'+CardCount.player_info.find_key(1)).end_turn.rpc_id(1)
	if event.is_action_pressed('rotate') and clicking and not clicking._in_hand:
		get_node('../'+clicking.name).rotate_non_authority_card.rpc_id(1,PI/2)
	if event.is_action_pressed("controls?"):
		$Instructions.visible=!$Instructions.visible
	if event.is_action_pressed("camera_controls"):
		$CameraInstruct.visible=!$CameraInstruct.visible
	if event.is_action_pressed("camera"):
		$Camera3D.global_transform=camera_default
	if event.is_action_pressed("card_zoom"):
		query=CardCount.raycast_from_mouse($Camera3D)
		# make this more intuitive so it goes away when you are looking at the same card
		if query:
			collider=query['collider']
			if collider._mesh and (collider._in_hand==self or collider.check_inplay()):
				$Camera3D/Cube.visible=true
				$Camera3D/Cube.mesh=load(collider._mesh)
		else:
			$Camera3D/Cube.visible=false
	
		
	if event.is_action_pressed('activate'):
		query=CardCount.raycast_from_mouse($Camera3D)
		if query:
			collider=query['collider']
			if not collider._card_type=='action' or collider._in_hand!=self or collider._owned!=multiplayer.get_unique_id() or collider.check_inplay() or not collider.has_method('check_inplay'):
				return
			if collider._mesh=="res://cards/action//passgo.tres" and cards.size()>8: 
				$AcceptDialog.dialog_text='You have too many cards to pass go.'
				$AcceptDialog.visible=true
			elif collider._mesh=="res://cards/action//sayno.tres":
				actions=-1
				get_node('../'+CardCount.player_info.find_key(1)).activate_card.rpc_id(1,collider.get_path())
			elif $TurnTaker.text==name:
				get_node('../'+CardCount.player_info.find_key(1)).activate_card.rpc_id(1,collider.get_path())
	if event.is_action_pressed("start") and not $TurnTaker.text:
		deal()
	
func _process(_delta):
	pass
	
		
		
