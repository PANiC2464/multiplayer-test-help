extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var lobby_members = []
var lobby_id : int

@onready var Camera: Camera3D = $Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var raycast = $Camera3D/RayCast3D
@onready var grab_anchor = $Camera3D/SpringArm3D/Grabber
@onready var object_name_label: Label = $ObjectNameLabel
var grabbing = false
var grabbed_object: RigidBody3D = null

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#if is_multiplayer_authority0:
#$Name.visible = false
#$Camera3D.make_current()
#$Name.text = Steam.getPersonaName(

func _process(_delta: float) -> void:
	$TabMenu/LobbyID.text = "Lobby ID"
	
	#func get_all_player_names(lobby_id):
	#lobby_members.clear(
	#var member_count = Steam.getNumLobbyMembers(lobby_id)
	
	
	#for i in range(member_count):
	#var member_steam_id = Steam.getLobbyMemberBylndex(lobby_id, i)
	#var member_name = Steam.getFriendPersonaName(member_steam_id)
	#lobby_members.append({"name": member_name, "id": member_steam_id})
	#$TabMenu/Players.text = str(member_name)

func _physics_process(delta: float) -> void:
	
	if !is_multiplayer_authority():
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Handle jump.
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("tab"):
		$TabMenu.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#get_all_player_names(lobby_id)
	
	if Input.is_action_just_released("tab"):
		$TabMenu.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if raycast.is_colliding() and grabbing == false:
		var body = raycast.get_collider()
		if body is RigidBody3D:
			pass # this is where you change the curser to show its available to pick something up
	
	if not raycast.is_colliding() and grabbing == false:
		pass # this is where you change the curser to show its NOT available to pick something up
	
	if grabbing == true:
		pass # this is where you change the curser to show its picking something up
	
	
	
	if Input.is_action_just_pressed("lmb"):
		if grabbed_object:
			_release_object()
		else:
			_try_grab()

	if grabbed_object:
		_drag_object(delta)
	
	if grabbing == true:
		var target_position = self.global_transform.origin
		var current_position = grabbed_object.global_transform.origin
		
		target_position.y = current_position.y
		
		if grabbed_object.rotation.y < self.rotation.y:
			grabbed_object.rotation.y += 0.1
		
		if grabbed_object.rotation.y > self.rotation.y:
			grabbed_object.rotation.y -= 0.1
		
		#grabbed_object.look_at(target_position, Vector3.UP)
		
		#grabbed_object.rotation.y = self.rotation.y

func _try_grab():
	if raycast.is_colliding():
		var body = raycast.get_collider()
		if body is RigidBody3D:
			grabbing = true
			grabbed_object = body
			grabbed_object.freeze = false
			grabbed_object.gravity_scale = 1.0
			grabbed_object.rotation.x = 0
			#grabbed_object.rotation.y = self.rotation.y
			grabbed_object.rotation.z = 0
			grabbed_object.lock_rotation = true

func _release_object():
	grabbed_object.lock_rotation = false
	grabbed_object = null
	grabbing = false
	object_name_label.text = ""

func _drag_object(delta):
	var target_pos = grab_anchor.global_transform.origin
	var current_pos = grabbed_object.global_transform.origin
	var direction = target_pos - current_pos
	var force = direction * 40.0 - grabbed_object.linear_velocity * 6.0  # spring + damping
	grabbed_object.apply_central_force(force)

func _unhandled_input(event):
	# CAMERA
	
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .003)
		Camera.rotate_x(-event.relative.y * .003)
		Camera.rotation.x = clamp(Camera.rotation.x, -PI/2, PI/2)

func _on_button_pressed() -> void:
	DisplayServer.clipboard_set(str("Lobby ID"))
