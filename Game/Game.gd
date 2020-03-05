extends Spatial

onready var players := $Players
onready var reflectors := $reflectors
onready var boxes := $Boxes
onready var server_camera := $ServerCamera

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	
	server_camera.current = get_tree().is_network_server()
	if not get_tree().is_network_server():
		create_player(get_tree().get_network_unique_id())
	addBox(0,0,0)
	loadLevel("res://levels/test.level")

func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_11:
			get_tree().quit()
	

func _on_network_peer_connected(id):
	if id != 1:
		create_player(id)


func _on_network_peer_disconnected(id):
	if players.has_node(str(id)):
		players.get_node(str(id)).queue_free()


func create_player(id : int):
	var new_player = preload("res://Player/Player.tscn").instance()
	var new_reflect = preload("res://Player/ReflectionProbe.tscn").instance()
	var new_draw = preload("res://Player/draw.tscn").instance()
	var new_point = preload("res://Player/pointer.tscn").instance()
	new_player.name = str(id)
	new_player.network_id = id
	players.add_child(new_player)
	new_player.teleport_drawer = new_draw
	new_player.cubemap = new_reflect
	new_player.pointer = new_point
	reflectors.add_child(new_reflect)
	reflectors.add_child(new_draw)
	reflectors.add_child(new_point)
func addBox(x : int, y : int, z : int):
	var new_box = preload("res://models/cube.tscn").instance()
	boxes.add_child(new_box)
	new_box.translate(Vector3(x,y,z))
	new_box.get_child(0)
	return new_box
var level_w = 0
var level_h = 0
const recursion_depth_up = 7.0
const recursion_depth_down = 7.0
func loadLevel(path):
	var raw = load_text_file(path)
	var alt_mat = preload("res://Materials/FPBR_Ground01/ground01.tres")
# warning-ignore:unused_variable
	var rows = []
	var buffer = ""
	for i in raw:
		if i != "\n":
			buffer = buffer + i
		else:
			rows.append(buffer)
			buffer = ""
	print("Level has "+ str(rows.size()) + " rows")
	print(rows)
	if not rows.empty() and not rows[0].empty():
		level_h = int(len(rows))
		level_w = int(rows[0])
	var x = int(0)
	var y = int(0)
	for i in rows:
		y = int(0)
		for xz in i:
			if xz != "-":
				for i in range(recursion_depth_down):
					addBox(int(int(x)*20),int(int(int(xz)-1) - int(10*i)),int(int(y)*20))
				for i in range(recursion_depth_up):
					addBox(int(int(x)*20),int(int(int(xz)-1) + int(10*i)),int(int(y)*20)).get_child(0).material_override = alt_mat
				print("New box at: " + str(int(x)*10) + ", " + str(int(y)*10))
			y = y + int(1)
		x = x + int(1)
func load_text_file(path):
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file, error code ", err)
		return ""
	var text = f.get_as_text()
	f.close()
	return text
func _physics_process(_delta):
	for i in players.get_children():
		var map = i.cubemap 
		#map.translation[0] = i.translation[0]
		##map.translation[1] = -i.translation[1]-14.9
		#map.translation[1] = i.translation[1]
		##if map.translation[1] < -14.9:
		##	map.translation[1] = -14.9
		##map.translation[1] = 30
		#map.translation[2] = i.translation[2]
		##print(i.cubemap)
