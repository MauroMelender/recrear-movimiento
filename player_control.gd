extends Node

# El Player tenia que tener: class_name Player
@onready var player: Player = self.owner 

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum STATE {
	IDLE,
	RUNNING,
	JUMPING,
	CROUCHED
}

var current_state: STATE = STATE.IDLE

func _physics_process(delta: float): 
	match current_state:
		STATE.IDLE: 
			player.velocity.x = 0
			player.play_animation(player.animation.idle)
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				current_state = STATE.RUNNING
			elif Input.is_action_just_pressed("ui_up"):
				current_state = STATE.JUMPING

		STATE.RUNNING:
			player.velocity.x = Input.get_axis("ui_left", "ui_right") + player.movement_stats.running_speed
			player.play_animation(player.animation.running)
			
			if Input.is_action_pressed("ui_up"):
				current_state = STATE.JUMPING	
			elif not Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
				current_state = STATE.IDLE 

		STATE.JUMPING:
			if player.is_on_floor():
				current_state = STATE.IDLE
		
		STATE.CROUCHED:
			pass
			
	player.move_and_slide() 

func handle_gravity(delta):
	if not player.is_on_floor():
		player.velocity.y += gravity * delta
