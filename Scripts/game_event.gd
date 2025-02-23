extends Node
class_name Event

enum flags{
	ONE_TIME = 1<<0,					#This event only appears once per game
	OWNING_NATION_ONLY = 1<<1,			#This event is only useable by the owning nation
	MULTIPLE_USERS = 1<<2,				#This event can be done by multiple nations
	REWARD_TARGET_IS_PROVINCE = 1<<3,	#Whether reward is done on province or nation
	FAIL_ACTION = 1<<4					#Should an action happen if the event isn't complete
}
@export_flags("One Time","Owning Nation Only","Multiple Users","Reward Target is Province","Action on Event Fail") var event_flags:int=0
@export var base_completion_time=10 #In days


@export var reward:String
@export var reward_args:Array

@export var inProvince:=-1


@export_category("Complete Requirements")
@export var total_strength:=0
@export var total_intelligence:=0
@export var total_wisdom:=0
@export var total_charisma:=0

@export var current_strength:=0.0
@export var current_intelligence:=0.0
@export var current_wisdom:=0.0
@export var current_charisma:=0.0


@export_category("Event Information")
@export var event_name:="Event Name_"
@export var event_description:="Event Description"
@export var event_button:="Event Button"

var eventBeingExplored=false


var eventID=0
func getReward(rewardObject:Node):
	var callable
	if event_flags&flags.REWARD_TARGET_IS_PROVINCE:
		print("Calling callable on Province")
		
		callable=Callable(rewardObject,reward)
	else:
		print("Calling callable on Nation")
		callable=Callable(rewardObject,reward)
	
	if reward_args.size()>0:
		callable.callv(reward_args)
	else:
		callable.call()
	queue_free()
enum explorerStatSearch {
	STRENGTH,
	INTELLIGENCE,
	WISDOM,
	CHARISMA
}
@export var receive_event_stat:explorerStatSearch
var attemptingNations:Array[Nation]
func startEvent(prov=-1):
	#Add total nations and random get the chosen nation
	if inProvince>=0: prov=inProvince
	var randomTotal=[]
	var randomNation=[]
	for i in Nation.Nations.values():
		var total_stat=0
		for adv in i.explorerPool:
			#Increase the total stats this nation has in the pool
			match receive_event_stat:
				explorerStatSearch.STRENGTH:
					total_stat+=adv.strength
				explorerStatSearch.INTELLIGENCE:
					total_stat+=adv.intelligence
				explorerStatSearch.WISDOM:
					total_stat+=adv.wisdom
				explorerStatSearch.CHARISMA:
					total_stat+=adv.charisma
		# # # WIP NEED TO DIVIDE TOTAL_STAT BY NUMBER OF CURRENT EXPLORE ACTIVITIES # # #
		
		# Now add it to the random total
		if total_stat>0:
			#First make sure we're not the first nation in the list
			if randomTotal.size()>0:
				randomTotal.append(total_stat+randomTotal[randomTotal.size()-1])
				randomNation.append(i)
			else:
				randomTotal.append(total_stat)
				randomNation.append(i)
	#Now we know the share of each nation
	if randomTotal.size()>0:
		var chosenNation=randi_range(0,randomTotal[randomTotal.size()-1])
		for i in range(randomTotal.size()):
			if i==randomTotal.size()-1:
				#Must be last nation
				#Check if we're doing owned nation only and we are tied to a province
				if event_flags&flags.OWNING_NATION_ONLY and prov>=0:
					if randomNation[i]==Nation.Nations[Province.Provinces[prov]]:
						randomNation[i].addEvent(self)
				else: #Any nation can get the event
					#In future we should give a function to the nation getting the event
					randomNation[i].addEvent(self)
			else:
				#Check if value at i > next value. If not then we've got our chosen nation
				if chosenNation>randomTotal[i] and chosenNation<randomTotal[i+1]:
					if event_flags&flags.OWNING_NATION_ONLY and prov>=0:
						if randomNation[i]==Nation.Nations[Province.Provinces[prov]]:
							randomNation[i].addEvent(self)
					else: #Any nation can get the event
						#In future we should give a function to the nation getting the event
						randomNation[i].addEvent(self)
		
