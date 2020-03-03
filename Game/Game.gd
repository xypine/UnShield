extends Spatial

onready var players := $Players
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
	new_player.name = str(id)
	new_player.network_id = id
	players.add_child(new_player)
func addBox(x : int, y : int, z : int):
	var new_box = preload("res://models/cube.tscn").instance()
	boxes.add_child(new_box)
	new_box.translate(Vector3(x,y,z))
var level_w = 0
var level_h = 0
func loadLevel(path):
	var raw = load_text_file(path)
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
				addBox(int(int(x)*20),int(int(int(xz)-1)),int(int(y)*20))
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
