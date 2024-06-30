extends GraphNode
@export var Fields = {}
@export var node_type = "Call"
@export var IDX = ""
var menu = []
@export var read_only = false

func _process(delta):
	resizable = !read_only
	draggable = !read_only
	selectable = !read_only
	$Container/CallInput.editable = !read_only
	title = "%s (%s)"%[node_type, IDX]

func set_fields(fields):
	Fields["Call"] = fields["Call"]
	$Container/CallInput.text = fields["Call"]
	
func get_fields():
	Fields["Call"] = $Container/CallInput.text
	return Fields
