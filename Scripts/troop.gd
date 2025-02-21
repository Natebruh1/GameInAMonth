extends Node2D
class_name troop

# # # Troop Stats # # #
var maxHealth=24:
	set(val):
		var healthPercent=health/maxHealth
		maxHealth=val
		health=val*healthPercent
var health=2:
	set(val):
		health=min(val,maxHealth)
var armour=0
var baseDamageRange=[1,4]:
	get:
		return [randi_range(baseDamageRange[0],baseDamageRange[1])]
var bonusDamage=0


@export var owning_nation:Nation:
	set(val):
		if val==null:
			owning_nation.troopList.erase(self)
			owning_nation=val
		else:
			owning_nation=val
			owning_nation.troopList.append(self)
		

#How much the troop costs in upkeep
var monthlyCost=1.0:
	get:
		if inProvince.owner_id==owning_nation.id:
			return monthlyCost*owning_nation.armyStationedMultiplier
		else:
			return monthlyCost
@export var inProvince:Province:
	set(val):
		if val!=null:
			if inProvince:
				#Remove this from the old Provinces list of troops
				inProvince.beingSieged=false
				inProvince.troopList.erase(self)
			inProvince=val
			var startPoint=val.startIndex
			var endPoint=val.endIndex
			position=Vector2((val.polygon[startPoint]+val.polygon[endPoint])/2.0)
			#Add us to the new troop list in the province
			val.troopList.append(self)
			val.beingSieged=false
			
			for i in val.troopList:
				if val.owner_id!=0 and owning_nation!=Nation.Nations[val.owner_id]:
					#If this troop does not belong to the owner of the province
					val.beingSieged=true
				if i.owning_nation!=owning_nation:
					#if all troops in here are the same nation as ours
					val.beingSieged=false
					val.siegeMonths=0
					break
			
			
			#print("New Position of Troop: " + str(position))


var mouseIn=false
var troop_is_selected=false
static var troopSplitIndex=0
static var troopSplitProvince:Province
var troopName=""
var currentlySplitting=false
var moveDays=0:
	set(val):
		moveDays=val
		if moveDays==0 and movingToProvince!=null:
			actuallyMove(movingToProvince)
			movingToProvince=null
@export var movingToProvince:Province=null:
	set(val):
		if val!=null:
			var startPoint=val.startIndex
			var endPoint=val.endIndex
			position=Vector2((inProvince.polygon[inProvince.startIndex]+inProvince.polygon[inProvince.endIndex])/2.0)
			position=lerp(position,Vector2((val.polygon[startPoint]+val.polygon[endPoint])/2.0),0.3)
		movingToProvince=val


@export var TroopSprite:Sprite2D


static func Factory()->troop:
	var newTroop=preload("res://scenes/troop.tscn").instantiate()
	
	return newTroop


@export var flag:Sprite2D
@export var healthBar:Sprite2D
func _ready():
	if (flag):
		var shader_material=ShaderMaterial.new()
		var shader=preload("res://Materials/flag.gdshader")
		shader_material.set_shader(shader)
		flag.material = shader_material
	if (healthBar):
		var shader_material=ShaderMaterial.new()
		var shader=preload("res://Materials/healthMaterial.gdshader")
		shader_material.set_shader(shader)
		healthBar.material = shader_material

func _unhandled_input(event):
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			# zoom in
			if event.button_index == MOUSE_BUTTON_LEFT:
				if mouseIn:
					#print("Troop Clicked")
					if !currentlySplitting:
						troop_is_selected=true
					else:
						if troopSplitProvince!=inProvince:
							troopSplitIndex=0
							troopSplitProvince=inProvince
						for i in range(inProvince.troopList.size()):
							if i==troopSplitIndex and inProvince.troopList[i]==self:
								inProvince.troopList[i].troop_is_selected=true
								incrementChosenIndex.call_deferred()
							else:
								troop_is_selected=false
									
				else:
					#print("Troop Deselected")
					troop_is_selected=false
			if event.button_index == MOUSE_BUTTON_RIGHT and troop_is_selected:
				if owning_nation and owning_nation==Nation.Nations[GameMode.player_nation]:
					for i in Province.Provinces:
						if Province.Provinces[i].mouseIn:
							#Our mouse is hovering this province --- try move the troop
							moveToNewProvince(Province.Provinces[i])
					

func incrementChosenIndex():
	#print(str(troopSplitIndex) + " has been selected!")
	troop_is_selected=true
	troopSplitIndex+=1
	troopSplitIndex=troopSplitIndex%inProvince.troopList.size()
	#print(str(troopSplitIndex))

var lifetime=0.0
func _process(delta):
	$Panel/Label.text=troopName
	lifetime+=delta
	TroopSprite.frame=int(floor(lifetime*4.0))%(TroopSprite.hframes*TroopSprite.vframes)
	var totalScale=1.1+0.1*sin(lifetime*1.5)
	$SelectorSprite.scale=Vector2(totalScale,totalScale)
	$SelectorSprite.visible=troop_is_selected
	
	if GameMode.cameraRef.zoom.x<1.0:
		visible=false
	else:
		visible=true
	if owning_nation!=null:
		$Flag.material.set_shader_parameter("flagColour",owning_nation.NationColor)
	$Healthbar.material.set_shader_parameter("healthPercentage",float(health)/float(maxHealth))
	
	if Input.is_action_just_pressed("ViewSplitTroops"):
		#Hide the province HUD
		$TroopCountPanel.visible=true
		var totalInProvince=0
		var totalInTeam=0
		for i in inProvince.troopList:
			if i.owning_nation.id==GameMode.player_nation: totalInTeam+=1
			totalInProvince+=1
		$TroopCountPanel/TroopCountLabel.text=str(totalInTeam)+"/"+str(totalInProvince)
		currentlySplitting=true
	if Input.is_action_just_released("ViewSplitTroops"):
		currentlySplitting=false
		$TroopCountPanel.visible=false
	
	if (troopSplitProvince==inProvince):
		$TroopCountPanel/TroopIndexPanel.visible=true
		$TroopCountPanel/TroopIndexPanel/TroopIndexLabel.text=str(troopSplitIndex)
		if inProvince.troopList.size()>=troopSplitIndex:
			if inProvince.troopList[troopSplitIndex].owning_nation.id==GameMode.player_nation:
				$TroopCountPanel/TroopIndexPanel/TroopIndexLabel.modulate=Color(0, 0.29019609093666, 1)
			else:
				$TroopCountPanel/TroopIndexPanel/TroopIndexLabel.modulate=Color(0.74657118320465, 0.08975055068731, 0.19938540458679)
		
	else:
		$TroopCountPanel/TroopIndexPanel.visible=false
func moveToNewProvince(prov:Province):
	#Prevent troops from moving to ocean
	if prov.province_terrain==Province.TERRAIN.OCEAN: return
	if prov==inProvince and movingToProvince!=null:
		movingToProvince=null
		inProvince=prov
	for i in inProvince.neighbours:
		if inProvince.get_node(i)==prov:
			#Found in neighbours, move
			movingToProvince=prov
			moveDays=floor(prov.calculateTotalDevelopment()*3.0+12.0)
			break
func incrementDay():
	moveDays-=1
func actuallyMove(prov:Province):
	inProvince=prov
func _on_area_2d_mouse_entered():
	mouseIn=true
	#print("Mouse entering troop")


func _on_area_2d_mouse_exited():
	mouseIn=false
	#print("Mouse exiting troop")
