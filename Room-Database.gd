extends Node2D

export var Room_Graphic_Folder = "res://Room-Tree/SimplePrototypeAssets/"
onready var Room_Folder_List = []
onready var Map = []
onready var Territory = [[[]]] #this is a matrix of rooms
# the rooms are stored with all their information from the Map array
# Doors should reference the room by two coords for this matrix
# the first entry is the starting room. That row contains a tunnel from there
# other rows are Tunnels as they are opened

onready var roomindex_cfg = ConfigFile.new()
onready var stagedroom_cfg = ConfigFile.new()

onready var BuildingMap = true

onready var TotalKeys : int = 0
onready var TotalRooms : int = 0

onready var PerimeterRooms = []

onready var Lockables = []

signal StillBuildingMap

func _ready():
	randomize()
	BuildMap()
	BuildingMap = false
	#temp_build_ValidContentsCfgs(Map)
#	BuildEmptyTerritory(10,4)
	#BuildTerritory(7, 10, 3)



func BuildEmptyTerritory(PreferredRoomNumber,PreferredTunnelNumber):
	if BuildingMap == true:
		emit_signal("StillBuildingMap")
		print("still building that map")
		return([[[]]])
	else:
		var ShuffledMap = ShuffleArray(Map)
		var TW_x = 0
		var TW_y = 0
		var candidate_first_room_empty_iObjs = Search_for_empty_iObjs(ShuffledMap[0])
		var Rooms_Already_Placed = []
		
		var empty_doors = [] # list of doors in already placed rooms that could be placed in format (tunnel row, room column, door iobj index)

		# first room empty objs added
		if candidate_first_room_empty_iObjs[0].size() < 1:
			print("error - ", ShuffledMap[0][0]," has no doors?!")
			get_tree().quit()
		else:
			for door in candidate_first_room_empty_iObjs[0]:
				var to_append = [TW_x, TW_y]
				to_append.append(door)
				empty_doors.append(to_append)
		

		#import first room
		Territory[TW_x][TW_y] = ShuffledMap[0]
		Rooms_Already_Placed.append(ShuffledMap[0][0])
		ShuffledMap.remove(0)

		# build loop variable
		var Territory_size = 1
		
		#principal building loop
		while Territory_size <= PreferredRoomNumber:
			var tunnel_counts = []
			for tunnel in Territory:
				var tunnel_length = 0
				for room in tunnel:
					tunnel_length += 1
				tunnel_counts.append(tunnel_length)
		
			# chose next door
			var chosen_door
			if empty_doors.size() != 0:
				chosen_door = empty_doors[randi() % empty_doors.size()]
			else:
				print("why are there no empty doors?")
				get_tree().quit()
			
			
			TW_x = chosen_door[0]
			TW_y = chosen_door[1]
			var TW_x_next = null
			var TW_y_next = null

			# weight chosen door
			if chosen_door[1] == Territory[chosen_door[0]].size() -1:
				if Territory.size() > PreferredTunnelNumber:
					chosen_door = empty_doors[randi() % empty_doors.size()]
			else:
				if Territory.size() < PreferredTunnelNumber:
					chosen_door = empty_doors[randi() % empty_doors.size()]

			
			# remove chosen door from empty doors
#			print("--")
#			print("removing chosen_door: ", chosen_door, "from empty doors")
			empty_doors.remove(empty_doors.find(chosen_door))
