extends GraphNode
@export var Fields = {}
@onready var menu_slot = load("res://objects/nodes/scene/menu_slot.tscn")
@export var node_type = "Scene"
@export var IDX = ""
var menu = []
signal delete_slot

@export var read_only = false
func _process(delta):
	resizable = !read_only
	draggable = !read_only
	selectable = !read_only
	$Container/MenuBox/MenuButton.disabled = read_only
	title = "%s (%s)"%[node_type, IDX]

func set_fields(fields):
	Fields["Label"] = fields["Label"]
	$Container/LabelBox/LabelInput.text = Fields["Label"]
	Fields["Text"] = fields["Text"]
	$Container/TextBox/TextInput.text = Fields["Text"]
	Fields["Menu"] = bool(int(fields["Menu"]))
	$Container/MenuBox/MenuButton.button_pressed = Fields["Menu"]
	_on_check_button_toggled(Fields["Menu"])
	Fields["Slots"] = fields["Slots"]
	for slot in Fields["Slots"]:
		create_slot(slot)
	
	

func get_fields():
	Fields["Label"] = $Container/LabelBox/LabelInput.text
	Fields["Text"] = $Container/TextBox/TextInput.text
	Fields["Menu"] = int($Container/MenuBox/MenuButton.button_pressed)
	Fields["Slots"] = []
	for slot in menu:
		Fields["Slots"].append(slot.text)
	return Fields


func _on_check_button_toggled(toggled_on):
	if !read_only:
		$Container/MenuBox/MenuAddButton.disabled = !toggled_on
		$Container/MenuBox/MenuRemoveButton.disabled = !toggled_on
		if toggled_on:
			$Output.text = "Out:"
			emit_signal("delete_slot", name, 0)
			set_slot_enabled_right($Output.get_index(), false)
		else:
			$Output.text = "Out"
			for i in range(get_output_port_count()):
				emit_signal("delete_slot", name, i)
			for i in menu:
				set_slot_enabled_right(i.get_index(), false)
				i.queue_free()
			menu = []
			set_slot_enabled_right($Output.get_index(), true)


func _on_menu_add_button_pressed():
	if !read_only:
		create_slot()
	
func create_slot(text=""):
	var slot = menu_slot.instantiate()
	slot.text = text
	menu.append(slot)
	add_child(slot)
	set_slot_enabled_right(slot.get_index(), true)

func _on_menu_remove_button_pressed():
	if !read_only:
		var slot = menu.pop_back()
		for i in range(get_output_port_count()):
			if slot.get_index() == get_output_port_slot(i):
				emit_signal("delete_slot", name, i)
				set_slot_enabled_right(slot.get_index(), false)
				slot.queue_free()

