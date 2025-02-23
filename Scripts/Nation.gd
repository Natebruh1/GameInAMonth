extends Node
class_name Nation
static var totalNations=0
static var Nations={} # Key [int], Value [Nation]

@onready var id:int
@export_category("Graphics")
@export var NationColor:=Color(1.0,1.0,1.0,1.0)
@export var nation_name:String
@export var portraitStyles:="Human_Male"

@export_category("Stats")
#Certain Nations might have certain starting gold
@export var gold:=0.0
var goldIncomeLastMonth=0.0
#Certain Nations might have certain starting influence
@export var influence:=0.0
var influenceIncomeLastMonth=0.0

var armyStationedMultiplier=0.7


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

@export var troopBonusDamage=0

@export var infantryBaseCost=10.0
@export var infantryBaseUpkeep=1.0
@export var infantryBaseDamage=[1,4]
@export var infantryBonusDamage=0
@export var infantryBaseMaxHealth=24
@export var infantryBaseArmour=0

@export var cavalryBaseCost=22.0
@export var cavalryBaseUpkeep=2.0
@export var cavalryBaseDamage=[1,4]
@export var cavalryBonusDamage=1
@export var cavalryBaseMaxHealth=22
@export var cavalryBaseArmour=0

@export var artilleryBaseCost=50.0
@export var artilleryBaseUpkeep=3.5
@export var artilleryBaseDamage=[1,8]
@export var artilleryBonusDamage=0
@export var artilleryBaseMaxHealth=18
@export var artilleryBaseArmour=4


@export_category("Missions")

@export_category("Provinces")
@export var owned_provinces:Array[Province]
#Produce Efficiency
#PLAINS,HILL,DESERT,FOREST,BONEFIELD,OCEAN,MOUNTAIN
@export var ProduceEfficiency=[1.0,1.0,1.0,1.0,1.0,1.0]

var lostAProvinceThisMonth=false

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

#Troops
@export var troopList:Array[troop]=[]

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
		#Get a random texture
		var idx=randi_range(0,NationGraphics.portrait_library[portraitStyles].size()-1)
		adv.adventurerTexture.texture=NationGraphics.portrait_library[portraitStyles][idx]
		
		if GameMode.player_nation==id:
			Settings.game_gamemode.HUD.add_adventurer(adv) #Add starting adventurers to the HUD
		i.queue_free()
		
	startingAdventurers.clear()
	
	#WIP REMOVE AUTO UPDATE ON READY
	#monthUpdate()
	

var withIncomeLogging:bool=false

