extends Node3D

var lobby_id : int = 0
var peer : SteamMultiplayerPeer

@export var player_scene : PackedScene

var is_host : bool = false
var is_joining : bool = false

@onready var host_button: Button = $UI/HostButton
@onready var join_buton: Button = $UI/JoinButton
@onready var join_button_final: Button = $UI/JoinScreen/JoinButtonFinal
@onready var back_button: Button = $UI/JoinScreen/BackButton
@onready var id_prompt: LineEdit = $UI/JoinScreen/id_prompt


var current_level = "TestWorld"

var LevelTSCN : Node

var MarketTSCN = preload("res://Levels/market.tscn")

func _ready() -> void:
	print("Steam Initialized:", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)

func process(_delta: float) -> void:
	Steam.run_callbacks()
	
	if Input.is_action_just_pressed("e") and is_host == true:
		change_level.rpc()

func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 6)
	is_host = true
	print("Host Lobby")
	$UI.visible = false

func join_lobby(lobby_id : int):
	is_joining = true
	Steam.joinLobby(lobby_id)
	$Ul.visible = false

func _on_lobby_joined(lobby_id : int, permissions : int, locked : bool, response : int):
	
	if !is_joining:
		return
	
	$Ul.visible = false
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	
	multiplayer.multiplayer_peer = peer
	is_joining = false
	
func _on_lobby_created(result: int, lobby_id: int):
	print("Lobby Created.")
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		print("Lobby ID:" + str(lobby_id))
		
		$LobbylD.text = str(lobby_id)
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		_add_player()

func _add_player(id : int = 1):
	var player = player_scene.instantiate0
	player.name = str(id)
	call_deferred("add_child", player)
	print("Add Player")

func _remove_player(id : int):
	if !self.has_node(str(id)):
		return
	
	self.get_node(str(id)).queue_free()

@rpc("authority", "call_local", "reliable", 0)
func change_level():
	if current_level == "TestWorld":
		$TestWorld.queue_free()
		
		LevelTSCN = MarketTSCN.instantiate()
		current_level = "Market"
		
		self.add_child(LevelTSCN)

func _on_host_button_pressed() -> void:
	host_lobby()
	$UI/HostButton.release_focus()

func _on_join_button_pressed() -> void:
	$Ul/JoinScreen.visible = true

func _on_back_button_pressed() -> void:
	$Ul/JoinScreen.visible = false

func _on_id_prompt_text_changed(new_text: String) -> void:
	join_button_final.disabled = (new_text.length() == 0)

func _on_join_button_final_pressed() -> void:
	join_lobby(id_prompt.text.to_int())
