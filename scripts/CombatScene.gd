# CombatScene.gd - Sistema de combate 2v2 com posicionamento
extends Control

# Referencias dos elementos UI
@onready var turn_label: Label = $UI/TurnLabel
@onready var attack_button: Button = $UI/AttackButton
@onready var special_button: Button = $UI/SpecialButton
@onready var switch_button: Button = $UI/SwitchButton
@onready var back_button: Button = $UI/BackButton
@onready var turn_order_ui: TurnOrderUI = $UI/TurnOrderBar

# 🆕 UI PARA 2v2
@onready var player_front_label: Label = $UI/PlayerTeam/FrontLabel
@onready var player_back_label: Label = $UI/PlayerTeam/BackLabel
@onready var enemy_front_label: Label = $UI/EnemyTeam/FrontLabel
@onready var enemy_back_label: Label = $UI/EnemyTeam/BackLabel

# 🆕 LOG DE COMBATE
@onready var combat_log_scroll: ScrollContainer = $UI/CombatLogPanel/ScrollContainer
@onready var combat_log_container: VBoxContainer = $UI/CombatLogPanel/ScrollContainer/VBoxContainer

# Estado do combate 2v2
var player_team: Array[CombatUnit] = []  # [front, back]
var enemy_team: Array[CombatUnit] = []   # [front, back]
var combat_ended: bool = false
var is_player_turn: bool = true
var current_acting_unit: CombatUnit

# Sistema de timeline contínua
var timeline_units: Array[Dictionary] = []
var current_time: float = 0.0
var time_multiplier: float = 100.0

# 🆕 SISTEMA DE LOG DE COMBATE
var combat_log_entries: Array[String] = []
const MAX_LOG_ENTRIES = 8

func _ready():
	connect_signals()
	setup_turn_order_ui()
	setup_combat_2v2()

func connect_signals():
	attack_button.pressed.connect(_on_attack_pressed)
	special_button.pressed.connect(_on_special_pressed)
	switch_button.pressed.connect(_on_switch_pressed)
	back_button.pressed.connect(_on_back_pressed)

func setup_turn_order_ui():
	if turn_order_ui:
		turn_order_ui.position = Vector2(300, 50)
		turn_order_ui.size = Vector2(1320, 70)

func setup_combat_2v2():
	# Verificar se há robôs suficientes
	var active_robots = GameManager.data_manager.get_active_robots()
	if active_robots.size() < 2:
		print("❌ Erro: Precisa de pelo menos 2 robôs para combate 2v2")
		_on_back_pressed()
		return
	
	# 🆕 CRIAR TEAMS 2v2
	create_player_team(active_robots)
	create_enemy_team()
	
	# Inicializar timeline para 4 unidades
	initialize_timeline_2v2()
	
	print("🥊 Combate 2v2 iniciado!")
	print_team_status()
	
	# 🆕 INICIALIZAR LOG DE COMBATE
	add_log_entry("🥊 Combate 2v2 iniciado!", Color.YELLOW)
	add_log_entry("⚔️ %s vs %s" % [
		player_team[0].robot_data.get_model_display_name() if player_team[0].robot_data else "PLAYER",
		enemy_team[0].robot_data.get_model_display_name() if enemy_team[0].robot_data else "ENEMY"
	], Color.WHITE)
	
	update_ui_2v2()
	update_turn_order_display()
	process_next_action()

func create_player_team(available_robots: Array[RobotData]):
	# Usar os 2 primeiros robôs disponíveis
	# TODO: Implementar seleção de team na FASE 2.3
	
	var front_robot = available_robots[0]
	var back_robot = available_robots[1] if available_robots.size() > 1 else available_robots[0]
	
	var front_unit = CombatUnit.new(front_robot)
	front_unit.current_position = CombatUnit.Position.FRONT
	
	var back_unit = CombatUnit.new(back_robot)
	back_unit.current_position = CombatUnit.Position.BACK
	
	# 🆕 APLICAR MODIFICADORES POSICIONAIS
	apply_positional_modifiers(front_unit)
	apply_positional_modifiers(back_unit)
	
	player_team = [front_unit, back_unit]

func create_enemy_team():
	# Criar 2 inimigos balanceados
	var enemy_1 = create_enemy_robot("GUARDIAN")  # Tank na frente
	var enemy_2 = create_enemy_robot("SWIFT")     # DPS atrás
	
	var front_unit = CombatUnit.new(enemy_1)
	front_unit.current_position = CombatUnit.Position.FRONT
	
	var back_unit = CombatUnit.new(enemy_2)
	back_unit.current_position = CombatUnit.Position.BACK
	
	# 🆕 APLICAR MODIFICADORES POSICIONAIS
	apply_positional_modifiers(front_unit)
	apply_positional_modifiers(back_unit)
	
	enemy_team = [front_unit, back_unit]

