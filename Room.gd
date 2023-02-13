extends Node2D

onready var BaseTarget
onready var BaseDisplay = $TextureRect

onready var iObj_Container = $Container_of_iObjs

signal Request_Room_Change
signal Unified_ask_about_key
signal Give_Item

func _ready():
	Disable_Interactivity()

#func _process(delta):
#	pass

func Give_Obj_Info(PassedArray):
	iObj_Container.Give_Obj_Info(PassedArray)
	

func Set_Background(TexturePath):
	BaseDisplay.set_texture(load(TexturePath))

func _on_Interactive_Object1_Request_Room_Change(NextRoomIndex):
	Unified_Room_Change_Request(NextRoomIndex)

func _on_Interactive_Object2_Request_Room_Change(NextRoomIndex):
	Unified_Room_Change_Request(NextRoomIndex)

func _on_Interactive_Object3_Request_Room_Change(NextRoomIndex):
	Unified_Room_Change_Request(NextRoomIndex)

func _on_Interactive_Object4_Request_Room_Change(NextRoomIndex):
	Unified_Room_Change_Request(NextRoomIndex)

func _on_Interactive_Object5_Request_Room_Change(NextRoomIndex):
	Unified_Room_Change_Request(NextRoomIndex)

func Unified_Room_Change_Request(NextRoomIndex):
	Disable_Interactivity()
	emit_signal("Request_Room_Change",NextRoomIndex)
#	print("Room Requested change to ", NextRoomIndex)

func Disable_Interactivity():
	iObj_Container.Disable_All()

func Enable_Interactivity():
	iObj_Container.Enable_All()


func _on_Interactive_Object1_Ask_about_key():
	Unified_Ask_about_key(0)

func _on_Interactive_Object2_Ask_about_key():
	Unified_Ask_about_key(1)

func _on_Interactive_Object3_Ask_about_key():
	Unified_Ask_about_key(2)

func _on_Interactive_Object4_Ask_about_key():
	Unified_Ask_about_key(3)
	
func _on_Interactive_Object5_Ask_about_key():
	Unified_Ask_about_key(4)

func Unified_Ask_about_key(RequestingSlot):
	emit_signal("Unified_ask_about_key", RequestingSlot)

func unlock(p_slot):
	iObj_Container.unlock(p_slot)


func _on_Interactive_Object1_Give_Item(item):
	Unified_give_item(item)

func _on_Interactive_Object2_Give_Item(item):
	Unified_give_item(item)

func _on_Interactive_Object4_Give_Item(item):
	Unified_give_item(item)

func _on_Interactive_Object3_Give_Item(item):
	Unified_give_item(item)

func _on_Interactive_Object5_Give_Item(item):
	Unified_give_item(item)

func Unified_give_item(item):
	emit_signal("Give_Item",item)