#			print("empty doors:")
#			print(empty_doors)
#			print("--")
			#verify that the chosen door is ACTUALLY empty?
			if Territory[chosen_door[0]][chosen_door[1]][4][chosen_door[2]][5] != null:
				print("chosen empty door - ", chosen_door, " - ended up not being empty - ", Territory[chosen_door[0]][chosen_door[1]][4][chosen_door[2]][5])
				Territory_size -= 1
			else:
				# chose the room through that door
				var load_cfg = ConfigFile.new()
				load_cfg.load(str("user://",Territory[chosen_door[0]][chosen_door[1]][0],"/Valid_Contents.cfg"))
				var returned_data = load_cfg.get_value(Territory[chosen_door[0]][chosen_door[1]][0], str("iObj#", chosen_door[2]), [])
				var roomsthroughdoor = returned_data[0]
				var matching_indices = returned_data[1]
				var infinite_breaker = 0
				while !ShuffledMap[0][0] in roomsthroughdoor:
					Kick_To_Back(ShuffledMap,0)
					returned_data = load_cfg.get_value(Territory[chosen_door[0]][chosen_door[1]][0], str("iObj#", chosen_door[2]), [])
					roomsthroughdoor = returned_data[0]
					matching_indices = returned_data[1]
					infinite_breaker += 1
					if infinite_breaker > ShuffledMap.size():
						print("error - didn't find a room through this door: ",chosen_door)
						#this needs to be replaced with a correcting code
						get_tree().quit()
			
				# add the spot for the next room
				# if the room with the chosen door is NOT on the end of its tunnel
				if chosen_door[1] != Territory[chosen_door[0]].size() - 1:
					TW_x = chosen_door[0]
					TW_y = chosen_door[1]
					Territory.append([])
					Territory[Territory.size()-1].append([])

					TW_x_next = Territory.size()-1
					TW_y_next = 0
				else:
					TW_x = chosen_door[0]
					TW_y = chosen_door[1]
					
					TW_x_next = chosen_door[0]
					Territory[TW_x_next].append([])
					TW_y_next = chosen_door[1] + 1

				# find which door in the new room connects to the door in the first room
				var reciprocal_index = matching_indices[roomsthroughdoor.find(ShuffledMap[0])]
				#a litt debug - only a valid test for the first set of rooms:
				if ((reciprocal_index - 2) * -1 + 2) != chosen_door[2]:
					print("your config files are wrong bro")
				
				# Mark old room door as open and associate destination
				Territory[TW_x][TW_y][4][chosen_door[2]][4] = 1
				print(Territory[TW_x][TW_y][4][chosen_door[2]][5], " being set to ", [TW_x_next, TW_y_next, reciprocal_index])
				Territory[TW_x][TW_y][4][chosen_door[2]][5] = [TW_x_next, TW_y_next, reciprocal_index]

				# import new room
				Territory[TW_x_next][TW_y_next] = ShuffledMap[0]
				Rooms_Already_Placed.append(ShuffledMap[0][0])
				ShuffledMap.remove(0)

				# Mark new room door and associate destination
				Territory[TW_x_next][TW_y_next][4][reciprocal_index][4] = 1
				print("ALSO - ", Territory[TW_x_next][TW_y_next][4][reciprocal_index][5], " being set to ", [TW_x, TW_y, chosen_door[2]])
				Territory[TW_x_next][TW_y_next][4][reciprocal_index][5] = [TW_x, TW_y, chosen_door[2]]
				# Add new room empty doors into the empty doors
				var next_room_empty_iObjs = Search_for_empty_iObjs(Territory[TW_x_next][TW_y_next])
				for door in next_room_empty_iObjs[0]:
					var to_append = [TW_x_next, TW_y_next]
					to_append.append(door)
					empty_doors.append(to_append)
			
	#			print("reciprocal door index != -1? ", empty_doors.find([TW_x_next, TW_y_next, reciprocal_index]))
#				empty_doors.remove(empty_doors.find([TW_x_next, TW_y_next, reciprocal_index]))

				# increase the Counter for the loop
				Territory_size += 1
		
#		# This was a debug print out
#		var visual_map_to_print = []
#		var i = 0
#		while i < Territory.size():
#			var tunnel_inventory = []
#			for room in Territory[i]:
#				var door_dests = [room[4][0][5],room[4][2][5],room[4][4][5],]
#				tunnel_inventory.append(door_dests)
#			visual_map_to_print.append(tunnel_inventory)
#			i += 1
#
#		i = 0
#		while i <  visual_map_to_print.size():
#			print(visual_map_to_print[i])
#			i += 1
		
		return(Territory)

func BuildLockKeyList(PreferredItemNumber):
	if BuildingMap == true:
		emit_signal("StillBuildingMap")
	else:
		#Build LockKeyList
		var KeyRing = []
