extends GraphNode

@export var Fields = {}
@export var node_type = "Screen"
var IDX = ""
var bg = ""
@export var main_node: Node
@onready var screen_node: TextureRect = $Container/Screen
@export var read_only = false

func _process(delta):
	resizable = !read_only
	draggable = !read_only
	selectable = !read_only
	title = "%s (%s)"%[node_type, IDX]

func set_fields(fields):
	Fields["Background"] = fields["Background"]
	bg = fields["Background"]
	if bg != "":
		var img = load_img(bg)
		$Container/Screen.texture = img[0]
		$Container/Screen.set_meta("Size", img[2])
		$Container/SettingsButton.disabled = false
		var objs = fields["Objects"]
		for obj in objs:
			add_img(objs[obj]["Path"], obj, bool(int(objs[obj]["Flip"])), objs[obj]["Layout"])


func get_fields():
	Fields["Background"] = bg
	Fields["Objects"] = {}
	for obj in $Container/Screen.get_children():
		var obj_name = obj.get_meta("Name")
		Fields["Objects"][obj_name] = {}
		Fields["Objects"][obj_name]["Path"] = str(obj.get_meta("Path"))
		Fields["Objects"][obj_name]["Flip"] = int(bool(obj.get_meta("Flip")))
		Fields["Objects"][obj_name]["Layout"] = {
			"AnchorLeft": obj.anchor_left,
			"AnchorTop": obj.anchor_top,
			"AnchorRight": obj.anchor_right,
			"AnchorBottom": obj.anchor_bottom,
			"OffsetLeft": obj.offset_left,
			"OffsetTop": obj.offset_top,
			"OffsetRight": obj.offset_right,
			"OffsetBottom": obj.offset_bottom
		}
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
	var files = get_dir(path+"/Resources/Images/")
	var menu = popup_node.get_popup()
	menu.clear()
	for file in files:
		menu.add_item(file)

func _on_add_button_about_to_popup():
	add_dir($Container/AddButton)

func _on_select_button_about_to_popup():
	add_dir($Container/SelectButton)
	
func _ready():
	$Container/SelectButton.get_popup().index_pressed.connect(_on_select_popup)
	$Container/AddButton.get_popup().index_pressed.connect(_on_add_popup)
	$Container/ControlButton.get_popup().index_pressed.connect(_on_control_popup)
	
func calc_ratio(size):
	if size[1] <= 0 or size[0] <= 0:
		return -1
	else:
		return roundf(float(size[0])/float(size[1])*1000)/1000
	
func load_img(path):
	var endpoint_path = main_node.current_path.left(main_node.current_path.rfind("/"))+"/Resources/Images/"+path	
	var img = Image.load_from_file(endpoint_path)
	var texture = ImageTexture.create_from_image(img)
	return [texture, calc_ratio(img.get_size()), img.get_size()]
	
func add_img(path, name = "", flip = false, layout = {}):
	var img = load_img(path)
	var rect = TextureRect.new()
	rect.set_meta("Path", path)
	if name == "":
		rect.set_meta("Name", path+"_"+str(int(Time.get_unix_time_from_system()))+str(randi()))
	else:
		rect.set_meta("Name", name)
	rect.set_meta("Ratio", img[1])
	rect.set_meta("Flip", flip)
	rect.flip_h = flip
	rect.texture = img[0]
	rect.expand_mode = rect.EXPAND_IGNORE_SIZE
	if layout != {}:
		rect.anchor_left = layout["AnchorLeft"]
		rect.anchor_top = layout["AnchorTop"]
		rect.anchor_right = layout["AnchorRight"]
		rect.anchor_bottom =layout["AnchorBottom"]
		rect.offset_left = layout["OffsetLeft"]
		rect.offset_top = layout["OffsetTop"]
		rect.offset_right = layout["OffsetRight"]
		rect.offset_bottom = layout["OffsetBottom"]
	else:
		rect.anchor_right = 0.5
		rect.anchor_bottom = 0.5
	$Container/Screen.add_child(rect)
	update_control()
	
func update_control():
	$Container/ControlButton.clear()
	for node in $Container/Screen.get_children():
		$Container/ControlButton.add_item(node.get_meta("Name")+" ("+str(node.get_meta("Ratio"))+")")
	
func _on_add_popup(index):
	add_img($Container/AddButton.get_popup().get_item_text(index))
	
