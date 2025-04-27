extends RigidBody3D
class_name Card

var falling=false
var rotation_needed
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
enum _states {hand,play,discard}
var _state=_states.hand
var tween=null
var _owned=null
var card_speed=80
@onready var camera=get_viewport().get_camera_3d()
var bounds
	
@rpc("any_peer", "call_local","reliable")
func change_card_visibility():
	if _state==_states.play or multiplayer.get_unique_id()==_owned:
		$Cube.mesh=load(_mesh)
	else:
		$Cube.mesh=load("res://cards/money/1M.tres")
		
@rpc("any_peer", "call_local","reliable")	
func make_card(mesh_path,type):
	_card_type=type
	_mesh=mesh_path
	$Cube.mesh=load("res://cards/money/1M.tres")
	bord=bord.duplicate()
	bord.emission_enabled=false
	$Cube.set_surface_override_material(0,bord)
	
func check_authority():
	return _owned==multiplayer.get_unique_id()
	
@rpc("any_peer", "call_local","reliable")
func play_card():
	if not multiplayer.is_server(): return
	global_rotation.x=0
	global_rotation.z=0 
	_in_hand=null
	_state=_states.play
	_update()
		
func give_parabola(t):
	global_position.y=default_pos.y+4*t*(1-t)
	
@rpc("any_peer", "call_local","reliable")
func move_to_hand(hand,place):
	if not multiplayer.is_server(): return
	default_pos=place
	if not is_inside_tree():
		await ready
	hand = get_node(hand)
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
	if not multiplayer.is_server(): return
	place.y=place.y-0.03
	default_pos=place
	if not is_inside_tree():
		await ready
	tween = create_tween()
	tween.tween_property(self,'global_position:x',place.x,animate_time)
	tween.parallel().tween_property(self,'global_position:z',place.z,animate_time)
	tween.parallel().tween_property(self,'global_rotation',Vector3(0,PI/2,0),animate_time)
	tween.parallel().tween_method(give_parabola,0.0,1.0,animate_time)
	tween.tween_callback(func(): _state=_states.discard).set_delay(animate_time)
	tween.tween_callback(func(): _update()).set_delay(animate_time+0.1)
	set_process(false)
	set_physics_process(false)
	
@rpc("any_peer","call_local","unreliable_ordered")	
func move_non_authority_card(suggested_velocity:Vector3):
	if not multiplayer.is_server(): return
	linear_velocity=suggested_velocity.limit_length(40)
	
@rpc("any_peer","call_local","unreliable_ordered")	
func rotate_non_authority_card(suggested_rotation):
	# Only for y rotations
	if not multiplayer.is_server(): return
	rotation_needed=true
	
func _physics_process(delta: float) -> void:
	# i could lower velocity when mouse moves off table
	if _clicked==multiplayer.get_unique_id():
		var suggested_velocity
		if _in_hand:
			var query=CardCount.raycast_from_mouse(get_viewport().get_camera_3d())
			if query:
				target=query['position']
			else:
				var mouse_pos=get_viewport().get_mouse_position()
				var origin=camera.project_ray_origin(mouse_pos)
				target=origin+camera.project_ray_normal(mouse_pos)*2
			suggested_velocity=(target-global_position).project(transform.basis.x)*card_speed*delta
			#if not suggested_velocity.y>0: return
			move_non_authority_card.rpc_id(1,suggested_velocity)
		elif _state==_states.play:
			check_inplay()
			var query=CardCount.raycast_from_mouse(get_viewport().get_camera_3d(),0b10)
			if query:
				target=query['position']
			suggested_velocity=(target-global_position)*card_speed*delta
			move_non_authority_card.rpc_id(1,suggested_velocity)
		
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not multiplayer.is_server(): return
	if _state==_states.play:
		check_inplay()
		var temp_form=state.transform
		temp_form.origin.x=clamp(temp_form.origin.x,-bounds.size.x/2,bounds.size.x/2)
		temp_form.origin.z=clamp(temp_form.origin.z,-bounds.size.z/2,bounds.size.z/2)
		if check_inplay() and _clicked:
			temp_form.origin.y=_play_area.global_position.y+.3
		if rotation_needed:
			angular_velocity=Vector3.ZERO
			temp_form.basis=Basis().looking_at(Vector3.UP,Vector3.UP,true)*Basis(Vector3.UP, deg_to_rad(90))
			rotation_needed=false
		if falling:
			temp_form.origin.y=5
			temp_form.origin.z=0
			temp_form.origin.x=0
			falling=false
		state.transform=temp_form
		
func set_hand(hand):
	if not multiplayer.is_server(): return
	_in_hand=hand
	_update()
	collision_layer=0b1
	change_card_visibility.rpc()
	
func check_inplay():
	_play_area=get_node('/root/Node/table/PlayArea')
	bounds=_play_area.mesh.get_aabb()
	var check_x=-bounds.size.x/2<global_position.x and global_position.x<bounds.size.x/2
	var check_z=-bounds.size.z/2<global_position.z and global_position.z<bounds.size.z/2
	return check_x and check_z
	
func _mouse_enter():
	if not check_authority(): return
	if _in_hand and not raised:
		$Cube.translate_object_local(Vector3(.1,0,0))
		raised=true
		$Cube.get_surface_override_material(0).emission_enabled=true
	
func _mouse_exit():
	if not check_authority(): return
	if raised:
		raised=false
		$Cube.translate_object_local(Vector3(-.1,0,0))
	$Cube.get_surface_override_material(0).emission_enabled=false
	
@rpc("any_peer", "call_local","reliable")
func click(clicker_id):
	_clicked=clicker_id
	if not multiplayer.is_server(): return
	gravity_scale=0
	
@rpc("any_peer", "call_local","reliable")
func unclick():
	_clicked=null
	if not multiplayer.is_server(): return
	if _in_hand:
		linear_velocity=Vector3.ZERO
		move_to_hand(_in_hand.get_path(),default_pos)
	else:
		gravity_scale=0.5
		collision_mask=0b11
		
@rpc("any_peer", "call_local","reliable")
func update_card(mesh,state,in_hand,card_type,clicked,owned):
	_mesh=mesh
	_state=state
	_card_type=card_type
	_clicked=clicked
	_owned=owned
	if in_hand==null: _in_hand=null
	else: _in_hand=get_node(in_hand)
	change_card_visibility()
	
@rpc("any_peer", "call_local","reliable")
func _update():
	if not multiplayer.is_server(): return
	if _in_hand!=null: _in_hand=_in_hand.get_path()
	update_card.rpc(_mesh,_state,_in_hand,_card_type,_clicked,_owned)
	
@rpc("any_peer","call_local")
func reset_authority(new_owner:int):
	_owned=new_owner
	
func _ready():
	tween=create_tween()
	
