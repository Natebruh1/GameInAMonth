extends CanvasLayer
class_name GAME_HUD


@export_category("Nations")
@export var nationNameNode:Label
@export var totalGoldNode:Label

var nationDisplayName="Name"
var totalGold=0.0
var goldLastMonth=0.0
var playerNation:int
@export var totalInfluenceNode:Label
var totalInfluence=0.0
var influenceLastMonth=0.0

#Nation Points
@export var nationAdmin:Label
@export var nationDiplo:Label
@export var nationMilit:Label
@export var nationMana:Label



#Provinces
var targetedID=0
var targetedProvince:Province:
	get:
		return targetedProvince
	set(prov):
		var validNeighbour = false
		for i in prov.neighbours:
			var p = prov.get_node(i)
			if Nation.Nations[GameMode.player_nation].owned_provinces.has(p):
				validNeighbour = true
		if !validNeighbour or prov.province_terrain==Province.TERRAIN.OCEAN:
			colonizeButton.disabled=true #Disable the colonize button for all non neighbours and ocean
		else:
			colonizeButton.disabled=false
		
		
		targetedProvince=prov
var provinceHUD_visible=false
@export_category("Province")
@export var provinceNameNode:Label

@export var localWealthNode:Label
@export var localIndustryNode:Label
@export var localVigorNode:Label
@export var localMagicNode:Label


@export var localWealthButton:Button
@export var localIndustryButton:Button
@export var localVigorButton:Button
@export var localMagicButton:Button

#colonize
@export var colonyNameNode:Label
@export var colonizeButton:Button

#Province Terrain
@export var terrainName:Label
@export var terrainTex:TextureRect
	#and colony
@export var colonyTerrainName:Label
@export var colonyTerrainTex:TextureRect

#Province Produce
@export var produceName:Label
@export var produceTex:TextureRect

@export var industryProduceGoldLabel:Label
@export var wealthProduceGoldLabel:Label
@export var totalProduceGoldLabel:Label

@export var vigorProduceInfluenceLabel:Label
@export var wealthProduceInfluenceLabel:Label
@export var totalProduceInfluenceLabel:Label

#Events
@export var provinceNameEventNode:Label
@export var eventNameNode:Label
@export var eventDescNode:Label
@export var eventButtonNode:Button

@export var loadupLogLabels:Array[Label]=[]
static var LogLabels:Array[Label]=[]

#HUD
@export var tabControl:TabContainer