func _on_select_popup(index):
	var img_str = $Container/SelectButton.get_popup().get_item_text(index)
	var img = load_img(img_str)
	$Container/Screen.texture = img[0]
	$Container/Screen.set_meta("Size", img[2])
	bg = img_str
	$Container/SettingsButton.disabled = false

func save_slider(node):
	$Container/SettingsContainer/PLSlider.value = node.anchor_left
	$Container/SettingsContainer/PTSlider.value = node.anchor_top
	$Container/SettingsContainer/PRSlider.value = node.anchor_right
	$Container/SettingsContainer/PBSlider.value = node.anchor_bottom
	$Container/SettingsContainer/OLSlider.value = node.offset_left
	$Container/SettingsContainer/OTSlider.value = node.offset_top
	$Container/SettingsContainer/ORSlider.value = node.offset_right
	$Container/SettingsContainer/OBSlider.value = node.offset_bottom
	$Container/SettingsContainer/FlipButton.button_pressed = node.get_meta("Flip")


func load_slider(node):
	node.anchor_left = $Container/SettingsContainer/PLSlider.value
	node.anchor_top = $Container/SettingsContainer/PTSlider.value
	node.anchor_right = $Container/SettingsContainer/PRSlider.value
	node.anchor_bottom = $Container/SettingsContainer/PBSlider.value
	node.offset_left = $Container/SettingsContainer/OLSlider.value
	node.offset_top = $Container/SettingsContainer/OTSlider.value
	node.offset_right = $Container/SettingsContainer/ORSlider.value
	node.offset_bottom = $Container/SettingsContainer/OBSlider.value
	node.set_meta("Flip", $Container/SettingsContainer/FlipButton.button_pressed)

func _on_control_popup(index):
	if index != -1:
		var node = $Container/Screen.get_children()[index]
		save_slider(node)
		_on_highlight_button_toggled($Container/HighlightButton.button_pressed)


func _on_set_button_pressed():
	var index = $Container/ControlButton.selected
	if index != -1:
		var node = $Container/Screen.get_children()[index]
		load_slider(node)
		_slider_value_changed(-1)
		node.flip_h = node.get_meta("Flip")


func _on_remove_button_pressed():
	var index = $Container/ControlButton.selected
	if index != -1:
		var node = $Container/Screen.get_children()[index]
		$Container/Screen.remove_child(node)
		node.queue_free()
		update_control()


func _slider_value_changed(value):
	var dx = ($Container/SettingsContainer/PRSlider.value - $Container/SettingsContainer/PLSlider.value)*$Container/Screen.get_meta("Size")[0]
	var dy = ($Container/SettingsContainer/PBSlider.value - $Container/SettingsContainer/PTSlider.value)*$Container/Screen.get_meta("Size")[1]
	var index = $Container/ControlButton.selected
	if index != -1:
		var node = $Container/Screen.get_children()[index]
		$Container/SettingsContainer/DataContainer/PointText.text = "L/T/R/B: %s/%s/%s/%s"%[
			$Container/SettingsContainer/PLSlider.value,
			$Container/SettingsContainer/PTSlider.value,
			$Container/SettingsContainer/PRSlider.value,
			$Container/SettingsContainer/PBSlider.value,
		]
		$Container/SettingsContainer/DataContainer/RatioText.text = "Ratio: %s (%s)"%[calc_ratio(node.size), calc_ratio([dx, dy])]
		$Container/SettingsContainer/OffsetText.text = "L/T/R/B: %s/%s/%s/%s"%[
			$Container/SettingsContainer/OLSlider.value,
			$Container/SettingsContainer/OTSlider.value,
			$Container/SettingsContainer/ORSlider.value,
			$Container/SettingsContainer/OBSlider.value,
		]

func _on_settings_button_toggled(toggled_on):
	$Container/SettingsContainer.visible = toggled_on


func _on_highlight_button_toggled(toggled_on):
	var index = $Container/ControlButton.selected
	if index != -1 and toggled_on:
		var node = $Container/Screen.get_children()[index]
		for child in $Container/Screen.get_children():
			if child == node:
				child.modulate = Color(1,0,0,1)
			else:
				child.modulate = Color(1,1,1,1)
	else:
		for child in $Container/Screen.get_children():
			child.modulate = Color(1,1,1,1)
		
