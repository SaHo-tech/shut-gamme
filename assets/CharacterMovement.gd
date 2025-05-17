extends CharacterBody3D

var double_jump_available = true
var is_crouching = false
var is_sliding = false
var is_sprinting = false
var is_moving = false

var slide_timer = 0.0
const SLIDE_DURATION = 1.5   # In seconds

@export var speed = 5.0
@export var jump_velocity = 6.0
@export var slide_velocity = 12.0
const DEFAULT_SPEED = 5.0
const SENSITIVITY = 0.003

@export var crouch_height = 1.0
@export var crouch_transition = 8.0

var stand_height : float

var sprint_speed = 8.0
var move_lerp_speed = 5.0
var crouch_speed = 3.0
var crouch_lerp_speed = 5.0
var slide_lerp_speed = 5.0

# Headbob variables
const BOB_FREQ = 2.5
const BOB_AMP = 0.055
var t_bob = 0.0

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var body = $CollisionShape3D
@onready var player_controller = $"."


func _ready() -> void:
	stand_height = body.shape.height
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		player_controller.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta: float) -> void:
	# Add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not is_on_floor() and is_sprinting:
		speed = sprint_speed
	
	if is_on_floor():
		double_jump_available = true

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle double jump.
	if Input.is_action_just_pressed("jump") and not is_on_floor() and double_jump_available:
		velocity.y = jump_velocity
		double_jump_available = false
	
	# Handle sprint.
	if Input.is_action_pressed("sprint") and is_on_floor() and not is_crouching:
		speed = sprint_speed
		is_sprinting = true
	if Input.is_action_just_released("sprint") and not is_crouching:
		speed = 5.0
		is_sprinting = false
	
	# Handle sliding
	if Input.is_action_just_pressed("crouch") and is_moving and is_sprinting and not is_sliding:
		is_sliding = true
		slide_timer = SLIDE_DURATION
		velocity = velocity.normalized() * slide_velocity
		speed = slide_velocity
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			is_sliding = false
			speed = DEFAULT_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (player_controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and is_on_floor() and not is_sliding:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		is_moving = true
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, 1.0 - exp(-move_lerp_speed * delta))
		velocity.z = lerp(velocity.z, direction.z * speed, 1.0 - exp(-move_lerp_speed * delta))
		is_moving = false
	
	
	
		# Handles input for crouching.
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		crouch()
	else:
		is_crouching = false
		crouch(true)
	
	 #Handles crouching speed
	if is_crouching:
		speed = crouch_speed
	else:
		speed = DEFAULT_SPEED
	
	
	# Headbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	return pos


# Crouch function that makes the player stand if reverse is true
func crouch(reverse = false):
	var target_height : float = crouch_height if not reverse else stand_height
	
	
	body.shape.height = target_height
	body.position.y = target_height * 0.5
	head.position.y = target_height



func _process(delta: float) -> void:
	pass
