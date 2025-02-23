extends Node


func eventScript1():
	print("Sanguire Event Script 1")
	var p:Province = get_parent()
	if p.troopList.size()>1:
		p.troopList[0].health=-100.0
		for i in p.troopList:
			i.maxHealth+=randi_range(1,3)

