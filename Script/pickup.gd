extends StaticBody3D


@export var item_name: String = "Koin"
@export var item_id: String = ""
@export var spin_speed: float = 2.0

var collected: bool = false


func _ready() -> void:
	add_to_group("pickup")
	if item_id == "":
		item_id = name


func _process(delta: float) -> void:
	if not collected:
		rotate_y(spin_speed * delta)


func get_prompt() -> String:
	return "[E] Ambil " + item_name


func interact(player) -> void:
	if collected:
		return
	player.collect_item(item_id)
	set_collected(true)


func set_collected(value: bool) -> void:
	collected = value
	visible = not value
	$CollisionShape3D.set_deferred("disabled", value)
