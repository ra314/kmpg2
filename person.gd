extends Node2D
class_name Person

const PERSON := preload("res://person.tscn")
const SCREEN_SIZE := Vector2(1920, 1080)
const MAX_SPEED := 200
const NON_RAND_SPEED := 100
var RNG := RandomNumberGenerator.new()

var velocity := Vector2(0,0)
var target_location = null
var huddle: Huddle
const HUDDLE_COOLDOWN := 5
var can_huddle := true

static func neww() -> Person:
	return PERSON.instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = random_vec(0, SCREEN_SIZE.x, 0, SCREEN_SIZE.y)
	velocity = random_velocity()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var new_position = position + (velocity*delta)
	if target_location != null:
		if new_position.distance_to(target_location) < position.distance_to(target_location):
			position = new_position
	else:
		position = new_position
	if is_out_of_bounds(position):
		bounce_off_wall()

func is_out_of_bounds(pos: Vector2) -> bool:
	return pos.x < 0 or pos.y < 0 or pos.x > SCREEN_SIZE.x or pos.y > SCREEN_SIZE.y

func bounce_off_wall():
	velocity = Vector2.ZERO
	while is_out_of_bounds(position+velocity):
		velocity = random_velocity()

func random_velocity() -> Vector2:
	return random_vec(-MAX_SPEED, MAX_SPEED, -MAX_SPEED, MAX_SPEED)

func random_vec(x1, x2, y1, y2) -> Vector2:
	return Vector2(RNG.randi_range(x1, x2), RNG.randi_range(y1, y2))

# Move to the target location with the same velocity magnitude
func move_to_location(location:Vector2) -> void:
	velocity = position.direction_to(location)*NON_RAND_SPEED
	target_location = location

func disband() -> void:
	target_location = null
	velocity = huddle.center.direction_to(position)*(NON_RAND_SPEED)
	huddle = null
	can_huddle = false
	get_tree().create_timer(HUDDLE_COOLDOWN).timeout.connect(reset_can_huddle)

func reset_can_huddle() -> void:
	can_huddle = true