#		print("hey, this says 0 right? - ", KeyRing.size())
		var LockKeyList = []
		var LockCounter : int = 0
		
		#Always Starts with a Lock for the Exit Door
		LockCounter +=1
		LockKeyList.append(str("Lock",LockCounter))
		KeyRing.append(str("Key",LockCounter))
		
		while LockCounter < PreferredItemNumber:
			# Weighted decision about if its Lock or Key next
			if randi() % 36 >= pow(6-KeyRing.size(),2):
				# It's Key Now - Select a Random Key to place
				var RandSelectedKey = randi() % KeyRing.size()
				# But, weight it to be half as likely to be the newest one, 1.5 x for oldest
				if RandSelectedKey == KeyRing.size() - 1:
					if randi() % 2 == 0:
						RandSelectedKey = 0
				# Add it to the List, remove it from the Key Ring
				LockKeyList.append(KeyRing[RandSelectedKey])
				KeyRing.remove(RandSelectedKey)
			else:
				# It's Lock Now - put a lock, mint the key on the ring
				LockCounter += 1
				LockKeyList.append(str("Lock",LockCounter))
				KeyRing.append(str("Key",LockCounter))
		
		# All the locks are placed, time to dump remaining Keys - unweighted for what its worth
		while KeyRing.size() > 0:
			var RandSelectedKey = randi() % KeyRing.size()
			LockKeyList.append(KeyRing[RandSelectedKey])
			KeyRing.remove(RandSelectedKey)
		
		print("********")
		print("LOCK KEY LIST: ", LockKeyList)
		print("********")
		
		return(LockKeyList)

func FillEmptyTerritory(P_LockKeyList):
	var Needs_Filling = []
	
	var Tx = 0
	while Tx < Territory.size():
		var last_room_in_tunnel_index = (Territory[Tx].size() - 1)
		var dead_end_slots = Search_for_empty_iObjs(Territory[Tx][last_room_in_tunnel_index])
		for index in dead_end_slots[1]:
			Needs_Filling.append([Tx, last_room_in_tunnel_index, index])
		Tx += 1
	
		# this is necessary to make sure that we don't prematuraly cut off a tunnel
		# a room shouldn't be locked unless all tunnels branching from it are lockable
		# AND all its branches' empty slots should be regarded as UNFILLABLE after locked
	var Tunnel_Forks = [[]]
	
	var TFx = 1
	while TFx < Territory.size():
#		print("Room [ ", TFx, ", 0 ] has these iObjs ")
#		print(Territory[TFx][0][4])
		for iObj in Territory[TFx][0][4]:
#			print("       #", Territory[TFx][0][4].find(iObj), " : ", iObj)
			if iObj[0] == true and iObj[4] > 0:
				
				if iObj[5] == null:
					print("open door with null content")
				elif iObj[5][0] < TFx:
#					print("Door at [ ", TFx, ", 0, ", Territory[TFx][0][4].find(iObj), " ] connects to ", iObj[5] )
					Tunnel_Forks.append(iObj[5])
					
		TFx += 1
	print("Tunnel_Forks is :", Tunnel_Forks)
	
	Lockables = []
	
	#Establish Exit Door 
	var possible_exit_doors = []
	Tx = 0
	while Tx < Territory.size(): 
		var last_room_in_tunnel_index = (Territory[Tx].size() - 1)
		var dead_end_doors = Search_for_empty_iObjs(Territory[Tx][last_room_in_tunnel_index])
		for index in dead_end_doors[0]:
			possible_exit_doors.append([Tx, last_room_in_tunnel_index, index])
		Tx += 1
	
	for candidate_door in possible_exit_doors:
		if Territory[candidate_door[0]][candidate_door[1]][4][candidate_door[2]][1] < 2:
			possible_exit_doors.remove(candidate_door)
	
	# Lock it
	var exit_door = possible_exit_doors[randi() % possible_exit_doors.size()]
	Safe_Lock(exit_door)
	Territory[exit_door[0]][exit_door[1]][4][exit_door[2]][5] = [-1, 0]
	
	# Make the door out of the room it is in "Lockable"
	var iObjCounter = 0
	for iObj in Territory[exit_door[0]][exit_door[1]][4]:
		if iObj[0] == true and iObj[4] == 1:
