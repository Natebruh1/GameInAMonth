extends Node
class_name Nation
static var totalNations=0
static var Nations={} # Key [int], Value [Nation]

@onready var id:int
@export_category("Graphics")
@export var NationColor:=Color(1.0,1.0,1.0,1.0)
@export var nation_name:String

@export_category("Stats")
#Certain Nations might have certain starting gold
@export var gold:=0.0
var goldIncomeLastMonth=0.0
#Certain Nations might have certain starting influence
@export var influence:=0.0
var influenceIncomeLastMonth=0.0

#Points which can be spent on improving provinces
@export var adminPoints:=0:
	set(val):
		var trueVal=val
		trueVal=max(trueVal,0)
		trueVal=min(trueVal,1000)
		adminPoints=trueVal
@export var diplomacyPoints:=0:
	set(val):
		var trueVal=val
		trueVal=max(trueVal,0)
		trueVal=min(trueVal,1000)
		diplomacyPoints=trueVal
@export var militaryPoints:=0:
	set(val):
		var trueVal=val
		trueVal=max(trueVal,0)
		trueVal=min(trueVal,1000)
		militaryPoints=trueVal
@export var manaPoints:=0:
	set(val):
		var trueVal=val
		trueVal=max(trueVal,0)
		trueVal=min(trueVal,1000)
		manaPoints=trueVal

#Magic Ratio, increases the effectiveness that Magic has on improving a province
@export var magic_ratio:=0.15

@export_category("Missions")

@export_category("Provinces")
@export var owned_provinces:Array[Province]
#Produce Efficiency
#PLAINS,HILL,DESERT,FOREST,BONEFIELD,OCEAN,MOUNTAIN
@export var ProduceEfficiency=[1.0,1.0,1.0,1.0,1.0,1.0]

func totalProvinceDevelopment()->int:
	var total=0
	for i in owned_provinces:
		total+=i.base_industry+i.base_magic+i.base_vigor+i.base_wealth
	return total

@export_category("Adventurers")
@export var startingAdventurers:Array[adventurer]
var adventurerPool:Array[adventurer]
var advisorPool:Array[adventurer]
var explorerPool:Array[adventurer]:
	set(val):
		explorerPool=val
		total_strength=0
		total_intelligence=0
		total_wisdom=0
		total_charisma=0
		for i in val:
			total_strength+=i.strength
			total_intelligence+=i.intelligence
			total_wisdom+=i.wisdom
			total_charisma+=i.charisma
@export var national_adventurer_bonus:=0
@export var national_strength_modifier:=0
@export var national_wisdom_modifier:=0
@export var national_intelligence_modifier:=0
@export var national_charisma_modifier:=0


@export_category("Events")
var events=[]
var eventProvinces={}
var currentlyActiveEvents=[]


var total_strength=0
var total_intelligence=0
var total_wisdom=0
var total_charisma=0



func _ready():
	totalNations+=1
	id=totalNations
	#Add us to the list of known nations
	Nations[id]=self
	
	NationGraphics.NationColors[id] = NationColor
	for prov in owned_provinces:
		
		prov.owner_id=id #Change province owner to us
		prov.default_color=prov.color
		prov.updateDisplay(Settings.mapmode)
	
	
	for i in startingAdventurers:
		var fac=preload("res://scenes/adventurer.tscn")
		var adv=fac.instantiate()
		
		adv.strength=i.strength
		adv.intelligence=i.intelligence
		adv.wisdom=i.wisdom
		adv.charisma=i.charisma
		adv.adventurer_name=i.adventurer_name
		adventurerPool.append(adv)
		if GameMode.player_nation==id:
			Settings.game_gamemode.HUD.add_adventurer(adv) #Add starting adventurers to the HUD
		i.queue_free()
		
	startingAdventurers.clear()
	
	#WIP REMOVE AUTO UPDATE ON READY
	monthUpdate()
	

