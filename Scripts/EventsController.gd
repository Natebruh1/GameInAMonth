extends Node
class_name EventController

# Called when the node enters the scene tree for the first time.

static var ignoredEvents=[]
static var eventController:EventController
static func monthUpdate():
	var totalEvents = randi_range(0,3)
	print("Starting "+ str(totalEvents) + " events!")
	for i in range(totalEvents):
		var idx=randi_range(0,Event.totalEvents)
		if !ignoredEvents.has(idx):
			var e = Event.factoryEvent(idx)
			if (e):
				eventController.add_child(e)
				e.startEvent()
func _ready():
	eventController=self