#			print("lockable constructed from exit door: ", [exit_door[0],exit_door[1],iObjCounter])
			Lockables.append([exit_door[0],exit_door[1],iObjCounter])
		iObjCounter += 1
	
	# AND make the slots in the antecedent room Fillable
	iObjCounter = 0
	if exit_door[1] > 0:
		for iobj in Territory[exit_door[0]][exit_door[1] - 1][4]:
			if iobj[0] == false and iobj[4] ==0:
				Needs_Filling.append([exit_door[0],exit_door[1] - 1, iObjCounter])
			iObjCounter += 1
	elif exit_door[0] == 0:
		print("exit door in first room?!")
	else:
		var ante_chamber = Tunnel_Forks[exit_door[0]]
		if ante_chamber.size() < 3:
			print("Very early tunnel fork problemo")
		else:
			for iobj in Territory[ante_chamber[0]][ante_chamber[1]][4]:
				if iobj[0] == false and iobj[4] == 0:
					Needs_Filling.append([ante_chamber[0], ante_chamber[1], iObjCounter])
				iObjCounter += 1
	
	
	# This Keyring has real keys
	# each Key is Defined by a 3 variable Array:
	#	0 = Key# for Key ring
	#	1 = sprite
	#	2 = 3 item array for unlockable iObj
	# Build the key to the Exit Door
	var KeyRing = []
	var KeyCounter = 1
	var KeySpriteFileName = str("Keyy-")
	while KeySpriteFileName.length() < 15:
		if (KeySpriteFileName.length() - 5)/2 == exit_door[2]:
			KeySpriteFileName = str(KeySpriteFileName,"kk")
		else:
			KeySpriteFileName = str(KeySpriteFileName,"xx")
	KeyRing.append([KeyCounter, str(Territory[exit_door[0]][exit_door[1]][1], KeySpriteFileName,".png"),exit_door])
	print("KeyRing #", KeyRing.size() - 1,": ", KeyRing[KeyRing.size()-1])
	KeyCounter += 1
	
	var LockKeyProgress : int = 1
#	print()
#	print("Starting work from LockKeyList. Lock Key List:")
#	print(P_LockKeyList)
#	print()
#	print("The territory being passed this many tunnels:", Territory.size())
	var Tcounter = 0
	while Tcounter < Territory.size():
#		print("Tunnel #", Tcounter, " has this many rooms: ", Territory[Tcounter].size())
		Tcounter += 1
#	print()
#	print("Tunnel forks at ", Tunnel_Forks)
#	print()
	# Work from Lock Key
	while LockKeyProgress < P_LockKeyList.size():
		print("ELEMENT #",LockKeyProgress," is ", P_LockKeyList[LockKeyProgress])
		if P_LockKeyList[LockKeyProgress].begins_with("Key"):
			if Needs_Filling.size() > 0: #we got a key and a place to put it
				
				var chosen_slot = Needs_Filling[randi() % Needs_Filling.size()]

				if Needs_Filling.find(chosen_slot) != -1:
					Needs_Filling.remove(Needs_Filling.find(chosen_slot))
					
				# get the key off the ring
				var CurrentKeyDummyIndex = P_LockKeyList[LockKeyProgress].trim_prefix("Key").to_int()
				var PassedKeyInfo = []
				
				print("KeyRing: ", KeyRing)
				print("Dummy index ", CurrentKeyDummyIndex)
				
				for Key in KeyRing:
					if Key[0] == CurrentKeyDummyIndex:
						PassedKeyInfo.append_array(Key)
						PassedKeyInfo.remove(0)
						PassedKeyInfo.append(KeyRing.find(Key))
#						print("here's a key - ", PassedKeyInfo)
				if PassedKeyInfo.size() < 3:
					print("ERROR - no key with dummy index ", CurrentKeyDummyIndex, " found on keyring")
					print("     ***KeyRing: ", KeyRing)
					print("     ***D index: ", CurrentKeyDummyIndex)
				
				
				
				# place the key
				if PassedKeyInfo.size() > 3:
					KeyRing.remove(PassedKeyInfo[2])
					PassedKeyInfo.remove(2)

				print("CHOSEN slot: ", chosen_slot, " filled with ", PassedKeyInfo)
				Territory[chosen_slot[0]][chosen_slot[1]][4][chosen_slot[2]][4] = 2
				Territory[chosen_slot[0]][chosen_slot[1]][4][chosen_slot[2]][5] = PassedKeyInfo

				# make slot lockable
