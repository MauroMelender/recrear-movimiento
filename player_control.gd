extends Node

@onready var player: Player = self.owner 

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum STATE { IDLE, RUNNING, JUMPING }
var current_state: STATE = STATE.IDLE

func _physics_process(delta: float):
	if player == null: return 

	# --- NUEVA LÓGICA DE DIRECCIÓN ---
	var input_dir = 0.0
	
	# Comprobamos qué teclas están siendo presionadas
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	
	if left and right:
		# Si ambas están presionadas, priorizamos la que se presionó ÚLTIMA
		if Input.is_action_just_pressed("ui_left"):
			input_dir = -1.0
		elif Input.is_action_just_pressed("ui_right"):
			input_dir = 1.0
		else:
			# Si ya estaban ambas hundidas, mantenemos la dirección actual basada en la velocidad
			input_dir = sign(player.velocity.x) if player.velocity.x != 0 else (1.0 if Input.is_action_just_released("ui_left") else -1.0)
	elif left:
		input_dir = -1.0
	elif right:
		input_dir = 1.0
	# ---------------------------------

	# Actualizar giro del sprite
	if input_dir != 0:
		player.set_facing_direction(input_dir)

	match current_state:
		STATE.IDLE:
			player.velocity.x = 0
			player.play_animation("idle")
			if input_dir != 0:
				current_state = STATE.RUNNING
			elif Input.is_action_just_pressed("ui_up") and player.is_on_floor():
				player.velocity.y = player.jump_velocity
				current_state = STATE.JUMPING

		STATE.RUNNING:
			# Forzamos la velocidad máxima siempre que haya una dirección
			player.velocity.x = input_dir * player.running_speed
			player.play_animation("run")
			
			if Input.is_action_just_pressed("ui_up") and player.is_on_floor():
				player.velocity.y = player.jump_velocity
				current_state = STATE.JUMPING
			elif input_dir == 0:
				current_state = STATE.IDLE

		STATE.JUMPING:
			player.velocity.x = input_dir * player.running_speed
			player.play_animation("jump")
			
			if Input.is_action_just_released("ui_up") and player.velocity.y < 0:
				player.velocity.y *= 0.5
				
			if player.is_on_floor() and player.velocity.y >= 0:
				current_state = STATE.RUNNING if input_dir != 0 else STATE.IDLE

	handle_gravity(delta)
	player.move_and_slide()

func handle_gravity(delta):
	if not player.is_on_floor():
		player.velocity.y += gravity * delta
