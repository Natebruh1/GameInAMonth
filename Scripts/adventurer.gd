extends Button
class_name adventurer


var HUDref=null


@export var nameLabel:Label
@export var strLabel:Label
@export var intLabel:Label
@export var wisLabel:Label
@export var chaLabel:Label

@export var strength:int=0:
	set(val):
		if strLabel: strLabel.text = "Strength : " + str(val)
		strength=val
@export var intelligence:int=0:
	set(val):
		if intLabel: intLabel.text = "Intelligence : " + str(val)
		intelligence=val
@export var wisdom:int=0:
	set(val):
		if wisLabel: wisLabel.text = "Wisdom : " + str(val)
		wisdom=val
@export var charisma:int=0:
	set(val):
		if chaLabel: chaLabel.text = "Charisma : " + str(val)
		charisma=val
#Name
@export var adventurer_name:String="NAME":
	set(val):
		if nameLabel: nameLabel.text = val
		adventurer_name=val
@export var adventurerTexture:TextureRect
func _on_pressed():
	print("Adventurer Pressed")
	
	HUDref.move_adventurer(self)
func del():
	queue_free()


