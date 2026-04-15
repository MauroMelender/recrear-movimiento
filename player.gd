extends CharacterBody2D
class_name Player

@export var running_speed: float = 400.0
@export var jump_velocity: float = -500.0
@export var acceleration: float = 10.0
@export var air_acceleration: float = 2.0
@export var air_friction: float = 0.0 # <--- Asegúrate que sea 0
@export var wall_jump_pushback: float = 600.0
@export var wall_jump_force: float = -600.0
@export var wall_slide_gravity: float = 150.0

# NO pongas lógica de movimiento aquí dentro de _physics_process
# Deja que el PlayerControl se encargue de modificar la 'velocity'
func _physics_process(_delta):
	pass 

func set_facing_direction(dir: float):
	# Usamos el nombre exacto del nodo: AnimatedSprite2D
	if $AnimatedSprite2D: 
		if dir > 0:
			$AnimatedSprite2D.flip_h = true
		elif dir < 0:
			$AnimatedSprite2D.flip_h = false
	else:
		print("Aalgo anda mal aca otra vez AnimatedSprite2D")


func play_animation(anim_name: String):
	# Para AnimatedSprite2D se usa .animation y .play()
	if $AnimatedSprite2D.animation != anim_name:
		$AnimatedSprite2D.play(anim_name)
