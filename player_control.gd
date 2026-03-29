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
var last_direction: float = 0.0 # <--- ESTA ES LA LÍNEA QUE FALTA

var current_state: STATE = STATE.IDLE

func _physics_process(delta: float):
	if player == null: return 

	# 1. DECLARACIÓN ÚNICA (Solo una vez aquí arriba)
	var input_dir = 0.0
	
	# Lógica de anulación/prioridad
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	
	if left and right:
		if Input.is_action_just_pressed("ui_right"):
			last_direction = 1.0
		elif Input.is_action_just_pressed("ui_left"):
			last_direction = -1.0
		input_dir = last_direction
	elif left:
		input_dir = -1.0
	elif right:
		input_dir = 1.0
	# Si no hay nada presionado, input_dir se queda en 0.0

	# Actualizar giro del sprite
	if input_dir != 0:
		player.set_facing_direction(input_dir)

	# 2. USO DE LA VARIABLE (Sin la palabra 'var')
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
			# NOTA: Aquí ya NO ponemos 'var', solo usamos el valor
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
				if input_dir != 0:
					current_state = STATE.RUNNING
				else:
					current_state = STATE.IDLE

	handle_gravity(delta)
	player.move_and_slide()

func handle_gravity(delta):
	if not player.is_on_floor():
		player.velocity.y += gravity * delta
