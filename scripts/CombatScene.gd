# CombatScene.gd - Sistema de combate com timeline contínua
extends Control

# Referencias dos elementos UI - ESTRUTURA ORIGINAL
@onready var turn_label: Label = $UI/TurnLabel
@onready var player_unit_label: Label = $UI/PlayerUnitLabel
@onready var enemy_unit_label: Label = $UI/EnemyUnitLabel
@onready var attack_button: Button = $UI/AttackButton
@onready var special_button: Button = $UI/SpecialButton
@onready var back_button: Button = $UI/BackButton
@onready var turn_order_ui: TurnOrderUI = $UI/TurnOrderBar

# Estado do combate
var player_unit: CombatUnit
var enemy_unit: CombatUnit
var combat_ended: bool = false
var is_player_turn: bool = true

# NOVO: Sistema de timeline contínua
var timeline_units: Array[Dictionary] = []  # {unit: CombatUnit, next_action_time: float}
var current_time: float = 0.0
var time_multiplier: float = 100.0  # Para converter velocidade em tempo

func _ready():
	connect_signals()
	setup_turn_order_ui()
	setup_combat()

func setup_turn_order_ui():
	# TurnOrderUI já está na scene com posição correta
	if turn_order_ui:
		turn_order_ui.position = Vector2(300, 50)
		turn_order_ui.size = Vector2(1320, 70)

func connect_signals():
	attack_button.pressed.connect(_on_attack_pressed)
	special_button.pressed.connect(_on_special_pressed)
	back_button.pressed.connect(_on_back_pressed)

func setup_combat():
	if GameManager.data_manager.robots.is_empty():
		print("❌ Erro: Nenhum robô disponível para combate")
		_on_back_pressed()
		return
	
	# Criar units
	var player_robot = GameManager.data_manager.get_active_robots()[0]
	player_unit = CombatUnit.new(player_robot)
	
	var enemy_robot = create_simple_enemy()
	enemy_unit = CombatUnit.new(enemy_robot)
	
	# NOVO: Inicializar timeline contínua
	initialize_timeline()
	
	print("🥊 Combate iniciado!")
	print("👤 Player: %s (HP: %d, SPD: %d)" % [player_unit.get_display_name(), player_unit.current_hp, player_unit.get_speed_stat()])
	print("🤖 Enemy: %s (HP: %d, SPD: %d)" % [enemy_unit.get_display_name(), enemy_unit.current_hp, enemy_unit.get_speed_stat()])
	
	update_ui()
	update_turn_order_display()
	process_next_action()

func initialize_timeline():
	"""Inicializa sistema de timeline baseado em velocidade real"""
	timeline_units.clear()
	current_time = 0.0
	
	# Calcular tempo até primeira ação baseado na velocidade
	# Velocidade maior = ações mais frequentes
	var player_action_delay = time_multiplier / float(player_unit.get_speed_stat())
	var enemy_action_delay = time_multiplier / float(enemy_unit.get_speed_stat())
	
	timeline_units.append({
		"unit": player_unit,
		"next_action_time": player_action_delay
	})
	
	timeline_units.append({
		"unit": enemy_unit,
		"next_action_time": enemy_action_delay
	})
	
	print("⏰ Timeline inicializada:")
	print("  Player próxima ação: %.1fs" % player_action_delay)
	print("  Enemy próxima ação: %.1fs" % enemy_action_delay)

func process_next_action():
	"""Processa próxima ação na timeline"""
	if combat_ended:
		return
	
	# Encontrar quem age primeiro
	var next_unit_data = get_next_acting_unit()
	if not next_unit_data:
		return
	
	var acting_unit = next_unit_data.unit
	current_time = next_unit_data.next_action_time
	
	# Determinar se é turno do player
	is_player_turn = (acting_unit == player_unit)
	
	print("\n⏰ Tempo %.1f - Turno de: %s" % [current_time, acting_unit.get_display_name()])
	
	update_ui()
	update_turn_order_display()
	
	if is_player_turn:
		# Aguardar ação do player
		enable_player_buttons()
	else:
		# Executar IA automaticamente
		disable_player_buttons()
		await get_tree().create_timer(1.0).timeout
		execute_ai_turn()

func get_next_acting_unit() -> Dictionary:
	"""Retorna dados da unidade que age primeiro"""
	if timeline_units.is_empty():
		return {}
	
	# Ordenar por tempo de próxima ação
	timeline_units.sort_custom(func(a, b): return a.next_action_time < b.next_action_time)
	
	return timeline_units[0]