const totalEvents=18
static func factoryEvent(idx:int) -> Event:
	var retVal:=Event.new()
	match idx:
		0:
			retVal.event_name="The Whispine Trollmound"
			retVal.event_description="For centuries, the tribes of the Whisperia Region have clashed with the local trolls in the mountain. Since coming together as a single Nation, the trolls have began forming bigger and bigger warpacks to attack your cities."
			retVal.event_button="Deal with them!"
			retVal.total_strength=300+(GameMode.year-1444)
			retVal.reward_args=[2]
			retVal.reward="increaseProvinceVigor"
			retVal.inProvince=11
			retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
		1:
			retVal.event_name="The Thinning Lumber"
			retVal.event_description="About 100 years ago, your mages began noticing that the trees were slowly getting thinner. No magic could fix this, yet this presents an interesting economic opportunity."
			retVal.event_button="Ratify the markets"
			retVal.total_wisdom=300+(GameMode.year-1444)
			retVal.total_intelligence=300+(GameMode.year-1444)
			retVal.reward_args=[0.1]
			retVal.reward="increaseProvinceWoodProduceEfficiency"
			retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			
		2:
			retVal.event_name="Untapped Arbour"
			retVal.event_description="The druids of your nation have long protected the trees in this area - perhaps it is time to kick them out. "
			retVal.event_button="Remove the Druids"
			retVal.total_wisdom=300+(GameMode.year-1444)
			retVal.reward_args=[Province.PRODUCE.WOOD]
			retVal.reward="changeProvinceProduce"
			retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			
		3:
			retVal.event_name="Fields of Fish"
			retVal.event_description="The distant nation of Piscinia have offered us a deal as part of their 'Grand Fish Plan' - they will give us unlimited fish in this province."
			retVal.event_button="Let it rain fish!"
			retVal.total_intelligence=100+(GameMode.year-1444)
			retVal.reward_args=[Province.PRODUCE.FISH]
			retVal.reward="changeProvinceProduce"
			retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			retVal.receive_event_stat=explorerStatSearch.CHARISMA
		4:
			retVal.event_name="The mole"
			retVal.event_description="Rumour has it, a mole is selling our military secrets to our neighbours."
			retVal.event_button="We must maintain absoluteness"
			retVal.total_strength=100+(GameMode.year-1444)
			retVal.reward_args=[1]
			retVal.reward="increaseProvinceVigor"
			retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
		5:
			retVal.event_name="Display of Strength : Whispine"
			retVal.event_description="We are a nation that prides itself on its strength. Recently our neighbours have begun to suspect us of being all talk. We will show them otherwise!"
			retVal.event_button="Flex our muscles!"
			retVal.total_strength=500+(2*(GameMode.year-1444))
			retVal.reward_args=[1]
			retVal.reward="increaseNationalStrengthModifier"
			retVal.inProvince=12
			retVal.event_flags+=flags.ONE_TIME
		6:
			var prodIncrease=randi_range(0,5)
			var prodIncreaseString=""
			var prodDecrease=randi_range(0,5)
			var prodChange=randf_range(0.0,0.2)
			while prodDecrease==prodIncrease: prodDecrease=randi_range(0,6)
			match prodIncrease:
				0:
					prodIncreaseString="Fish"
				1:
					prodIncreaseString="Iron"
				2:
					prodIncreaseString="Wheat"
				3:
					prodIncreaseString="Wood"
				4:
					prodIncreaseString="Wool"
				5:
					prodIncreaseString="Bone"
			retVal.event_name="Adjusting the Market : "+prodIncreaseString
			retVal.event_description="By better focussing our nations markets we can increase the market value of our "+prodIncreaseString
			retVal.event_button="Invest!"
			retVal.total_wisdom=350+(3*(GameMode.year-1444))
			retVal.total_intelligence=350+(3*(GameMode.year-1444))
			retVal.reward_args=[prodIncrease,prodDecrease,prodChange]
			retVal.reward="adjustMarkets"
			retVal.receive_event_stat=explorerStatSearch.WISDOM
		7:
			var prodIncrease=randi_range(0,5)
			var prodIncreaseString=""
			var prodDecrease=randi_range(0,5)
			var prodChange=randf_range(0.0,0.2)
			while prodDecrease==prodIncrease: prodDecrease=randi_range(0,5)
			match prodIncrease:
				0:
					prodIncreaseString="Fish"
				1:
					prodIncreaseString="Iron"
				2:
					prodIncreaseString="Wheat"
				3:
					prodIncreaseString="Wood"
				4:
					prodIncreaseString="Wool"
				5:
					prodIncreaseString="Bone"
			retVal.event_name="Adjusting the Market : "+prodIncreaseString
			retVal.event_description="By better focussing our nations markets we can increase the market value of our "+prodIncreaseString
			retVal.event_button="Invest"
			retVal.total_wisdom=350+(3*(GameMode.year-1444))
			retVal.total_intelligence=350+(3*(GameMode.year-1444))
			retVal.reward_args=[prodIncrease,prodDecrease,prodChange]
			retVal.reward="adjustMarketsFail"
			retVal.receive_event_stat=explorerStatSearch.WISDOM
		8:
			retVal.event_name="Adventurers Wanted!"
			retVal.event_description="The world gets more and more dangerous each day! We should prepare by training the next generation of adventurers"
			retVal.event_button="Train the newbies."
			retVal.total_strength=750+(2*(GameMode.year-1444))
			retVal.total_wisdom=750+(2*(GameMode.year-1444))
			retVal.total_intelligence=750+(2*(GameMode.year-1444))
			retVal.total_charisma=750+(2*(GameMode.year-1444))
			retVal.reward_args=[1]
			retVal.reward="increaseAdventurerBonus"
			retVal.receive_event_stat=explorerStatSearch.INTELLIGENCE
		9:
			retVal.event_name="Level Up"
			retVal.event_description="One of our adventurers feels they are ready to train to the next level. We shouldn't let this opportunity go to waste!"
			retVal.event_button="Let them train!"
			retVal.total_strength=300+(1.2*(GameMode.year-1444))
			retVal.total_wisdom=300+(1.2*(GameMode.year-1444))
			retVal.total_intelligence=300+(1.2*(GameMode.year-1444))
			retVal.total_charisma=300+(1.2*(GameMode.year-1444))
			retVal.reward_args=[2]
			retVal.reward="improveRandomAdventurer"
		10:
			retVal.event_name="Rumour : Dragon"
			retVal.event_description="Potential Dragon sightings have thrown the nation into turmoil! We must investigate immediately"
			retVal.event_button="Lets slay this foul beast!"
			retVal.total_strength=300+(1.2*(GameMode.year-1444))
			retVal.total_wisdom=300+(1.2*(GameMode.year-1444))
			retVal.total_intelligence=300+(1.2*(GameMode.year-1444))
			retVal.total_charisma=300+(1.2*(GameMode.year-1444))
			var reward=randi_range(0,8)
			retVal.reward_args=[reward]
			retVal.reward="slayDragon"
			if reward==8:
				retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
		11:
			retVal.event_name="Rally the Barbarians"
			retVal.event_description="Our adventurers have grown weak!"
			retVal.event_button="Rally the Barbarians!"
			retVal.total_strength=50+(2.2*(GameMode.year-1444))
			retVal.total_wisdom=0
			retVal.total_intelligence=0
			retVal.total_charisma=0
			var reward=(randi_range(0,2)<1)
			retVal.reward_args=[reward]
			retVal.reward="increaseNationalStrengthModifier"
		12:
			retVal.event_name="Rally the Druids"
			retVal.event_description="Our adventurers have grown foolish!"
			retVal.event_button="Rally the Druids!"
			retVal.total_strength=0
			retVal.total_wisdom=50+(2.2*(GameMode.year-1444))
			retVal.total_intelligence=0
			retVal.total_charisma=0
			var reward=(randi_range(0,2)<1)
			retVal.reward_args=[reward]
			retVal.reward="increaseNationalWisdomModifier"
			retVal.receive_event_stat=explorerStatSearch.WISDOM
		13:
			retVal.event_name="Rally the Bards"
			retVal.event_description="Our adventurers have grown repulsive!"
			retVal.event_button="Rally the Bards!"
			retVal.total_strength=0
			retVal.total_wisdom=0
			retVal.total_intelligence=0
			retVal.total_charisma=50+(2.2*(GameMode.year-1444))
			var reward=(randi_range(0,2)<1)
			retVal.reward_args=[reward]
			retVal.reward="increaseNationalCharismaModifier"
			retVal.receive_event_stat=explorerStatSearch.CHARISMA
		14:
			retVal.event_name="Rally the Wizards"
			retVal.event_description="Our adventurers have grown stupid!"
			retVal.event_button="Rally the Wizards!"
			retVal.total_strength=0
			retVal.total_wisdom=0
			retVal.total_intelligence=50+(2.2*(GameMode.year-1444))
			retVal.total_charisma=0
			var reward=(randi_range(0,2)<1)
			retVal.reward_args=[reward]
			retVal.reward="increaseNationalIntelligenceModifier"
			retVal.receive_event_stat=explorerStatSearch.INTELLIGENCE
		15:
			retVal.event_name="The Farmer's Collective"
			retVal.event_description="A new group called The Farmer's Collective has risen in Havensfield. While they promote free discussion - many of these discussions talk about independence"
			retVal.event_button="Increase Authoritativeness"
			retVal.total_strength=50+(GameMode.year-1444)
			var reward= randi_range(0,2)
			if reward!=2:
				retVal.reward_args=[randi_range(0,1)]
				retVal.reward="increaseProvinceVigor"
				retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			else:
				retVal.reward_args=[Province.Provinces[5],Nation.Nations[4]]
				retVal.reward="transferProvinceToNewNation"
			retVal.inProvince=5
			retVal.receive_event_stat=explorerStatSearch.WISDOM
		16:
			retVal.event_name="Reparations of the Trolls"
			retVal.event_description="After the last great Troll War, the trolls begrudgingly must pay reparations of a spare soldier every so often. Taking these soldiers often causes mass unrest in their tribes however."
			retVal.event_button="Take the soldier! (Trolls could rebel)"
			retVal.total_strength=(GameMode.year-1444)*12.0
			var reward = randi_range(1,12)
			if reward==1:
				retVal.reward_args=[Province.Provinces[11],Nation.Nations[5]]
				retVal.reward="transferProvinceToNewNation"
			else:
				retVal.reward_args=["Troll"]
				retVal.reward="BuyTroop"
				retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			retVal.inProvince=11
		17:
			retVal.event_name="Sanguire : Blood Sacrifice"
			retVal.event_description="The wild vampires of Sanguire have made us an offer - feed them one of our troops in order to strengthen the rest of our troops in Sanguire with blood magic."
			retVal.event_button="Sacrifice them!"
			retVal.reward="eventScript1"
			retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			retVal.inProvince=70
			retVal.receive_event_stat=explorerStatSearch.CHARISMA
		18:
			retVal.event_name="Mage Slaves"
			retVal.total_strength=(GameMode.year-1444)*5.0
			retVal.total_wisdom=(GameMode.year-1444)*5.0
			retVal.event_description="The Deadplains are an are of great potential - if we use some our prisoner mages, we can make it great!"
			retVal.event_button="Use the mages!"
			var reward = randi_range(1,10)
			if reward<4:
				retVal.reward_args=[2]
				retVal.reward="increaseProvinceVigor"
				retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			elif reward<7:
				retVal.reward_args=[2]
				retVal.reward="increaseProvinceIndustry"
				retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			elif reward<10:
				retVal.reward_args=[2]
				retVal.reward="increaseProvinceWealth"
				retVal.event_flags+=flags.REWARD_TARGET_IS_PROVINCE
			else:
				retVal.reward_args=[Province.Provinces[100],Nation.Nations[21]]
				retVal.reward="transferProvinceToNewNation"
			
			retVal.inProvince=100
			retVal.receive_event_stat=explorerStatSearch.INTELLIGENCE
			
	retVal.eventID=idx
	return retVal
