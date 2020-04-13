extends KinematicBody2D

onready var world = get_parent().get_parent()
onready var player = world.get_child(2)
onready var camera = player.get_child(9)

var id = 4
const CHOKE = 3

const GRAVITY = 900
const JUMP_STR = -400

var state = 0
var spr_offset = Vector2()
var spr_shake = 0

var thrst_pos = {
	0 : Vector2(-1, 22),
	1 : Vector2(1, 22),
	2 : Vector2(0, 22),
	3 : Vector2(1, 22),
	4 : Vector2(19, 2),
	5 : Vector2(-19, 2),
}

func _ready():
	$anim.play("fade_in")
	
	$sprite.flip_h = true
	

func _physics_process(delta):
	
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
	
	if $sprite.frame == 8 and spr_shake == 0:
		spr_shake = 8

func _on_anim_finished(anim_name):
	match anim_name:
		"fade_in":
			world.boss = true
			world.play_music("boss")
			$anim.play("move_to")
			$tween.interpolate_property(self, "position", position, position + Vector2(-88, 64), 0.75, Tween.TRANS_LINEAR, Tween.EASE_IN)
			$tween.start()
		
		"intro":
			world.fill_b_meter = true

func _on_tween_completed(object, key):
	$anim.play("intro")