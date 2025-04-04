extends Node3D
@onready var camera = $Camera3D

#func _unhandled_input(event):
	#if not is_multiplayer_authority(): return
	#
	#if event is InputEventMouseMotion:
		#rotate_y(-event.relative.x * .005)
		#camera.rotate_x(-event.relative.y * .005)
		#camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	#
	#if Input.is_action_just_pressed("shoot") \
			#and anim_player.current_animation != "shoot":
		#play_shoot_effects.rpc()
		#if raycast.is_colliding():
			#var hit_player = raycast.get_collider()
			#hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
#
#func _physics_process(delta):
	#if not is_multiplayer_authority(): return
	#
	## Add the gravity.
	#if not is_on_floor():
		#velocity.y -= gravity * delta
#
	## Handle Jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector("left", "right", "up", "down")
	#var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
#
	#if anim_player.current_animation == "shoot":
		#pass
	#elif input_dir != Vector2.ZERO and is_on_floor():
		#anim_player.play("move")
	#else:
		#anim_player.play("idle")
#
	#move_and_slide()
#
#@rpc("call_local")
#func play_shoot_effects():
	#anim_player.stop()
	#anim_player.play("shoot")
	#muzzle_flash.restart()
	#muzzle_flash.emitting = true
#
#@rpc("any_peer")
#func receive_damage():
	#health -= 1
	#if health <= 0:
		#health = 3
		#position = Vector3.ZERO
	#health_changed.emit(health)
#
#func _on_animation_player_animation_finished(anim_name):
	#if anim_name == "shoot":
		#anim_player.play("idle")