#				print("another lockable made from chosen_slot here: ", chosen_slot)
				Lockables.append(chosen_slot)
				# IF all the doors in the room with the lockable are lockable
				# Make the door into the room with the key "Lockable" and the slots fillable
				# is at a tunnel fork?
				
				var entry_room = null
				if chosen_slot[1] > 0:
					iObjCounter = 0
					for iobj in Territory[chosen_slot[0]][chosen_slot[1]-1][4]:
						if iobj[0] == true and iobj[5] != null:
							if iobj[5][0] == chosen_slot[0] and iobj[5][1] == chosen_slot[1]:
								entry_room = [chosen_slot[0], chosen_slot[1] - 1, iObjCounter]
						iObjCounter += 1
				elif chosen_slot[0] <= 0:
					print("Snapitall! we looking for an antechamber to the first room?!")
				else:
					entry_room = Tunnel_Forks[chosen_slot[0]]
				
				iObjCounter = 0
				print("entry room = ", entry_room)
				for iObj in Territory[entry_room[0]][entry_room[1]][4]:
#					print(iObj)
					if iObj[0] == true and iObj[5] != null:
						if iObj[5][0] == chosen_slot[0] and iObj[5][1] == chosen_slot[1]:
							var to_append = [entry_room[0],entry_room[1],iObjCounter]
							print("lockable added from entry room: ", to_append)
							Lockables.append(to_append)
					elif iObj[0] == false and iObj[4] == 0:
						Needs_Filling.append([entry_room[0],entry_room[1],iObjCounter])
					iObjCounter += 1
				
				PassedKeyInfo = []
			else:
				print("# we got a key but no place to put it?")

		elif P_LockKeyList[LockKeyProgress].begins_with("Lock"): # WE GOT A LOCK HERE
			
			if Lockables.size() <= 0:
				print("error - unexpectedly ran out of lockables?")
			else:
				#Lockables Debug
				for Lockable in Lockables:
					if Lockable.size() < 3:
						print("error - why less than 3 items in this -> ", Lockable)
				
				#choose lockable
				var chosen_lockable = Lockables[randi() % Lockables.size()]

				# Lock it
#				print(chosen_lockable)
				Safe_Lock(chosen_lockable)
				
				# Make the Key and put it on the KeyRing
				KeySpriteFileName = str("Keyy-")
				while KeySpriteFileName.length() < 15:
					if (KeySpriteFileName.length() - 5)/2 == chosen_lockable[2]:
						KeySpriteFileName = str(KeySpriteFileName,"kk")
					else:
						KeySpriteFileName = str(KeySpriteFileName,"xx")
				KeyRing.append([KeyCounter, str(Territory[chosen_lockable[0]][chosen_lockable[1]][1],KeySpriteFileName,".png"),exit_door])
				print("*KeyRing #", KeyRing.size() - 1,": ", KeyRing[KeyRing.size()-1])
				KeyCounter += 1
				
				# IF THE LOCKABLE WAS A DOOR remove the slots behind that door from needs_filling
				# first, we need to make a list of all the rooms
				if Territory[chosen_lockable[0]][chosen_lockable[1]][4][chosen_lockable[2]][0] == true:
					var rooms_just_locked = []
					# list the first locked room
					# list the first locked room
					var fulldoor = Territory[chosen_lockable[0]][chosen_lockable[1]][4][chosen_lockable[2]][5]
#					print(fulldoor)
					fulldoor.remove(2)
					rooms_just_locked.append(fulldoor)
					# list the rest of the tunnel behind that door
					var tunnel_y = chosen_lockable[1]
					while rooms_just_locked.size() < Territory[chosen_lockable[0]].size() - 1:
						tunnel_y += 1
						rooms_just_locked.push_back([chosen_lockable[0], tunnel_y])

					#look for tunnel forks behind that door
					# and then add the whole tunnel to the list
					# then do it again till we're done
					for forkentry in Tunnel_Forks:
						
						if forkentry != []:
							if rooms_just_locked.find([forkentry[0],forkentry[1]]) != -1:
								var currentTunnel = Tunnel_Forks.find(forkentry) 
								tunnel_y = 0
								var i = 0
								while  i < Territory[currentTunnel].size() - 1:
									rooms_just_locked.push_back([currentTunnel, i])
									i += 1
					# THEN remove every iObj from those rooms from needs filling
					while rooms_just_locked.size() > 0:
						var i = 0
						while i < 5:
							if Needs_Filling.find([rooms_just_locked[0][0],rooms_just_locked[0][1],i]) != -1:
								Needs_Filling.remove(Needs_Filling.find([rooms_just_locked[0][0],rooms_just_locked[0][1],i]))
							i += 1
						rooms_just_locked.remove(0)
				
				# Okay now make entry door to the room with the new locked lockable
				# Is it NOT on a tunnel fork? easy:
				var entry_door = [null, null, null]
				if chosen_lockable[1] > 0:
					for iObj in Territory[chosen_lockable[0]][chosen_lockable[1] - 1][4]:
						if iObj[0] == true and iObj[4] > 0:
							if iObj[5][0] == chosen_lockable[0] and iObj[5][1] == chosen_lockable[1]:
								print("iObj search impicated? ", Territory[chosen_lockable[0]][chosen_lockable[1] - 1][4].find(iObj), "<- found that index?")
								entry_door = [chosen_lockable[0], chosen_lockable[1] - 1, Territory[chosen_lockable[0]][chosen_lockable[1] - 1][4].find(iObj)]
				elif chosen_lockable[0] == 0 and chosen_lockable[1] == 0:
					print("locking a door in the first room now?")
					entry_door = [null,null,null]
				else:
