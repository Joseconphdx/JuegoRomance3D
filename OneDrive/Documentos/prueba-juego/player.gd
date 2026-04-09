extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const ROTATION_SPEED = 10.0

var gravity = 9.8
var interacting = false

@onready var visual_mesh = $VisualMesh
@onready var spring_arm = $SpringArm3D
@onready var interaction_ray = $SpringArm3D/Camera3D/InteractionRay

@onready var interact_hint = $UI/InteractHint
@onready var dialogue_panel = $UI/DialoguePanel
@onready var dialogue_text = $UI/DialoguePanel/DialogueText

var current_interactable = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if interacting:
		if event is InputEventKey and event.pressed and event.keycode == KEY_E:
			close_dialogue()
		return

	if event is InputEventMouseMotion:
		spring_arm.rotate_y(-event.relative.x * SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x - event.relative.y * SENSITIVITY, deg_to_rad(-80), deg_to_rad(45))
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif event.keycode == KEY_E and current_interactable != null:
			open_dialogue(current_interactable.get_meta("dialogue", "No hay nada que decir."))

func _physics_process(delta):
	# Añadir la gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	if interacting:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	check_interactions()

	# Salto
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Input
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	# La direccion relativa a la camara
	var camera_basis = spring_arm.global_transform.basis
	var direction = (camera_basis * Vector3(input_dir.x, 0, input_dir.y))
	direction.y = 0
	direction = direction.normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotar la malla visible hacia donde se mueve
		var look_dir = atan2(velocity.x, velocity.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, look_dir, delta * ROTATION_SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func check_interactions():
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider is Area3D and collider.has_meta("dialogue"):
			current_interactable = collider
			interact_hint.visible = true
			return
	
	current_interactable = null
	interact_hint.visible = false

func open_dialogue(text: String):
	interacting = true
	interact_hint.visible = false
	dialogue_panel.visible = true
	dialogue_text.text = text

func close_dialogue():
	interacting = false
	dialogue_panel.visible = false
