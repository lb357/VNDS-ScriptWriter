extends GraphNode
@export var Fields = {}
@export var node_type = "Sound"
@export var IDX = ""
var menu = []
@export var read_only = false
@export var main_node: Node

func _process(delta):
	resizable = !read_only
	draggable = !read_only
	selectable = !read_only
	title = "%s (%s)"%[node_type, IDX]


func set_fields(fields):
	Fields["Sound"] = fields["Sound"]
	$Container/SoundButton.clear()
	$Container/SoundButton.add_item(Fields["Sound"])
	$Container/SoundButton.select(0)

func get_fields():
	Fields["Sound"] = $Container/SoundButton.get_item_text($Container/SoundButton.selected)
	return Fields


func get_dir(path, prefix = ""):
	var dir = DirAccess.open(path)
	var files = dir.get_files()
	var dirs = dir.get_directories()
	var outfiles = []
	for ldir in dirs:
		files.append_array(get_dir(path+"/"+ldir, ldir+"/"))
	for file in files:
		outfiles.append(prefix+file)
	return outfiles

func add_dir(popup_node):
	var path = main_node.current_path.left(main_node.current_path.rfind("/"))
	var files = get_dir(path+"/Resources/Sounds/")
	var menu = popup_node.get_popup()
	menu.clear()
	for file in files:
		menu.add_item(file)
		


func _on_option_button_pressed():
	add_dir($Container/SoundButton)
