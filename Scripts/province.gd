class_name Province
extends Polygon2D

# Province Data
static var total_provinces=0
var province_id=0
static var Provinces={}

#Graphics
var default_color:Color
var offset_color:Color
var offset_seed:int
var offset_rand:RandomNumberGenerator
var offset_range:=0.1
#Game
enum PRODUCE {FISH, IRON, WHEAT, WOOD, WOOL, BONE}
var ProduceEfficiency=[1.0,1.0,1.0,1.0,1.0,1.0]
enum TERRAIN {PLAINS,HILL,DESERT,FOREST,BONEFIELD,OCEAN,MOUNTAIN}
@export_category("World")
@export var province_name:String
@export var neighbours:Array[NodePath] #Neighbouring provinces
var potentialNeighbours=[]
@export var province_terrain:TERRAIN
@export var province_produce:PRODUCE
@export var province_extra_cost:=0.0
@export_category("Nation")
@export var owner_id:=0:
	set(val):
		owner_id=val
		if val==GameMode.player_nation:
			#Set Material so we know what we are
			material=preload("res://Materials/ownedNation.tres")
		else:
			material=null

@export_category("Developments")
@export var base_wealth:int:
	set(val):
		base_wealth=val
		calculateTotalDevelopment()
		#Calculate local wealth gold
		
		localWealthInfluence=sqrt(sqrt(self.total_wealth*self.total_wealth*self.total_wealth))*0.05
		
@export var base_industry:int:
	set(val):
		base_industry=val
		calculateTotalDevelopment()
		#Calculate local industry gold
		#if owner_id!=0:
			#localIndustryGold=(1.0*self.total_industry*log(self.total_industry+1.0))*Nation.Nations[owner_id].ProduceEfficiency[self.province_produce]*self.ProduceEfficiency[self.province_produce]
			
		
@export var base_vigor:int:
	set(val):
		base_vigor=val
		calculateTotalDevelopment()
		localVigorInfluence=sqrt(sqrt(self.total_vigor*self.total_vigor*self.total_vigor))*0.05
@export var base_magic:int:
	set(val):
		base_magic=val
		calculateTotalDevelopment()
var total_wealth:float
var total_industry:float
var total_vigor:float
var total_magic:float
@export var magic_ratio:=1.0 #Effect that magic has on total development
#WIP BASE BUILDINGS#



@export_category("Graphics")
@export var startIndex=0
@onready var startPoint=polygon[startIndex]
@export var endIndex=4
@onready var endPoint=polygon[endIndex]


#Mouse Detection
var detectionArea:=Area2D.new()
var detectionShape:=CollisionPolygon2D.new()


#income
var localIndustryGold=0.0
var localWealthGold=0.0

var localVigorInfluence=0.0
var localWealthInfluence=0.0


#Event
var hasEvent=false:
	set(val):
		hasEvent=val
		displayEvent=val
var displayEvent=false

#Troops
var troopList:Array[troop]:
	set(val):
		troopList=val
		if val.size()==0:
			siegeMonths=0
			beingSieged=false
		var currentSieger=null
		for i in val:
			if currentSieger==null and i.owning_nation!=Nation.Nations[owner_id]:
				currentSieger=i.owning_nation
				beingSieged=true
			if i.owning_nation!=currentSieger and currentSieger!=null:
				#There are armies from multiple nations here
				beingSieged=false
				currentSieger=null
				break
var siegeMonths=0
var beingSieged=false
var provinceMaxHealth=80.0:
	set(val):
		provinceMaxHealth=val+calculateTotalDevelopment()
	get:
		if owner_id!=0 and Nation.Nations[owner_id].gold<0.0:
			return provinceHealth + Nation.Nations[owner_id].gold
		else:
			return provinceHealth
var provinceHealth=80.0

func _ready():
	
	#Add the collision shape and the callback
	detectionShape.polygon=polygon
	
	detectionArea.mouse_entered.connect(_mouseIn)
	detectionArea.mouse_exited.connect(_mouseOut)
	add_child(detectionArea)
	detectionArea.add_child(detectionShape)
	
	#Add this to the list of provinces
	
	province_id=total_provinces
	Provinces[province_id]=self
	
	total_provinces+=1
	
	
	
	#Set Texture Settings
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_scale=Vector2(4,4)
	if owner_id==0: default_color=color
	
	
	#Turn the province name into a random seed
	var seedArr=province_name.to_utf32_buffer().to_int32_array()
	offset_seed=0
	for i in seedArr:
		offset_seed+=i
	
	offset_rand=RandomNumberGenerator.new()
	offset_rand.seed=offset_seed
	
	offset_color=Color(offset_rand.randf_range(-offset_range,offset_range),offset_rand.randf_range(-offset_range,offset_range),offset_rand.randf_range(-offset_range,offset_range))
	
	#Update the display
	updateDisplay(Settings.mapmode)
	
	

	
