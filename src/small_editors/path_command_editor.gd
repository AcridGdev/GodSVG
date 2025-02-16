extends PanelContainer

signal cmd_update_value(idx: int, new_value: float, property: StringName)
signal cmd_delete(idx: int)
signal cmd_toggle_relative(idx: int)
signal cmd_insert_after(idx: int, cmd_char: String)

const MiniNumberField = preload("mini_number_field.tscn")
const FlagField = preload("flag_field.tscn")

var tag_idx := -1
var cmd_char := ""
var cmd_idx := -1
var path_command: PathCommand

@onready var relative_button: Button = $HBox/RelativeButton
@onready var more_button: Button = $HBox/MoreButton
@onready var fields_container: HBoxContainer = $HBox/Fields
@onready var action_popup: Popup = $ActionsPopup
@onready var command_picker: Popup = $PathPopup

var fields_added_before_ready: Array[Control] = []
var fields: Array[Control] = []

func update_type() -> void:
	cmd_char = path_command.command_char
	var command_type := cmd_char.to_upper()
	fields.clear()
	
	# Instantiate the input fields.
	if command_type == "A":
		var fields_rx_ry: Array[BetterLineEdit] = add_number_field_pair()
		var field_rx := fields_rx_ry[0]
		var field_ry := fields_rx_ry[1]
		var field_rot: BetterLineEdit = add_number_field()
		var field_large_arc_flag: Button = add_flag_field()
		var field_sweep_flag: Button = add_flag_field()
		field_large_arc_flag.set_value(path_command.large_arc_flag)
		field_sweep_flag.set_value(path_command.sweep_flag)
		field_rx.mode = field_rx.Mode.ONLY_POSITIVE
		field_ry.mode = field_ry.Mode.ONLY_POSITIVE
		field_rot.mode = field_rot.Mode.ANGLE
		field_rot.custom_minimum_size.x -= 6
		field_rx.set_value(path_command.rx)
		field_ry.set_value(path_command.ry)
		field_rot.set_value(path_command.rot)
		field_rx.tooltip_text = "rx"
		field_ry.tooltip_text = "ry"
		field_rot.tooltip_text = "rot"
		field_large_arc_flag.tooltip_text = "large_arc_flag"
		field_sweep_flag.tooltip_text = "sweep_flag"
		field_rx.value_changed.connect(update_value.bind(&"rx"))
		field_ry.value_changed.connect(update_value.bind(&"ry"))
		field_rot.value_changed.connect(update_value.bind(&"rot"))
		field_large_arc_flag.value_changed.connect(update_value.bind(&"large_arc_flag"))
		field_sweep_flag.value_changed.connect(update_value.bind(&"sweep_flag"))
		fields.append(field_rx)
		fields.append(field_ry)
		fields.append(field_rot)
		fields.append(field_large_arc_flag)
		fields.append(field_sweep_flag)
	if command_type == "Q" or command_type == "C":
		var fields_x1_y1: Array[BetterLineEdit] = add_number_field_pair()
		var field_x1 := fields_x1_y1[0]
		var field_y1 := fields_x1_y1[1]
		field_x1.set_value(path_command.x1)
		field_y1.set_value(path_command.y1)
		field_x1.tooltip_text = "x1"
		field_y1.tooltip_text = "y1"
		field_x1.value_changed.connect(update_value.bind(&"x1"))
		field_y1.value_changed.connect(update_value.bind(&"y1"))
		fields.append(field_x1)
		fields.append(field_y1)
	if command_type == "C" or command_type == "S":
		var fields_x2_y2: Array[BetterLineEdit] = add_number_field_pair()
		var field_x2 := fields_x2_y2[0]
		var field_y2 := fields_x2_y2[1]
		field_x2.set_value(path_command.x2)
		field_y2.set_value(path_command.y2)
		field_x2.tooltip_text = "x2"
		field_y2.tooltip_text = "y2"
		field_x2.value_changed.connect(update_value.bind(&"x2"))
		field_y2.value_changed.connect(update_value.bind(&"y2"))
		fields.append(field_x2)
		fields.append(field_y2)
	if command_type != "Z":
		if command_type == "H":
			var field_x: BetterLineEdit = add_number_field()
			field_x.set_value(path_command.x)
			field_x.tooltip_text = "x"
			field_x.value_changed.connect(update_value.bind(&"x"))
			fields.append(field_x)
		elif command_type == "V":
			var field_y: BetterLineEdit = add_number_field()
			field_y.set_value(path_command.y)
			field_y.tooltip_text ="y"
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields.append(field_y)
		else:
			var fields_x_y: Array[BetterLineEdit] = add_number_field_pair()
			var field_x := fields_x_y[0]
			var field_y := fields_x_y[1]
			field_x.set_value(path_command.x)
			field_x.tooltip_text = "x"
			field_y.set_value(path_command.y)
			field_y.tooltip_text ="y"
			field_x.value_changed.connect(update_value.bind(&"x"))
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields.append(field_x)
			fields.append(field_y)

