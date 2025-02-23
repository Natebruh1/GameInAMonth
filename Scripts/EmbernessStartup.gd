extends Node

var p:Nation=null
# Called when the node enters the scene tree for the first time.
func _ready():
	
	addStartTroop.call_deferred()
	
func addStartTroop():
	p=get_parent()
	p.owned_provinces[0].BuyTroop("Treant")