func updateDisplay(mapmode):
	match mapmode:
		0:		#Political
			if (owner_id==0):
				updateToTerrain()
			else:
				color=NationGraphics.NationColors[owner_id]+offset_color
			#else update to owner colour
		1:		#Terrain
			updateToTerrain()
		2:	#Political Simple
			texture=null
			if (owner_id==0):
				color=default_color
			else:
				color=NationGraphics.NationColors[owner_id]+offset_color
		3:	#Terrain Simple
			texture=null
			color=default_color
func updateToTerrain(): #Texture the map to terrain
	color=Color(1.0,1.0,1.0,1.0)
	match province_terrain:
		TERRAIN.FOREST:
			texture=preload("res://assets/forest.jpg")
		TERRAIN.OCEAN:
			texture=preload("res://assets/ocean.png")
		TERRAIN.PLAINS:
			texture=preload("res://assets/field.jpg")
		TERRAIN.MOUNTAIN:
			texture=preload("res://assets/rock.png")
		TERRAIN.HILL:
			texture=preload("res://assets/hill.jpg")
		TERRAIN.BONEFIELD:
			texture=preload("res://assets/bonefield.jpg")

static var z_level=1.0
func _process(delta):
	if (z_level!=$"../../PlayerController".zoom_level):
		z_level=$"../../PlayerController".zoom_level
		queue_redraw()
	else:
		queue_redraw()
func _draw():
	#ThemeDB.fallback_font.draw_string(get_canvas(),Vector2(0.0,0.0),"Name")
	
	var textStartPoint=lerp(startPoint,endPoint,0.1)
	var ang=startPoint.angle_to_point(endPoint)
	draw_set_transform(textStartPoint,ang,Vector2(1.0,1.0)/z_level)
	if (startPoint.distance_to(endPoint)>3.4*24.0*(1.0/z_level)):
		#(province_name.length()*0.11)
		
		if !displayEvent:
			draw_string(ThemeDB.fallback_font,Vector2(0.0,0.0),province_name,HORIZONTAL_ALIGNMENT_FILL,max(startPoint.distance_to(endPoint)*sqrt(z_level),6.5*max(province_name.length(),8)*sqrt(z_level)),24.0)
		else:
			#(startPoint+endPoint)/2.0
			draw_texture(preload("res://assets/EventMarker.png"),((endPoint-startPoint)/2.2)*z_level)
		
	
func calculateTotalDevelopment():
	#Calculate magic bonus
	
	#Split magic into each dev
	var magicBonus=base_magic*magic_ratio
	
	#Now add it to each base dev
	total_wealth=base_wealth+magicBonus
	var x =max(self.total_wealth,1.0)
	localWealthGold=(1.0/x)+sqrt(x-1.0) - 0.8
	
	total_industry=base_industry+magicBonus
	if owner_id!=0 and Nation.Nations.size()>=owner_id:
		localIndustryGold=(0.1*self.total_industry*log(self.total_industry+1.0))
		var nat=Nation.Nations[owner_id]
		localIndustryGold=localIndustryGold*nat.ProduceEfficiency[self.province_produce]
		localIndustryGold=localIndustryGold*self.ProduceEfficiency[self.province_produce]
		
		localIndustryGold=(floor(localIndustryGold*100.0))/100.0
	
	total_vigor=base_vigor+magicBonus
	total_magic=base_magic
	return total_industry+total_magic+total_vigor+total_wealth
#---Signal Callback---#
var mouseIn=false
func _mouseIn():
	mouseIn=true
	#print("Mouse in "+province_name)
func _mouseOut():
	mouseIn=false
	#print("Mouse out "+province_name)


func getTextureForResource()->Texture:
	var texPath=""
	#Fish Iron Wood Wheat Wool Bone
	match province_produce:
		PRODUCE.FISH:
			texPath="res://assets/fish.png"
		PRODUCE.IRON:
			texPath="res://assets/Iron.png"
		PRODUCE.WOOD:
			texPath="res://assets/wood.png"
		PRODUCE.WHEAT:
			texPath="res://assets/wheat.png"
		PRODUCE.WOOL:
			texPath="res://assets/wool.png"
		PRODUCE.BONE:
			texPath="res://assets/bone.png"
	return load(texPath)


