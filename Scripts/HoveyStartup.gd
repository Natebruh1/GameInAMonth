extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	setup.call_deferred()

func setup():
	var p:Nation=get_parent()
	p.owned_provinces[0].provinceMaxHealth=250.0