# 🆕 SISTEMA DE MODIFICADORES POSICIONAIS
func apply_positional_modifiers(unit: CombatUnit):
	# Conforme GDD: Front = +10% DEF/DEF-ESP/VDA, Back = +10% ATK/ATK-ESP
	if not unit.robot_data:
		return
	
	match unit.current_position:
		CombatUnit.Position.FRONT:
			# +10% nas defesas
			unit.robot_data.base_defense = int(unit.robot_data.base_defense * 1.1)
			unit.robot_data.base_special_defense = int(unit.robot_data.base_special_defense * 1.1)
			unit.robot_data.base_health = int(unit.robot_data.base_health * 1.1)
			
		CombatUnit.Position.BACK:
			# +10% nos ataques
			unit.robot_data.base_attack = int(unit.robot_data.base_attack * 1.1)
			unit.robot_data.base_special_attack = int(unit.robot_data.base_special_attack * 1.1)
	
	# Recalcular HP máximo se foi modificado
	if unit.current_position == CombatUnit.Position.FRONT:
		var new_stats = unit.robot_data.get_final_stats()
		unit.max_hp = new_stats.health
		unit.current_hp = unit.max_hp

func create_enemy_robot(preferred_model: String) -> RobotData:
	var robot = RobotData.new()
	
	var elements = ["COBRE", "FERRO", "ALUMINIO"]
	var chosen_element = elements.pick_random()
	
	robot.serial_number = "ENEMY-%s-%s-%03d" % [chosen_element, preferred_model, randi_range(1, 999)]
	robot.type = get_robot_type(chosen_element, preferred_model)
	robot.rarity = RobotData.Rarity.COMUM
	
	apply_model_stats(robot, preferred_model)
	
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	return robot

func get_robot_type(element: String, model: String) -> RobotData.Type:
	match element:
		"COBRE":
			match model:
				"LIGHTNING": return RobotData.Type.COBRE_LIGHTNING
				"GUARDIAN": return RobotData.Type.COBRE_GUARDIAN
				"SWIFT": return RobotData.Type.COBRE_SWIFT
		"FERRO":
			match model:
				"LIGHTNING": return RobotData.Type.FERRO_LIGHTNING
				"GUARDIAN": return RobotData.Type.FERRO_GUARDIAN
				"SWIFT": return RobotData.Type.FERRO_SWIFT
		"ALUMINIO":
			match model:
				"LIGHTNING": return RobotData.Type.ALUMINIO_LIGHTNING
				"GUARDIAN": return RobotData.Type.ALUMINIO_GUARDIAN
				"SWIFT": return RobotData.Type.ALUMINIO_SWIFT
	
	return RobotData.Type.COBRE_LIGHTNING

func apply_model_stats(robot: RobotData, model: String):
	match model:
		"LIGHTNING":
			robot.base_attack = randi_range(7, 10) * 10
			robot.base_special_attack = randi_range(7, 10) * 10
			robot.base_defense = randi_range(7, 10) * 10
			robot.base_special_defense = randi_range(7, 10) * 10
			robot.base_health = randi_range(8, 11) * 10
			robot.base_speed = randi_range(7, 10) * 10
		
		"GUARDIAN":
			robot.base_attack = randi_range(5, 7) * 10
			robot.base_special_attack = randi_range(4, 6) * 10
			robot.base_defense = randi_range(10, 13) * 10
			robot.base_special_defense = randi_range(9, 12) * 10
			robot.base_health = randi_range(11, 14) * 10
			robot.base_speed = randi_range(4, 6) * 10
		
		"SWIFT":
			robot.base_attack = randi_range(9, 12) * 10
			robot.base_special_attack = randi_range(10, 13) * 10
			robot.base_defense = randi_range(5, 7) * 10
			robot.base_special_defense = randi_range(6, 8) * 10
			robot.base_health = randi_range(6, 9) * 10
			robot.base_speed = randi_range(11, 14) * 10

func initialize_timeline_2v2():
	timeline_units.clear()
	current_time = 0.0
	
	# Adicionar todas as 4 unidades na timeline
	var all_units = player_team + enemy_team
	
	for unit in all_units:
		var action_delay = time_multiplier / float(unit.get_speed_stat())
		timeline_units.append({
			"unit": unit,
			"next_action_time": action_delay
		})
	
	print("⏰ Timeline 2v2 inicializada com %d unidades" % timeline_units.size())