func monthUpdate():
	lostAProvinceThisMonth=false
	#Income
	var totalGoldIncome=goldIncomeLastMonth
	var totalInfluenceIncome=influenceIncomeLastMonth
	
	var productionIncome=0.0
	var wealthGoldIncome=0.0
	var wealthInfluenceIncome=0.0
	var armyReductionPercentage=0.0
	var vigorInfluenceIncome=0.0
	for i in owned_provinces:
		i.magic_ratio=magic_ratio #Update the magic ratio to the nations magic ratio
		i.calculateTotalDevelopment()
		#Heal this province
		i.provinceHealth=min(i.provinceHealth+3.0/max(i.troopList.size(),1.0),i.provinceMaxHealth)
		#Production Income [Gold]
		# 0.1*prov[industry]*ln(prov[industry]+1)*nation[ProvinceEfficiency]*prov[ProvinceEfficiency]
		if i.beingSieged: #Steal income
			print(name + " being sieged!")
			var pilferGold=0.0
			var pilferInfluence=0.0
			var siegeLerp = lerp(0.1,0.7,float(min(i.siegeMonths,5.0))/5.0)
			productionIncome+=i.localIndustryGold*siegeLerp
			pilferGold+=i.localIndustryGold*(1.0-siegeLerp)
			#(0.1*i.total_industry*log(i.total_industry+1.0))*ProduceEfficiency[i.province_produce]*i.ProduceEfficiency[i.province_produce]
			
			#Wealth Income [Gold/Influence]
			#var x =max(i.total_wealth,1.0)
			#wealthGoldIncome+=(1.0/x)+sqrt(x-1.0) - 0.8
			wealthGoldIncome+=i.localWealthGold*siegeLerp
			pilferGold+=i.localWealthGold*(1.0-siegeLerp)
			wealthInfluenceIncome+=sqrt(sqrt(i.total_wealth*i.total_wealth*i.total_wealth))*siegeLerp
			pilferInfluence+=sqrt(sqrt(i.total_wealth*i.total_wealth*i.total_wealth))*(1.0-siegeLerp)
			#Vigor Income [Influence/Army Reduction]
			armyReductionPercentage+=(1+(i.total_vigor/(log(i.total_vigor)-100)))
			vigorInfluenceIncome+=sqrt(sqrt(i.total_vigor*i.total_vigor*i.total_vigor))*siegeLerp
			pilferInfluence+=sqrt(sqrt(i.total_vigor*i.total_vigor*i.total_vigor))*(1.0-siegeLerp)
			i.siegeMonths+=1
			
			#Give the pilfered money and influence to the other nation
			i.troopList[0].owning_nation.goldIncomeLastMonth+=pilferGold
			i.troopList[0].owning_nation.influenceIncomeLastMonth+=pilferInfluence*0.05
			i.troopList[0].owning_nation.gold+=pilferGold
			i.troopList[0].owning_nation.influence+=pilferInfluence*0.05
			
			var neighbouringNations=[]
			for n in i.neighbours:
				var neighProv=i.get_node(n)
				if neighProv.owner_id!=0 and !neighbouringNations.has(neighProv.owner_id):
					neighbouringNations.append(neighProv.owner_id)
			if neighbouringNations.has(i.troopList[0].owning_nation.id):
				var totalDamage=0.0
				for Troop in i.troopList:
					totalDamage+=Troop.baseDamageRange[0]
				i.provinceHealth-=totalDamage
				if i.provinceHealth<=0.0:
					call_deferred("transferProvinceToNewNation",i,i.troopList[0].owning_nation)
				
		else:
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
	
	totalGoldIncome+=wealthGoldIncome+productionIncome
	#goldIncomeLastMonth=totalGoldIncome
	
	totalInfluenceIncome+=(wealthInfluenceIncome+vigorInfluenceIncome)*0.05
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
	#print("Advisor Size :"+str(advisorPool.size()))
	totalInfluenceIncome-=advisorCost
	totalInfluenceIncome-=explorerCost
		#Army Costs
	var troopCost=0.0
	for Troop in troopList:
		troopCost+=Troop.monthlyCost
	#Reduce the cost based upon vigor
	troopCost=troopCost*armyReductionPercentage
	totalGoldIncome-=troopCost
	
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
	if id==GameMode.player_nation:
		PlayerController.this.updateHUD()
	miltiaryGoldLastMonth=goldIncomeLastMonth
	goldIncomeLastMonth=0.0
	influenceIncomeLastMonth=0.0
	#Remove raided gold and influence
	
	
	# # # Remove Unworked events # # #
	
	for i in events:
		if !(currentlyActiveEvents.has(i)):
			#We're not a currently active event so remove
			eventProvinces[i].hasEvent=false
			i.queue_free()
		
func transferProvinceToNewNation(prov:Province,nat:Nation):
	if prov.owner_id!=nat.id and nat!=null:
		owned_provinces.erase(prov)
		prov.owner_id=nat.id
		nat.owned_provinces.append(prov)
		prov.updateDisplay(Settings.mapmode)
		GAME_HUD.LogNewMessage(str(nat.nation_name)+" has conquered "+str(prov.province_name)+ " from "+str(nation_name))
	if nat==null:
		GAME_HUD.LogNewMessage(str(nation_name)+" has lost control of "+str(prov.province_name))
		owned_provinces.erase(prov)
		prov.owner_id=0
		
		prov.updateDisplay(Settings.mapmode)

var miltiaryGoldLastMonth=0.0
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
		GAME_HUD.LogNewMessage(str(name)+" has colonized "+str(prov.province_name))
		
func improveProvince(prov:Province, improvementType:int):
	var cost=calcImproveProvince(prov,improvementType)
	prov.provinceMaxHealth=80
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
	provCost+=prov.province_extra_cost
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
		#Set Stats
		adv.strength=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_strength_modifier
		adv.charisma=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_charisma_modifier
		adv.intelligence=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_intelligence_modifier
		adv.wisdom=randi_range(-1+national_adventurer_bonus,1+national_adventurer_bonus) + national_wisdom_modifier
		#Set Portrait
		var idx=randi_range(0,NationGraphics.portrait_library[portraitStyles].size()-1)
		adv.adventurerTexture.texture=NationGraphics.portrait_library[portraitStyles][idx]
		#Set Name
		idx=randi_range(0,NationGraphics.adventurer_titles[portraitStyles].size()-1)
		var advName=NationGraphics.adventurer_titles[portraitStyles][idx] + " "
		idx=randi_range(0,NationGraphics.adventurer_names[portraitStyles].size()-1)
		advName+=NationGraphics.adventurer_names[portraitStyles][idx]
		adv.adventurer_name=advName
		
		adventurerPool.append(adv)
		if GameMode.player_nation==id:
			Settings.game_gamemode.HUD.add_adventurer(adv)


