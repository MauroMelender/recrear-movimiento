extends CharacterBody2D
class_name Player

@onready var sprite = $AnimatedSprite2D # Asegúrate que el nombre coincida
@export var running_speed: float = 300.0
@export var jump_velocity: float = -400.0

func play_animation(anim_name: String):
	# Verificamos si la animación existe en los "SpriteFrames"
	if sprite.sprite_frames.has_animation(anim_name):
		# Solo reproducir si no es la que ya está sonando
		if sprite.animation != anim_name:
			sprite.play(anim_name)
	else:
		# Esto saldrá en la consola si escribes mal el nombre en el otro script
		print("OJO: La animación '", anim_name, "' no existe en tu AnimatedSprite2D")

const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
