# MainHub.gd - Tela principal MVP
extends Control

# Referências dos botões
@onready var sucata_label: Label = $Header/SucataLabel
@onready var fundicao_btn: Button = $Center/FundicaoButton
@onready var arsenal_btn: Button = $Center/ArsenalButton
@onready var oficina_btn: Button = $Center/OficinaButton
@onready var bancada_btn: Button = $Center/BancadaButton

func _ready():
	connect_signals()
	update_ui()
	print("🏠 MainHub carregado")

func connect_signals():
	fundicao_btn.pressed.connect(_on_fundicao_pressed)
	arsenal_btn.pressed.connect(_on_arsenal_pressed)
	oficina_btn.pressed.connect(_on_oficina_pressed)
	bancada_btn.pressed.connect(_on_bancada_pressed)

func update_ui():
	var player = GameManager.current_player
	if player:
		sucata_label.text = "Sucata: %d" % player.sucata

func _on_fundicao_pressed():
	print("🏭 Acessando Fundição")
	get_tree().change_scene_to_file("res://scenes/Fundicao.tscn")

func _on_arsenal_pressed():
	print("⚙️ Acessando Arsenal")
	get_tree().change_scene_to_file("res://scenes/Arsenal.tscn")

func _on_oficina_pressed():
	print("🔧 Acessando Oficina")
	get_tree().change_scene_to_file("res://scenes/Oficina.tscn")
	
func _on_bancada_pressed():
	print("🔧 Acessando Bancada")
	get_tree().change_scene_to_file("res://scenes/Bancada.tscn")