func process_next_action():
	if combat_ended:
		return
	
	var next_unit_data = get_next_acting_unit()
	if not next_unit_data:
		return
	
	current_acting_unit = next_unit_data.unit
	current_time = next_unit_data.next_action_time
	
	# Verificar se unidade ainda está viva
	if not current_acting_unit.is_alive():
		schedule_next_action(current_acting_unit)
		process_next_action()
		return
	
	# Determinar se é turno do player
	is_player_turn = (current_acting_unit in player_team)
	
	print("\n⏰ Tempo %.1f - Turno de: %s (%s)" % [
		current_time, 
		current_acting_unit.robot_data.get_model_display_name() if current_acting_unit.robot_data else "UNKNOWN",
		"FRONT" if current_acting_unit.current_position == CombatUnit.Position.FRONT else "BACK"
	])
	
	update_ui_2v2()
	update_turn_order_display()
	
	if is_player_turn:
		enable_player_buttons()
	else:
		disable_player_buttons()
		await get_tree().create_timer(1.0).timeout
		execute_ai_turn()

func get_next_acting_unit() -> Dictionary:
	if timeline_units.is_empty():
		return {}
	
	timeline_units.sort_custom(func(a, b): return a.next_action_time < b.next_action_time)
	return timeline_units[0]

func schedule_next_action(unit: CombatUnit):
	var action_delay = time_multiplier / float(unit.get_speed_stat())
	
	for i in range(timeline_units.size()):
		if timeline_units[i].unit == unit:
			timeline_units[i].next_action_time = current_time + action_delay
			break

func print_team_status():
	print("👥 PLAYER TEAM:")
	if player_team[0] and player_team[0].robot_data:
		print("  Front: %s (HP: %d)" % [player_team[0].robot_data.get_model_display_name(), player_team[0].current_hp])
	if player_team[1] and player_team[1].robot_data:
		print("  Back:  %s (HP: %d)" % [player_team[1].robot_data.get_model_display_name(), player_team[1].current_hp])
	print("🤖 ENEMY TEAM:")
	if enemy_team[0] and enemy_team[0].robot_data:
		print("  Front: %s (HP: %d)" % [enemy_team[0].robot_data.get_model_display_name(), enemy_team[0].current_hp])
	if enemy_team[1] and enemy_team[1].robot_data:
		print("  Back:  %s (HP: %d)" % [enemy_team[1].robot_data.get_model_display_name(), enemy_team[1].current_hp])

# 🆕 TARGETING SIMPLIFICADO - SEMPRE ATACA FRONT
func _on_attack_pressed():
	if not is_player_turn or combat_ended:
		return
	execute_player_action(CombatUnit.AttackType.PHYSICAL)

func _on_special_pressed():
	if not is_player_turn or combat_ended or not current_acting_unit.can_use_special_attack():
		return
	execute_player_action(CombatUnit.AttackType.SPECIAL)

# 🆕 SISTEMA DE LOG DE COMBATE
func add_log_entry(text: String, color: Color = Color.WHITE):
	"""Adiciona uma entrada ao log de combate com cor"""
	
	# Adicionar timestamp simples
	var entry = "[T%.0f] %s" % [current_time, text]
	combat_log_entries.append(entry)
	
	# Manter apenas últimas MAX_LOG_ENTRIES entradas
	if combat_log_entries.size() > MAX_LOG_ENTRIES:
		combat_log_entries.pop_front()
	
	# Atualizar UI do log
	update_combat_log_ui(color)

func update_combat_log_ui(last_entry_color: Color = Color.WHITE):
	"""Atualiza a interface do log de combate"""
	if not combat_log_container:
		return
	
	# Limpar labels existentes
	for child in combat_log_container.get_children():
		child.queue_free()
	
	# Criar labels para cada entrada do log
	for i in range(combat_log_entries.size()):
		var entry = combat_log_entries[i]
		var label = Label.new()
		label.text = entry
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 280  # Largura fixa
		
		# Cor especial para última entrada
		if i == combat_log_entries.size() - 1:
			label.modulate = last_entry_color
		else:
			label.modulate = Color.LIGHT_GRAY
		
		combat_log_container.add_child(label)
	
	# Auto-scroll para última entrada
	if combat_log_scroll:
		await get_tree().process_frame  # Aguardar UI atualizar
		combat_log_scroll.scroll_vertical = combat_log_scroll.get_v_scroll_bar().max_value

