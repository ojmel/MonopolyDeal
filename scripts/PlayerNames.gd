extends Label


func _ready() -> void:
	pass
	
func print_names(names:Array):
	text=''
	for _name in names:
		text+=_name+'\n'
	
func _process(_delta: float) -> void:
	pass
