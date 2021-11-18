extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered",self,"collided")
func collided(body):
	if body.name=="Player":
		body.translation=Vector3(-312,1.3,-148.418)
		
