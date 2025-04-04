extends CharacterBody3D
class_name Card

var animate_time=0.3
var _in_hand=null
var raised=false
var default_pos
var _card_type=null
var _mesh=null
var bord=preload('res://card_border.tres')
var _clicked=null
var _play_area=null
var target=Vector3.ZERO
enum _states {hand,play,active,discard}
var _state=_states.hand
var tween=null
var owned=null
var card_speed=80
@onready var camera=get_viewport().get_camera_3d()
var bounds
#TODO zoom in on card
func _enter_tree():
	if not process_mode==PROCESS_MODE_DISABLED:
		set_multiplayer_authority(owned)

func play_card():
	global_rotation.x=0
	global_rotation.z=0 
	_in_hand=null
	_state=_states.play
	_update()
		
func give_parabola(t):
	global_position.y=default_pos.y+4*t*(1-t)
	
func move_to_hand(hand,place):
	default_pos=place
	if not is_inside_tree():
		await ready
	tween = create_tween()
	tween.tween_property(self,'global_position:x',place.x,animate_time)
	tween.parallel().tween_property(self,'global_position:z',place.z,animate_time)
	tween.parallel().tween_property(self,'global_rotation',hand.global_rotation+Vector3(PI/4,PI/2,PI/4),animate_time)
	if not _in_hand:
		tween.parallel().tween_method(give_parabola,0.0,1.0,animate_time)
		tween.tween_callback(set_hand.bind(hand)).set_delay(animate_time)
	else:
		tween.parallel().tween_property(self,'global_position:y',place.y,animate_time)
	
@rpc("any_peer", "call_local","reliable")
func move_to_discard(place):
	if not is_multiplayer_authority(): return
	place.y=place.y-0.03
	default_pos=place
	set_process(false)
	set_physics_process(false)
	if not is_inside_tree():
		await ready
	tween = create_tween()
	tween.tween_property(self,'global_position:x',place.x,animate_time)
	tween.parallel().tween_property(self,'global_position:z',place.z,animate_time)
	tween.parallel().tween_property(self,'global_rotation',Vector3(0,PI/2,0),animate_time)
	tween.parallel().tween_method(give_parabola,0.0,1.0,animate_time)
	_state=_states.active
	_update()
	
@rpc("any_peer", "call_local","reliable")
func change_card_visibility(visibility=true):
	if not visibility:
		if get_multiplayer_authority()==multiplayer.get_unique_id():
			$Cube.mesh=load(_mesh)
		else:
			$Cube.mesh=load("res://cards/money/1M.tres")	
	elif not _in_hand or _in_hand.overlaps_body(self):
		$Cube.mesh=load(_mesh)
		
@rpc("any_peer", "call_local","reliable")	
func make_card(mesh_path,type):
	_card_type=type
	_mesh=mesh_path
	$Cube.mesh=load("res://cards/money/1M.tres")
	bord=bord.duplicate()
	bord.emission_enabled=false
	$Cube.set_surface_override_material(0,bord)
	
@rpc("any_peer","call_local","unreliable_ordered")	
func move_non_authority_card(suggested_velocity):
	if not is_multiplayer_authority(): return
	velocity=suggested_velocity
	move_and_slide()
	position.y=_play_area.global_position.y+.3

@rpc("any_peer","call_local","unreliable_ordered")	
func rotate_non_authority_card(suggested_rotation):
	# Only for y rotations
	if not is_multiplayer_authority(): return
	rotate_y(suggested_rotation)
	
func _physics_process(delta):
	if _clicked:
		if _in_hand and _clicked==owned:
			var query=CardCount.raycast_from_mouse(get_viewport().get_camera_3d())
			if query:
				target=query['position']
			else:
				var mouse_pos=get_viewport().get_mouse_position()
				var origin=camera.project_ray_origin(mouse_pos)
				target=origin+camera.project_ray_normal(mouse_pos)*2
			velocity=(target-global_position).project(global_transform.basis.x)*card_speed*delta
			if not is_multiplayer_authority(): return
			move_and_slide()
			
		elif _state==_states.play and _clicked==owned:
			check_inplay()
			var query=CardCount.raycast_from_mouse(get_viewport().get_camera_3d(),0b10)
			if query:
				target=query['position']
			velocity=(target-global_position)*card_speed*delta
			if not is_multiplayer_authority(): return
			move_and_slide()
			position.y=_play_area.global_position.y+.3
			
		elif _state==_states.play and _clicked==multiplayer.get_unique_id():
			check_inplay()
			var query=CardCount.raycast_from_mouse(get_viewport().get_camera_3d(),0b10)
			if query:
				target=query['position']
			var suggest_velocity=(target-global_position)*card_speed
			get_node('../{0}'.format([name])).move_non_authority_card.rpc_id(get_multiplayer_authority(),suggest_velocity*delta)
		
	if is_on_floor():
		if not is_multiplayer_authority(): return
		velocity=velocity*.9
		if velocity.length()<0.0003:
			velocity=Vector3.ZERO
			
	if _state==_states.play:
		if not is_multiplayer_authority(): return
		move_and_slide()
		check_inplay()
		position.y=clamp(position.y,_play_area.global_position.y-.02,_play_area.global_position.y+.4)
		position.x=clamp(position.x,-bounds.size.x/2,bounds.size.x/2)
		position.z=clamp(position.z,-bounds.size.z/2,bounds.size.z/2)
		
func set_hand(hand):
	_in_hand=hand
	_update()
	collision_layer=0b1
	change_card_visibility.rpc(false)
	
func check_inplay():
	_play_area=get_node('/root/Node/table/PlayArea')
	bounds=_play_area.mesh.get_aabb()
	var check_x=-bounds.size.x/2<global_position.x and global_position.x<bounds.size.x/2
	var check_z=-bounds.size.z/2<global_position.z and global_position.z<bounds.size.z/2
	return check_x and check_z
	
func _mouse_enter():
	if not is_multiplayer_authority(): return
	if _in_hand and not raised:
		$Cube.translate_object_local(Vector3(.1,0,0))
		raised=true
		$Cube.get_surface_override_material(0).emission_enabled=true
		
func _mouse_exit():
	if not is_multiplayer_authority(): return
	if raised:
		raised=false
		$Cube.translate_object_local(Vector3(-.1,0,0))
	$Cube.get_surface_override_material(0).emission_enabled=false
	
@rpc("any_peer", "call_local","reliable")
func unclick():
	_clicked=null
	if not is_multiplayer_authority(): return
	if _in_hand:
		velocity=Vector3.ZERO
		move_to_hand(_in_hand,default_pos)
	else:
		motion_mode=CharacterBody3D.MOTION_MODE_GROUNDED
		velocity.y=-1
		collision_mask=0b11
		
@rpc("any_peer", "call_local","reliable")
func update_card(mesh,state,in_hand,card_type,clicked):
	
	_mesh=mesh
	_state=state	
	_in_hand=in_hand
	_card_type=card_type
	_clicked=clicked
	
func _update():
	if not is_multiplayer_authority(): return
	update_card.rpc(_mesh,_state,_in_hand,_card_type,_clicked)

						
@rpc("any_peer", "call_local","reliable")
func click(clicker_id):
	_clicked=clicker_id
	
func _ready():
	tween=get_tree().create_tween()
	velocity=Vector3.ZERO
	