func addEvent(e:Event):
	events.append(e)
	if e.inProvince==-1:
		var eventableProvinces:Array[Province]=[]
		for prov in owned_provinces:
			eventableProvinces.append(prov)
			#for provNeighbour in prov.neighbours:
				#if randi_range(1,6)==2:
					#var a = prov.get_node(provNeighbour)
					#if a!=null:
						#
						#if a.province_terrain!=Province.TERRAIN.OCEAN:
							#if a.owner_id==0 or a==id:
								#eventableProvinces.append(a)
		var randIndex=randi_range(0,eventableProvinces.size()-1)
		if randIndex>=0:
			e.inProvince=eventableProvinces[randIndex].province_id
	if Province.Provinces.has(e.inProvince):
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
	if x>0:
		GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Strength Modifier by "+str(x))
	else:
		GAME_HUD.LogNewMessage(str(name)+" failed to increase their Adventurer Strength Modifier")
func increaseNationalWisdomModifier(x:int):
	national_wisdom_modifier+=x
	if x>0:
		GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Wisdom Modifier by "+str(x))
	else:
		GAME_HUD.LogNewMessage(str(name)+" failed to increase their Adventurer Wisdom Modifier")
func increaseNationalIntelligenceModifier(x:int):
	national_intelligence_modifier+=x
	if x>0:
		GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Intelligence Modifier by "+str(x))
	else:
		GAME_HUD.LogNewMessage(str(name)+" failed to increase their Adventurer Intelligence Modifier")
func increaseNationalCharismaModifier(x:int):
	national_charisma_modifier+=x
	if x>0:
		GAME_HUD.LogNewMessage(str(name)+" increased their Adventurer Charisma Modifier by "+str(x))
	else:
		GAME_HUD.LogNewMessage(str(name)+" failed to increase their Adventurer Charisma Modifier")

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

func improveRandomAdventurer(x:int, trainingMessage=" has levelled!"):
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
			3:
				selectedAdventurer.charisma+=1
	GAME_HUD.LogNewMessage(selectedAdventurer.adventurer_name+trainingMessage)	
func slayDragon(x:int):
	match x:
		0:
			GAME_HUD.LogNewMessage(name+" has increased its infantry strength whilst searching for a dragon!")
			infantryBonusDamage+=1
		1:
			GAME_HUD.LogNewMessage(name+" has increased its infantry strength whilst searching for a dragon!")
			artilleryBonusDamage+=1
		2:
			improveRandomAdventurer(4, " has trained from killing a dragon!")
		3:
			improveRandomAdventurer(1, " has trained from skirmishing a dragon!")
		4:
			improveRandomAdventurer(1, " has trained from skirmishing a dragon!")
		5:
			improveRandomAdventurer(1, " has trained from skirmishing a dragon!")
		6:
			gold+=100.0
			GAME_HUD.LogNewMessage(name+" has turned a profit, selling dragon meat!")
		7:
			influence+=20.0
			GAME_HUD.LogNewMessage(name+" has inspired the other nations, by killing a dragon!")


enum FOCUS {EXPAND,FIGHT,DEVELOP,ADMINISTRATE}
enum MILTYPE{DEFENCE,OFFENCE,PIRATE,BARBARIAN}

