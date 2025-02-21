extends Node

@export var NationColors={0:Color(0,0,0)}


var portrait_library={}
var adventurer_titles={}
var adventurer_names={}

func _ready():
	#Adventurer Portraits
	portrait_library["Human_Male"]=[preload("res://assets/Portrait1.png"),preload("res://assets/Portrait2.png"),preload("res://assets/Portrait5.png"),preload("res://assets/Portrait6.png"),preload("res://assets/Portrait8.png")]
	portrait_library["Human_Female"]=[preload("res://assets/Portrait3.png"),preload("res://assets/Portrait4.png"),preload("res://assets/Portrait7.png"),preload("res://assets/Portrait9.png")]
	

	#Adventurer Titles
	adventurer_titles["Human_Male"]=["Merchant","Prince","Lord","Admiral","General","Duke"]
	adventurer_titles["Human_Female"]=["Merchant","Princess","Lady","Admiral","General","Dame"]
	
	#Adventurer Names
	adventurer_names["Human_Male"]=["Maxis","Erda","Kyrinn","Axiun","Dororek","Adame","Goren","Omtud","Toddum","Eroxxer"]
	adventurer_names["Human_Female"]=["Arrysi","Prita","Freyja","Tahia","Usa","Opocha","Alys","Sirin","Oxi","Looce"]