# 🆕 SISTEMA DE ANIMAÇÃO DE MORTE
func show_death_animation(dying_unit: CombatUnit):
	"""Mostra animação de morte com HP chegando a zero"""
	
	# Encontrar label correspondente à unidade que morreu
	var target_label: Label = null
	
	if dying_unit in player_team:
		if player_team[0] == dying_unit:
			target_label = player_front_label
		else:
			target_label = player_back_label
	else:
		if enemy_team[0] == dying_unit:
			target_label = enemy_front_label
		else:
			target_label = enemy_back_label
	
	if not target_label:
		return
	
	# Animação de HP chegando a zero
	var original_text = target_label.text
	var dying_name = dying_unit.robot_data.get_model_display_name() if dying_unit.robot_data else "ROBÔ"
	
	# Mostrar HP chegando a 0
	target_label.text = "%s\n🔴 0/0 HP" % dying_name
	target_label.modulate = Color.RED
	
	# Aguardar 1.5 segundos
	await get_tree().create_timer(1.5).timeout
	
	# Mostrar "DERROTADO" com fade
	target_label.text = "💀 %s\nDERROTADO" % dying_name
	
	# Animação de fade
	var tween = create_tween()
	tween.tween_property(target_label, "modulate:a", 0.5, 0.5)
	await tween.finished

func _on_switch_pressed():
	# TODO: Implementar troca de posições na FASE 2.4
	print("🔄 Sistema de troca de posições será implementado na FASE 2.4")

func execute_player_action(attack_type: CombatUnit.AttackType):
	print("\n=== AÇÃO DO PLAYER ===")
	
	current_acting_unit.reduce_cooldowns()
	
	# 🎯 TARGETING SIMPLIFICADO: Sempre atacar front primeiro
	var target = get_front_target(enemy_team)
	if not target:
		print("❌ Nenhum alvo disponível!")
		return
	
	var damage = calculate_damage(current_acting_unit, target, attack_type)
	var target_died = target.apply_damage(damage)
	
	if attack_type == CombatUnit.AttackType.SPECIAL:
		current_acting_unit.use_special_attack()
	
	var attack_name = "Ataque Básico" if attack_type == CombatUnit.AttackType.PHYSICAL else "Ataque Especial"
	var attacker_name = current_acting_unit.robot_data.get_model_display_name() if current_acting_unit.robot_data else "VOCÊ"
	var target_name = target.robot_data.get_model_display_name() if target.robot_data else "ALVO"
	
	print("🗡️ %s usa %s em %s! Dano: %d" % [attacker_name, attack_name, target_name, damage])
	
	# 🆕 ADICIONAR AO LOG DE COMBATE
	var attack_icon = "🗡️" if attack_type == CombatUnit.AttackType.PHYSICAL else "⚡"
	add_log_entry("%s %s atacou %s (%d dano)" % [attack_icon, attacker_name, target_name, damage], Color.CYAN)
	
	if target_died:
		print("💀 %s foi derrotado!" % target_name)
		add_log_entry("💀 %s foi derrotado!" % target_name, Color.RED)
		
		# 🆕 ANIMAÇÃO DE MORTE
		await show_death_animation(target)
		
		check_victory_condition()
		if combat_ended:
			return
	
	schedule_next_action(current_acting_unit)
	process_next_action()

func execute_ai_turn():
	print("\n=== AÇÃO DA IA ===")
	
	if combat_ended:
		return
	
	current_acting_unit.reduce_cooldowns()
	
	# 🎯 IA também usa targeting simplificado
	var target = get_front_target(player_team)
	if not target:
		print("❌ IA não encontrou alvo válido!")
		end_combat(true)  # Player vence se IA não tem alvo
		return
	
	var damage = calculate_damage(current_acting_unit, target, CombatUnit.AttackType.PHYSICAL)
	var target_died = target.apply_damage(damage)
	
	var attacker_name = current_acting_unit.robot_data.get_model_display_name() if current_acting_unit.robot_data else "IA"
	var target_name = target.robot_data.get_model_display_name() if target.robot_data else "SEU ROBÔ"
	
	print("🤖 %s ataca %s! Dano: %d" % [attacker_name, target_name, damage])
	
	# 🆕 ADICIONAR AO LOG DE COMBATE
	add_log_entry("🤖 %s atacou %s (%d dano)" % [attacker_name, target_name, damage], Color.ORANGE)
	
	if target_died:
		print("💀 %s foi derrotado!" % target_name)
		add_log_entry("💀 %s foi derrotado!" % target_name, Color.RED)
		
		# 🆕 ANIMAÇÃO DE MORTE
		await show_death_animation(target)
		
		check_victory_condition()
		if combat_ended:
			return
	
	schedule_next_action(current_acting_unit)
	process_next_action()

