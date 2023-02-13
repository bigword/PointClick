extends Container

onready var iObj1 = $Interactive_Object1
onready var iObj2 = $Interactive_Object2
onready var iObj3 = $Interactive_Object3
onready var iObj4 = $Interactive_Object4
onready var iObj5 = $Interactive_Object5

func _ready():
	pass # Replace with function body.

#func _process(delta):
#	pass

func Give_Obj_Info(PassedArray):
	iObj1.Give_Obj_Info(PassedArray[0])
	iObj2.Give_Obj_Info(PassedArray[1])
	iObj3.Give_Obj_Info(PassedArray[2])
	iObj4.Give_Obj_Info(PassedArray[3])
	iObj5.Give_Obj_Info(PassedArray[4])

func Disable_All():
	iObj1.set_disabled(true)
	iObj2.set_disabled(true)
	iObj3.set_disabled(true)
	iObj4.set_disabled(true)
	iObj5.set_disabled(true)

func Enable_All():
	iObj1.set_disabled(false)
	iObj2.set_disabled(false)
	iObj3.set_disabled(false)
	iObj4.set_disabled(false)
	iObj5.set_disabled(false)

func unlock(p_slot):
	if p_slot == 0:
		iObj1.unlock()
	elif p_slot == 1:
		iObj2.unlock()
	elif p_slot == 2:
		iObj3.unlock()
	elif p_slot == 3:
		iObj4.unlock()
	elif p_slot == 4:
		iObj5.unlock()
