extends CanvasLayer


onready var DiveBombForceLabel: Label = $MarginContainer/HBoxContainer/VBoxContainer/DiveBombForce
onready var DiveBombForceSlider: Slider = $MarginContainer/HBoxContainer/VBoxContainer/HSlider

func _on_Bird_divebombforce_updated(force):
	DiveBombForceLabel.text = "Dive Bomb Force: %s" % force
	DiveBombForceSlider.value = force