func incrementDay():
	for Troop in troopList:
		Troop.incrementDay()
		
	#Create 'teams' of troops belonging to the same nation
	var troopTeams={}
	for Troop in troopList:
		if troopTeams.has(Troop.owning_nation):
			troopTeams[Troop.owning_nation].append(Troop)
		else:
			#Create the team array
			troopTeams[Troop.owning_nation]=[Troop]
	if troopTeams.keys().size()>1:
		#multiple teams
		var teamDamage={}
		for team in troopTeams.keys():
			teamDamage[team]=0.0
			for tr in troopTeams[team]:
				teamDamage[team]+=tr.baseDamageRange[0] + tr.bonusDamage
			#Have total damage, now split between other units
			var totalOtherUnits=0
			for otherTeam in troopTeams.keys():
				if otherTeam!=team:
					totalOtherUnits+=troopTeams[otherTeam].size()
			#Split damage
			teamDamage[team]=teamDamage[team]/totalOtherUnits
			#Now deal damage
			for otherTeam in troopTeams.keys():
				if otherTeam!=team:
					for tr in troopTeams[otherTeam]:
						tr.health-= max(1,teamDamage[team]-tr.armour)
		for team in troopTeams.keys():
			for tr in troopTeams[team]:
				if tr.health<=0:
					troopList.erase(tr)
					tr.owning_nation.troopList.erase(tr)
					tr.queue_free()
		for Troop in troopList:
			#Now add attrition (reduce armor by 1)
			Troop.armour-=1
			Troop.armour=max(Troop.armour,0)
	else:
		#Heal non fighting units
		for Troop in troopList:
			Troop.health+=calculateTotalDevelopment()/4.0
			Troop.armour=Troop.maxArmour
		
		
		


func generateProvinceEvent():
	#Check event type
	
	
	
	pass



# Event rewards
func increaseProvinceVigor(x:int):
	base_vigor+=x
	if owner_id==GameMode.player_nation: GAME_HUD.LogNewMessage(str(name)+" has developed its vigor by "+str(x))
func increaseProvinceMagic(x:int):
	base_magic+=x
	if owner_id==GameMode.player_nation: GAME_HUD.LogNewMessage(str(name)+" has developed its magic by "+str(x))
func increaseProvinceIndustry(x:int):
	base_industry+=x
	if owner_id==GameMode.player_nation: GAME_HUD.LogNewMessage(str(name)+" has developed its industry by "+str(x))
func increaseProvinceWealth(x:int):
	base_wealth+=x
	if owner_id==GameMode.player_nation: GAME_HUD.LogNewMessage(str(name)+" has developed its wealth by "+str(x))

func increaseProvinceWoodProduceEfficiency(x:float):
	ProduceEfficiency[3]+=x
	if owner_id==GameMode.player_nation: GAME_HUD.LogNewMessage(str(name)+" has increased it's production efficiency for wood by "+str(x))
func changeProvinceProduce(x):
	if owner_id==GameMode.player_nation: GAME_HUD.LogNewMessage(str(name)+" has changed its produce to "+str(PRODUCE.keys()[x]))
	province_produce=x

func slayDragon(x:int):
	#1 in 8 chance to capture the dragon instead
	GAME_HUD.LogNewMessage(str(Nation.Nations[owner_id])+" has captured a dragon in "+str(province_name))
	BuyTroop("Dragon")

