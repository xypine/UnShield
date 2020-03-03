extends KinematicBody

onready var camera_socket := $CameraSocket
onready var camera := $CameraSocket/Camera
onready var flash := $CameraSocket/SpotLight
onready var animation_player := $AnimationPlayer
onready var walk_player := $WalkPlayer
onready var sprint_player := $SprintPlayer
onready var jump_player := $JumpPlayer
onready var crosshair := $Crosshair
onready var coll := $CollisionShape

var is_me := true
var network_id := -1
var connected_to_server := false
var vertical_velocity := 0.0
var sneaking := false setget set_sneaking

const GRAVITY := 0.2
const JUMP_FORCE_BASE := 4.0
const JUMP_FORCE_MAX := 15.0
const MOVEMENT_SPEED := 0.1
const SPRINTING_MULTIPLIER := 1.2
const MOUSE_SENSITIVITY := 600.0

func _ready():
	is_me = network_id == get_tree().get_network_unique_id()
	
	if is_me:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	camera.current = is_me
	crosshair.visible = is_me
	
	set_process_input(is_me)
	set_physics_process(is_me)
	
	rset_config("translation", MultiplayerAPI.RPC_MODE_REMOTE)
	rset_config("rotation", MultiplayerAPI.RPC_MODE_REMOTE)
	
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	flash.hide()

var flash_k_cool = 0
var flashOn = false
var JUMP_FORCE = JUMP_FORCE_BASE * 1

func _physics_process(_delta):
	if(global_transform.origin[1] < -10):
		print("You fell...")
		global_transform.origin = Vector3(0,0,0)
	var movement_input := get_movement_input() * get_movement_speed_multiplier()
	move_and_collide(movement_input.rotated(Vector3.UP, rotation.y))
	if Input.is_key_pressed(KEY_F) and flash_k_cool < 1:
		flashOn = not flashOn
		flash_k_cool = 15
		if flashOn:
			flash.show()
			sprint_player.play()
		else:
			flash.hide()
		print("Flashlight on: " + str(flashOn))
	elif flash_k_cool > -1:
		flash_k_cool = flash_k_cool - 1
	if is_on_floor() and Input.is_action_pressed("jump"):
		vertical_velocity = JUMP_FORCE
		jump_player.play()
	else:
		vertical_velocity -= GRAVITY
	move_and_slide(Vector3.UP * vertical_velocity, Vector3.UP)
	
	if Input.is_action_pressed("sprint") and JUMP_FORCE < JUMP_FORCE_MAX - 1:
		JUMP_FORCE = JUMP_FORCE + 0.1
	elif JUMP_FORCE > JUMP_FORCE_BASE + 1:
		JUMP_FORCE = JUMP_FORCE -0.1
	
	var sprint_pressed := Input.is_action_pressed("sprint")
	var moving = Vector3(movement_input.x, 0, movement_input.z).length() > 0 and is_on_floor()
	var walking = moving and not sprint_pressed
	var sprinting = moving and sprint_pressed
	if not moving:
		walk_player.stop()
		sprint_player.stop()
	elif walking and not walk_player.playing:
		walk_player.play()
	elif sprinting and not sprint_player.playing:
		sprint_player.play()
	
	set_sneaking(Input.is_action_pressed("sneak"))
	
	if connected_to_server:
		rset_unreliable("translation", translation)


func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x / MOUSE_SENSITIVITY)
		camera_socket.rotate_x(-event.relative.y / MOUSE_SENSITIVITY)
		camera_socket.rotation_degrees.x = clamp(camera_socket.rotation_degrees.x, -60, 60)
		if connected_to_server:
			rset_unreliable("rotation", rotation)


func _on_connected_to_server():
	connected_to_server = true


func set_sneaking(to):
	if sneaking != to:
		$SneakPlayer.play()
		animation_player.play("Sneak" if to else "UnSneak")
		sneaking = to


func get_movement_input() -> Vector3:
	var movement := Vector3()
	movement.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	movement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	return movement


func get_movement_speed_multiplier() -> float:
	return MOVEMENT_SPEED * (SPRINTING_MULTIPLIER if Input.is_action_pressed("sprint") else 1.0)
