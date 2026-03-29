extends Node

# Esta es la referencia al CharacterBody2D (el Player)
@onready var player: Player = self.owner 

# Obtener la gravedad del proyecto correctamente
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum STATE {
	IDLE,
	RUNNING,
	JUMPING
}

var current_state: STATE = STATE.IDLE

func _physics_process(delta: float):
	# Seguridad: si no encuentra al jugador, no hace nada para no dar error
	if player == null: 
		return 

	match current_state:
		STATE.IDLE:
			player.velocity.x = 0
			player.play_animation("idle") # Asegúrate que en AnimationPlayer se llame "idle"
			
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				current_state = STATE.RUNNING
			elif Input.is_action_just_pressed("ui_up") and player.is_on_floor():
				current_state = STATE.JUMPING

		STATE.RUNNING:
			var input_dir = Input.get_axis("ui_left", "ui_right")
			# Usamos la variable @export que creamos en el Player
			player.velocity.x = input_dir * player.running_speed
			player.play_animation("run") # Asegúrate que en AnimationPlayer se llame "run"
			
			if Input.is_action_just_pressed("ui_up") and player.is_on_floor():
				current_state = STATE.JUMPING
			elif input_dir == 0:
				current_state = STATE.IDLE

		STATE.JUMPING:
			# Aplicamos el impulso del salto (variable @export del Player)
			if player.is_on_floor():
				player.velocity.y = player.jump_velocity
			
			if player.is_on_floor() and player.velocity.y >= 0:
				current_state = STATE.IDLE

	# Aplicar gravedad siempre que no esté en el suelo
	handle_gravity(delta)
	
	# ¡IMPORTANTE! Esta línea hace que el personaje realmente se mueva
	player.move_and_slide()

func handle_gravity(delta):
	if not player.is_on_floor():
		player.velocity.y += gravity * delta
