extends KinematicBody2D

onready var world = get_parent().get_parent()
onready var player = world.get_child(2)
onready var camera = player.get_child(9)

var id = 4
const CHOKE = 3

const GRAVITY = 700
const JUMP_STR = -250

var intro = true
var fill_bar = true

var state = 0
var spr_offset = Vector2()
var spr_shake = 0
var thrusters = false
var thr_strt = -1
var thr_frame = 0
var thr_delay = 0
var thr_state = -1

var turns = 0
var x_target = 0
var hits = 0
var drop_delay = 60
var shot_delay = 60
var shot_step = 0
var shots = 2

var velocity = Vector2()

var thrst_pos = {
	0 : Vector2(-1, 22),
	1 : Vector2(1, 22),
	2 : Vector2(0, 22),
	4 : Vector2(19, 2),
	5 : Vector2(-19, 2),
}

var thrst_data = {
	5 : [0, 0, Vector2(0, 22)],
	6 : [1, 0, Vector2(1, 22)],
	7 : [2, 0, Vector2(1, 22)],
	8 : [3, 0, Vector2(1, 22)],
	9 : [4, 0, Vector2(1, 22)],
	10 : [5, 4, Vector2(-19, 2)],
	12 : [6, 2, Vector2(1, 22)],
}

func _ready():
	$anim.play("fade_in")
	
	$sprite.flip_h = true
	
	turns = round(rand_range(2, 5))
	print(turns)
	

func _physics_process(delta):
	
	if state == 5 or state == 6:
		drop_delay -= 1
	
	match state:
		1:
			if $sprite.flip_h and global_position.x < camera.limit_right - 72:
				velocity.x = 200
			elif $sprite.flip_h and global_position.x >= camera.limit_right - 72:
				if velocity.x > 0:
					velocity.x -= 10
				else:
					$anim.play("turn_1")
					turns -= 1
					if turns > 0:
						state = 2
					else:
						if hits != 0:
							state = 4
						else:
							state = 10
			elif !$sprite.flip_h and global_position.x > camera.limit_left + 72:
				velocity.x = -200
			elif !$sprite.flip_h and global_position.x <= camera.limit_left + 72:
				if velocity.x < 0:
					velocity.x += 10
				else:
					$anim.play("turn_1")
					turns -= 1
					if turns > 0:
						state = 2
					else:
						if hits != 0:
							state = 4
						else:
							state = 10
		
		3:
			if $sprite.flip_h:
				if velocity.x < 200:
					velocity.x += 20
			else:
				if velocity.x > -200:
					velocity.x -= 20
			
			if velocity.x == -200 or velocity.x == 200:
				state = 1
				
		4:
			if global_position.y > camera.limit_bottom - 104:
				velocity.y -= GRAVITY * delta
			else:
				velocity = Vector2(0, 0)
				state = 5
				
		5:
			if player.global_position.x < global_position.x and $sprite.flip_h or player.global_position.x > global_position.x and !$sprite.flip_h:
				$anim.play("turn_2")
				state = 6
			
			if drop_delay <= 0:
				$anim.play("open")
				state = 7
		
		8:
			velocity.y += GRAVITY * delta
			
			if velocity.y > 0 and $anim.get_current_animation() == "rise":
				$anim.play("fall")
			
			if is_on_floor() and state == 8:
				world.shake = 12
				world.sound("wall_hit")
				state = 9
		
		10:
			shot_delay -= 1
			
			if shot_delay == 0:
				if shots > 0:
					if shot_step == 0:
						if shots > 1:
							var slow = load("res://scenes/bosses/def_bullet.tscn").instance()
							slow.type = 0
							if $sprite.flip_h:
								slow.velocity = Vector2(1, 0)
								slow.position.x = global_position.x + 3
							else:
								slow.velocity = Vector2(-1, 0)
								slow.position.x = global_position.x - 3
							slow.position.y = global_position.y + 8
							slow.speed = 125
							world.get_child(1).add_child(slow)
							print(slow.global_position,', ',global_position)
						else:
							var fast = load("res://scenes/bosses/def_bullet.tscn").instance()
							fast.type = 1
							if $sprite.flip_h:
								fast.velocity = Vector2(1, 0)
								fast.position.x = global_position.x + 3
							else:
								fast.velocity = Vector2(-1, 0)
								fast.position.x = global_position.x - 3
							fast.position.y = global_position.y + 8
							fast.speed = 250
							world.get_child(1).add_child(fast)
						$anim.play("open")
						shot_step += 1
						shot_delay = 15
						shots -= 1
					else:
						$anim.play("close")
						shot_step -= 1
						shot_delay = 30
				
				
	
	#Make the boss shake when her shields clang together.
	if spr_shake > 0:
		spr_offset = Vector2(rand_range(-2, 2), rand_range(-2, 2))
		$sprite.offset = spr_offset
		$thrusters/sprite.offset = $sprite.offset
		spr_shake -= 1
	
	if spr_shake == 0 and spr_offset != Vector2(0, 0):
		spr_offset = Vector2(0, 0)
		$sprite.offset = spr_offset
		$thrusters/sprite.offset = $sprite.offset
	
	#Add sound effect for the clang.
	if $sprite.frame == 8 and spr_shake == 0:
		world.sound("clang")
		spr_shake = 8
	
	#Display the thruster sprites appropriately.
	#Check sprite frame.
	if thrst_data.has($sprite.frame) and thrusters:
		#If frame is in dict, pull data and set frames.
		if thr_state != thrst_data.get($sprite.frame)[0]:
			if thr_strt != thrst_data.get($sprite.frame)[1]:
				thr_strt = thrst_data.get($sprite.frame)[1]
				$thrusters/sprite.frame = thr_strt
				thr_delay = 0
				thr_frame = 0
			if !$sprite.flip_h:
				$thrusters/sprite.position.x = -thrst_data.get($sprite.frame)[2].x
			else:
				$thrusters/sprite.position.x = thrst_data.get($sprite.frame)[2].x
			$thrusters/sprite.position.y = thrst_data.get($sprite.frame)[2].y
			if $sprite.frame == 10:
				$thrusters/sprite.flip_h = $sprite.flip_h
			else:
				$thrusters/sprite.flip_h = false
			$thrusters.show()
			thr_state = thrst_data.get($sprite.frame)[0]
	elif !thrst_data.has($sprite.frame) and thr_state != -1:
		$thrusters.hide()
		thr_state = -1
	
	#Animate the thrusters.
	if thrusters:
		thr_delay += 1
	
	if thr_delay > 3:
		thr_frame += 1
		
		if thr_frame > 1:
			thr_frame = 0
	
		$thrusters/sprite.frame = thr_strt + thr_frame
		thr_delay = 0
	
	velocity = move_and_slide(velocity, Vector2(0, -1))