#					print("Tunnel Forks implicated: ", Tunnel_Forks[chosen_lockable[0]])
#					print("from the ", chosen_lockable[0], " index of this Array:")
#					print(Tunnel_Forks)
					entry_door = Tunnel_Forks[chosen_lockable[0]]
					# error correcting code?
					if entry_door.size() < 3:
						for iobj in Territory[chosen_lockable[0]][0][4]:
							if iobj[0] == true and iobj[4] > 0:
								if iobj[5].size() < 3:
									print("ERROR - apparently this tunnel fork thing is on the territory?!")
								else:
									Tunnel_Forks[chosen_lockable[0]] = iobj[5]
									print("correcting ", entry_door, " to ", iobj[5])
									entry_door = iobj[5]
						
					
#				print("appending lockable from a locked door inside - ", entry_door)
				
				if entry_door != [null,null,null]:
					if entry_door.size() == 3:
						Lockables.append(entry_door)
					else:
						print("entry_door size is not 3, but... : ", entry_door.size())
				
				
		LockKeyProgress += 1
	
	return(Territory)

# This function tests the PassedMap to see if going through Door in RoomIndex1 can go to Room2
# Return [False,null if it cannot
# Returns [true, x ] if it can where x is the index of a valid connecting door in Room2
func Search_for_room_through_door(PShuffledMap,RoomWithDoorIndex,DoorIndex,SearchRoomIndex):
	var loaded_Room1_valid_contents_cfg = ConfigFile.new()
	loaded_Room1_valid_contents_cfg.load(str("user://",PShuffledMap[RoomWithDoorIndex][0],"/Valid_Contents.cfg"))
	
	var Room1_Door_data = loaded_Room1_valid_contents_cfg.get_value(PShuffledMap[RoomWithDoorIndex][0], str("iObj#", DoorIndex), [])
	var Room1_Door_valid_rooms =  Room1_Door_data[0]
	var Room1_Door_indices = Room1_Door_data[1]
	var room_door_index_found = Room1_Door_valid_rooms.find(PShuffledMap[SearchRoomIndex][0]) 
	var array_to_return = []
	
	if room_door_index_found == -1:
		array_to_return = [false, null]
	else:
		array_to_return.append(true)
		array_to_return.append(Room1_Door_indices[room_door_index_found])
	
	return array_to_return

func Kick_To_Back(passedArray,KickIndex):
	var kicked_item = passedArray[KickIndex]
	passedArray.remove(KickIndex)
	passedArray.append(kicked_item)
	return(passedArray)


func ShuffleArray(PassedArray):
		var UnshuffledArray = PassedArray
		var ShuffledArray = []
		var i = 0
		while i < UnshuffledArray.size():
			var x = randi() % UnshuffledArray.size()
			ShuffledArray.append(UnshuffledArray[x])
			UnshuffledArray.remove(x)
			i += 0
			
		return(ShuffledArray)

func Search_for_empty_iObjs(PRoom):
	#Select Exit Door in the First Door
	var doors_found = []
	var slots_found = []
	var i =0
	while i < 5:
		if PRoom[4][i][0] == true:
			if PRoom[4][i][4] == 0:
				doors_found.append(i)
		elif PRoom[4][i][0] == false:
			if PRoom[4][i][4] == 0:
				slots_found.append(i)
		i += 1
	return([doors_found, slots_found])

