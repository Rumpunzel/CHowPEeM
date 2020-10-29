extends KinematicBody2D

signal divebombforce_updated(force)

const THRESHOLD_VELOCITY = 40.0
const MAX_DIVEBOMB_FORCE = 35.0

export (int) var max_speed = 200
export (int) var acceleration = 800
export (float) var drag = 0.05

var direction: Vector2 = Vector2()
var velocity: Vector2 = Vector2()
var flying: bool = false
var is_facing_left: bool = false
var charging_divebomb: bool = false
var charging_divebomb_speed: float = 30.0
var divebomb_force: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO

onready var playback: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")
onready var sprite: Sprite = $BirdSprite

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
	charging_divebomb = Input.is_action_pressed("charge_divebomb") #space bar


func _ready():
	playback.start("Idle")


func _process(_delta):
	if _is_landing():
		flying = false
		playback.travel("Idle")
		
	if _is_starting_flying():
		flying = true
		playback.travel("Fly")


func _is_landing():
	return velocity.length() < THRESHOLD_VELOCITY and flying


func _is_starting_flying():
	return velocity.length() > THRESHOLD_VELOCITY and not flying


func _physics_process(delta):
	get_input()
	
	if charging_divebomb and direction.y > 0:
		#"VISUAL CUE NEEDED! For now some stupid ass icon
		$ChargingIndicator.visible = true
		$ChargingIndicator.rotation_degrees += delta * 1000.0
		var delta_force = delta * charging_divebomb_speed
		divebomb_force = clamp(divebomb_force + delta_force, 0, MAX_DIVEBOMB_FORCE)
	if not charging_divebomb:
		$ChargingIndicator.visible = false
	
	
	# dive bomb movement
	if divebomb_force > 0.01 and not charging_divebomb:
		velocity += direction * acceleration * delta * (divebomb_force)
		divebomb_force /= 1.5
	# usual movement
	else:
		velocity += direction * acceleration * delta
		if velocity.length() > max_speed:
			velocity = direction * max_speed
	
	var dash_dir: Vector2 = Vector2.ZERO
	if Input.is_action_just_pressed("dash_right"):
		dash_dir = Vector2.RIGHT
	if Input.is_action_just_pressed("dash_left"):
		dash_dir = Vector2.LEFT
		
	if dash_velocity.length() <= 0.01:
		$Tween.interpolate_property(self, "dash_velocity", dash_dir * 500, Vector2.ZERO, 0.4, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$Tween.start()
	velocity += dash_velocity
	
	velocity = move_and_slide(velocity)
	_change_direction_of_sprite()
	_rotate_sprite()
	_slow_down_or_stop_entirely()
	
	emit_signal("divebombforce_updated", divebomb_force)



func _slow_down_or_stop_entirely():
	if velocity.length() < 0.1:
		velocity = Vector2.ZERO
	else:
		velocity *= 1 - drag


func _change_direction_of_sprite():
	# is_facing_left is used to determine rotation of sprite
	# avoid changes on 0 to maintain current direction while diving, or going up!
	if velocity.x > 0:
		is_facing_left = false
	elif velocity.x < 0:
		is_facing_left = true
	sprite.flip_h = is_facing_left


func _rotate_sprite():
	if flying:
		var raw_direction = Vector2.RIGHT if not is_facing_left else Vector2.LEFT
		var degrees = rad2deg(velocity.angle_to(raw_direction))
		sprite.rotation_degrees = -degrees
	else:
		sprite.rotation_degrees = 0.0
	
