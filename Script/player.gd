extends CharacterBody3D


const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.004

# Head bob
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob: float = 0.0

# FOV
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var speed: float = WALK_SPEED
var camera_base_pos: Vector3

# Item yang sudah diambil (disimpan ke save file)
var collected_items: Array = []

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var interact_label = get_node_or_null("UI/InteractLabel")


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_base_pos = camera.transform.origin
	ray.add_exception(self)
	ray.target_position = Vector3(0, 0, -3)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

	# Save / load
	if event is InputEventKey and event.pressed and not event.echo:
		var save_manager = get_node_or_null("/root/SaveManager")
		if save_manager == null:
			push_error("SaveManager tidak ditemukan, cek Autoload di Project Settings")
			return
		if event.keycode == KEY_F5:
			save_manager.save_game()
		elif event.keycode == KEY_F9:
			save_manager.load_game()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction: Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = camera_base_pos + _headbob(t_bob)

	# FOV
	var velocity_clamped: float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov: float = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

	# Raycast interaction
	_check_interaction()


func _headbob(time: float) -> Vector3:
	var pos := Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


# ===== Raycasting =====

func _check_interaction() -> void:
	var target = null

	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider != null and collider.has_method("interact"):
			target = collider

	if interact_label != null:
		if target != null:
			interact_label.text = target.get_prompt()
		else:
			interact_label.text = ""

	if target != null and Input.is_action_just_pressed("interact"):
		target.interact(self)


func collect_item(item_id: String) -> void:
	if not collected_items.has(item_id):
		collected_items.append(item_id)
	print("Item diambil: ", item_id, " | Total: ", collected_items.size())


# ===== Save / Load =====

func get_save_data() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y, global_position.z],
		"head_rot_y": head.rotation.y,
		"camera_rot_x": camera.rotation.x,
		"collected_items": collected_items
	}


func load_save_data(data: Dictionary) -> void:
	var p: Array = data["position"]
	global_position = Vector3(p[0], p[1], p[2])
	head.rotation.y = data["head_rot_y"]
	camera.rotation.x = data["camera_rot_x"]
	velocity = Vector3.ZERO

	collected_items = data.get("collected_items", [])
	for pickup in get_tree().get_nodes_in_group("pickup"):
		pickup.set_collected(collected_items.has(pickup.item_id))
