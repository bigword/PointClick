extends Node2D

onready var Text_button = $TextureButton

onready var Mask = BitMap.new()
onready var ExtractedImage = Image.new()

func _ready():
	var Target_Texture = load("res://Room-Tree/SimplePrototypeAssets/Blue_Brown/Modd-d1xxxxxxxx.png")
	ExtractedImage = Target_Texture.get_data()
	Text_button.set_normal_texture(Target_Texture)
	Mask.create_from_image_alpha(ExtractedImage,0.5)
	Text_button.set_click_mask(Mask)
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TextureButton_pressed():
	print("I got clicked at ", get_global_mouse_position()) 
