extends Node
class_name GameMode
@export var chosen_nation:=1
static var player_nation:=1

@export var HUD:Node

@export var DateTimer:Timer
var speeds=[1.5,0.5,0.25,0.05]
var currentSpeedIndex=0:
	set(val):
		currentSpeedIndex=clampi(val,0,speeds.size()-1)
		currentSpeedIndex=currentSpeedIndex%speeds.size() #Make sure there's no out of bounds
		DateTimer.wait_time=speeds[currentSpeedIndex] #Set the timer speed
		
#Day
static var day:=0:
	set(val):
		day=val%31
		if day==0:
			month+=1
		
		
		
#Month
static var month:=0:
	set(val):
		month=val%12
		for nation in Nation.Nations.values():
			nation.monthUpdate()
		EventController.monthUpdate()
		if month==0:
			year+=1
		print("----MONTH COMPLETE----")
		
#Year
static var year:=1444
static var this:GameMode
func _ready():
	this=self
	player_nation=Settings.startingPlayer
	DateTimer.timeout.connect(incrementDay)
	HUD.playerNation=player_nation
	Settings.game_gamemode=self
	
var paused=true

#Add 1 day to the date
func incrementDay():
	if (!paused):
		day+=1
		HUD.date=[day,month,year]
		for i in Nation.Nations.values():
			i.incrementDay()
		for i in Province.Provinces.values():
			i.incrementDay()
	
func _process(delta):
	paused=HUD.paused
	if (!paused and DateTimer.is_stopped()):
		DateTimer.start()
	if Input.is_action_just_pressed("IncreaseDateSpeed"):
		currentSpeedIndex+=1
		
	if Input.is_action_just_pressed("DecreaseDateSpeed"):
		currentSpeedIndex-=1


static var cameraRef:Camera2D		
func _getHUD()->Node:
	return HUD
