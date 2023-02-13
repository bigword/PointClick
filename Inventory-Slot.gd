extends Panel

var KeyClass = preload("res://Key.tscn")
var KeyContained = null

signal Key_Ready_to_Inv(P_Key, P_Self)

func _ready():
#	if randi() % 3 == 0:
#		put_into_slot(KeyClass.instance())
	CreateKey()
	refresh_style()

func refresh_style():
	if KeyContained == null:
		set_visible(false)
	else:
		set_visible(true)


func pick_from_slot():
	remove_child(KeyContained)
	refresh_style()
	return (KeyContained)
	

func return_to_slot(ReturnedItem : Node):
	add_child(ReturnedItem)
	ReturnedItem.set_global_position(self.get_global_position())
	if ReturnedItem != KeyContained:
		print("error - ", ReturnedItem, " returned to slot containing ", KeyContained)
	KeyContained.set_global_position(self.get_global_position())
	refresh_style()

func put_into_slot(ReceivedItem):
	if KeyContained != null:
		print("error - ", ReceivedItem," put into slot already containing ", KeyContained)
		return(false)
	else:
		KeyContained = ReceivedItem
		add_child(KeyContained)
		KeyContained.set_global_position(self.get_global_position())
	refresh_style()

func CreateKey():
	var NewKey = KeyClass.instance()
	NewKey.connect("Readied",self, "_Key_Readied")
	print("newkey created ", NewKey)
	put_into_slot(NewKey)


func _Key_Readied(P_Key):
	emit_signal("Key_Ready_to_Inv", P_Key, self)
	print("slot notifying Inventory about Key created")