func calculate_damage(attacker: CombatUnit, defender: CombatUnit, attack_type: CombatUnit.AttackType) -> int:
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

func check_victory_condition():
	# Verificação segura de vitória
	var player_alive = false
	var enemy_alive = false
	
	# Verificar players vivos
	for unit in player_team:
		if unit and unit.is_alive():
			player_alive = true
			break
	
	# Verificar inimigos vivos
	for unit in enemy_team:
		if unit and unit.is_alive():
			enemy_alive = true
			break
	
	if not player_alive:
		end_combat(false)
	elif not enemy_alive:
		end_combat(true)

func end_combat(player_won: bool):
	combat_ended = true
	disable_player_buttons()
	
	if player_won:
		turn_label.text = "🏆 VITÓRIA! Time inimigo derrotado!"
		print("🏆 PLAYER TEAM VENCEU!")
		add_log_entry("🏆 VITÓRIA! Time inimigo derrotado!", Color.GREEN)
		
		var reward_sucata = 50  # Maior recompensa para 2v2
		GameManager.current_player.sucata += reward_sucata
		print("💰 Recompensa: +%d sucata" % reward_sucata)
		add_log_entry("💰 Recompensa: +%d sucata" % reward_sucata, Color.YELLOW)
	else:
		turn_label.text = "💀 DERROTA! Seu time foi destruído!"
		print("💀 PLAYER TEAM PERDEU!")
		add_log_entry("💀 DERROTA! Seu time foi destruído!", Color.RED)
	
	# Reduzir ciclos de robôs usados
	for unit in player_team:
		if unit.robot_data:
			unit.robot_data.remaining_cycles -= 1
			print("🔄 %s - Ciclos restantes: %d" % [unit.robot_data.serial_number, unit.robot_data.remaining_cycles])
			add_log_entry("🔄 %s perdeu 1 ciclo" % unit.robot_data.get_model_display_name(), Color.GRAY)
	
	GameManager.data_manager.save_game()
	
	await get_tree().create_timer(3.0).timeout
	_on_back_pressed()

# 🆕 UI ATUALIZADA PARA 2v2
func update_ui_2v2():
	if combat_ended:
		return
	
	# Atualizar labels dos teams
	update_team_labels()
	
	# Atualizar indicador de turno
	if is_player_turn and current_acting_unit and current_acting_unit.robot_data:
		turn_label.text = "🎯 SEU TURNO - %s (%s)" % [
			current_acting_unit.robot_data.get_model_display_name(),
			"FRONT" if current_acting_unit.current_position == CombatUnit.Position.FRONT else "BACK"
		]
		turn_label.modulate = Color.CYAN
	elif current_acting_unit and current_acting_unit.robot_data:
		turn_label.text = "⏳ TURNO INIMIGO - %s" % current_acting_unit.robot_data.get_model_display_name()
		turn_label.modulate = Color.ORANGE
	else:
		turn_label.text = "⏳ AGUARDANDO..."
		turn_label.modulate = Color.GRAY
	
	update_special_button_status()