var withIncomeLogging:bool=false
func monthUpdate():
	#Income
	var totalGoldIncome=0.0
	var totalInfluenceIncome=0.0
	
	var productionIncome=0.0
	var wealthGoldIncome=0.0
	var wealthInfluenceIncome=0.0
	var armyReductionPercentage=0.0
	var vigorInfluenceIncome=0.0
	for i in owned_provinces:
		i.magic_ratio=magic_ratio #Update the magic ratio to the nations magic ratio
		i.calculateTotalDevelopment()
		
		#Production Income [Gold]
		# 0.1*prov[industry]*ln(prov[industry]+1)*nation[ProvinceEfficiency]*prov[ProvinceEfficiency]
		productionIncome+=i.localIndustryGold
		#(0.1*i.total_industry*log(i.total_industry+1.0))*ProduceEfficiency[i.province_produce]*i.ProduceEfficiency[i.province_produce]
		
		#Wealth Income [Gold/Influence]
		#var x =max(i.total_wealth,1.0)
		#wealthGoldIncome+=(1.0/x)+sqrt(x-1.0) - 0.8
		wealthGoldIncome+=i.localWealthGold
		wealthInfluenceIncome+=sqrt(sqrt(i.total_wealth*i.total_wealth*i.total_wealth))
		
		#Vigor Income [Influence/Army Reduction]
		armyReductionPercentage+=(1+(i.total_vigor/(log(i.total_vigor)-100)))
		vigorInfluenceIncome+=sqrt(sqrt(i.total_vigor*i.total_vigor*i.total_vigor))
		
		
	armyReductionPercentage=armyReductionPercentage/owned_provinces.size()
	
	totalGoldIncome=wealthGoldIncome+productionIncome
	#goldIncomeLastMonth=totalGoldIncome
	
	totalInfluenceIncome=(wealthInfluenceIncome+vigorInfluenceIncome)*0.05
	#influenceIncomeLastMonth=totalInfluenceIncome
	if (withIncomeLogging):
		print("Industry Gold : "+str(productionIncome)+" || Wealth Gold : "+str(wealthGoldIncome))
		print("Total Gold : "+str(totalGoldIncome))
		
		print("Wealth Influence : "+str(wealthInfluenceIncome)+ "|| Vigor Influence : "+str(vigorInfluenceIncome))
		print("Total Influence : "+str(totalInfluenceIncome))
	
	#Mana points
	adminPoints+=1
	diplomacyPoints+=1
	militaryPoints+=1
	manaPoints+=1
	
	#Advisor Point income
	var adminIncome=0
	var diploIncome=0
	var militaryIncome=0
	var manaIncome=0
	for advisor in advisorPool:
		#Average 2 stats (rounded down)
		adminIncome+=floor((advisor.charisma+advisor.intelligence)/2.0)
		diploIncome+=floor((advisor.charisma+advisor.strength)/2.0)
		militaryIncome+=floor((advisor.strength+advisor.wisdom)/2.0)
		manaIncome+=floor((advisor.wisdom+advisor.intelligence)/2.0)
	adminPoints+=adminIncome
	diplomacyPoints+=diploIncome
	militaryPoints+=militaryIncome
	manaPoints+=manaIncome
	
	#Outcome
		#Adventurer Costs
	var advisorCost=(advisorPool.size()+1)*advisorPool.size()*(Settings.game_gamemode.year/8000.0)
	var explorerCost=(explorerPool.size()-0.25)*explorerPool.size()*(Settings.game_gamemode.year/8000.0)
	print("Advisor Size :"+str(advisorPool.size()))
	totalInfluenceIncome-=advisorCost
	totalInfluenceIncome-=explorerCost
		#Army Costs
		
		#Building Costs
	
	#Attracted any Adventurers
	var freq=7.0
	var x=adventurerPool.size()+advisorPool.size()+explorerPool.size()
	#var requiredInfluence=pow(log(x+32),x)
	var requiredInfluence=log(x*freq)
	requiredInfluence+=(sin(x*freq)-sin(x*freq*2.0)+sin(x*freq*3.0))
	requiredInfluence=requiredInfluence*log(x*freq)*2.5
	if (influence+totalInfluenceIncome>requiredInfluence):
		#Attract Adventurer to nation
		add_adventurer() #Create a default random adventurer
	#Add events to this month
	
		#AI events
	
	
	#Update Total Gold and Influence
	influence+=totalInfluenceIncome
	if influence<0.0: #We can't have negative influence but it will drain finances
		totalGoldIncome+=influence
		influence=0.0
	gold+=totalGoldIncome
		#Round them
		
		
		
	influence = influence * 100.0
	influence = floor(influence)
	influence = influence / 100.0
	
	influenceIncomeLastMonth=totalInfluenceIncome
	influenceIncomeLastMonth = influenceIncomeLastMonth * 100.0
	influenceIncomeLastMonth = floor(influenceIncomeLastMonth)
	influenceIncomeLastMonth = influenceIncomeLastMonth / 100.0
	
	
	gold = gold * 100.0
	gold = floor(gold)
	gold = gold / 100.0
	
	goldIncomeLastMonth=totalGoldIncome
	goldIncomeLastMonth = goldIncomeLastMonth * 100.0
	goldIncomeLastMonth = floor(goldIncomeLastMonth)
	goldIncomeLastMonth = goldIncomeLastMonth / 100.0
	
	
	# # # Remove Unworked events # # #
	
	for i in events:
		if !(currentlyActiveEvents.has(i)):
			#We're not a currently active event so remove
			eventProvinces[i].hasEvent=false
			i.queue_free()
	
	