@export_category("Date")
@export var dateLabel:Label
var date=[0,0,1444]
var paused=true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	nationNameNode.text=nationDisplayName
	totalGoldNode.text=str(totalGold)
	totalGoldNode.tooltip_text="Gold last month : " + str(goldLastMonth)
	
	totalInfluenceNode.text=str(totalInfluence)
	totalInfluenceNode.tooltip_text="Influence last month : " + str(influenceLastMonth)
	
	#Update Date
	
	var monthName=""
	#Get month name
	match date[1]:
		0:
			monthName="Gena"
		1:
			monthName="Hares"
		2:
			monthName="Mare"
		3:
			monthName="Apra"
		4:
			monthName="Hennes"
		5:
			monthName="Epilte"
		6:
			monthName="Charilte"
		7:
			monthName="Aman"
		8:
			monthName="Veik"
		9:
			monthName="Oura"
		10:
			monthName="Luca"
		11:
			monthName="Annen"
	dateLabel.text=str(date[0]+1)+", "+monthName+"("+str(date[1]+1)+"), "+str(date[2])
	
	if playerNation!=0:
		nationAdmin.text=str(Nation.Nations[playerNation].adminPoints)
		nationDiplo.text=str(Nation.Nations[playerNation].diplomacyPoints)
		nationMilit.text=str(Nation.Nations[playerNation].militaryPoints)
		nationMana.text=str(Nation.Nations[playerNation].manaPoints)
	
	
	if (Province.Provinces.has(targetedID)):
		$Frame/ProvincePanel.visible=provinceHUD_visible #Make invisible
		
		targetedProvince=Province.Provinces[targetedID]
		
		#If it's a colonize province
		if tabControl.current_tab <=1:
			if targetedProvince.owner_id==0:
				tabControl.current_tab=1
			else:
				tabControl.current_tab=0
		if !targetedProvince.hasEvent:
			if targetedProvince.owner_id==0:
				tabControl.current_tab=1
			else:
				tabControl.current_tab=0
		#Update HUD Province Name
		provinceNameNode.text=targetedProvince.province_name
			#and for colonize screen
		colonyNameNode.text=targetedProvince.province_name
			#amd for event tab
		provinceNameEventNode.text=targetedProvince.province_name
		
		# Update Event information
		if targetedProvince.hasEvent:
			var e:Event
			for eve in Nation.Nations[GameMode.player_nation].eventProvinces.keys():
				if Nation.Nations[GameMode.player_nation].eventProvinces[eve]==targetedProvince and eve!=null:
					e=eve
			#if (Nation.Nations[GameMode.player_nation].eventProvinces.find_key(targetedProvince))!=null:
				#var a= Nation.Nations[GameMode.player_nation].eventProvinces.find_key(targetedProvince)
				#if a!=null: e=a
			#var eProvinces=Nation.Nations[GameMode.player_nation].eventProvinces.values()
			#for i in range(eProvinces.size()):
				#if eProvinces[i]==targetedProvince:
					#if (Nation.Nations[GameMode.player_nation].eventProvinces.keys()[i]!=null):
						#e=Nation.Nations[GameMode.player_nation].eventProvinces.keys()[i]
			if e:
				eventNameNode.text = e.event_name
				eventDescNode.text=e.event_description
				eventButtonNode.text=e.event_button
				eventButtonNode.disabled=e.eventBeingExplored
				eventButtonNode.tooltip_text="Strength : "+str(e.total_strength)+", Intelligence : "+str(e.total_intelligence)+", Wisdom : " +str(e.total_wisdom)+", Charisma : " +str(e.total_charisma)
			else:
				targetedProvince.displayEvent=false
		
		#Update Local Development
		localWealthNode.text="Wealth : "+str((floor(targetedProvince.total_wealth*10.0))/10.0)
		localIndustryNode.text="Industry : "+str((floor(targetedProvince.total_industry*10.0))/10.0)
		localVigorNode.text="Vigor : "+str((floor(targetedProvince.total_vigor*10.0))/10.0)
		localMagicNode.text="Magic : "+str((floor(targetedProvince.total_magic*10.0))/10.0)
		
		#Grey out buttons if need be
		if targetedProvince.owner_id!=GameMode.player_nation:
			localWealthButton.disabled=true
			localIndustryButton.disabled=true
			localVigorButton.disabled=true
			localMagicButton.disabled=true
		else:
			localWealthButton.disabled=false
			localIndustryButton.disabled=false
			localVigorButton.disabled=false
			localMagicButton.disabled=false
			
			localWealthButton.tooltip_text=str("Improving Wealth here costs ")+str(Nation.Nations[targetedProvince.owner_id].calcImproveProvince(targetedProvince,0))
			localIndustryButton.tooltip_text=str("Improving Industry here costs ")+str(Nation.Nations[targetedProvince.owner_id].calcImproveProvince(targetedProvince,1))
			localVigorButton.tooltip_text=str("Improving Vigor here costs ")+str(Nation.Nations[targetedProvince.owner_id].calcImproveProvince(targetedProvince,2))
			localMagicButton.tooltip_text=str("Improving Magic here costs ")+str(Nation.Nations[targetedProvince.owner_id].calcImproveProvince(targetedProvince,3))
		
		
		#Update terrain icons and name
		terrainName.text=str(Province.TERRAIN.keys()[targetedProvince.province_terrain])
		colonyTerrainName.text=str(Province.TERRAIN.keys()[targetedProvince.province_terrain])
		match targetedProvince.province_terrain:
			Province.TERRAIN.FOREST:
				terrainTex.texture=preload("res://assets/forest.jpg")
				colonyTerrainTex.texture=preload("res://assets/forest.jpg")
			Province.TERRAIN.OCEAN:
				terrainTex.texture=preload("res://assets/ocean.png")
				colonyTerrainTex.texture=preload("res://assets/ocean.png")
			Province.TERRAIN.PLAINS:
				terrainTex.texture=preload("res://assets/field.jpg")
				colonyTerrainTex.texture=preload("res://assets/field.jpg")
			Province.TERRAIN.MOUNTAIN:
				terrainTex.texture=preload("res://assets/rock.png")
				colonyTerrainTex.texture=preload("res://assets/rock.png")
			
		#Update Produce icons and name
		produceName.text=str(Province.PRODUCE.keys()[targetedProvince.province_produce])
		produceTex.texture=targetedProvince.getTextureForResource()
			#Monthly gold income
		industryProduceGoldLabel.text=str("Industry Gold : "+ str(floor(targetedProvince.localIndustryGold*100.0)/100.0))
		wealthProduceGoldLabel.text=str("Wealth Gold : "+str(floor(targetedProvince.localWealthGold*100.0)/100.0))
			#Monthly Wealth Influence
		vigorProduceInfluenceLabel.text=str("Vigor Influence : "+ str(floor(targetedProvince.localVigorInfluence*100.0)/100.0))
		wealthProduceInfluenceLabel.text=str("Wealth Influence : "+ str(floor(targetedProvince.localWealthInfluence*100.0)/100.0))
			#Total per province
		totalProduceGoldLabel.text=str("Total Gold : "+ str((floor(targetedProvince.localWealthGold*100.0)/100.0)+(floor(targetedProvince.localIndustryGold*100.0)/100.0)))
		totalProduceInfluenceLabel.text=str("Total Influence : "+ str((floor(targetedProvince.localWealthInfluence*100.0)/100.0)+(floor(targetedProvince.localVigorInfluence*100.0)/100.0)))
		
		#Update Colony influence cost
		if targetedProvince.owner_id==0 && playerNation!=0:
			colonizeButton.text= "Colonize : " + str(Nation.Nations[playerNation].calcProvinceCost(targetedProvince))
