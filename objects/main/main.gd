extends Control

@export var node_types_array: Array = [
	"res://objects/nodes/start/start.tscn",
	"res://objects/nodes/scene/scene.tscn",
	"res://objects/nodes/screen/screen.tscn",
	"res://objects/nodes/sound/sound.tscn",
	"res://objects/nodes/call/call.tscn"
	]
var node_types = {}
var lang = ""
const version = "dev1"
var current_path = ""
var current_file = {}
var last_selected_node_IDX = ""
var selected_nodes = Array()
var start_data = {
	"Type": "Visual Novel Development Studio",
	"Meta": {
		"Author": "",
		"Project": "",
		"Time": Time.get_unix_time_from_system(),
		"ProjectVersion": 0,
		"VNDSVersion": version,
		"Language": "",
		"BaseLanguage": 1
	},
	"Data": {
		"Replacements": {},
		"Script": {
			"Start": {
				"Type": "Start",
 				"X": 0,
 				"Y": 0,
 				"Fields":{},
 				"Connections":{}
			}
		}
	}
}

func _ready():
	$MainPanel/ToolsContainer/VersionLabel.text = "v. " + version
	for node_type in node_types_array:
		var pack_obj = load(node_type)
		var obj = pack_obj.instantiate()
		node_types[obj.node_type] = pack_obj
		obj.queue_free()
		
	print("VNDS ScriptWriter | v. ", version, " | 2024")
	print(node_types)
	for node_type in node_types:
		if node_type != "Start":
			$MainPanel/Menu.add_item(node_type)
	
	var args = OS.get_cmdline_user_args()
	if len(args) != 0:
		var path = args[0].replace("--", "")
		current_path = path
		load_json(path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_json(path):
	path = str(path).replace("\\", "/")
	current_path = path
	print("Loading JSON: ", path)
	var file = FileAccess.open(path, FileAccess.READ)
	var json_parser = JSON.new()
	var fdata = json_parser.parse_string(file.get_as_text())
	file.close()
	if fdata["Type"] == "Visual Novel Development Studio" and "Meta" in fdata and "Data" in fdata:
		json_parser = JSON.new()
		$MainPanel/ToolsContainer/ReplacementsInput.text = json_parser.stringify(fdata["Data"]["Replacements"])
		$MainPanel/ToolsContainer/ImportButton.disabled = true
		$MainPanel/ToolsContainer/CreateButton.disabled = true
		$MainPanel/ToolsContainer/NameInput.text = str(fdata["Meta"]["Project"])
		$MainPanel/ToolsContainer/AuthorInput.text = str(fdata["Meta"]["Author"])
		var data = fdata["Data"]
		var nodes_by_name = {}
		for node in data["Script"]:
			var new_node = node_types[data["Script"][node]["Type"]].instantiate()
			nodes_by_name[node] = new_node
			if "delete_slot" in new_node:
				new_node.delete_slot.connect(_delete_slot)
			if "main_node" in new_node:
				new_node.main_node = self
			$MainPanel/Editor.add_child(new_node)
			new_node.IDX = node
			new_node.position_offset.x = data["Script"][node]["X"]
			new_node.position_offset.y = data["Script"][node]["Y"]
			if not bool(int(fdata["Meta"]["BaseLanguage"])):
				new_node.read_only = true

			new_node.set_fields(data["Script"][node]["Fields"])
		for fnode in data["Script"]:
			var from_node_obj = nodes_by_name[fnode].name
			for fpoint in data["Script"][fnode]["Connections"]:
				for tnode in data["Script"][fnode]["Connections"][fpoint]:
					var to_node_obj = nodes_by_name[tnode].name
					var tpoint = data["Script"][fnode]["Connections"][fpoint][tnode]

					$MainPanel/Editor.connect_node(from_node_obj, int(fpoint), to_node_obj, int(tpoint))
		$MainPanel/ToolsContainer/ExportButton.disabled = false
		$MainPanel/ToolsContainer/ShowButton.disabled = false
		current_file = fdata
	else:
		push_error("JSON is broken!")

func save_json():
	var data = get_json()
	print("Saving JSON:", current_path)
	var file = FileAccess.open(current_path, FileAccess.WRITE)
	var json_parser = JSON.new()
	var str_data = json_parser.stringify(data, "\t")
	file.store_string(str_data)
	file.close()

func get_json():
	print("Get JSON...")
	var data = {}
	for node in $MainPanel/Editor.get_children():
		data[node.IDX] = {
			"Type": node.node_type,
			"X": node.position_offset.x,
			"Y": node.position_offset.y,
			"Fields": node.get_fields(),
			"Connections": {}
		}
	for con in $MainPanel/Editor.get_connection_list():
		var fnode = $MainPanel/Editor.get_node(str($MainPanel/Editor.get_path())+"/"+con["from_node"])
		var tnode = $MainPanel/Editor.get_node(str($MainPanel/Editor.get_path())+"/"+con["to_node"])
		if str(con["from_port"]) not in data[fnode.IDX]["Connections"]:
			data[fnode.IDX]["Connections"][str(con["from_port"])] = {}
		data[fnode.IDX]["Connections"][str(con["from_port"])][tnode.IDX] = int(con["to_port"])
	current_file["Data"]["Script"] = data
	var json_parser = JSON.new()
	current_file["Data"]["Replacements"] = json_parser.parse_string($MainPanel/ToolsContainer/ReplacementsInput.text)
	current_file["Meta"]["Time"] = Time.get_unix_time_from_system()
	current_file["Meta"]["Author"] = $MainPanel/ToolsContainer/AuthorInput.text
	current_file["Meta"]["Project"] = $MainPanel/ToolsContainer/NameInput.text
	current_file["Meta"]["ProjectVersion"] = int(current_file["Meta"]["ProjectVersion"]) + 1
	return current_file

func _on_file_dialog_file_selected(path):
	load_json(path)

func _delete_slot(node, port):
	for con in $MainPanel/Editor.get_connection_list():
		if con["from_node"] == node and con["from_port"] == port:
			_on_editor_disconnection_request(node, port, con["to_node"], con["to_port"])

func _on_editor_connection_request(from_node, from_port, to_node, to_port):
	if bool(int(current_file["Meta"]["BaseLanguage"])):
		if $MainPanel/Editor.is_node_connected(from_node, from_port, to_node, to_port):
			_on_editor_disconnection_request(from_node, from_port, to_node, to_port)
		else:
			var cons = 0
			for con in $MainPanel/Editor.get_connection_list():
				if con["from_node"] == from_node and con["from_port"] == from_port:
					cons += 1
			if cons == 0:
				$MainPanel/Editor.connect_node(from_node, from_port, to_node, to_port)

func _on_editor_disconnection_request(from_node, from_port, to_node, to_port):
	if bool(int(current_file["Meta"]["BaseLanguage"])):
		$MainPanel/Editor.disconnect_node(from_node, from_port, to_node, to_port)



func _on_import_button_pressed():
	$FileDialog.popup_centered()


func _on_export_button_pressed():
	save_json()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed() and current_file != {}:
			$MainPanel/Menu.position = event.position
			$MainPanel/Menu.popup()
			accept_event()
	elif event.is_action_pressed("copy_idx"):
		if last_selected_node_IDX != "":
			print("Node IDX: ", last_selected_node_IDX)
			DisplayServer.clipboard_set(last_selected_node_IDX)
	elif event.is_action_pressed("duplicate_node"):
		for node in selected_nodes:
			if node.node_type != "Start":
				var dnode = node.duplicate()
				dnode.position_offset.x += 15
				dnode.position_offset.y += 15
				dnode.IDX = "script_"+str(int(Time.get_unix_time_from_system()*10000))+str(randi())
				if dnode.node_type == "Screen":
					for obj in node.screen_node.get_children():
						var layout = {
							"AnchorLeft": obj.anchor_left,
							"AnchorTop": obj.anchor_top,
							"AnchorRight": obj.anchor_right,
							"AnchorBottom": obj.anchor_bottom,
							"OffsetLeft": obj.offset_left,
							"OffsetTop": obj.offset_top,
							"OffsetRight": obj.offset_right,
							"OffsetBottom": obj.offset_bottom
						}
						dnode.add_img(obj.get_meta("Path"), "", obj.get_meta("Flip"), layout)
				$MainPanel/Editor.add_child(dnode)
	elif event.is_action_pressed("delete_node"):
		for node in selected_nodes:
			print(node, selected_nodes)
			if node.node_type != "Start":
				selected_nodes.erase(node)
				for con in $MainPanel/Editor.get_connection_list():
					if con["from_node"] == node.name:
						_on_editor_disconnection_request(node.name,  con["from_port"], con["to_node"], con["to_port"])
					if con["to_node"] == node.name:
						_on_editor_disconnection_request(con["from_node"],  con["from_port"], node.name, con["to_port"])
				node.queue_free()

func add_node(node_name):
	var new_node = node_types[node_name].instantiate()
	if "delete_slot" in new_node:
		new_node.delete_slot.connect(_delete_slot)
	if "main_node" in new_node:
		new_node.main_node = self
	var x = $MainPanel/Editor.get_local_mouse_position().x+$MainPanel/Editor.scroll_offset.x
	var y = $MainPanel/Editor.get_local_mouse_position().y+$MainPanel/Editor.scroll_offset.y
	new_node.position_offset = Vector2(x/$MainPanel/Editor.zoom,y/$MainPanel/Editor.zoom)
	new_node.IDX = "script_"+str(int(Time.get_unix_time_from_system()*10000))+str(randi())
	$MainPanel/Editor.add_child(new_node)

func _on_menu_index_pressed(index):
	var node_name = $MainPanel/Menu.get_item_text(index)
	if node_name in node_types:
		add_node(node_name)



func _on_editor_node_selected(node):
	last_selected_node_IDX = node.IDX
	selected_nodes.append(node)


func _on_editor_node_deselected(node):
	selected_nodes.erase(node)


func _on_create_button_pressed():
	$DirectoryDialog.popup_centered()


func _on_directory_dialog_dir_selected(dir):
	var dirac = DirAccess.open(dir)
	dirac.make_dir("Resources")
	dirac.make_dir("Resources/Images")
	dirac.make_dir("Resources/Sounds")
	var file = FileAccess.open(dir+"/project.json", FileAccess.WRITE)
	var json_parser = JSON.new()
	var str_data = json_parser.stringify(start_data)
	file.store_string(str_data)
	file.close()
	load_json(dir+"/project.json")
	


func _on_show_button_pressed():
	OS.shell_open(current_path.left(current_path.rfind("/")))
