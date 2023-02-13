extends Node2D

onready var Map = [ ]
onready var Territory = [[[]]]
onready var got_territory : bool = false
onready var territory_created : bool = false
onready var NodeTerritory : Array = []
onready var Current_Room_Index = []
onready var Current_Room

onready var TestRoom1 = $DefaultRoom1
onready var TestRoom2 = $DefaultRoom2
onready var WinRoom = $You_Win_Room
onready var RoomDB = $Room_Database

onready var Inventory = $Jib/Inventory

onready var PrefRooms = 15
onready var PrefItems = 7
onready var PrefTunnels = 4

onready var Camera_1 = $Jib

const RoomClass = preload("res://Room.tscn")

func _ready():
	#this one REALLY needs to change after tests
	
	var WinRoom_ManulObjInfo = [
		[true, 1, ["BASE","res://Images/UI-elements/You_Win_Restart.png"], [null], 1, [-1,-2]],
		[true, 1, ["BASE","res://Images/UI-elements/You_Win_Quit.png"], [null], 1, [-1,-3]],
		[false, 0, [null], [null], 0, null],
		[false, 0, [null], [null], 0, null],
		[false, 0, [null], [null], 0, null]]
	WinRoom.Give_Obj_Info(WinRoom_ManulObjInfo)

	Get_Territory()

func Get_Territory():
	Territory = RoomDB.BuildEmptyTerritory(PrefRooms-1,PrefTunnels)
	#debug output Territory
	var Territoryoutput = ConfigFile.new()
	var Tcount = 0
	
	for Tuns in Territory:
		var Rcount = 0
		for Roms in Tuns:
			var IOcount = 0
			for iobjs in Roms:
				Territoryoutput.set_value(str("Room [ ",Tcount," , ", Rcount," ]"), str("iObj#", IOcount), str(Territory[Tcount][Rcount][4][IOcount]))
				IOcount += 1
			Rcount += 1
		Tcount += 1
	
	Territoryoutput.save("user://Temp_Territory_Debug.cfg")
	#debug over
	
	#checking that all doors reciprocate:
	print("*****")
	var Tc = 0
	for tunnel in Territory:
		var Rc = 0
		for room in tunnel:
			var iOc = 0
			for iobj in room[4]:
				if iobj[0] == true and iobj[4] == 1:
					var dest_door = iobj[5]
					if dest_door.size() >= 3:
						var dest_door_folder = Territory[dest_door[0]][dest_door[1]][4][dest_door[2]]
						if dest_door_folder[0] == true and dest_door_folder[4] == 1:
							if dest_door_folder[5].size() >= 3:
								
								if dest_door_folder[5] != [Tc,Rc,iOc]:
									print(dest_door_folder[5], " != ", [Tc,Rc,iOc])
				iOc += 1
			Rc += 1
		Tc += 1
	print("*****")
	FillTerritories()

func Create_NodeTerritory():
	if territory_created == false:
		#for each room profile, create the empty room node territory
		var i = 0
		
		while i < Territory.size():
			var tunnel_array : Array = []
			for room in Territory[i]:
				tunnel_array.append([])
			NodeTerritory.append(tunnel_array)
			i += 1
		
		# then actual room node
		var temp_territory = Territory
		
		while temp_territory.size() > 0 and temp_territory[0].size() > 0:
			var current_x = temp_territory.size() - 1
			if temp_territory[current_x].size() == 0:
				temp_territory.remove(current_x)
				current_x -= 1
			var current_y = temp_territory[current_x].size() - 1

			var New_Room = RoomClass.instance()
			add_child(New_Room)
			New_Room.connect("Request_Room_Change", self, "_Room_Change_Requested")
			New_Room.connect("Unified_ask_about_key", self, "_Key_Handler")
			New_Room.connect("Give_Item", self, "_Key_Receiver")
			NodeTerritory[current_x][current_y] = New_Room

			NodeTerritory[current_x][current_y].Set_Background(str(Territory[current_x][current_y][1],Territory[current_x][current_y][2]))
			#debug loop
			var counter = 0
			for iobj in Territory[current_x][current_y][4]:
				if iobj[0] == false and iobj[4] > 0:
#					print(current_x,", ", current_y, " iboj#", counter, " State: ", iobj[4], " and contents: ", iobj[5])
					counter += 1
			#debug loop over
			NodeTerritory[current_x][current_y].Give_Obj_Info(Territory[current_x][current_y][4])
			NodeTerritory[current_x][current_y].set_global_position(Vector2(-1242*current_x, -954*current_y))
			

			temp_territory[current_x].remove(current_y)
		
		territory_created = true
		Current_Room_Index = [0, 0]
		
		refresh()

func FillTerritories():
	var LockKeyList = RoomDB.BuildLockKeyList(PrefItems)
	Territory = RoomDB.FillEmptyTerritory(LockKeyList)
	Create_NodeTerritory()

func refresh():
	if Current_Room_Index != ["WinRoom","WinRoom"]:
		Current_Room = NodeTerritory[Current_Room_Index[0]][Current_Room_Index[1]]
	
	Camera_1.set_global_position(Current_Room.get_global_position())
	Current_Room.Enable_Interactivity()

func _Room_Change_Requested(RoomIndexArray):
#	print(RoomIndexArray, " requested.")
	
	if RoomIndexArray[0] >= 0:	
		Current_Room_Index = [RoomIndexArray[0], RoomIndexArray[1]]
		refresh()
	elif RoomIndexArray[0] == -1:
		if RoomIndexArray[1] == 0:
			Current_Room_Index = [str("WinRoom"),str("WinRoom")]
			Current_Room = WinRoom
			refresh()
		elif RoomIndexArray[1] == 1:
			print("I still need to add the restart game function")
			refresh()
		elif RoomIndexArray[1] == 2:
			get_tree().quit()
	

func _Key_Handler(RequestingSlot):
	var held_item = Inventory._Query_held_item()
	var RequestingLock = [Current_Room_Index[0], Current_Room_Index[1], RequestingSlot]
	if held_item == null:
		pass
	elif held_item[1] == RequestingLock:
		Current_Room.unlock(RequestingSlot)
		Inventory.destroy_held_item()
	
	
func _on_RoomDatabase_StillBuildingMap():
	Get_Territory() # Replace with function body.

func _Key_Receiver(ReceivedKey):
	Inventory.Get_New_Item(ReceivedKey)
