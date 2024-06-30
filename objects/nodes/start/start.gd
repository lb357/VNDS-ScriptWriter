extends GraphNode

@export var Fields = {}
@export var node_type = "Start"
var IDX = "Start"

@export var read_only = false
func _process(delta):
	resizable = !read_only
	draggable = !read_only
	selectable = !read_only
	title = "%s (%s)"%[node_type, IDX]
	

func set_fields(fields):
	Fields = {}

func get_fields():
	return Fields
