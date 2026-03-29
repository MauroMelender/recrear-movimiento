extends Node

@onready var player:Player = self.owner 


var gravity:float = ProyectSettings.get_settings("physics/2d/default_gravity")

enum STATE {
	IDLE,
	RUNNING,
	JUMPING,
	CROUCHED
}

var current_state:STATE = STATE.IDLE

func _physics_process(delta)
	match current_state:
		STATE.IDLE
			player.velocity.x = 0
			player.play_animation(player.animation.idle)
			if Imput.is_action_pressed("ui_left") or Imput.is_action_pressed("ui_right"):
				current_state = STATE.RUNNING
			elif Imput.is_action_pressed("ui_up"):
				current.state = STATE.JUMPING
		STATE.RUNNING
			player.velocity.x = Imput.get_axis("ui_left" , "ui_right") + player.movement_stats.running_speed
			player.play_animation(player.animation.running)
			if Imput.is_action_pressed("ui_up"):
				current.state = STATE.JUMPING
			if not Imput.is_action_pressed("ui_left") and not Imput.is_action_pressed("ui_right"):
				current_state = STATE.RUNNING
		STATE.JUMPING
			player.velocity.x = player.movement_stats.jump_speed
			if player.is_on_floor():
				current_state = STATE.IDLE
		STATE.CROUCHED
			pass
	handle_gravity(delta)
	12	
