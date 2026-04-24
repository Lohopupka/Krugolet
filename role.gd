extends Control

@onready var role_student: CheckBox = $role_student
@onready var role_teacher: CheckBox = $role_teacher
@onready var role_parent: CheckBox = $role_parent
@onready var start_button: Button = $start_button

func _ready() -> void:
	start_button.disabled = true

	var group = ButtonGroup.new()
	group.allow_unpress = false 
	
	role_student.button_group = group
	role_teacher.button_group = group
	role_parent.button_group = group
	role_student.toggled.connect(_on_any_role_toggled)
	role_teacher.toggled.connect(_on_any_role_toggled)
	role_parent.toggled.connect(_on_any_role_toggled)

func _on_any_role_toggled(button_pressed: bool) -> void:
	if button_pressed:
		start_button.disabled = false
	else:
		if not role_student.button_pressed and not role_teacher.button_pressed and not role_parent.button_pressed:
			start_button.disabled = true

func _on_start_button_pressed() -> void:
	var selected_role: String = ""
	if role_student.button_pressed:
		selected_role = "student"
		get_tree().change_scene_to_file("res://1calendar.tscn")
	elif role_teacher.button_pressed:
		selected_role = "teacher"
		get_tree().change_scene_to_file("res://2calendar.tscn")
	elif role_parent.button_pressed:
		selected_role = "parent"
		get_tree().change_scene_to_file("res://1calendar.tscn")
	print(selected_role)
