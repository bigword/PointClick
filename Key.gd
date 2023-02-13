extends Node2D

onready var Name : String = "???"
onready var Description : String = "An item whose Description was not successfully passed"
onready var Visual = preload("res://Images/UI-elements/BlankKeyQuestion.png")
onready var LockLocation = []
onready var VisualDisplay = $TextureRect
onready var Readied_confirmed = false

signal Readied(PassSelf)

# Called when the node enters the scene tree for the first time.
func _ready():
#	print(VisualDisplay)
	VisualDisplay.set_texture(Visual)
#	print(VisualDisplay)
	print("Key ready done")
	

func _process(delta):
	if Readied_confirmed ==false:
		emit_signal("Readied",self)
		print("key emits signal")

func set_info(Visual_Passed, LockLocation_Passed):
#	Name = Name_Passed
#	Description = Description_Passed
	print(VisualDisplay)
	print("old Visual ", Visual)
	Visual = load(str(Visual_Passed))
	print("setting info on Key - ", Visual_Passed)
	LockLocation = LockLocation_Passed
#	print(VisualDisplay)
	VisualDisplay.set_texture(Visual)

func _Readied_confirmation():
	print("Key receives confirmation of it's ready signal from Inv")
	Readied_confirmed = true
