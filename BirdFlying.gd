extends KinematicBody2D
const MAX_VERTICAL_VELOCITY: float = 6.0
const MAX_HORIZONTAL_VELOCITY: float = 3.0
const STOP_DISTANCE: float = 50.0
const MAX_SPEED: float = 5.0
const JUMP_FORCE: float = 3.0
const GRAVITY: float = 1.75
const FOLLOW_SPEED: float = 0.02
const DRAG: float = 0.1

var sprite: Sprite

var label: Label
var dest: Vector2

var playing: bool = false  # just to start the game with first click
var velocity: Vector2 = Vector2(0.0, 0.0)
var pressed_jump: bool = false

func _ready():
	pressed_jump = false
	label = get_node("../Destination/Camera2D/Label")
	sprite = get_node("BirdSprite")

func _physics_process(delta):
	
	#This is left in from the code I stole from lick.
	#TODO: Make into a dive 
	if pressed_jump:
		velocity.y = -JUMP_FORCE
	
	#This is the target position we are flying at
	dest = get_node("../Destination").position
	
	#Raw distance to our destination
	var distance_to_destination = Vector2(
		dest.x - position.x,
		dest.y - position.y).length()
		
	#This is a normalized vector that gives us the relative direction of the 
	# target from the bird
	var flying_direction = Vector2(
		dest.x - position.x,
		dest.y - position.y).normalized()
		
	#Flip the sprite if going left (Saves on animation computation)
	if flying_direction.x < 0.0:
		sprite.scale = Vector2(-0.25, 0.25)
	else:
		sprite.scale = Vector2(0.25, 0.25)
	
	#--------------------------------------------------------------------------
	#-------FLYING NONSENSE
	#--------------------------------------------------------------------------
	velocity *= 1 - DRAG
	
	#If we are far enough from the target, accelerate toward it
	if distance_to_destination > STOP_DISTANCE:
		velocity +=  flying_direction * (FOLLOW_SPEED * distance_to_destination / MAX_SPEED)
	#If we are close to the target, slow down our acceleration
	else:
		velocity +=  Vector2(flying_direction.x * (FOLLOW_SPEED * (distance_to_destination / MAX_SPEED)) / 2, 0.0)
	
	#Only apply gravity if the bird is stopped
	var cur_speed = velocity.length()
	if cur_speed <= 0.5:
		velocity.y += delta * GRAVITY
	
	#This is where the actual bird is flying, not just the angle to the target
	var real_direction = velocity.normalized()
	
	#Cap our movement speed
	if abs(velocity.x) > MAX_HORIZONTAL_VELOCITY:
		velocity.x = real_direction.x * MAX_HORIZONTAL_VELOCITY
	if abs(velocity.y) > MAX_VERTICAL_VELOCITY:
		velocity.y = real_direction.y * MAX_VERTICAL_VELOCITY
		
	#This is really gross, and needs a lot of cleaning.
	#It rotates the bird and chooses the animation based on the birds direction
	#The Dot product tells us how "Vertical" the intended direction is
	# -1.0 is straight up, 1.0 is straight down
	# currently not used.
	var anim_angle = Vector2(0.0, 1.0).dot(flying_direction)
	
	var tree = $AnimationPlayer/AnimationTree.get("parameters/playback")
	#If we're close enough to the "Stop Zone", play the idle animation
	if distance_to_destination < STOP_DISTANCE:
		sprite.rotation = 0.0
		tree.travel("Fly_Idle")
	#if not, we're flying. These angles are all kinds of dumb and need cleaning
	else:
		if real_direction.x < 0.0:
			sprite.rotation = (real_direction * -1.0).angle()
		else:
			sprite.rotation = real_direction.angle()
		tree.travel("Fly_horiz")
		
	label.text = "X: " +  str(flying_direction.y) + ", Y: " + str(flying_direction.y)
	
	#I left this in from lick's code, too. It can be updated to have the bird bounce around
	# Since the target doesn't move, the bird will keep trying to fly at it.
	var collision: KinematicCollision2D = move_and_collide(velocity)
	if collision:
		velocity.x = -velocity.x / 2

func _process(_delta):
	pressed_jump = Input.is_action_just_pressed("ui_accept")
	
	if not playing and pressed_jump:
		playing = true
