extends Node

var player: Player
var anim_player: AnimationPlayer
var anim_sprite: AnimatedSprite2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_direction: float = 1.0
var is_wall_jumping: bool = false
var previous_state: STATE = STATE.IDLE

enum STATE { IDLE, RUNNING, JUMPING, FALLING, WALL_SLIDING }
var current_state: STATE = STATE.IDLE

# Polvo - ASIGNAR EN EL INSPECTOR (Nodo par_vfx_dust)
@export var vfx_dust: CPUParticles2D

func _ready():
	player = self.owner as Player
	if player:
		anim_player = player.get_node("AnimationPlayer")
		anim_sprite = player.get_node("AnimatedSprite2D")
		
		# Conectamos la señal. Asegúrate de que el AnimatedSprite2D tenga frames.
		if anim_sprite:
			anim_sprite.frame_changed.connect(_on_frame_changed)
	else:
		print("ERROR: player es null en el script de control")

func _on_frame_changed():
	if anim_sprite.animation == "run":
		if anim_sprite.frame in [2, 6]:
			# Usamos last_direction para que el 40 sea positivo o negativo
			# Si last_direction es 1.0, X será 40. Si es -1.0, X será -40.
			var offset_x = 40.0 * last_direction
			var offset_y = 65.0
			
			vfx_dust.position = Vector2(offset_x, offset_y)
			
				
			# 2. EMISIÓN CONTROLADA
			# NO usamos restart() porque borra las anteriores.
			# Simplemente activamos la emisión. 
			vfx_dust.emitting = true
			
			# Opcional: Si querés que tire "puchitos" exactos, 
			# podés crear un timer rápido para apagarlo:
			await get_tree().create_timer(0.01).timeout
			vfx_dust.emitting = false


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

	# --- 2. LÓGICA DE TRANSICIÓN ---
	var wall_sensor_distance = 8.0
	
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

		STATE.JUMPING, STATE.FALLING:
			if player.is_on_floor():
				current_state = STATE.IDLE if input_dir == 0 else STATE.RUNNING
			else:
				var check_dir = input_dir if input_dir != 0 else last_direction
				var collision_near = player.test_move(player.global_transform, Vector2(check_dir * wall_sensor_distance, 0))
				if collision_near and player.velocity.y > 0:
					current_state = STATE.WALL_SLIDING
				elif player.velocity.y >= 0:
					current_state = STATE.FALLING

		STATE.WALL_SLIDING:
			if player.is_on_floor():
				current_state = STATE.IDLE
			elif not player.is_on_wall() and not player.test_move(player.global_transform, Vector2(last_direction * wall_sensor_distance, 0)):
				current_state = STATE.FALLING

	# --- 3. FÍSICA HORIZONTAL ---
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

	# --- 4. ANIMACIONES ---
	var face_dir = input_dir if input_dir != 0 else last_direction
	anim_sprite.flip_h = face_dir > 0

	match current_state:
		STATE.IDLE:
			anim_sprite.position.x = face_dir * 4.0
			play_anim("idle")
		STATE.RUNNING:
			anim_sprite.position.x = face_dir * 0.0
			play_anim("run")
			# Volteo de partículas: Si el personaje mira a la izquierda, las partículas salen hacia la derecha
			if vfx_dust:
				vfx_dust.scale.x = -face_dir
		STATE.JUMPING:
			anim_sprite.position.x = face_dir * 4.0
			play_anim("jump")
		STATE.FALLING:
			anim_sprite.position.x = face_dir * 4.0
			play_anim("falling")
		STATE.WALL_SLIDING:
			var wall_normal = player.get_wall_normal()
			var side = wall_normal.x if player.is_on_wall() else -last_direction
			anim_sprite.flip_h = side < 0
			last_direction = side
			anim_sprite.position.x = side * 33.0
			play_anim("wall_slide")

	# --- 5. MECÁNICAS ---
	if current_state == STATE.JUMPING:
		if Input.is_action_just_released("ui_up") and player.velocity.y < 0:
			player.velocity.y *= 0.5

	if current_state == STATE.WALL_SLIDING:
		if player.velocity.y < 0: player.velocity.y = 0
		player.velocity.y = min(player.velocity.y, player.wall_slide_gravity)
		if Input.is_action_just_pressed("ui_up"):
			var wall_normal = player.get_wall_normal()
			var jump_side = wall_normal.x if player.is_on_wall() else -last_direction
			player.velocity.x = jump_side * player.wall_jump_pushback
			player.velocity.y = player.wall_jump_force
			is_wall_jumping = true
			last_direction = jump_side
			current_state = STATE.JUMPING

	previous_state = current_state
	handle_gravity(delta)
	player.move_and_slide()

func play_anim(anim_name: String):
	if anim_sprite == null: return
	if not anim_sprite.sprite_frames.has_animation(anim_name):
		return
	if anim_sprite.animation == anim_name and anim_sprite.is_playing():
		return
	anim_sprite.play(anim_name)
	if anim_player != null and anim_player.has_animation(anim_name):
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
