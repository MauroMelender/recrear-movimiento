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
			player.play_animation("idle")
			
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				current_state = STATE.RUNNING
			elif Input.is_action_just_pressed("ui_up") and player.is_on_floor():
				# APLICAMOS EL IMPULSO AQUÍ
				player.velocity.y = player.jump_velocity 
				current_state = STATE.JUMPING

		STATE.RUNNING:
			var input_dir = Input.get_axis("ui_left", "ui_right")
			
			# Flip
			if input_dir != 0:
				player.set_facing_direction(input_dir)
			
			player.velocity.x = input_dir * player.running_speed
			player.play_animation("run")
			
			if Input.is_action_just_pressed("ui_up") and player.is_on_floor():
				# APLICAMOS EL IMPULSO AQUÍ TAMBIÉN
				player.velocity.y = player.jump_velocity
				current_state = STATE.JUMPING
			elif input_dir == 0:
				current_state = STATE.IDLE

		STATE.JUMPING:
			player.play_animation("jump")
			
			# Salto Variable
			if Input.is_action_just_released("ui_up") and player.velocity.y < 0:
				# Velocidad de Frenado 
				player.velocity.y *= 0.4 

			# 2. Movimiento lateral en el aire
			var input_dir = Input.get_axis("ui_left", "ui_right")
			player.velocity.x = input_dir * player.running_speed
			if input_dir != 0:
				player.set_facing_direction(input_dir)

			# Si toca el suelo
			if player.is_on_floor() and player.velocity.y >= 0:
				if input_dir != 0:
					current_state = STATE.RUNNING
				else:
					current_state = STATE.IDLE

			# CONDICIÓN DE SALIDA: Si toca el suelo y está cayendo (velocity.y >= 0)
			if player.is_on_floor() and player.velocity.y >= 0:
				if Input.get_axis("ui_left", "ui_right") != 0:
					current_state = STATE.RUNNING
				else:
					current_state = STATE.IDLE

	# Aplicar gravedad siempre que no esté en el suelo
	handle_gravity(delta)
	
	# ¡IMPORTANTE! Esta línea hace que el personaje realmente se mueva
	player.move_and_slide()

func handle_gravity(delta):
	if not player.is_on_floor():
		player.velocity.y += gravity * delta