# Alternative to fully rebuilding the path command editor, if the layout is unchanged.
func sync_values(cmd: PathCommand) -> void:
	# Instantiate the input fields.
	match cmd_char:
		"A":
			fields[0].set_value(cmd.rx)
			fields[1].set_value(cmd.ry)
			fields[2].set_value(cmd.rot)
			fields[3].set_value(cmd.large_arc_flag)
			fields[4].set_value(cmd.sweep_flag)
			fields[5].set_value(cmd.x)
			fields[6].set_value(cmd.y)
		"C":
			fields[0].set_value(cmd.x1)
			fields[1].set_value(cmd.y1)
			fields[2].set_value(cmd.x2)
			fields[3].set_value(cmd.y2)
			fields[4].set_value(cmd.x)
			fields[5].set_value(cmd.y)
		"H":
			fields[0].set_value(cmd.x)
		"M", "T":
			fields[0].set_value(cmd.x)
			fields[1].set_value(cmd.y)
		"Q":
			fields[0].set_value(cmd.x1)
			fields[1].set_value(cmd.y1)
			fields[2].set_value(cmd.x)
			fields[3].set_value(cmd.y)
		"S":
			fields[0].set_value(cmd.x2)
			fields[1].set_value(cmd.y2)
			fields[2].set_value(cmd.x)
			fields[3].set_value(cmd.y)
		"V":
			fields[0].set_value(cmd.y)
		_: return


func update_value(value: float, property: StringName) -> void:
	Interactions.set_inner_selection(tag_idx, cmd_idx)
	cmd_update_value.emit(cmd_idx, value, property)

func delete() -> void:
	action_popup.hide()
	cmd_delete.emit(cmd_idx)

func toggle_relative() -> void:
	cmd_toggle_relative.emit(cmd_idx)

func insert_after() -> void:
	action_popup.hide()
	command_picker.popup(Utils.calculate_popup_rect(
			more_button.global_position, more_button.size, command_picker.size))

func open_actions() -> void:
	Interactions.set_inner_selection(tag_idx, cmd_idx)
	var buttons_arr: Array[Button] = []
	
	var delete_btn := Button.new()
	delete_btn.text = tr(&"#delete")
	delete_btn.icon = load("res://visual/icons/Delete.svg")
	delete_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	delete_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	delete_btn.pressed.connect(delete)
	buttons_arr.append(delete_btn)
	
	var insert_after_btn := Button.new()
	insert_after_btn.text = tr(&"#insert_after")
	insert_after_btn.icon = load("res://visual/icons/Plus.svg")
	insert_after_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	insert_after_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	insert_after_btn.pressed.connect(insert_after)
	buttons_arr.append(insert_after_btn)
	
	action_popup.set_btn_array(buttons_arr)
	action_popup.popup(Utils.calculate_popup_rect(more_button.global_position,
			more_button.size, action_popup.size, true))


func _ready() -> void:
	Interactions.selection_changed.connect(determine_selection_highlight)
	Interactions.hover_changed.connect(determine_selection_highlight)
	determine_selection_highlight()
	setup_relative_button()
	setup_command_picker()
	more_button.pressed.connect(open_actions)
	while not fields_added_before_ready.is_empty():
		fields_container.add_child(fields_added_before_ready.pop_front())


# Helpers

func create_stylebox(inside_color: Color, border_color: Color) -> StyleBoxFlat:
	var new_stylebox := StyleBoxFlat.new()
	new_stylebox.bg_color = inside_color
	new_stylebox.border_color = border_color
	new_stylebox.set_border_width_all(2)
	new_stylebox.set_corner_radius_all(4)
	new_stylebox.content_margin_bottom = 0.5
	new_stylebox.content_margin_top = 0.5
	new_stylebox.content_margin_left = 5
	new_stylebox.content_margin_right = 5
	return new_stylebox

