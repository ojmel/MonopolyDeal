extends Camera3D
var rot_x = 0
var rot_y = 0
var velocity
func _ready():
	if not is_multiplayer_authority(): return
	#global_rotation=Vector3.ZERO
	
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	velocity=3*delta
	if Input.is_action_pressed('ui_left'):
		translate(Vector3(-velocity,0,0))
	if Input.is_action_pressed('ui_right'):
		translate(Vector3(velocity,0,0))
	if Input.is_action_just_released('ui_page_up'):
		translate(Vector3(0,0,-velocity*10))
	if Input.is_action_just_released('ui_page_down'):
		translate(Vector3(0,0,velocity*10))
	if Input.is_action_pressed('ui_down'):
		translate(Vector3(0,-velocity,0))
		#position.y=clamp(position.y,position.y,position.y)
	if Input.is_action_pressed('ui_up'):
		translate(Vector3(0,velocity,0))
		#position.y=clamp(position.y,position.y,position.y)
	position=position.clamp(Vector3(-8,0,-8),Vector3(8,5,8))
		
func _input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		if event.button_mask==2:
			var rotation_speed=PI/25
			rotate_object_local(Vector3(1,0,0),lerp(rotation_speed,-rotation_speed,inverse_lerp(-30.0,30.0,event.relative.y)))
			rotation.x=clamp(rotation.x,-1.4,.7)
			rotate_object_local(Vector3(0,1,0),lerp(rotation_speed,-rotation_speed,inverse_lerp(-50.0,50.0,event.relative.x)))
			rotation.z=clamp(rotation.z,0,0)

func _process(delta):
	pass
