
# Called when the node enters the scene tree for the first time.


			

		
		


	
#func _input(event):
	#if event is InputEventMouseButton:
		#if event.button_index==1 and event.is_pressed():
			#var query=CardCount.raycast_from_mouse()
			#if query:
				#if query['collider'].has_method('make_card'):
					#var collider=query['collider']
					#collider.clicked=true
					#collider.add_to_group(clicked_group)
		#elif event.button_index==1 and not event.is_pressed():
			#get_tree().call_group(clicked_group,'unclick')
			
func _process(delta):
	pass