var ai_focus:FOCUS=FOCUS.EXPAND
@export_category("AI")
@export var ai_level:int=12 # Default they act once every 12 days
@export var ai_complexity:int=1
@export var ai_adminEfficiency=2.0 # How often we focus on admin and how frequent we take admin actions (this being high can be a blessing and curse)
@export var militaryType:MILTYPE
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
	if owned_provinces.size()==0: return
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
			#Maximise Influence by reducing Advisors and Explorers
			for adv in explorerPool:
				explorerPool.erase(adv)
				adventurerPool.append(adv)
			for adv in advisorPool:
				advisorPool.erase(adv)
				adventurerPool.append(adv)
			#This is a gold saving tactic
			#Now check to see if we want to train any troops
			match militaryType:
				MILTYPE.DEFENCE:
					#We want a target number of troops equal to our provinces with non friendly
					#non ocean neighbour
					var borderProvinces=encroachingNeighbours
					
					
					#We prefer a large amount of infantry since we're not moving (cavalry)
					#and we're not sieging (artillery)
					if troopList.size()<borderProvinces+owned_provinces.size():
						#We want to train more
						if miltiaryGoldLastMonth>infantryBaseUpkeep:
							owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Infantry")
					#If income is high enough, produce more defensive troops
					if miltiaryGoldLastMonth>infantryBaseUpkeep*2.0:
						owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Infantry")
				MILTYPE.OFFENCE:
					if miltiaryGoldLastMonth>artilleryBaseUpkeep*1.0:
						owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Artillery")
					elif miltiaryGoldLastMonth>cavalryBaseUpkeep*1.0:
						owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Cavalry")
					elif miltiaryGoldLastMonth>infantryBaseUpkeep*1.2:
						owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Infantry")
					
				MILTYPE.PIRATE:
					if troopList.size()<owned_provinces.size()/2.0:
						if (randi_range(0,2)<1):
							owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Infantry")
						else:
							owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Cavalry")
					elif miltiaryGoldLastMonth>artilleryBaseUpkeep*1.2:
						owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Artillery")
				MILTYPE.BARBARIAN:
					if (randi_range(0,32)>1):
						owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Infantry")
					else:
						owned_provinces[randi_range(0,owned_provinces.size()-1)].BuyTroop("Orc")
			
			
			
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
				if adv.strength+adv.wisdom+adv.charisma+adv.intelligence>-2:
					adventurerPool.erase(adv)
					explorerPool.append(adv)