func buyProvince(prov:Province):
	var cost=calcProvinceCost(prov)
	#Deduct Influence
	if influence>=cost:
		print("Buying Province")
		influence-=cost
	
		#Add province
		owned_provinces.append(prov)
		prov.owner_id=id
		prov.updateDisplay(Settings.mapmode)
		
func improveProvince(prov:Province, improvementType:int):
	var cost=calcImproveProvince(prov,improvementType)
	match improvementType:
		0:
			if cost<=adminPoints:
				prov.base_wealth+=1
				adminPoints-=cost
				return true
		1:
			if cost<=diplomacyPoints:
				prov.base_industry+=1
				diplomacyPoints-=cost
				return true
		2:
			if cost<=militaryPoints:
				prov.base_vigor+=1
				militaryPoints-=cost
				return true
		3:
			if cost<=manaPoints:
				prov.base_magic+=1
				manaPoints-=cost
				return true
func calcImproveProvince(prov:Province, improvementType:int)->int:
	var base_cost=calcProvinceCost(prov)-(owned_provinces.size()*0.85)
	base_cost=base_cost*0.5
	match improvementType:
		0:
			base_cost+=log(prov.base_wealth)
		1:
			base_cost+=log(prov.base_industry)
		2:
			base_cost+=log(prov.base_vigor)
		3:
			base_cost+=log(prov.base_magic)
	return int(max(floor(base_cost),0))+5
	
func calcProvinceCost(prov:Province)->float:
	#Calculate Province cost
	var provCost=float(owned_provinces.size()*log(owned_provinces.size()))+1.0
	var provDev=prov.base_industry+prov.base_magic+prov.base_vigor+prov.base_wealth+1
	provCost+=provDev*log(provDev)*prov.ProduceEfficiency[prov.province_produce]
	provCost=floor(provCost*100.0)/100.0
	return provCost

# # # # # # # # # #
# # # # # # # # # #
# # ADVENTURERS # #
# # # # # # # # # #
# # # # # # # # # #

func add_adventurer(ad:adventurer=null):
	if ad:
		pass
	else:
		#set stats randomly
		
		
		
		var advRes=load("res://scenes/adventurer.tscn")
		var adv:adventurer=advRes.instantiate()
		adv.strength=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_strength_modifier
		adv.charisma=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_charisma_modifier
		adv.intelligence=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_intelligence_modifier
		adv.wisdom=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_wisdom_modifier
		adventurerPool.append(adv)
		if GameMode.player_nation==id:
			Settings.game_gamemode.HUD.add_adventurer(adv)


