extends KinematicBody

###################-VARIABLES-####################

# Camera
export(float) var mouse_sensitivity = 8.0
export(NodePath) var head_path = "Head"
export(NodePath) var cam_path = "Head/Camera"
export(float) var FOV = 80.0
var mouse_axis := Vector2()
onready var head: Spatial = get_node(head_path)
onready var cam: Camera = get_node(cam_path)
# Move
var velocity := Vector3()
var direction := Vector3()
var move_axis := Vector2()
var snap := Vector3()
var sprint_enabled := true
var sprinting := false
# Walk
const FLOOR_MAX_ANGLE: float = deg2rad(46.0)
export(float) var gravity = 30.0
export(int) var walk_speed = 10
export(int) var sprint_speed = 16
export(int) var acceleration = 8
export(int) var deacceleration = 10
export(float, 0.0, 1.0, 0.05) var air_control = 0.3
export(int) var jump_height = 10
var _speed: int
var _is_sprinting_input := false
var _is_jumping_input := false
var paused=false
##################################################
var steptimer=0
# Called when the node enters the scene tree
func _ready() -> void:
	if get_tree().current_scene.name=="bigland":
		var FF = Directory.new()
		if FF.file_exists("res://biglandwell"):
			self.translation=Vector3(147.618,-1.173,-109.825)
			self.rotation_degrees.y=90
			FF.remove("res://biglandwell")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.fov = FOV
	OS.min_window_size=Vector2(320,240)
	if get_tree().current_scene.name=="apt":
		walk_speed=3
		sprint_speed =5
		$AudioStreamPlayer3D.autoplay=false
		$AudioStreamPlayer3D.playing=false
	if get_tree().current_scene.name=="ship":
		$AudioStreamPlayer3D.pitch_scale=1.3
	if get_tree().current_scene.name=="bigland":
		print(get_parent().get_child(3).environment.fog_color)
		var dist = get_parent().get_child(4).get_child(0).translation.distance_to(translation)
		if dist <=150:
			get_parent().get_child(3).environment.fog_depth_end=250-dist
			get_parent().get_child(3).environment.fog_depth_begin=150-dist
			$Head/Camera.far=250-(dist-50)
			var perc = int((dist/150)*100)
			get_parent().get_child(3).environment.fog_color=Color8(155-perc,155-int(perc/2),85)
			get_parent().get_child(3).environment.background_color=Color8(155-perc,155-int(perc/2),85)
			$AudioStreamPlayer3D.set_pitch_scale(1.325+(-float(dist)/400.0))
		dist = get_parent().get_child(4).get_child(1).translation.distance_to(translation)
		if dist <=100:
			get_parent().get_child(3).environment.fog_depth_end=200-dist
			get_parent().get_child(3).environment.fog_depth_begin=100-dist
			$Head/Camera.far=200-(dist-50)
			var perc = int((dist/100)*70)
			dist=int(dist)
			print(perc)
			$AudioStreamPlayer3D.set_pitch_scale(1.25+(-float(dist)/400.0))
			get_parent().get_child(3).environment.fog_color=Color8(155-dist,155-int(dist/2),155-perc)
			get_parent().get_child(3).environment.background_color=Color8(155-dist,155-int(dist/2),155-perc)



# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(_delta: float) -> void:
	move_axis.x = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	move_axis.y = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if Input.is_action_just_pressed("ui_cancel"):
		match paused:
			true:
				paused=false
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			false:
				paused=true
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	#rgb: 55,105,85
	#rgb2: 155,155,85
	if move_axis.x!=0||mouse_axis.y!=0:
				
		if get_tree().current_scene.name=="bigland":
			print(get_parent().get_child(3).environment.fog_color)
			var dist = get_parent().get_child(4).get_child(0).translation.distance_to(translation)
			if dist <=150:
				get_parent().get_child(3).environment.fog_depth_end=250-dist
				get_parent().get_child(3).environment.fog_depth_begin=150-dist
				$Head/Camera.far=250-(dist-50)
				var perc = int((dist/150)*100)
				$AudioStreamPlayer3D.set_pitch_scale(1.325+(-float(dist)/400.0))
				get_parent().get_child(3).environment.fog_color=Color8(155-perc,155-int(perc/2),85)
				get_parent().get_child(3).environment.background_color=Color8(155-perc,155-int(perc/2),85)
			dist = get_parent().get_child(4).get_child(1).translation.distance_to(translation)
			if dist <=100:
				get_parent().get_child(3).environment.fog_depth_end=200-dist
				get_parent().get_child(3).environment.fog_depth_begin=100-dist
				$Head/Camera.far=200-(dist-50)
				var perc = int((dist/100)*70)
				dist=int(dist)
				print(1.0+(-float(dist)/200.0))
				$AudioStreamPlayer3D.set_pitch_scale(1.25+(-float(dist)/400.0))
				get_parent().get_child(3).environment.fog_color=Color8(155-dist,155-int(dist/2),155-perc)
				get_parent().get_child(3).environment.background_color=Color8(155-dist,155-int(dist/2),155-perc)

	if !Input.is_action_just_pressed("move_jump"):
		if Input.is_action_pressed("move_sprint")&&!_is_jumping_input:
			_is_sprinting_input = true
		
	else:
		_is_jumping_input = true
	


# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	walk(delta)


# Called when there is an input event
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		print(OS.window_size)
		mouse_axis.x = (OS.window_size.x/320)*event.relative.x
		mouse_axis.y = (OS.window_size.y/240)*event.relative.y
		camera_rotation()


func walk(delta: float) -> void:
	direction_input()
	
	if is_on_floor():
		if move_axis.x!=0||mouse_axis.y!=0&&!_is_jumping_input:
			if !$AudioStreamPlayer.playing:
				$AudioStreamPlayer.play()
				steptimer=0
		snap = -get_floor_normal() - get_floor_velocity() * delta
		
		# Workaround for sliding down after jump on slope
		if velocity.y < 0:
			velocity.y = 0
		
		jump()
	else:
		# Workaround for 'vertical bump' when going off platform
		if snap != Vector3.ZERO && velocity.y != 0:
			velocity.y = 0
		
		snap = Vector3.ZERO
		
		velocity.y -= gravity * delta
	
	sprint(delta)
	
	accelerate(delta)
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, FLOOR_MAX_ANGLE)
	_is_jumping_input = false
	_is_sprinting_input = false


func camera_rotation() -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if mouse_axis.length() > 0:
		var horizontal: float = -mouse_axis.x/2
		var vertical: float = -mouse_axis.y/2
		
		mouse_axis = Vector2()
		
		rotate_y(deg2rad(horizontal))
		head.rotate_x(deg2rad(vertical))
		
		# Clamp mouse rotation
		var temp_rot: Vector3 = head.rotation_degrees
		temp_rot.x = clamp(temp_rot.x, -90, 90)
		head.rotation_degrees = temp_rot


func direction_input() -> void:
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if move_axis.x >= 0.5:
		direction -= aim.z
	if move_axis.x <= -0.5:
		direction += aim.z
	if move_axis.y <= -0.5:
		direction -= aim.x
	if move_axis.y >= 0.5:
		direction += aim.x
	direction.y = 0
	direction = direction.normalized()


func accelerate(delta: float) -> void:
	# Where would the player go
	var _temp_vel: Vector3 = velocity
	var _temp_accel: float
	var _target: Vector3 = direction * _speed
	
	_temp_vel.y = 0
	if direction.dot(_temp_vel) > 0:
		_temp_accel = acceleration
		
	else:
		_temp_accel = deacceleration
	
	if not is_on_floor():
		_temp_accel *= air_control
	
	# Interpolation
	_temp_vel = _temp_vel.linear_interpolate(_target, _temp_accel * delta)
	
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	
	# Make too low values zero
	if direction.dot(velocity) == 0:
		var _vel_clamp := 0.01
		if abs(velocity.x) < _vel_clamp:
			velocity.x = 0
		if abs(velocity.z) < _vel_clamp:
			velocity.z = 0


func jump() -> void:
	if _is_jumping_input:
		velocity.y = jump_height
		snap = Vector3.ZERO


func sprint(delta: float) -> void:
	if can_sprint():
		if move_axis.x!=0||mouse_axis.y!=0:
			print(steptimer)
			if !$AudioStreamPlayer2.playing && steptimer>=6:
				$AudioStreamPlayer2.play()
				steptimer=0
			steptimer+=1
		_speed = sprint_speed
		cam.set_fov(lerp(cam.fov, FOV * 1.2, delta * 8))
		sprinting = true
		
	else:
		_speed = walk_speed
		cam.set_fov(lerp(cam.fov, FOV, delta * 8))
		sprinting = false


func can_sprint() -> bool:
	return (sprint_enabled and is_on_floor() and _is_sprinting_input and move_axis.x >= 0.5)