func aiAction():
	if owned_provinces.size()>0:
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
				match militaryType:
					MILTYPE.DEFENCE:
						if troopList.size()>3.5*owned_provinces.size() or gold>15.0*owned_provinces.size(): militaryType=MILTYPE.OFFENCE
						var occupiedProvinces=[]
						for i in owned_provinces:
							for Troop in i.troopList:
								if Troop.owning_nation!=self:
									occupiedProvinces.append(i)
						if occupiedProvinces.size()==0 or troopList.size()==0:
							#Nothing to defend against so we definitely want to switch focus
							aiChangeFocus(selectAIFocus(0,3.0))
						else:
							#Try move our troops into occupiedProvinces
							for Troop in troopList:
								Troop.moveToNewProvince(occupiedProvinces[0])
					MILTYPE.OFFENCE:
						if gold<(-30.0)-(4.0*owned_provinces.size()): militaryType=MILTYPE.DEFENCE
						var occupiedProvinces=[]
						for i in owned_provinces:
							for Troop in i.troopList:
								if Troop.owning_nation!=self:
									occupiedProvinces.append(i)
						if borderProvinceList.size()==0 or troopList.size()==0:
							#Nothing to fight against so we definitely want to switch focus
							aiChangeFocus(selectAIFocus(0,3.0))
						else:
							#Find the focus borderProvince
							var borderedProvince=null
							if borderProvinceList.size()>0:
								for i in borderProvinceList[0].neighbours:
									if borderProvinceList[0].get_node(i).owner_id==id:
										borderedProvince=borderProvinceList[0].get_node(i)
							
							for Troop in troopList:
								if Troop.movingToProvince!=null: continue
								if borderedProvince!=null:
									if Troop.inProvince==borderedProvince and Troop.inProvince.troopList.size()>3:
										#Move troops to enemy neighbour province in groups of at least 3
										Troop.moveToNewProvince(borderProvinceList[0])
									else:
										Troop.moveToNewProvince(borderedProvince)
										if Troop.movingToProvince!=borderedProvince and Troop.movingToProvinceSecondary!=borderedProvince:
											for i in borderedProvince.neighbours:
												#If it's not an ocean neighbour
												if borderedProvince.get_node(i).province_terrain!=Province.TERRAIN.OCEAN:
													#Try move to our neighbour
													Troop.moveToNewProvince(borderedProvince.get_node(i))
										if Troop.movingToProvince==null:
											Troop.moveToNewProvince(owned_provinces[randi_range(0,owned_provinces.size()-1)])
									
										
								else:
									#Move our troops towards a province with an edge
									for prov in owned_provinces:
										for neighbourProv in prov.neighbours:
											var nP:Province=prov.get_node(neighbourProv)
											if nP.province_terrain!=Province.TERRAIN.OCEAN and nP.owner_id!=id:
												Troop.moveToNewProvince(prov)
							
							aiChangeFocus(selectAIFocus())
					MILTYPE.PIRATE:
						for Troop in troopList:
							if Troop.inProvince.siegeMonths>1:
								#Move them back to this nation
								for prov in owned_provinces:
									Troop.moveToNewProvince(prov)
							else:
								for prov in borderProvinceList:
									if prov.siegeMonths<1:
										Troop.moveToNewProvince(prov)
						if miltiaryGoldLastMonth<1.0 or runningChangesWithoutSwitchingFocus>100.0:
							aiChangeFocus(selectAIFocus(0,100.0))
					MILTYPE.BARBARIAN:
						var hordes={}
						for Troop in troopList:
							if hordes.has(Troop.inProvince):
								#Add this to the horde
								hordes[Troop.inProvince].append(Troop)
							else:
								#Create a horde of this troop
								hordes[Troop.inProvince]=[Troop]
						
						#Now iterate through the hordes and decide what to do
						for hordeProv in hordes.keys():
							var hordeHasActioned=false
							var hProvNeighbours=[]
							#Get a list of neighbouring provinces to this horde
							for n in hordeProv.neighbours:
								hProvNeighbours.append(hordeProv.get_node(n))
							for h in hordes.keys():
								var horde=hordes[h]
								#If a neighbouring province has a bigger horde
								if (horde.size()>hordes[hordeProv].size() or hordes[hordeProv].size()==1) and hProvNeighbours.has(h): #If there is a horde that is bigger than us in our neighbours:
									for Troop in hordes[hordeProv]:
										Troop.moveToNewProvince(h)
									hordeHasActioned=true
									break
							if !hordeHasActioned and hordes[hordeProv][0].movingToProvince==null:
								#If we haven't actioned the current horde
								if hordes[hordeProv].size()>owned_provinces.size():
									#Move this horde, first try random and then try enemy troops
									var randNeighbour = hordeProv.get_node(hordeProv.neighbours[randi_range(0,hordeProv.neighbours.size()-1)])
									for Troop in hordes[hordeProv]:
										Troop.moveToNewProvince(randNeighbour)
									var flaggedProv:Province=null
									for provPath in randNeighbour.neighbours:
										var prov:Province=randNeighbour.get_node(provPath)
										
										if prov.troopList.size()>0:
											for i in prov.troopList:
												if i.owning_nation.id!=id:
													flaggedProv=prov
													break
										if flaggedProv!=null:
											for Troop in hordes[hordeProv]:
												Troop.moveToNewProvince(prov)
											hordeHasActioned=true
											break
							if !hordeHasActioned:
								aiChangeFocus(selectAIFocus())
							
								
									
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
					if !(currentlyActiveEvents.has(eventProvinces.keys()[i])) and currentlyActiveEvents.size()<ai_adminEfficiency:
						startCompletingEvent(eventProvinces.values()[i]) #Start completing it
			
					
				
var encroachingNeighbours=0
var borderProvinceList:Array[Province]=[]
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
	
	encroachingNeighbours=0
	borderProvinceList.clear()
	var provincesBeingAttacked=0
	var biggerArmies=0
	for prov in owned_provinces:
		for n in prov.neighbours:
			var neighbour=prov.get_node(n)
			if neighbour.owner_id!=0 and neighbour.owner_id!=id:
				encroachingNeighbours+=1
				borderProvinceList.append(neighbour)
				break
		for t in prov.troopList:
			if t.owning_nation!=self:
				provincesBeingAttacked+=1
				break
	for n in Nations.values():
		if n.troopList.size()>troopList.size():
			biggerArmies+=1
	match militaryType:
		MILTYPE.DEFENCE:
			aiValue[1]=(1.5*provincesBeingAttacked+1.0*encroachingNeighbours)*normBias[1]
		MILTYPE.OFFENCE:
			aiValue[1]=(0.5*provincesBeingAttacked+1.0*encroachingNeighbours+1.0*biggerArmies)*normBias[1]
		MILTYPE.PIRATE:
			aiValue[1]=(2.5*encroachingNeighbours)*normBias[1]
		MILTYPE.BARBARIAN:
			aiValue[1]=(1.5*biggerArmies+1.0*encroachingNeighbours)*normBias[1]
	
			
				
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
		
	
	
	