func schedule_next_action(unit: CombatUnit):
	"""Agenda próxima ação de uma unidade"""
	var action_delay = time_multiplier / float(unit.get_speed_stat())
	
	# Encontrar e atualizar entrada na timeline
	for i in range(timeline_units.size()):
		if timeline_units[i].unit == unit:
			timeline_units[i].next_action_time = current_time + action_delay
			print("  📅 %s próxima ação: %.1fs" % [unit.get_display_name(), timeline_units[i].next_action_time])
			break

func get_timeline_preview(look_ahead_actions: int = 6) -> Array:
	"""Gera preview dos próximos turnos para UI"""
	var preview = []
	var temp_timeline = timeline_units.duplicate(true)
	var temp_time = current_time
	
	for i in range(look_ahead_actions):
		if temp_timeline.is_empty():
			break
		
		# Ordenar por tempo
		temp_timeline.sort_custom(func(a, b): return a.next_action_time < b.next_action_time)
		
		var next_data = temp_timeline[0]
		var unit = next_data.unit
		
		# Não incluir unidades mortas
		if not unit.is_alive():
			temp_timeline.erase(next_data)
			continue
		
		preview.append({
			"unit": unit,
			"turn_number": i + 1,
			"action_time": next_data.next_action_time,
			"is_current_turn": (i == 0)
		})
		
		# Simular próxima ação desta unidade
		var action_delay = time_multiplier / float(unit.get_speed_stat())
		next_data.next_action_time += action_delay
	
	return preview

func create_simple_enemy() -> RobotData:
	var robot = RobotData.new()
	robot.serial_number = "ENEMY-FERRO-GUARDIAN-001"
	robot.type = RobotData.Type.FERRO_GUARDIAN
	robot.rarity = RobotData.Rarity.COMUM
	
	# Stats de Guardian (tank)
	robot.base_attack = 60
	robot.base_defense = 120
	robot.base_special_attack = 50
	robot.base_special_defense = 110
	robot.base_health = 130
	robot.base_speed = 40
	
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	return robot

func calculate_simple_damage(attacker: CombatUnit, defender: CombatUnit, attack_type: CombatUnit.AttackType) -> int:
	var base_damage: int
	var defender_defense: int
	
	match attack_type:
		CombatUnit.AttackType.PHYSICAL:
			base_damage = attacker.get_attack_stat()
			defender_defense = defender.get_defense_stat()
		CombatUnit.AttackType.SPECIAL:
			base_damage = attacker.get_special_attack_stat()
			defender_defense = defender.get_special_defense_stat()
	
	var effective_defense = defender_defense * 0.8
	var raw_damage = base_damage - effective_defense
	var damage = max(base_damage * 0.2, raw_damage + randi_range(-2, 5))
	
	return int(damage)

func update_turn_order_display():
	var next_turns = get_timeline_preview(6)
	
	if turn_order_ui:
		turn_order_ui.update_turn_order(next_turns)

func update_ui():
	if combat_ended:
		return
	
	# Atualizar labels de HP com melhor formatação
	if player_unit and player_unit.robot_data:
		var hp_percent = float(player_unit.current_hp) / float(player_unit.max_hp)
		var hp_status = ""
		
		if hp_percent > 0.6:
			hp_status = "🟢"
		elif hp_percent > 0.3:
			hp_status = "🟡"
		else:
			hp_status = "🔴"
		
		player_unit_label.text = "🤖 SEU ROBÔ %s\n%s\n%s %d/%d HP" % [
			hp_status,
			player_unit.robot_data.get_model_display_name(),
			hp_status,
			player_unit.current_hp,
			player_unit.max_hp
		]
	
	if enemy_unit and enemy_unit.robot_data:
		var hp_percent = float(enemy_unit.current_hp) / float(enemy_unit.max_hp)
		var hp_status = ""
		
		if hp_percent > 0.6:
			hp_status = "🟢"
		elif hp_percent > 0.3:
			hp_status = "🟡"
		else:
			hp_status = "🔴"
		
		enemy_unit_label.text = "🔥 INIMIGO %s\n%s\n%s %d/%d HP" % [
			hp_status,
			enemy_unit.robot_data.get_model_display_name(),
			hp_status,
			enemy_unit.current_hp,
			enemy_unit.max_hp
		]
	
	# Atualizar indicador de turno com melhor visual
	if is_player_turn:
		turn_label.text = "🎯 SEU TURNO - Escolha uma ação"
		turn_label.modulate = Color.CYAN
		enable_player_buttons()
	else:
		turn_label.text = "⏳ TURNO DO INIMIGO - Aguarde..."
		turn_label.modulate = Color.ORANGE
		disable_player_buttons()
	
	# Atualizar status do special attack
	update_special_button_status()

