extends Area3D
class_name Hand
var cards=[]
var card_spacing=0.125
var z_spacing=0.01
var card_scene=preload("res://scenes/CARD.tscn")
@onready var camera = $Camera3D
var camera_default
var table=null
signal me_want_card(hand)
var deck_cards=[]
var discards=[]
var turn_taker:int
var clicked_group='clicked_group'
var spawner
var clicking
var players=[]
var actions=0

@rpc("any_peer")
func add_card_to_hand(peer_id:int):
	if deck_cards:
		var info=deck_cards.pop_front()
		CardCount.internal_update(deck_cards,discards)
		spawner.spawn([info,table.global_position,peer_id])
		
func _enter_tree():
	print_debug(str(name).to_int())
	set_multiplayer_authority(str(name).to_int())

@rpc("any_peer","call_local","reliable")
func change_authority():
	set_multiplayer_authority(1)

@rpc("any_peer","call_local","reliable")
func change_turn(current_turn_taker):
	turn_taker=current_turn_taker
	get_node('/root/Node/Label').text=str(current_turn_taker)
	if multiplayer.is_server():
		for x in range(2):
			if current_turn_taker==1:
				request_dealer(1)
			else:
				get_node('../'+str(current_turn_taker)).request_dealer.rpc_id(current_turn_taker,current_turn_taker)
	
func _ready():
	CardCount.update_cards()
	spawner=get_node('../CardSpawn')
	spawner.spawn_function=add_to_hand
	print_debug(get_multiplayer_authority())
	if not is_multiplayer_authority(): return
	camera_default=camera.global_transform
	camera.current = true
	table=get_node_or_null('/root/Node/table/Deck')
	if multiplayer.is_server():
		for type in CardCount.card_count.keys():
			var material_dict=CardCount.card_count[type]
			for material in material_dict.keys():
				for _x in range(material_dict[material]):
					deck_cards.append([material,type])
			deck_cards.shuffle()
		CardCount.internal_update(deck_cards,discards)
		
@rpc("any_peer")
func request_dealer(peer_id:int):
	if cards.size()<10:
		if multiplayer.is_server():
			add_card_to_hand(peer_id)
		else:
			get_node('../1').request_dealer.rpc_id(1,peer_id)

@rpc("authority","call_local")
func add_to_hand(data):
	#if not is_multiplayer_authority(): return
	var card_info=data[0]
	var start=data[1]
	var peer_id=data[2]
	var card1=card_scene.instantiate()
	card1.make_card(card_info[0],card_info[1])
	card1.name=card_info[0].get_file().get_basename()+str(Time.get_ticks_msec())
	card1.rotation.z=PI
	card1.position=start
	card1.owned=peer_id
	get_node('../'+str(peer_id)).cards.append(card1)
	get_node('../'+str(peer_id)).reorganize_cards()
	return card1
	
@rpc('any_peer',"call_local")
func activate_card(card_path):
	if multiplayer.is_server():
		var card=get_node(card_path)
		card.get_node('CollisionShape3D').disabled=true
		var discard=get_node('/root/Node/table/Discard')
		if card._mesh=="res://cards/action//passgo.tres":
			for x in range(2):
				# Will glitch things out if youplay more than 1 pass go at your limit
				add_card_to_hand(turn_taker)
		card.move_to_discard.rpc(discard.global_position+Vector3(0,0.005*discards.size(),0))
		discards.append([card._mesh,card._card_type])
		CardCount.internal_update(deck_cards,discards)
		
	
@rpc("any_peer","call_local")
func reorganize_cards():
	if not is_multiplayer_authority(): return
	if cards.is_empty():
		return
	var start=cards.size()-1
	for x in range(cards.size()):
		var card_spot=to_global(Vector3(start*card_spacing,0,-z_spacing*x+0.04))
		cards[x].move_to_hand(self,card_spot)
		cards[x].default_pos=card_spot
		start-=2
		
func card_exited(body):
	if not is_multiplayer_authority(): return
	if body._in_hand==self and get_node('/root/Node/Label').text==name:
		actions+=1
		body.play_card()
		body.change_card_visibility.rpc()
		cards.erase(body)
		reorganize_cards()
		
func deal():
	if not multiplayer.is_server(): return
	
	players=get_node('/root/Node').active_players.values()
	
	players=players.map(func(player): return str(player.name).to_int())
	print_debug(get_node('/root/Node').active_players)
	for player in players:
		for x in range(5):
			add_card_to_hand(player)
	players.shuffle()
	turn_taker=players.front()
	change_turn.rpc(turn_taker)
		
@rpc("any_peer","call_local")
func end_turn():
	if not multiplayer.is_server(): return
	players.push_back(players.pop_front())
	turn_taker=players.front()
	change_turn.rpc(turn_taker)
	
func _input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseButton:
		if event.button_index==1 and event.is_pressed() and not clicking:
			var query=CardCount.raycast_from_mouse($Camera3D)
			if query:
				if query['collider'].has_method('make_card') and not query['collider']._clicked:
					clicking=query['collider']
					clicking.click.rpc(multiplayer.get_unique_id())
					clicking.add_to_group(clicked_group)
		elif event.button_index==1 and not event.is_pressed():
			clicking=false
			for card in get_tree().get_nodes_in_group(clicked_group):
				card.unclick.rpc()
	if event.is_action_pressed('rotate') and clicking and not clicking._in_hand:
		get_node('../{0}'.format([clicking.name])).rotate_non_authority_card.rpc_id(clicking.get_multiplayer_authority(),PI/2)
	if event.is_action_pressed("controls?"):
		$Label.visible=!$Label.visible
	if event.is_action_pressed("camera"):
		$Camera3D.global_transform=camera_default
	if event.is_action_pressed("card_zoom"):
		var query=CardCount.raycast_from_mouse($Camera3D)
		# make this more intuitive so it goes away when you are looking at the same card
		if query:
			var collider=query['collider']
			if collider._in_hand==self or collider.check_inplay():
				$Camera3D/Cube.visible=true
				$Camera3D/Cube.mesh=load(collider._mesh)
		else:
			$Camera3D/Cube.visible=false
			
func _process(delta):
	if not is_multiplayer_authority(): return
	if actions>=3 or (Input.is_action_just_pressed("start") and get_node('/root/Node/Label').text==name):
		actions=0
		get_node('../1').end_turn.rpc_id(1)
	if Input.is_action_just_pressed('activate') and get_node('/root/Node/Label').text==name:
		var query=CardCount.raycast_from_mouse($Camera3D)
		if query:
			var collider=query['collider']
			if collider._mesh=="res://cards/action//passgo.tres" and cards.size()>8: 
				$AcceptDialog.dialog_text='You have too many cards to pass go.'
				$AcceptDialog.visible=true
			elif collider._card_type=='action' and collider._in_hand==self and collider.is_multiplayer_authority() and not collider.check_inplay() and collider.has_method('check_inplay'):
				get_node('../1').activate_card.rpc_id(1,collider.get_path())
	if Input.is_action_just_pressed("start") and not get_node('/root/Node/Label').text:
		deal()
	if Input.is_key_pressed(KEY_TAB):
		change_authority.rpc()
		
		