# # # Troops # # #
func BuyTroop(template:String):
	
	var nat:Nation=Nation.Nations[owner_id]
	
	var specialT=template
	var cost =0.0
	match template:
		"Infantry":
			cost=nat.infantryBaseCost
			if nat.id==5: #Troll nation
				specialT="Troll"
			if nat.id==7 or nat.id==9:
				cost=nat.infantryBaseCost*1.5
				specialT="Orc"
		"Artillery":
			cost=nat.artilleryBaseCost
		"Dragon":
			cost=0.0
		"Orc":
			cost=0.0
		"Troll":
			cost=0.0
		"Cavalry":
			cost=nat.cavalryBaseCost
	if nat.gold>=cost:
		nat.gold-=cost
		var newTroop=troop.Factory()
		match specialT:
			"Infantry":
				newTroop.monthlyCost=nat.infantryBaseUpkeep
				newTroop.baseDamageRange=nat.infantryBaseDamage
				newTroop.bonusDamage=nat.troopBonusDamage+nat.infantryBonusDamage
				newTroop.maxHealth=nat.infantryBaseMaxHealth
				#DOn't set current health so that the troop regenerates some health
				newTroop.armour=nat.infantryBaseArmour
				newTroop.maxArmour=nat.infantryBaseArmour
				#Set Owner and Province
				newTroop.owning_nation=nat
				newTroop.inProvince=self
				#Set Texture and Scale
				newTroop.troopName="Infantry"
				newTroop.TroopSprite.texture=preload("res://assets/knight.png")
				newTroop.TroopSprite.scale=Vector2(1.0,1.0)
				get_parent().get_parent().get_node("Troops").add_child(newTroop)
			"Artillery":
				newTroop.monthlyCost=nat.artilleryBaseUpkeep
				newTroop.baseDamageRange=nat.artilleryBaseDamage
				newTroop.bonusDamage=nat.troopBonusDamage+nat.artilleryBonusDamage
				newTroop.maxHealth=nat.artilleryBaseMaxHealth
				#DOn't set current health so that the troop regenerates some health
				newTroop.armour=nat.artilleryBaseArmour
				newTroop.maxArmour=nat.artilleryBaseArmour
				#Set Owner and Province
				newTroop.owning_nation=nat
				newTroop.inProvince=self
				#Set Texture and Scale
				newTroop.troopName="Artillery"
				newTroop.TroopSprite.texture=preload("res://assets/artillery.png")
				newTroop.TroopSprite.scale=Vector2(0.5,0.5)
				get_parent().get_parent().get_node("Troops").add_child(newTroop)
			"Cavalry":
				newTroop.monthlyCost=nat.cavalryBaseUpkeep
				newTroop.baseDamageRange=nat.cavalryBaseDamage
				newTroop.bonusDamage=nat.troopBonusDamage+nat.cavalryBonusDamage
				newTroop.maxHealth=nat.cavalryBaseMaxHealth
				#DOn't set current health so that the troop regenerates some health
				newTroop.armour=nat.cavalryBaseArmour
				newTroop.maxArmour=nat.cavalryBaseArmour
				#Set Owner and Province
				newTroop.owning_nation=nat
				newTroop.inProvince=self
				#Set Texture and Scale
				newTroop.troopName="Cavalry"
				newTroop.TroopSprite.texture=preload("res://assets/cavalry.png")
				newTroop.TroopSprite.hframes=9
				newTroop.TroopSprite.scale=Vector2(0.5,0.5)
				get_parent().get_parent().get_node("Troops").add_child(newTroop)
			"Dragon": #A special troop, available only via events
				newTroop.monthlyCost=50.0
				newTroop.baseDamageRange=[8,24]
				newTroop.bonusDamage=0
				newTroop.maxHealth=120
				newTroop.armour=10.0
				newTroop.maxArmour=10.0
				#Set Owner and Province
				newTroop.owning_nation=nat
				newTroop.inProvince=self
				#Set Texture and Scale
				newTroop.troopName="Dragon"
				newTroop.TroopSprite.texture=preload("res://assets/flying_dragon-gold.png")
				newTroop.TroopSprite.hframes=6
				newTroop.TroopSprite.scale=Vector2(0.8,0.8)
				get_parent().get_parent().get_node("Troops").add_child(newTroop)
			"Orc": #A special troop, available only via events
				newTroop.monthlyCost=1.8
				newTroop.baseDamageRange=[1,6]
				
				newTroop.maxHealth=24
				newTroop.armour=4.0
				newTroop.maxArmour=4.0
				
				newTroop.bonusDamage=0
				#Set Owner and Province
				newTroop.owning_nation=nat
				newTroop.inProvince=self
				#Set Texture and Scale
				newTroop.troopName="Orc"
				newTroop.TroopSprite.texture=preload("res://assets/orc1_idle.png")
				newTroop.TroopSprite.hframes=4
				newTroop.TroopSprite.scale=Vector2(0.8,0.8)
				get_parent().get_parent().get_node("Troops").add_child(newTroop)
			"Troll": #Troll's are available to troll nations and from events
				newTroop.monthlyCost=nat.infantryBaseUpkeep
				newTroop.baseDamageRange=nat.infantryBaseDamage
				
				newTroop.maxHealth=nat.infantryBaseMaxHealth-4.0
				newTroop.armour=nat.infantryBaseArmour
				newTroop.maxArmour=nat.infantryBaseArmour
				
				newTroop.bonusDamage=nat.infantryBonusDamage
				#Set Owner and Province
				newTroop.owning_nation=nat
				newTroop.inProvince=self
				#Set Texture and Scale
				newTroop.troopName="Troll"
				newTroop.TroopSprite.texture=preload("res://assets/troll.png")
				
				newTroop.TroopSprite.scale=Vector2(0.6,0.6)
				get_parent().get_parent().get_node("Troops").add_child(newTroop)