func update_team_labels():
	# Player team - verificar se existem e estão vivos
	if player_team.size() > 0 and player_team[0] and player_team[0].is_alive() and player_team[0].robot_data:
		var hp_status = get_hp_status_icon(player_team[0])
		player_front_label.text = "🛡️ FRONT: %s\n%s %d/%d HP" % [
			player_team[0].robot_data.get_model_display_name(),
			hp_status,
			player_team[0].current_hp,
			player_team[0].max_hp
		]
		player_front_label.modulate = Color.WHITE
	else:
		player_front_label.text = "💀 FRONT: DERROTADO"
		player_front_label.modulate = Color.RED
	
	if player_team.size() > 1 and player_team[1] and player_team[1].is_alive() and player_team[1].robot_data:
		var hp_status = get_hp_status_icon(player_team[1])
		player_back_label.text = "⚔️ BACK: %s\n%s %d/%d HP" % [
			player_team[1].robot_data.get_model_display_name(),
			hp_status,
			player_team[1].current_hp,
			player_team[1].max_hp
		]
		player_back_label.modulate = Color.WHITE
	else:
		player_back_label.text = "💀 BACK: DERROTADO"
		player_back_label.modulate = Color.RED
	
	# Enemy team - verificar se existem e estão vivos
	if enemy_team.size() > 0 and enemy_team[0] and enemy_team[0].is_alive() and enemy_team[0].robot_data:
		var hp_status = get_hp_status_icon(enemy_team[0])
		enemy_front_label.text = "🔥 FRONT: %s\n%s %d/%d HP" % [
			enemy_team[0].robot_data.get_model_display_name(),
			hp_status,
			enemy_team[0].current_hp,
			enemy_team[0].max_hp
		]
		enemy_front_label.modulate = Color.WHITE
	else:
		enemy_front_label.text = "💀 FRONT: DERROTADO"
		enemy_front_label.modulate = Color.GRAY
	
	if enemy_team.size() > 1 and enemy_team[1] and enemy_team[1].is_alive() and enemy_team[1].robot_data:
		var hp_status = get_hp_status_icon(enemy_team[1])
		enemy_back_label.text = "🔥 BACK: %s\n%s %d/%d HP" % [
			enemy_team[1].robot_data.get_model_display_name(),
			hp_status,
			enemy_team[1].current_hp,
			enemy_team[1].max_hp
		]
		enemy_back_label.modulate = Color.WHITE
	else:
		enemy_back_label.text = "💀 BACK: DERROTADO"
		enemy_back_label.modulate = Color.GRAY

func get_hp_status_icon(unit: CombatUnit) -> String:
	var hp_percent = float(unit.current_hp) / float(unit.max_hp)
	if hp_percent > 0.6:
		return "🟢"
	elif hp_percent > 0.3:
		return "🟡"
	else:
		return "🔴"

func update_special_button_status():
	if not current_acting_unit or not is_player_turn:
		special_button.disabled = true
		special_button.modulate = Color.GRAY
		return
	
	if not current_acting_unit.can_use_special_attack():
		if current_acting_unit.robot_data.equipped_arms == "":
			special_button.text = "❌ SEM BRAÇO"
		else:
			var cooldown = current_acting_unit.special_attack_cooldown
			special_button.text = "⏰ ESPECIAL (%d)" % cooldown
		special_button.disabled = true
		special_button.modulate = Color.GRAY
	else:
		special_button.text = "⚡ ATAQUE ESPECIAL"
		special_button.disabled = false
		special_button.modulate = Color.WHITE

func enable_player_buttons():
	attack_button.disabled = false
	attack_button.modulate = Color.WHITE
	switch_button.disabled = false
	switch_button.modulate = Color.WHITE
	update_special_button_status()

func disable_player_buttons():
	disable_action_buttons()
	switch_button.disabled = true
	switch_button.modulate = Color.GRAY

func disable_action_buttons():
	attack_button.disabled = true
	attack_button.modulate = Color.GRAY
	special_button.disabled = true
	special_button.modulate = Color.GRAY

func update_turn_order_display():
	var next_turns = get_timeline_preview(6)
	if turn_order_ui:
		turn_order_ui.update_turn_order(next_turns)

func get_timeline_preview(look_ahead_actions: int = 6) -> Array:
	var preview = []
	var temp_timeline = timeline_units.duplicate(true)
	
	for i in range(look_ahead_actions):
		if temp_timeline.is_empty():
			break
		
		temp_timeline.sort_custom(func(a, b): return a.next_action_time < b.next_action_time)
		
		var next_data = temp_timeline[0]
		var unit = next_data.unit
		
		if not unit.is_alive():
			temp_timeline.erase(next_data)
			continue
		
		preview.append({
			"unit": unit,
			"turn_number": i + 1,
			"action_time": next_data.next_action_time,
			"is_current_turn": (i == 0)
		})
		
		var action_delay = time_multiplier / float(unit.get_speed_stat())
		next_data.next_action_time += action_delay
	
	return preview

# 🎯 FUNÇÃO AUXILIAR PARA TARGETING SIMPLIFICADO
func get_front_target(team: Array[CombatUnit]) -> CombatUnit:
	"""Retorna o alvo prioritário: Front se vivo, senão Back"""
	
	# Sempre atacar front primeiro (index 0)
	if team.size() > 0 and team[0] and team[0].is_alive():
		return team[0]
	
	# Se front morto, atacar back (index 1)
	if team.size() > 1 and team[1] and team[1].is_alive():
		return team[1]
	
	# Nenhum alvo disponível
	return null

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