func BuildMap():
	var dir = Directory.new()
	dir.open(Room_Graphic_Folder)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			Room_Folder_List.append(file)
	
	dir.list_dir_end()
	
	
	for Room_Folder in Room_Folder_List:
		TotalRooms += 1
		
		var New_Room_Profile : Array = [null, null, null, null, null]
		#Definitions of a Room, by index:
		#0 = Node
		#1 = folder path
		#2 = path for Base Sprite
		#3 = iObj count
		#4 = iObj array (of arrays)
		#	for each iObj: [ Is_Door, Valid_States, State_Sprite_array, Valid_Contents
		#					Current_State, Current_Contents,  
		New_Room_Profile[0] = str(Room_Folder)
		New_Room_Profile[1] = str(Room_Graphic_Folder,Room_Folder,"/")
		New_Room_Profile = Generate_Object_Array(New_Room_Profile)
		
		
		Map.append(New_Room_Profile)
		var i : int = 0
		while i < 5:
			var temp_typestring = "error"
			if New_Room_Profile[4][i][0] == true:
				temp_typestring = "door"
			else:
				temp_typestring = "slot"
			
			var temp_validstatestring = "error"
			match New_Room_Profile[4][i][1]:
				0:
					temp_validstatestring = "removed"
				1:
					temp_validstatestring = "open/empty"
				2:
					temp_validstatestring = "locked/full"
				3:
					temp_validstatestring = "exit/locked"
			i += 1
			roomindex_cfg.set_value(str(Map.size(), " ", New_Room_Profile[0]), str("iObj#", i+1,"(",temp_typestring,")"), str(temp_validstatestring))
		
	
	roomindex_cfg.save("user://roomindex.cfg")
	
	#temp_build_ValidContentsCfgs(Map)
	


func Generate_Object_Array(PNew_Room_Profile):
	var New_Room_iObj_Array = []
	while New_Room_iObj_Array.size() < 5:
		New_Room_iObj_Array.append([null,0,[],[],0,null])
	
	var dir2 = Directory.new()
	dir2.open(str(PNew_Room_Profile[1]))
	dir2.list_dir_begin()
	var iObj_State_Sprites = []
	while iObj_State_Sprites.size() < 5:
		iObj_State_Sprites.append([null,null,null,null])
	
	
	while true:
		var file2 = dir2.get_next()
		
		
		if file2 == "":
			break
		elif not file2.begins_with("."):
			if file2.begins_with("Base") and file2.ends_with(".png"):
				PNew_Room_Profile[2] = file2
				
				var i: int = 0
				while i < 5:
					if file2[5+2*i] == "d":
						New_Room_iObj_Array[i][0] = true
					elif file2[5+2*i] == "s":
						New_Room_iObj_Array[i][0] = false
					else:
						print("invalid Base sprite name: ", file2)
#
#					if int(file2[6+2*i]) > New_Room_iObj_Array[i][1]:
#						New_Room_iObj_Array[i][1] = int(file2[6+2*i])
#						print("Outdated Base Format - non-zero state purportedly represented on Base")
#
#					iObj_State_Sprites[i][int(file2[6+2*i])] = null
					
					i += 1
			elif file2.begins_with("Modd") and file2.ends_with(".png"):
				
				var i: int = 0
				while i < 5:
					
					if file2[5+2*i] != "x":
						if int(file2[6+2*i]) > New_Room_iObj_Array[i][1]:
							New_Room_iObj_Array[i][1] = int(file2[6+2*i])
						
						iObj_State_Sprites[i][int(file2[6+2*i])] = str(PNew_Room_Profile[1],file2)
						
						var offset_for_seeing_if_this_can_be_locked : int = 0
						if New_Room_iObj_Array[i][0] == true:
							offset_for_seeing_if_this_can_be_locked += 1
						if (New_Room_iObj_Array[i][1]+offset_for_seeing_if_this_can_be_locked) >= 3:
							TotalKeys += 1
					i += 1
	
	
	var i: int = 0
	while i <5:
		New_Room_iObj_Array[i][2] = iObj_State_Sprites[i]
		i += 1
	
	PNew_Room_Profile[4] = New_Room_iObj_Array
	PNew_Room_Profile[3] = New_Room_iObj_Array.size()
	
	return(PNew_Room_Profile)
	