func play_anim(anim):
	$anim.play(anim)

func _on_anim_finished(anim_name):
	match anim_name:
		"fade_in":
			thrusters = true
			world.boss = true
			world.play_music("boss")
			$anim.play("move_to")
			$tween.interpolate_property(self, "position", position, position + Vector2(-88, 64), 0.75, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$tween.start()
		
		"intro":
			world.fill_b_meter = true
		
		"close":
			if state == 0:
				$anim.play("fly")
				state = 3
		
		"turn_1":
			if state == 2:
				$anim.play("fly")
				if $sprite.flip_h:
					$sprite.flip_h = false
				else:
					$sprite.flip_h = true
				state = 3
			elif state == 4:
				$anim.play("hover_1")
				if $sprite.flip_h:
					$sprite.flip_h = false
					velocity.x = -90
				else:
					$sprite.flip_h = true
					velocity.x = 90
				velocity.y = 100
			elif state == 10:
				$anim.play("hover_1")
				if $sprite.flip_h:
					$sprite.flip_h = false
				else:
					$sprite.flip_h = true
			
		"turn_2":
			if state == 6:
				$anim.play("hover_1")
				if $sprite.flip_h:
					$sprite.flip_h = false
				else:
					$sprite.flip_h = true
				thr_state = -1
				state = 5
		
		"open":
			if state == 7:
				$anim.play("rise")
				if $sprite.flip_h:
					velocity.x = 90
				else:
					velocity.x = -90
				velocity.y = JUMP_STR
				state = 8
		
		"fall":
			velocity.x = 0

func _on_tween_completed(object, key):
	$anim.play("intro")
