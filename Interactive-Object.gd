extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var Is_Door : bool
#else assume it is a slot

onready var Valid_States 
# 0 is removed ONLY
# 1 also includes open for doors, empty for slots
# 2 also includes locked for doors, full for slots
# 3 also includes locked for slots AND exit doors which are open and, for now, look like normal doors
#consider combining Is_door and Valid States into one variable with 7 states

onready var Sprite_Array = [null, null, null, null]

onready var Valid_Contents : Array
#list of valid items or destinations to be in this particular slot

onready var Current_State
onready var Current_Content = null
#if its a door its a destination, if its a slot its a key object

signal Request_Room_Change
signal Ask_about_key
signal Give_Item

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func refresh():
	
	if Sprite_Array[int(Current_State)] != null and Sprite_Array[int(Current_State)] != "BASE":
		var Target_Texture : StreamTexture = load(str(Sprite_Array[int(Current_State)]))
#		print(str(Sprite_Array[int(Current_State)]))
		var Extracted_Image : Image = Target_Texture.get_data()
		var Mask = BitMap.new()
		set_normal_texture(Target_Texture)
		Mask.create_from_image_alpha(Extracted_Image,0.5)
		set_click_mask(Mask)
		if int(Current_State) == 0:
			set_disabled(true)
		else:
			set_disabled(false)
			

func Give_Obj_Info(SourceArray):
	Is_Door = SourceArray[0]
	Valid_States = SourceArray[1]
	Sprite_Array = SourceArray[2]
	Valid_Contents = SourceArray[3]
	Current_State = SourceArray[4]
	Current_Content = SourceArray[5]
	if Current_State > 0 and Current_Content == []:
		print("error - passed invalid data")
		print(SourceArray)
		print("*****")
	refresh()

func _on_InteractiveObject_pressed():
	if Current_State == 0:
		pass #this should really be disabled as a button by now
	elif Current_State == 1:
		if Is_Door == false:
			pass #this should really be disabled as a button by now
		elif Is_Door == true:
			emit_signal("Request_Room_Change",Current_Content)
	elif Current_State == 2:
		if Is_Door == true:
			emit_signal("Ask_about_key")
			#so this needs to say it's lock with the locked message if no item is selected, say that it doesn't work with wrong item selected AND
			#finally, if correct item is selected, it needs to say it unlocked it AND send the signal to Main to change the map, then update the curent state to open, and update graphics
		elif Is_Door == false:
			print("Giving item - ", Current_Content)
			emit_signal("Give_Item", Current_Content)
			
			#add the key to the inventory, change state to empty, update graphics.
	elif Current_State == 3:
		if Is_Door == true:
			print("ERROR: State = 3 for a Door")
		elif Is_Door == false:
			print("This needs to look for a key in the invetory system")
			#similar to above for a door - needs to look at the item, give feedback, unlock etc.
		
		
	

func unlock():
	if Is_Door == true and Current_State == 2:
		Current_State = 1
	elif Is_Door == false and Current_State == 3:
		Current_State = 2
	else:
		print("***")
		print("ERROR - bad unlock request passed")
		print("***")