func setup_relative_button() -> void:
	relative_button.text = cmd_char
	relative_button.pressed.connect(toggle_relative)
	if Utils.is_string_upper(cmd_char):
		relative_button.add_theme_stylebox_override(&"normal", create_stylebox(
				Color.from_hsv(0.08, 0.8, 0.8), Color.from_hsv(0.1, 0.6, 0.9)))
		relative_button.add_theme_stylebox_override(&"hover", create_stylebox(
				Color.from_hsv(0.09, 0.75, 0.9), Color.from_hsv(0.11, 0.55, 0.95)))
		relative_button.add_theme_stylebox_override(&"pressed", create_stylebox(
				Color.from_hsv(0.11, 0.6, 1.0), Color.from_hsv(0.13, 0.4, 1.0)))
	else:
		relative_button.add_theme_stylebox_override(&"normal", create_stylebox(
				Color.from_hsv(0.8, 0.8, 0.8), Color.from_hsv(0.76, 0.6, 0.9)))
		relative_button.add_theme_stylebox_override(&"hover", create_stylebox(
				Color.from_hsv(0.78, 0.75, 0.9), Color.from_hsv(0.74, 0.55, 0.95)))
		relative_button.add_theme_stylebox_override(&"pressed", create_stylebox(
				Color.from_hsv(0.74, 0.6, 1.0), Color.from_hsv(0.7, 0.4, 1.0)))

func setup_command_picker() -> void:
	command_picker.disable_invalid(cmd_char)


func add_number_field() -> BetterLineEdit:
	var new_field := MiniNumberField.instantiate()
	safely_add_field(new_field)
	return new_field

func add_flag_field() -> Button:
	var new_field := FlagField.instantiate()
	safely_add_field(new_field)
	return new_field

func add_number_field_pair() -> Array[BetterLineEdit]:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override(&"separation", 3)
	var new_fields: Array[BetterLineEdit] =\
			[MiniNumberField.instantiate(), MiniNumberField.instantiate()]
	hbox.add_child(new_fields[0])
	hbox.add_child(new_fields[1])
	safely_add_field(hbox)
	return new_fields

func safely_add_field(field: Control) -> void:
	if fields_container == null:
		fields_added_before_ready.append(field)
	else:
		fields_container.add_child(field)

func _on_relative_button_pressed() -> void:
	cmd_char = cmd_char.to_upper() if Utils.is_string_lower(cmd_char)\
			else cmd_char.to_lower()
	setup_relative_button()

func _on_path_command_picked(new_command: String) -> void:
	cmd_insert_after.emit(cmd_idx + 1, new_command)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.ctrl_pressed:
				Interactions.toggle_inner_selection(tag_idx, cmd_idx)
			else:
				Interactions.set_inner_selection(tag_idx, cmd_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Interactions.set_inner_selection(tag_idx, cmd_idx)
			open_actions()

func determine_selection_highlight() -> void:
	var stylebox: StyleBox
	if tag_idx == Interactions.semi_selected_tag and\
	cmd_idx in Interactions.inner_selections:
		stylebox = StyleBoxFlat.new()
		stylebox.set_corner_radius_all(3)
		if Interactions.semi_hovered_tag == tag_idx and\
		Interactions.inner_hovered == cmd_idx:
			stylebox.bg_color = Color(0.7, 0.7, 1.0, 0.17)
		else:
			stylebox.bg_color = Color(0.6, 0.6, 1.0, 0.16)
	elif Interactions.semi_hovered_tag == tag_idx and\
	Interactions.inner_hovered == cmd_idx:
		stylebox = StyleBoxFlat.new()
		stylebox.set_corner_radius_all(3)
		stylebox.bg_color = Color(0.8, 0.8, 1.0, 0.05)
	else:
		stylebox = StyleBoxEmpty.new()
	stylebox.content_margin_left = 3
	stylebox.content_margin_right = 2
	stylebox.content_margin_top = 2
	stylebox.content_margin_bottom = 2
	add_theme_stylebox_override(&"panel", stylebox)


var mouse_inside := false:
	set(new_value):
		if mouse_inside != new_value:
			mouse_inside = new_value
			if mouse_inside:
				Interactions.set_inner_hovered(tag_idx, cmd_idx)
			else:
				Interactions.remove_inner_hovered(tag_idx, cmd_idx)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_inside = get_global_rect().has_point(get_global_mouse_position()) and\
		get_node(^"../../../../../../../../..").get_global_rect().\
				has_point(get_global_mouse_position())