func addEvent(e:Event):
	events.append(e)
	if e.inProvince==-1:
		var eventableProvinces:Array[Province]=[]
		for prov in owned_provinces:
			eventableProvinces.append(prov)
			for provNeighbour in prov.neighbours:
				if randi_range(1,4)==2:
					var a = get_node(provNeighbour)
					if get_node(provNeighbour):
						
						if get_node(provNeighbour).province_terrain!=Province.TERRAIN.OCEAN:
							if get_node(provNeighbour).owner_id==0 or get_node(provNeighbour).owner_id==id:
								eventableProvinces.append(get_node(provNeighbour))
		var randIndex=randi_range(0,eventableProvinces.size()-1)
		e.inProvince=eventableProvinces[randIndex].province_id
	Province.Provinces[e.inProvince].hasEvent=true
	eventProvinces[e]=Province.Provinces[e.inProvince]




func incrementDay():
	var eventsSize=float(currentlyActiveEvents.size()+1.0)
	total_strength=0
	total_charisma=0
	total_intelligence=0
	total_wisdom=0
	for i in explorerPool:
		total_strength+=i.strength
		total_wisdom+=i.wisdom
		total_charisma+=i.charisma
		total_intelligence+=i.intelligence
	for e in currentlyActiveEvents:
		if e!=null:
			e.current_strength+=float(total_strength)/eventsSize
			e.current_intelligence+=float(total_intelligence)/eventsSize
			e.current_wisdom+=float(total_wisdom)/eventsSize
			e.current_charisma+=float(total_charisma)/eventsSize
			if (e.current_strength>=e.total_strength or e.total_strength<=0) and (e.current_wisdom>=e.total_wisdom or e.total_wisdom<=0) and (e.current_intelligence>=e.total_intelligence or e.total_intelligence<=0) and (e.current_charisma>=e.total_charisma or e.total_charisma<=0):
				eventProvinces[e].hasEvent=false
				if e.event_flags&Event.flags.REWARD_TARGET_IS_PROVINCE:
					e.getReward(eventProvinces[e]) #Reward is for province
				else:
					e.getReward(self) #Reward is for nation
			
	for e in events:
		if e==null:
			events.erase(e)
			currentlyActiveEvents.erase(e)
			
			eventProvinces.erase(e)
	
	#Countdown to AI performing action
	if (id!=GameMode.player_nation):
		ai_action_cd-=1
	
func startCompletingEvent(prov:Province):
	var key:Event
	for eve in eventProvinces.keys():
		if eventProvinces[eve]==prov and eve!=null:
			key=eve
	if key and !currentlyActiveEvents.has(key):
		currentlyActiveEvents.append(key)
		key.eventBeingExplored=true
		if key.event_flags&Event.flags.ONE_TIME>0:
			print("ONE TIME EVENT")
			$"../../Events".ignoredEvents.append(key.eventID)

# # # # # EVENT REWARDS # # # # #

func increaseNationalStrengthModifier(x:int):
	national_strength_modifier+=x
	GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Strength Modifier by "+str(x))
func increaseNationalWisdomModifier(x:int):
	national_wisdom_modifier+=x
	GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Wisdom Modifier by "+str(x))
func increaseNationIntelligenceModifier(x:int):
	national_intelligence_modifier+=x
	GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Intelligence Modifier by "+str(x))
func increaseNationCharismaModifier(x:int):
	national_charisma_modifier+=x
	GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Charisma Modifier by "+str(x))

func increaseAdventurerBonus(x:int):
	national_adventurer_bonus+=x
	GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Bonus Modifier by "+str(x))


func adjustMarkets(x:float, y:float, z:float):
	ProduceEfficiency[x]+=z
	ProduceEfficiency[y]-=z
	GAME_HUD.LogNewMessage(str(name)+" leveraged an increase to their "+str(Province.PRODUCE.keys()[x]).capitalize() + " market")

func adjustMarketsFail(x:float, y:float, z:float):
	ProduceEfficiency[x]-=(z/2.0)
	ProduceEfficiency[y]-=(z/2.0)
	GAME_HUD.LogNewMessage(str(name)+" has lost confidence in their "+str(Province.PRODUCE.keys()[x]).capitalize() + " market")