func _on_increase_wealth_button_pressed():
	print("Trying to increase wealth")
	Nation.Nations[playerNation].improveProvince(targetedProvince,0)
	


func _on_increase_industry_button_pressed():
	print("Trying to increase industry")
	Nation.Nations[playerNation].improveProvince(targetedProvince,1)



func _on_increase_vigor_button_pressed():
	print("Trying to increase vigor")
	Nation.Nations[playerNation].improveProvince(targetedProvince,2)

func _on_increase_magic_button_pressed():
	print("Trying to increase magic")
	Nation.Nations[playerNation].improveProvince(targetedProvince,3)

func _on_play_button_pressed():
	paused=!paused
	print("Paused : "+str(paused))
	


func _on_colonize_button_pressed():
	Nation.Nations[playerNation].buyProvince(targetedProvince)
		

@export_category("Adventurer")
@export var JobTabs:TabContainer
@export var adventurerPool:HBoxContainer
#Different Jobs
@export var advisorPool:HBoxContainer
@export var explorerPool:HBoxContainer

#ONLY THE PLAYER CAN CALL THIS - NEED TO ADD AI ADVENTURER SWAPPING
func move_adventurer(adv:adventurer):
	var currentTab=JobTabs.current_tab
	var playerNat=Nation.Nations[playerNation]
	if playerNat.adventurerPool.has(adv):
		adventurerPool.remove_child(adv)
		playerNat.adventurerPool.erase(adv)
		match currentTab:
			0:	#Advisors
				advisorPool.add_child(adv)
				playerNat.advisorPool.append(adv)
			1:	#Explorers
				explorerPool.add_child(adv)
				playerNat.explorerPool.append(adv)
	else:	#If we're instead moving adventurer into storage
		match currentTab:
			0:	#Advisors
				advisorPool.remove_child(adv)
				playerNat.advisorPool.erase(adv)
			1:	#Explorers
				explorerPool.remove_child(adv)
				playerNat.explorerPool.erase(adv)
		#Remove it from nation adventurerPool
		playerNat.adventurerPool.append(adv)
		adventurerPool.add_child(adv)
func add_adventurer(adv:adventurer):
	#call_deferred("add_child",adventurerPool,adv)
	adventurerPool.add_child(adv)
	adv.HUDref=self
	
		
	


func _on_run_event_button_pressed():
	print("Trying to start event")
	Nation.Nations[GameMode.player_nation].startCompletingEvent(targetedProvince)



func _ready():
	LogLabels=loadupLogLabels
static func LogNewMessage(s:String):
	if LogLabels:
		var prevMessage=s
		for i in range(10):
			var tempCopy=LogLabels[i].text
			LogLabels[i].text = prevMessage
			LogLabels[i].tooltip_text= prevMessage
			prevMessage=tempCopy
				
				
