extends Label

var base_font_size
@onready var base_screen_height := 648

func _ready():
	base_font_size=label_settings.font_size
	update_font_size()
	get_viewport().connect("size_changed", update_font_size)

func update_font_size():
	var font_scale = get_viewport().size.y / base_screen_height
	var new_font_size = int(base_font_size * font_scale)
	label_settings.font_size=new_font_size
