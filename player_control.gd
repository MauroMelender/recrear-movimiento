extends Node

@onready var player: Player = self.owner 
@onready var anim_player: AnimationPlayer = player.get_node("AnimationPlayer")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_direction: float = 1.0 # Empezamos mirando a la derecha
var is_wall_jumping: bool = false

enum STATE { IDLE, RUNNING, JUMPING, FALLING, WALL_SLIDING }
var current_state: STATE = STATE.IDLE

func _physics_process(delta: float):
	if player == null: return 

	# --- 1. CAPTURA DE INPUT ---
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

	# --- 2. LÓGICA DE TRANSICIÓN DE ESTADOS (Evita reinicio de animaciones) ---
	match current_state:
		STATE.IDLE:
			if not player.is_on_floor():
				current_state = STATE.FALLING
			elif Input.is_action_just_pressed("ui_up"):
				player.velocity.y = player.jump_velocity
				current_state = STATE.JUMPING
			elif input_dir != 0:
				current_state = STATE.RUNNING

		STATE.RUNNING:
			if not player.is_on_floor():
				current_state = STATE.FALLING
			elif Input.is_action_just_pressed("ui_up"):
				player.velocity.y = player.jump_velocity
				current_state = STATE.JUMPING
			elif input_dir == 0 and abs(player.velocity.x) < 10.0:
				current_state = STATE.IDLE

		STATE.JUMPING:
			if player.is_on_floor():
				current_state = STATE.IDLE if input_dir == 0 else STATE.RUNNING
			elif player.is_on_wall() and input_dir != 0:
				current_state = STATE.WALL_SLIDING
			elif player.velocity.y >= 0:
				current_state = STATE.FALLING

		STATE.FALLING:
			if player.is_on_floor():
				current_state = STATE.IDLE if input_dir == 0 else STATE.RUNNING
			elif player.is_on_wall() and input_dir != 0:
				current_state = STATE.WALL_SLIDING
			elif player.velocity.y < 0:
				current_state = STATE.JUMPING

		STATE.WALL_SLIDING:
			if player.is_on_floor():
				current_state = STATE.IDLE
			elif not player.is_on_wall():
				current_state = STATE.FALLING

	# --- 3. FÍSICA HORIZONTAL (Tu lógica original de impulso e inercia) ---
	var target_vel_x = input_dir * player.running_speed
	var accel = 0.0
	
	if player.is_on_floor():
		accel = player.acceleration
		is_wall_jumping = false 
	else:
		if input_dir != 0:
			accel = player.air_acceleration * (0.1 if is_wall_jumping else 1.0)
		else:
			accel = 0.0 if is_wall_jumping else player.air_friction 

	player.velocity.x = lerp(player.velocity.x, target_vel_x, accel * delta)

	# --- 4. EJECUCIÓN DE ANIMACIONES Y MECÁNICAS DE ESTADO ---
	match current_state:
		STATE.IDLE:
			play_anim("idle_r" if last_direction > 0 else "idle_l")

		STATE.RUNNING:
			play_anim("run_r" if input_dir > 0 else "run_l")

		STATE.JUMPING:
			var jump_dir = input_dir if input_dir != 0 else last_direction
			play_anim("jump_r" if jump_dir > 0 else "jump_l")
			# Variable Jump Height (Salto corto)
			if Input.is_action_just_released("ui_up") and player.velocity.y < 0:
				player.velocity.y *= 0.5
		
		STATE.FALLING:
			var fall_dir = input_dir if input_dir != 0 else last_direction
			play_anim("falling_r" if fall_dir > 0 else "falling_l")

		STATE.WALL_SLIDING:
			var wall_normal = player.get_wall_normal()
			if wall_normal.x > 0:
				play_anim("wall_slide_l")
				last_direction = -1.0
			else:
				play_anim("wall_slide_r")
				last_direction = 1.0

			# Gravedad reducida en pared
			if player.velocity.y < 0: player.velocity.y = 0
			player.velocity.y = min(player.velocity.y, player.wall_slide_gravity)
			
			# Lógica de Wall Jump (Impulso recuperado)
			if Input.is_action_just_pressed("ui_up"):
				player.velocity.x = wall_normal.x * player.wall_jump_pushback
				player.velocity.y = player.wall_jump_force
				is_wall_jumping = true
				last_direction = wall_normal.x
				current_state = STATE.JUMPING # Transición inmediata para la animación

	handle_gravity(delta)
	player.move_and_slide()

# FUNCIÓN PARA EVITAR CONGELACIÓN
func play_anim(anim_name: String):
	if anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			print("Cambiando a: ", anim_name) # <--- AÑADE ESTO
			anim_player.play(anim_name)

func handle_gravity(delta):
	if not player.is_on_floor():
		if current_state == STATE.WALL_SLIDING:
			player.velocity.y += (gravity * 0.2) * delta
		else:
			player.velocity.y += gravity * delta
	else:
		if player.velocity.y > 0:
			player.velocity.y = 0