func update_special_button_status():
	"""Atualiza status do botão de special attack com cooldown"""
	if not player_unit.can_use_special_attack():
		if player_unit.robot_data.equipped_arms == "":
			special_button.text = "❌ SEM BRAÇO"
			special_button.disabled = true
			special_button.modulate = Color.GRAY
		else:
			var cooldown = player_unit.special_attack_cooldown
			special_button.text = "⏰ ESPECIAL (%d)" % cooldown
			special_button.disabled = true
			special_button.modulate = Color.GRAY
	else:
		special_button.text = "⚡ ATAQUE ESPECIAL"
		special_button.disabled = not is_player_turn
		special_button.modulate = Color.WHITE if is_player_turn else Color.GRAY

func enable_player_buttons():
	attack_button.disabled = false
	attack_button.modulate = Color.WHITE
	update_special_button_status()

func disable_player_buttons():
	attack_button.disabled = true
	attack_button.modulate = Color.GRAY
	special_button.disabled = true
	special_button.modulate = Color.GRAY

func _on_attack_pressed():
	if not is_player_turn or combat_ended:
		return
	execute_player_action(CombatUnit.AttackType.PHYSICAL)

func _on_special_pressed():
	if not is_player_turn or combat_ended or not player_unit.can_use_special_attack():
		return
	execute_player_action(CombatUnit.AttackType.SPECIAL)

func execute_player_action(attack_type: CombatUnit.AttackType):
	print("\n=== AÇÃO DO PLAYER ===")
	
	# CORRIGIDO: Reduzir cooldown ANTES da ação (do turno anterior)
	player_unit.reduce_cooldowns()
	
	# Calcular e aplicar dano
	var damage = calculate_simple_damage(player_unit, enemy_unit, attack_type)
	var enemy_died = enemy_unit.apply_damage(damage)
	
	# Usar special attack se necessário (aplica cooldown APÓS reduzir)
	if attack_type == CombatUnit.AttackType.SPECIAL:
		player_unit.use_special_attack()
	
	var attack_name = "Ataque Básico" if attack_type == CombatUnit.AttackType.PHYSICAL else "Ataque Especial"
	print("🗡️ Player usa %s! Dano: %d" % [attack_name, damage])
	
	if enemy_died:
		end_combat(true)
		return
	
	# Agendar próxima ação do player
	schedule_next_action(player_unit)
	
	# Continuar timeline
	process_next_action()

func execute_ai_turn():
	print("\n=== AÇÃO DA IA ===")
	
	if combat_ended:
		return
	
	# CORRIGIDO: Reduzir cooldown ANTES da ação (do turno anterior)
	enemy_unit.reduce_cooldowns()
	
	# IA escolhe ação simples
	var damage = calculate_simple_damage(enemy_unit, player_unit, CombatUnit.AttackType.PHYSICAL)
	var player_died = player_unit.apply_damage(damage)
	
	print("🤖 Inimigo ataca! Dano: %d" % damage)
	
	if player_died:
		end_combat(false)
		return
	
	# Agendar próxima ação do inimigo
	schedule_next_action(enemy_unit)
	
	# Continuar timeline
	process_next_action()

func end_combat(player_won: bool):
	combat_ended = true
	disable_player_buttons()
	
	if player_won:
		turn_label.text = "🏆 VITÓRIA! Inimigo derrotado!"
		print("🏆 PLAYER VENCEU!")
		
		var reward_sucata = 30
		GameManager.current_player.sucata += reward_sucata
		print("💰 Recompensa: +%d sucata" % reward_sucata)
	else:
		turn_label.text = "💀 DERROTA! Seu robô foi destruído!"
		print("💀 PLAYER PERDEU!")
	
	if player_unit.robot_data:
		player_unit.robot_data.remaining_cycles -= 1
		print("🔄 Ciclos restantes: %d" % player_unit.robot_data.remaining_cycles)
	
	GameManager.data_manager.save_game()
	
	await get_tree().create_timer(3.0).timeout
	_on_back_pressed()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
