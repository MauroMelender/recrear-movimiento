extends CharacterBody2D
class_name Player

@onready var sprite = $AnimationPlayer # Asegúrate que el nombre coincida
@export var running_speed: float = 300.0 
@export var jump_velocity: float = -400.0 # Ya que estás, puedes exportar el salto

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func play_animation(anim_name: String): #Caja vacia, se rellena en Player control segun el STATE
	if anim_player.has_animation(anim_name) and anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

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