func improveRandomAdventurer(x:int):
	var selectedAdventurer:adventurer
	var allAdventurersSize=adventurerPool.size()+explorerPool.size()+advisorPool.size()
	var randIDX=randi_range(0,allAdventurersSize-1)
	if randIDX<adventurerPool.size():
		selectedAdventurer=adventurerPool[randIDX]
	elif randIDX-adventurerPool.size() < explorerPool.size():
		selectedAdventurer=explorerPool[randIDX-adventurerPool.size()]
	else:
		selectedAdventurer=advisorPool[randIDX-adventurerPool.size()-explorerPool.size()]
	for point in range(x):
		match randi_range(0,3):
			0:
				selectedAdventurer.strength+=1
			1:
				selectedAdventurer.intelligence+=1
			2:
				selectedAdventurer.wisdom+=1
			0:
				selectedAdventurer.charisma+=1
					

enum FOCUS {EXPAND,FIGHT,DEVELOP,ADMINISTRATE}
var ai_focus:FOCUS=FOCUS.EXPAND
@export_category("AI")
@export var ai_level:int=12 # Default they act once every 12 days
@export var ai_complexity:int=1
@export var ai_adminEfficiency=2.0 # How often we focus on admin and how frequent we take admin actions (this being high can be a blessing and curse)
var ai_action_cd=ai_level: #How many days before the AI tries to take an action
	set(val):
		ai_action_cd=val
		if val==0:
			
			for i in range(ai_complexity):
				aiAction()
			if GameMode.day+ai_level>30:
				aiChangeFocus(selectAIFocus(0,1.0))
				print("NATION : " +str(name)+" AI is currently "+str(FOCUS.keys()[ai_focus]))
			if ai_focus==FOCUS.ADMINISTRATE: 
					#Since we want the ai to have a greater chance of finding events - nations with good admin efficiency 
					# will focus on adding events more often
				ai_action_cd=max(1,floor(ai_level/ai_adminEfficiency))
			else:
				ai_action_cd=ai_level
# # # # # GAME AI # # # # #
var runningChangesWithoutSwitchingFocus=0
func aiChangeFocus(newFocus:FOCUS):
	runningChangesWithoutSwitchingFocus+=1
	if ai_focus!=newFocus: 
		ai_focus=newFocus
		runningChangesWithoutSwitchingFocus=0
	match newFocus:
		FOCUS.EXPAND:
			#Maximise Influence by reducing Advisors and Explorers
			for adv in explorerPool:
				explorerPool.erase(adv)
				adventurerPool.append(adv)
			for adv in advisorPool:
				advisorPool.erase(adv)
				adventurerPool.append(adv)
		FOCUS.FIGHT:
			pass
		FOCUS.DEVELOP:
			#Maximise all 4 mana by Moving all adventurers and explorers to Advisor Roles
			for adv in explorerPool:
				explorerPool.erase(adv)
				adventurerPool.append(adv)
			for adv in adventurerPool:
				adventurerPool.erase(adv)
				advisorPool.append(adv)
		FOCUS.ADMINISTRATE:
			#Maximise event probabilities by moving all adventurers and advisors to Explorer roles
			for adv in advisorPool:
				advisorPool.erase(adv)
				adventurerPool.append(adv)
			for adv in adventurerPool:
				adventurerPool.erase(adv)
				explorerPool.append(adv)
