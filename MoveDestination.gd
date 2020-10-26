extends KinematicBody2D
#Pretty basic. The target accelerates and decelerates using physics.

export (int) var max_speed = 200
export (int) var acceleration = 800
export (float) var drag = 0.05

var direction = Vector2()
var velocity = Vector2()
func get_input():
	var dir = Vector2()
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	direction = dir.normalized()

func _physics_process(delta):
	get_input()
	velocity += direction * acceleration * delta
	if velocity.length() > max_speed:
		velocity = direction * max_speed
		
	velocity = move_and_slide(velocity)
	velocity *= 1 - drag
