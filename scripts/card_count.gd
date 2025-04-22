extends Node3D
var action={'res://cards/action//dealbreaker.tres':2, 'res://cards/action//sayno.tres':3, 
'res://cards/action//slydeal.tres':3 ,'res://cards/action//forceddeal.tres':4, 'res://cards/action//debtcollect.tres':3,
'res://cards/action//birthday.tres':3, 'res://cards/action//passgo.tres':10,   'res://cards/action//doublerent.tres': 2,
'res://cards/action//pinkorangerent.tres':2,
'res://cards/action//blackgrayrent.tres':2,'res://cards/action/brownbluerent.tres':2,'res://cards/action/greenbluerent.tres':2,
'res://cards/action//redyellowrent.tres':2,'res://cards/action//wildrent.tres':3}
var property={'res://cards/property//atlantic.tres':1, 
'res://cards/property//baltic.tres':1, 'res://cards/property//bando.tres':1, 'res://cards/property//blackgreenwild.tres':1, 
'res://cards/property//blueblackwild.tres':1, 'res://cards/property//bluebrownwild.tres':1, 
'res://cards/property//bluegreenwild.tres':1, 'res://cards/property//boardwalk.tres':1, 'res://cards/property//connecticut.tres':1, 
'res://cards/property//electric.tres':1, 'res://cards/property//grayblackwild.tres':1, 'res://cards/property//illinois.tres':1, 
'res://cards/property//indiana.tres':1, 'res://cards/property//kentuck.tres':1, 'res://cards/property//marvin.tres':1, 
'res://cards/property//mediter.tres':1, 'res://cards/property//newyork.tres':1, 'res://cards/property//northcarolina.tres':1, 
'res://cards/property//orangepinkwild.tres':2, 'res://cards/property//oriental.tres':1, 'res://cards/property//pacific.tres':1, 
'res://cards/property//parkplace.tres':1, 'res://cards/property//pennsyl.tres':1, 'res://cards/property//pennsylrail.tres':1, 
'res://cards/property//propertywild.tres':2, 'res://cards/property//reading.tres':1, 'res://cards/property//redyellowwild.tres':2, 
'res://cards/property//shortline.tres':1, 'res://cards/property//states.tres':1, 'res://cards/property//stcharles.tres':1, 
'res://cards/property//stjames.tres':1, 'res://cards/property//tennessee.tres':1, 'res://cards/property//ventor.tres':1, 
'res://cards/property//vermont.tres':1, 'res://cards/property//virginia.tres':1, 'res://cards/property//waterworks.tres':1}
var money={'res://cards/money//10M.tres':1, 'res://cards/money//1M.tres':6,
 'res://cards/money//2M.tres':5, 'res://cards/money//3M.tres':3, 'res://cards/money//4M.tres':3, 'res://cards/money//5M.tres':2,'res://cards/money//house.tres':3, 
'res://cards/money//hotel.tres':3}
var card_count={'money':money,'property':property,'action':action}
var mutual_card_info={'deck':[],'discard':[],'table':[]}
var player_info:Dictionary={}
signal updated()
@rpc("any_peer","call_local","reliable")
func map_card_hands(player_name:String,card_paths:Array):
	if not multiplayer.is_server(): return
	mutual_card_info[player_name]=card_paths
	transfer_card_data.rpc(mutual_card_info)
	
func raycast_from_mouse(camera,collision_mask=0b1):
	if camera:
		var ray=PhysicsRayQueryParameters3D.new()
		ray.collision_mask=collision_mask
		ray.collide_with_areas=true
		var mouse_pos=get_viewport().get_mouse_position()
		ray.hit_from_inside=true
		ray.from=camera.project_ray_origin(mouse_pos)
		ray.to=camera.project_ray_normal(mouse_pos)*1000
		return get_world_3d().direct_space_state.intersect_ray(ray)
		
@rpc("any_peer","call_local","reliable")
func update_cards():
	for card in get_node('/root/Node').get_children().filter(func(node):return node.has_method('make_card')):
		card._update.rpc_id(1)
		
func internal_update(deck:Array,discard:Array):
	mutual_card_info['deck']=deck
	mutual_card_info['discard']=discard
	transfer_card_data.rpc(mutual_card_info)
	
		
@rpc("any_peer","call_local","reliable")
func transfer_card_data(card_info):
	mutual_card_info=card_info
	updated.emit()
		
func local_player_update(data:Array):
	if not multiplayer.is_server(): return
	var player_name:String=data[0]
	var peer_id:int=data[1]
	player_info[player_name]=peer_id
	update_players.rpc(player_info)
	
@rpc("any_peer","call_local","reliable")
func update_players(new_info):
	player_info=new_info
	
@rpc("any_peer","call_local","reliable")
func request_update():
	if not multiplayer.is_server(): return
	var server_hand=get_node('/root/Node/'+CardCount.player_info.find_key(1))
	internal_update(server_hand.deck_cards,server_hand.discards)
	
