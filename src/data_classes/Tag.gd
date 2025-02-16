class_name Tag extends RefCounted

signal attribute_changed

var title: String
var attributes: Dictionary  # Dictionary{String: Attribute}

func _init():
	for attribute in attributes.values():
		attribute.propagate_value_changed.connect(emit_attribute_changed)

func emit_attribute_changed():
	attribute_changed.emit()