# The following function was used to BUILD config files for my first round of room art
# It is kept for future developer work but is not expected to have user functionality
func temp_build_ValidContentsCfgs(PassedMap):
	for CurrentRoom in PassedMap:
		var valid_contents_cfg = ConfigFile.new()
		var ObjectCounter = 0
		var CurrentRoomWalls = CurrentRoom[0].get_slice("_", 0)
		var CurrentRoomFloor = CurrentRoom[0].get_slice("_", 1)
		for CurrentObject in CurrentRoom[4]:
			var temp_valid_contents_list : Array = []
			var temp_array_2 : Array = []
			if CurrentObject[0] == false:
				 temp_valid_contents_list.append("ALL")
			else:
				for ConsideredRoom in PassedMap:
					if ConsideredRoom[0].get_slice("_", 0) != CurrentRoomWalls and ConsideredRoom[0].get_slice("_", 1) != CurrentRoomFloor:
						temp_valid_contents_list.append(str(ConsideredRoom[0]))
						temp_array_2.append((ObjectCounter-2)*-1+2)
			
			var total_array = [temp_valid_contents_list,temp_array_2]
			
			valid_contents_cfg.set_value(CurrentRoom[0],str("iObj#", ObjectCounter),total_array)
			ObjectCounter += 1
		var temp_save_path : String = str("user://",CurrentRoom[0],"/Valid_Contents.cfg")
		#var temp_dir = Directory.new()
		#temp_dir.open("res://")
		#temp_dir.make_dir(CurrentRoom[0])
#		print(valid_contents_cfg)
#		print(temp_save_path)
		valid_contents_cfg.save(temp_save_path)
	
	
	

func Safe_Lock(iObj = []):
	var success = false
	if iObj.size () < 3:
		print("Safe_Lock passed bad iobj to lock: ", iObj)
	else:
		if Territory[iObj[0]][iObj[1]][4][iObj[2]][0] == false: #It's a slot
			if Territory[iObj[0]][iObj[1]][4][iObj[2]][4] == 2: # slot is filled and unlocked
				if Territory[iObj[0]][iObj[1]][4][iObj[2]][5] != null: #Slot has the filling
					#print("Safe_Lock locked a slot with no problems")
					Territory[iObj[0]][iObj[1]][4][iObj[2]][4] = 3
					Lockables.remove(Lockables.find(iObj))
					success = true
				else: # slot has no filling?
					print("Safe_Lock passed slot marked filled with no filling")
			else: #Slot passed in wrong state
				print("safe lock passed slot in wrong state. 2 != ", Territory[iObj[0]][iObj[1]][4][iObj[2]][4])
		else: #It's a DOOR!
			if Territory[iObj[0]][iObj[1]][4][iObj[2]][4] == 1: # Door is open, unlocked
				if Territory[iObj[0]][iObj[1]][4][iObj[2]][5] != null and Territory[iObj[0]][iObj[1]][4][iObj[2]][5].size() >= 3:
					# DOOR has valid destination
					success = Safe_Lock_Valid_Door(iObj)
	return(success)

func Safe_Lock_Valid_Door(iObj):
	var Dest_Room_index = Territory[iObj[0]][iObj[1]][4][iObj[2]][5]
	var Dest_Room_iobjs = Territory[Dest_Room_index[0]][Dest_Room_index[1]][4]
	var SafeToLock = true
	
	var i_counter = 0
	while i_counter < Dest_Room_iobjs.size():
		var Checking_iobj_index = [Dest_Room_index[0], Dest_Room_index[1], i_counter]
		var Checking_iobj = Territory[Dest_Room_index[0]][Dest_Room_index[1]][4][i_counter]
		if Checking_iobj[0] == true and Checking_iobj[4] == 1:
			if Lockables.find(Checking_iobj_index) == -1:
				print("Safe Lock denied lock of Valid Door")
				SafeToLock = false
		i_counter += 1
	
	if SafeToLock == true:
		Territory[iObj[0]][iObj[1]][4][iObj[2]][4] == 2
		Lockables.remove(Lockables.find(iObj))
	
	return(SafeToLock)

#func _process(delta):
#	pass
