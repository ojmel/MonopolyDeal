extends Label


func _ready() -> void:
	pass
	
func print_names(names:Array):
	text=''
	for name in names:
		text+=name+'\n'
	
func _process(delta: float) -> void:
	pass
