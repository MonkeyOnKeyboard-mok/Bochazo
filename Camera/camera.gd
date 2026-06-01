class_name Camera
extends Node3D

## Anchor Points
var mainPos : Vector3 = Vector3(35,6.195, 00) ## In Test Scene
var mainRot : Vector3 = Vector3(-24.0,90, 00) ## In Test Scene

## Zoom 
var checkPos : Vector3 = Vector3(-22,15, 00) ## In Test Scene
var checkRot : Vector3 = Vector3(-90,90, 00) ## In Test Scene

## Movement control
var is_moving : bool = false
var move_timer : float = 0.0
var delay_before_move : float = 2.0  # Wait 2 seconds before moving
var x_move_duration : float = 0.7    # Move on X for 1.5 seconds
var xy_move_duration : float = 1.5   # Then move on X+Y for 1.5 seconds
var total_move_time : float = 0.0

var start_pos : Vector3
var target_pos : Vector3
var start_rot : Vector3
var target_rot : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = mainPos
	global_rotation_degrees = mainRot

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_moving:
		move_timer += delta
		
		# Wait for initial delay
		if move_timer < delay_before_move:
			return
		
		# Calculate progress after delay
		var progress_time = move_timer - delay_before_move
		
		# Phase 1: Move only on X axis
		if progress_time < x_move_duration:
			var t = progress_time / x_move_duration
			t = ease(t, -2.0)  # Smooth easing
			
			# Only interpolate X position
			global_position.x = lerp(start_pos.x, target_pos.x, t)
			global_position.y = start_pos.y
			global_position.z = start_pos.z
			
			# Interpolate rotation
			global_rotation_degrees = start_rot.lerp(target_rot, t)
		
		# Phase 2: Move on both X and Y (creates arc)
		elif progress_time < (x_move_duration + xy_move_duration):
			var t = (progress_time - x_move_duration) / xy_move_duration
			t = ease(t, -2.0)
			
			# Interpolate both X and Y
			global_position.x = lerp(start_pos.x, target_pos.x, 1.0)  # X already at target
			global_position.y = lerp(start_pos.y, target_pos.y, t)
			global_position.z = lerp(start_pos.z, target_pos.z, t)
			
			# Continue rotation interpolation
			global_rotation_degrees = start_rot.lerp(target_rot, 
				(progress_time) / (x_move_duration + xy_move_duration))
		
		# Movement complete
		else:
			global_position = target_pos
			global_rotation_degrees = target_rot
			is_moving = false
			move_timer = 0.0

## Call this function from another node to trigger movement
func move_to_check_position() -> void:
	start_pos = global_position
	target_pos = checkPos
	start_rot = global_rotation_degrees
	target_rot = checkRot
	is_moving = true
	move_timer = 0.0

## Return to main position
func move_to_main_position() -> void:
	start_pos = global_position
	target_pos = mainPos
	start_rot = global_rotation_degrees
	target_rot = mainRot
	is_moving = true
	move_timer = 0.0
