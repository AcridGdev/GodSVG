extends BetterLineEdit

enum Mode {DEFAULT, ONLY_POSITIVE, ANGLE}

var mode := Mode.DEFAULT

signal value_changed(new_value: float)
var _value: float  # Must not be updated directly.

func set_value(new_value: float, emit_value_changed := true):
	if is_nan(new_value):
		return
	var old_value := _value
	_value = validate(new_value)
	if _value != old_value and emit_value_changed:
		value_changed.emit(_value)
	
	text = String.num(_value, 4)

func get_value() -> float:
	return _value


func _ready() -> void:
	super()
	value_changed.connect(_on_value_changed)
	text = str(get_value())

func validate(new_value: float) -> float:
	match mode:
		Mode.ONLY_POSITIVE: return maxf(new_value, 0.0001)
		Mode.ANGLE: return fmod(new_value, 180.0)
		_: return new_value

func _on_value_changed(new_value: float) -> void:
	text = String.num(new_value, 4)


func _on_focus_exited() -> void:
	set_value(Utils.evaluate_numeric_expression(text))
	super()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(Utils.evaluate_numeric_expression(submitted_text))
	super(submitted_text)
