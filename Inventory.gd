extends Node2D

onready var SlotClass = preload("res://Inventory-Slot.tscn")
onready var inv_slot_collection = $GridContainer
onready var held_item = null
onready var check_ticket = null

onready var Info = []

func _ready():
#	var counter = 0
	for inv_slot in inv_slot_collection.get_children():
#		counter += 1
#		print(counter," inv slots")
		inv_slot.connect("gui_input", self, "Inventory_Input_process", [inv_slot]) 
		inv_slot.connect("Key_Ready_to_Inv", self, "_Key_Ready")
	
	Get_New_Item(["res://Room-Tree/SimplePrototypeAssets/Blue_Purple/Keyy-kkxxxxxxxx.png", [0, 5, 0]])

func Inventory_Input_process(event : InputEvent, slot):
	print("invenrory input process OK!")
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if held_item ==  null:
				held_item = slot.pick_from_slot()
				add_child(held_item)
				check_ticket = slot
			elif check_ticket != null:
				var swap_bool = false
				if slot != check_ticket:
					swap_bool = true
				remove_child(held_item)
				check_ticket.return_to_slot(held_item)
				held_item = null
				check_ticket = null
				if swap_bool == true:
					held_item = slot.pick_from_slot()
					add_child(held_item)
					check_ticket = slot

#func _process(delta):
#	pass

func _input(event):
	if held_item != null:
		held_item.global_position = get_global_mouse_position()
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT && event.pressed:
			if check_ticket != null:
				remove_child(held_item)
				check_ticket.return_to_slot(held_item)
				held_item = null
				check_ticket = null

func _Query_held_item():
	return(held_item)

func Get_New_Item(Received):
	print("received item is array with at least two elements? ", Received)
	if held_item != null and check_ticket != null:
		remove_child(held_item)
		check_ticket.return_to_slot(held_item)
		held_item = null
		check_ticket = null
	
	var empty_slots = []
	for inv_slot in inv_slot_collection.get_children():
		if inv_slot.get_child_count() == 0:
			empty_slots.append(inv_slot)
	if empty_slots.size() < 1:
		print("error - pick with no empty slots")
	else:
		Info = Received
		print("early info ", Info)
		empty_slots[0].CreateKey()
		
#		print(NewKey.get_signal_connection_list("Readied"))

func _Key_Ready(ReadyKey, RelevantSlot):
		print("Inventory heard about the Key being Ready")
		ReadyKey._Readied_confirmation()
		RelevantSlot.put_into_slot(ReadyKey)
		held_item = RelevantSlot.pick_from_slot()
		print("info ", Info)
		ReadyKey.set_info(Info[0], Info[1])


func _on_InventorySlot_Key_Ready_to_Inv(P_Key, P_Self):
	_Key_Ready(P_Key, P_Self) 

func _on_InventorySlot2_Key_Ready_to_Inv(P_Key, P_Self):
	_Key_Ready(P_Key, P_Self) 

func _on_InventorySlot3_Key_Ready_to_Inv(P_Key, P_Self):
	_Key_Ready(P_Key, P_Self) 

func _on_InventorySlot4_Key_Ready_to_Inv(P_Key, P_Self):
	_Key_Ready(P_Key, P_Self) 

func _on_InventorySlot5_Key_Ready_to_Inv(P_Key, P_Self):
	_Key_Ready(P_Key, P_Self) 
