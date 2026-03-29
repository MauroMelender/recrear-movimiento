extends Node

@onready var player: Player = self.owner 

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_direction: float = 0.0
var is_wall_jumping: bool = false

enum STATE { IDLE, RUNNING, JUMPING, WALL_SLIDING }
var current_state: STATE = STATE.IDLE

func _physics_process(delta: float):
	if player == null: return 

	# --- 1. LÓGICA DE DIRECCIÓN ---
	var input_dir = 0.0
	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	
	if left and right:
		if Input.is_action_just_pressed("ui_right"): last_direction = 1.0
		elif Input.is_action_just_pressed("ui_left"): last_direction = -1.0
		input_dir = last_direction
	elif left: 
		input_dir = -1.0
		last_direction = -1.0
	elif right: 
		input_dir = 1.0
		last_direction = 1.0
	
	if input_dir != 0:
		player.set_facing_direction(input_dir)

	# --- 2. RESET DE ESTADO AL TOCAR SUELO ---
	if player.is_on_floor():
		is_wall_jumping = false 
		if input_dir != 0:
			current_state = STATE.RUNNING
		else:
			current_state = STATE.IDLE

	# --- 3. FÍSICA HORIZONTAL ---
	var target_vel_x = input_dir * player.running_speed
	var accel = 0.0
	
	if player.is_on_floor():
		# EN SUELO: Control total y frenado instantáneo
		accel = player.acceleration
		is_wall_jumping = false # Por seguridad, reseteamos aquí también
	else:
		# EN EL AIRE:
		if input_dir != 0:
			# Si el jugador pulsa una dirección:
			if is_wall_jumping:
				# Si venimos de un salto de pared, el control es MUY sutil (mucha inercia)
				accel = player.air_acceleration * 0.1 
				
				# Si el jugador insiste en ir hacia el lado contrario, 
				# eventualmente recupera el control normal
				if sign(input_dir) != sign(player.velocity.x):
					# Opcional: puedes quitar el is_wall_jumping aquí si quieres 
					# que el primer toque de tecla ya recupere el control
					pass 
			else:
				# Salto normal: Control aéreo estándar (se siente más firme)
				accel = player.air_acceleration
		else:
			# SI NO PULSA NADA:
			if is_wall_jumping:
				# Venimos de la pared: FRICCIÓN CERO (Parábola perfecta)
				accel = 0.0 
			else:
				# Salto normal: Aplicamos la fricción que tengas en el player
				# (Sugerencia: ponle un valor como 2.0 o 5.0 para que se detenga)
				accel = player.air_friction 

	# APLICAR EL MOVIMIENTO
	if accel > 0:
		player.velocity.x = lerp(player.velocity.x, target_vel_x, accel * delta)
	else:
		# Si accel es 0 (Inercia pura), no tocamos la velocidad X
		pass

	# --- 4. MÁQUINA DE ESTADOS ---
	match current_state:
		STATE.IDLE:
			player.play_animation("idle")
			if input_dir != 0:
				current_state = STATE.RUNNING
			elif Input.is_action_just_pressed("ui_up"):
				player.velocity.y = player.jump_velocity
				current_state = STATE.JUMPING

		STATE.RUNNING:
			player.play_animation("run")
			if Input.is_action_just_pressed("ui_up"):
				player.velocity.y = player.jump_velocity
				current_state = STATE.JUMPING
			elif input_dir == 0 and abs(player.velocity.x) < 1.0:
				current_state = STATE.IDLE

		STATE.JUMPING:
			player.play_animation("jump")
			
			# --- DETECCIÓN AUTOMÁTICA DE PARED ---
			# Si el personaje está tocando una pared (is_on_wall) 
			# Y está cayendo (velocity.y > 0)
			# SE PEGA SOLO, sin importar el input_dir
			if player.is_on_wall() and not player.is_on_floor() and player.velocity.y > 0:
				# Opcional: Detenemos la velocidad X para que se "pegue" visualmente
				player.velocity.x = 0 
				current_state = STATE.WALL_SLIDING

		STATE.WALL_SLIDING:
			player.play_animation("wall_slide")
			player.velocity.y = min(player.velocity.y, player.wall_slide_gravity)
			
			# 1. OBTENER LA NORMAL DE LA PARED (Hacia dónde apunta el "aire")
			var wall_normal = player.get_wall_normal()
			
			# 2. PERMITIR DESPEGARSE MOVIÉNDOSE
			# Si el jugador presiona la dirección opuesta a la pared (ej: pared a la izq, pulsa derecha)
			if input_dir != 0 and sign(input_dir) == sign(wall_normal.x):
				# Le damos una velocidad inicial pequeña para separarlo de la colisión
				player.velocity.x = input_dir * (player.running_speed * 0.5)
				current_state = STATE.JUMPING
			else:
				# Si no intenta despegarse, mantenemos la velocidad X en 0 para que siga pegado
				player.velocity.x = 0

			# 3. SALTO DESDE LA PARED (Mantenemos tu lógica de salto)
			if Input.is_action_just_pressed("ui_up"):
				player.velocity.x = wall_normal.x * player.wall_jump_pushback
				player.velocity.y = player.wall_jump_force
				is_wall_jumping = true
				current_state = STATE.JUMPING
			
			# 4. SALIR SI SE ACABA LA PARED O TOCA EL SUELO
			if not player.is_on_wall() or player.is_on_floor():
				current_state = STATE.JUMPING

	handle_gravity(delta)
	player.move_and_slide()

func handle_gravity(delta):
	if not player.is_on_floor():
		if current_state == STATE.WALL_SLIDING:
			player.velocity.y += (gravity * 0.2) * delta
		else:
			player.velocity.y += gravity * delta
	else:
		if player.velocity.y > 0:
			player.velocity.y = 0