func aiAction():
	match ai_focus:
		FOCUS.EXPAND:
			var lowestCost=10000000.0
			var lowestCostProvince:Province
			for prov in owned_provinces:
				for provNeighbour in prov.neighbours:
					var pNeighbour=prov.get_node(provNeighbour)
					
					if pNeighbour.owner_id==0 and pNeighbour.province_terrain!=Province.TERRAIN.OCEAN:
						if calcProvinceCost(pNeighbour)<lowestCost:
							lowestCost=calcProvinceCost(pNeighbour)
							lowestCostProvince=pNeighbour
			if lowestCost>influence:
				aiChangeFocus(selectAIFocus())
			else:
				buyProvince(lowestCostProvince)
		FOCUS.FIGHT:
			pass
		FOCUS.DEVELOP:
			#We want to improve what we're likely to focus on next, we should also account for
			#industry never being second so we check to see if its likely to come up again soon.
			var secondChoice = selectAIFocus(1,0.3*runningChangesWithoutSwitchingFocus)
			var randProvince=randi_range(0,owned_provinces.size()-1)
			match secondChoice:
				FOCUS.EXPAND:	#Improve Magic
					if !(improveProvince(owned_provinces[randProvince],3)):
						randProvince=randi_range(0,owned_provinces.size()-1)
						if !(improveProvince(owned_provinces[randProvince],3)): #Try twice before changing AI Focus
							aiChangeFocus(selectAIFocus())
				FOCUS.FIGHT:	#Improve Vigor
					if !(improveProvince(owned_provinces[randProvince],2)):
						randProvince=randi_range(0,owned_provinces.size()-1)
						if !(improveProvince(owned_provinces[randProvince],2)): #Try twice before changing AI Focus
							aiChangeFocus(selectAIFocus())
				FOCUS.DEVELOP:	#Improve Industry
					if !(improveProvince(owned_provinces[randProvince],1)):
						randProvince=randi_range(0,owned_provinces.size()-1)
						if !(improveProvince(owned_provinces[randProvince],1)): #Try twice before changing AI Focus
							aiChangeFocus(selectAIFocus())
				FOCUS.ADMINISTRATE:	#Improve Wealth
					if !(improveProvince(owned_provinces[randProvince],0)):
						randProvince=randi_range(0,owned_provinces.size()-1)
						if !(improveProvince(owned_provinces[randProvince],0)): #Try twice before changing AI Focus
							aiChangeFocus(selectAIFocus())
							
		FOCUS.ADMINISTRATE:
			#See if there are any active events
			for i in range(eventProvinces.keys().size()):
				# if we can't find an available event in our currently active events
				if !(currentlyActiveEvents.has(eventProvinces.keys()[i])):
					startCompletingEvent(eventProvinces.values()[i]) #Start completing it
			
					
				
			
@export var aiBias:Array=[1,1,1,1]
func selectAIFocus(place:int=0, extraDecisiveness:=0.0): #Place is asking if we want 1st 2nd, 3rd most important focus
	var normBias=aiBias
	var total=0.0
	for i in aiBias:
		total+=i
	for i in range(normBias.size()):
		normBias[i]=float(normBias[i])/float(total)
	var decisiveness=float(runningChangesWithoutSwitchingFocus)/10.0
	match ai_focus: 
		FOCUS.EXPAND:
			normBias[0]=normBias[0]/(1.0+decisiveness+extraDecisiveness)
		FOCUS.FIGHT:
			normBias[1]=normBias[1]/(1.0+decisiveness+extraDecisiveness)
		FOCUS.DEVELOP:
			normBias[2]=normBias[2]/(1.0+decisiveness+extraDecisiveness)
		FOCUS.ADMINISTRATE:
			normBias[3]=normBias[3]/(1.0+decisiveness+extraDecisiveness)
	var aiValue=[0,0,0,0]
	#Expand
	aiValue[0]= normBias[0]/(owned_provinces.size())
	#Fight
	aiValue[1]=0.0
	#Develop
	aiValue[2]=((totalProvinceDevelopment()/4.0)) * normBias[2] 
	#Administrate
	aiValue[3]=((influenceIncomeLastMonth*ai_adminEfficiency)/max(1.0,currentlyActiveEvents.size()))*normBias[3]
	
	var typeToDict={}
	typeToDict[aiValue[0]]="Expand"
	typeToDict[aiValue[1]]="Fight"
	typeToDict[aiValue[2]]="Develop"
	typeToDict[aiValue[3]]="Administrate"
	aiValue.sort()
	
	#Now that its sorted from most wanted to least wanted, we return what the function asks
	var idx=3-place
	#for aiVal in range(4):
		#if aiVal<3 and aiValue[aiVal]>aiValue[aiVal+1]:
			#We've found the largest element
			#idx=aiVal-place
			#break
	#if idx<0: idx=0 #Prevent out of bounds errors
	var returnValString = typeToDict[aiValue[idx]]
	match returnValString:
		"Expand":
			return FOCUS.EXPAND
		"Fight":
			return FOCUS.FIGHT
		"Develop":
			return FOCUS.DEVELOP
		"Administrate":
			return FOCUS.ADMINISTRATE
		
	
	
	
