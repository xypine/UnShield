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
onready var indicator_jump := $JumpIndicator
onready var raycaster := $CameraSocket/RayCast
onready var lineDrawer := $ImmediateGeometry
var indicator_base = preload("res://Materials/indicator_jump_base.tres")
var indicator_hot = preload("res://Materials/indicator_jump_hot.tres")

var cubemap : ReflectionProbe

var is_me := true
var network_id := -1
var connected_to_server := false
var vertical_velocity := 0.0
var sneaking := false setget set_sneaking

const GRAVITY := 0.2
const JUMP_FORCE_BASE := 4.0
const JUMP_FORCE_MAX := 11
const JUMP_FORCE_REGEN := 0.2
const MOVEMENT_SPEED := 0.1
const SPRINTING_MULTIPLIER := 3.2
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
	#flash.hide()

var flash_k_cool = 0
var flashOn = false
var JUMP_FORCE = JUMP_FORCE_BASE * 1
var JUMP_COOLDOWN = 0

var to = Vector3(0,0,0)
var from = Vector3(0,0,0)
var teleport_cooldown = 0
var teleport_drawer
var pointer

var targetTrue = false
func _physics_process(_delta):
	if(global_transform.origin[1] < -20):
		print("You fell...")
		#global_transform.origin = Vector3(0,10,0)
		#translate(Vector3(0, 20, 0))
	
	#reflectionProbe.translation = camera.translation
	#reflectionProbe.translation[2] = -reflectionProbe.translation[2]
	raycaster.force_raycast_update( )
	if raycaster.is_colliding():
			#$MeshInstance.material_override.albedo_color = "ff7e00"
			to = raycaster.get_collision_point ( )
			if "teleportTarget" in raycaster.get_collider():
				#print("Teleport target found!")
				#$TeleportLight.light_color = "ff7e00"
				pointer.get_child(0).light_color = "00ff00"
				pointer.get_child(0).light_energy = 9
				pointer.get_child(0).omni_range = 10
				teleport_drawer.get_material_override().emission = "00ff00"
				targetTrue = true
			else:
				pointer.get_child(0).light_color = "ff7e00"
				pointer.get_child(0).light_energy = 1
				pointer.get_child(0).omni_range = 5
				teleport_drawer.get_material_override().emission = "ff7e00"
				targetTrue = false
	if (is_on_wall()) and JUMP_COOLDOWN >= 10:
		#vertical_velocity = vertical_velocity +5
		global_transform.origin[1] = global_transform.origin[1] + 0
	if Input.is_key_pressed(KEY_E) and JUMP_COOLDOWN < 10:
				global_transform.origin = to
				#global_transform.origin[1] = global_transform.origin[1] + 1
				$TeleportLight.light_energy = 5.04
				$TeleportLight.show()
				JUMP_COOLDOWN = JUMP_COOLDOWN +1
				if(targetTrue):
					vertical_velocity = vertical_velocity +3.2
	else:
				if $TeleportLight.light_energy > 0:
					$TeleportLight.light_energy = $TeleportLight.light_energy - 0.25
				else:
					$TeleportLight.hide()
	#else:
		#teleport_cooldown = teleport_cooldown - 1 
	var teleportTarget
	
	if is_instance_valid(teleport_drawer):
		#flash.global_transform.origin
		var line = [to, to + Vector3(0,2,0)]
		#var line = [Vector3(global_transform.origin[0],global_transform.origin[1],global_transform.origin[2]), from]
		teleport_drawer.point_set = line
	if is_instance_valid(pointer):
		pointer.global_transform.origin = to
	#raycaster.cast_to
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
	indicator_jump.global_scale = Vector2(100-int(JUMP_COOLDOWN*10),3)
	indicator_jump.global_position.x = get_viewport().size.x / 2
	indicator_jump.global_position.y = get_viewport().size.y / 2 + 50
	if JUMP_COOLDOWN < 10 and (is_on_floor() or is_on_wall()) and Input.is_action_pressed("jump"):
		vertical_velocity = JUMP_FORCE
		if JUMP_COOLDOWN < 3:
			jump_player.play()
		JUMP_COOLDOWN = JUMP_COOLDOWN + 3.4
	elif is_on_floor() and not Input.is_action_pressed("jump"):
		vertical_velocity = 0
	else:
		vertical_velocity -= GRAVITY
		if JUMP_COOLDOWN > 10:
			JUMP_COOLDOWN = JUMP_COOLDOWN + 0.95
			indicator_jump.material = indicator_hot
		else:
			indicator_jump.material = indicator_base
		if JUMP_COOLDOWN > 0:
			JUMP_COOLDOWN = JUMP_COOLDOWN - 1
	move_and_slide(Vector3.UP * vertical_velocity, Vector3.UP)
	
	if Input.is_action_pressed("sprint") and JUMP_FORCE < JUMP_FORCE_MAX - 1:
		JUMP_FORCE = JUMP_FORCE + JUMP_FORCE_REGEN
	elif JUMP_FORCE > JUMP_FORCE_BASE + 1:
		JUMP_FORCE = JUMP_FORCE -JUMP_FORCE_REGEN
	
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

const ray_length = 10000
func _input(event):
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x / MOUSE_SENSITIVITY)
		camera_socket.rotate_x(-event.relative.y / MOUSE_SENSITIVITY)
		camera_socket.rotation_degrees.x = clamp(camera_socket.rotation_degrees.x, -90, 90)
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
	return MOVEMENT_SPEED * (SPRINTING_MULTIPLIER + (abs(vertical_velocity * 0.04)) if Input.is_action_pressed("sprint") else 1.0)
