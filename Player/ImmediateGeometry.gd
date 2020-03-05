extends ImmediateGeometry


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var point_set = []
func _process(delta):
	clear()
	begin(1, null) #1 = is an enum for draw line, null is for text
	for i in range(point_set.size()):
		if i + 1 < point_set.size():
			var A = point_set[i]
			var B = point_set[i + 1]
			add_vertex(A)
			add_vertex(B)
	end()
