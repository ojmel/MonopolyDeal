@tool
extends EditorScript

func _run():
	print(ResourceLoader.load("res://cards/carv3.gd"))
	
	#print(print_all_files_in_directory('res://cards/money/'))
	#var folder_path = "res://card_stuff/"  # Replace with your folder path
	#var script_to_attach = load("res://cards/card.gd")  # Replace with your script path
	#var dir = DirAccess.open(folder_path)
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if file_name.ends_with(".glb"):  # Look for scene files
				#var scene_path = folder_path + file_name
				#var scene = load(scene_path).instantiate()
				#var mesh=scene.get_node('Cube').mesh
				#var new_path='res://cards/action/' +file_name.replace('glb','tres')
				#print(ResourceSaver.save(mesh,new_path))
				##print("Script attached to: ", file_name)
			#file_name = dir.get_next()
		#dir.list_dir_end()
	#else:
		#print("Failed to open directory.")

#func print_all_files_in_directory(directory_path: String):
	#var dir = DirAccess.open(directory_path)
	#var file_list=[]
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#
		#while file_name != "":
			#if not dir.current_is_dir():  # Check if it's a file
				#file_list.append("'"+directory_path + '/' + file_name+"':1")
			#file_name = dir.get_next()
		#
		#dir.list_dir_end()
	#else:
		#print("Failed to open directory: ", directory_path)
	#
	#return ", ".join(file_list)
	pass
