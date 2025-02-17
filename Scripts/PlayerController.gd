extends Node2D
static var provFont:Font


#Player Controls
var dragStartMousePos=Vector2.ZERO
var dragStartCameraPos=Vector2.ZERO
var isDragging:= false




@export var player_nation:=1

#---HUD Variables---#
@export var HUD:CanvasLayer
#---Camera Variables---#
var zoom_pos:=Vector2(0.0,0.0)
@export var cam:Camera2D
var zoom_level=1.0
const zoom_speed=20.0
var target_zoom=1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Update Camera
	zoom_level=lerp(zoom_level,target_zoom,5.0*delta)
	
	#zoom_level = min(zoom_level,target_zoom)
	cam.zoom.x=zoom_level
	cam.zoom.y=zoom_level
	
	ClickAndDrag()
	
	#Update HUD
		#Update Name
	HUD.nationDisplayName=Nation.Nations[GameMode.player_nation].nation_name
		#Update Total Gold
	HUD.totalGold=Nation.Nations[GameMode.player_nation].gold
		#Update Gold Last Month
	HUD.goldLastMonth=Nation.Nations[GameMode.player_nation].goldIncomeLastMonth
		#Update Total Influence
	HUD.totalInfluence=Nation.Nations[GameMode.player_nation].influence
		#Update Influence Last Month
	HUD.influenceLastMonth=Nation.Nations[GameMode.player_nation].influenceIncomeLastMonth
		
		
		#---#
		#Hide Province if escape pressed
	if Input.is_action_just_pressed("EscapeProvinceHUD"):
		#Hide the province HUD
		HUD.provinceHUD_visible=false
	if Input.is_action_just_pressed("ChangeMapmode"):
		Settings.mapmode+=1
		Settings.mapmode=Settings.mapmode % Settings.maxMapmodes
		for prov in Province.Provinces.values():
			prov.updateDisplay(Settings.mapmode)
#func _input(event):
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		zoom_pos = get_global_mouse_position()
	if event is InputEventMouseButton:
		if event.is_pressed():
			# zoom in
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				
				# call the zoom function
				zoom(zoom_pos,zoom_speed*1.5)
				
			# zoom out
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				
				# call the zoom function
				zoom(zoom_pos,-zoom_speed)
			#Check if we're clicking province
			if event.button_index == MOUSE_BUTTON_LEFT:
				for prov in Province.Provinces.values():
					if prov.mouseIn==true:
						
						HUD.targetedID=prov.province_id #Update the targeted ID to that of the province
						HUD.provinceHUD_visible=true
						HUD.tabControl.current_tab=0
			if event.button_index == MOUSE_BUTTON_RIGHT:
				for prov in Province.Provinces.values():
					if prov.mouseIn==true:
						
						HUD.targetedID=prov.province_id #Update the targeted ID to that of the province
						HUD.provinceHUD_visible=true
						if prov.hasEvent:
							HUD.tabControl.current_tab=2
func zoom(zoomPos,dir):
	var d=get_process_delta_time()
	zoom_level=clamp(zoom_level,0.8,4.0)
	target_zoom+=dir*d
	target_zoom=clamp(target_zoom,0.8,4.0)
	if (dir>0.0) && target_zoom<4.0:
		cam.global_position=lerp(cam.global_position,zoom_pos,(dir/10.0)*d)


func ClickAndDrag():
	if !isDragging and Input.is_action_just_pressed("camera_pan"):
		dragStartMousePos=get_viewport().get_mouse_position()
		dragStartCameraPos=cam.position
		isDragging=true
	if isDragging and Input.is_action_just_released("camera_pan"):
		isDragging=false
	if isDragging:
		var moveVector=get_viewport().get_mouse_position()-dragStartMousePos
		cam.position=dragStartCameraPos-moveVector* 1/cam.zoom.x
