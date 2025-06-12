# CombatSystem.gd - Sistema principal de combate (SEM MODELFACTORY)
extends Node

# Elemental advantages: Copper > Iron > Aluminum > Copper
const ELEMENTAL_BONUS = 1.15  # +15% damage

static func calculate_damage(attacker: CombatUnit, defender: CombatUnit, attack_type: CombatUnit.AttackType) -> int:
	var base_damage: int
	var attacker_element: String
	var defender_defense: int
	
	# Determinar stats baseado no tipo de ataque
	match attack_type:
		CombatUnit.AttackType.PHYSICAL:
			base_damage = attacker.get_attack_stat()
			attacker_element = attacker.get_element()
			defender_defense = defender.get_defense_stat()
		CombatUnit.AttackType.SPECIAL:
			base_damage = attacker.get_special_attack_stat()
			attacker_element = attacker.get_arm_element()
			defender_defense = defender.get_special_defense_stat()
	
	# NOVA FÓRMULA MAIS CONSERVADORA
	var effective_defense = defender_defense * 0.8  # Defesa 80% efetiva
	var raw_damage = base_damage - effective_defense
	var damage = max(base_damage * 0.2, raw_damage + randi_range(-2, 5)) # Dano mínimo = 20% do ataque
	
	# Aplicar vantagem elemental
	var elemental_multiplier = get_elemental_multiplier(attacker_element, defender.get_element())
	damage = int(damage * elemental_multiplier)
	
	return damage

static func get_elemental_multiplier(attacker_element: String, defender_element: String) -> float:
	# Copper > Iron > Aluminum > Copper
	match attacker_element:
		"COPPER":
			if defender_element == "IRON":
				return ELEMENTAL_BONUS
		"IRON":
			if defender_element == "ALUMINUM":
				return ELEMENTAL_BONUS
		"ALUMINUM":
			if defender_element == "COPPER":
				return ELEMENTAL_BONUS
	
	return 1.0  # Sem vantagem/desvantagem

static func get_elemental_effectiveness(attacker_element: String, defender_element: String) -> String:
	var multiplier = get_elemental_multiplier(attacker_element, defender_element)
	if multiplier > 1.0:
		return "Super efetivo!"
	elif multiplier < 1.0:
		return "Pouco efetivo..."
	else:
		return ""

static func create_enemy_robot() -> RobotData:
	# Criar inimigo SEM ModelFactory - função interna
	var robot = RobotData.new()
	
	# Escolher modelo e elemento aleatório
	var models = ["LIGHTNING", "GUARDIAN", "SWIFT"]
	var elements = ["COBRE", "FERRO", "ALUMINIO"]
	
	var chosen_model = models.pick_random()
	var chosen_element = elements.pick_random()
	
	# Gerar número de série
	robot.serial_number = "ENEMY-%s-%s-%03d" % [chosen_element, chosen_model, randi_range(1, 999)]
	
	# Determinar tipo enum
	robot.type = get_robot_type(chosen_element, chosen_model)
	robot.rarity = RobotData.Rarity.COMUM
	
	# Aplicar stats dirigidos
	apply_model_stats(robot, chosen_model)
	
	robot.remaining_cycles = 20
	robot.max_cycles = 20
	
	print("🤖 Inimigo criado: %s %s" % [chosen_element, chosen_model])
	print("📊 Enemy Stats: ATK:%d DEF:%d HP:%d SPD:%d" % [
		robot.base_attack, robot.base_defense, robot.base_health, robot.base_speed
	])
	
	return robot

static func get_robot_type(element: String, model: String) -> RobotData.Type:
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

static func apply_model_stats(robot: RobotData, model: String):
	# Stats dirigidos baseados no database (multiplicador 10x)
	match model:
		"LIGHTNING":  # Balanced
			robot.base_attack = randi_range(7, 10) * 10
			robot.base_special_attack = randi_range(7, 10) * 10
			robot.base_defense = randi_range(7, 10) * 10
			robot.base_special_defense = randi_range(7, 10) * 10
			robot.base_health = randi_range(8, 11) * 10
			robot.base_speed = randi_range(7, 10) * 10
		
		"GUARDIAN":  # Tank
			robot.base_attack = randi_range(5, 7) * 10
			robot.base_special_attack = randi_range(4, 6) * 10
			robot.base_defense = randi_range(10, 13) * 10
			robot.base_special_defense = randi_range(9, 12) * 10
			robot.base_health = randi_range(11, 14) * 10
			robot.base_speed = randi_range(4, 6) * 10
		
		"SWIFT":  # DPS
			robot.base_attack = randi_range(9, 12) * 10
			robot.base_special_attack = randi_range(10, 13) * 10
			robot.base_defense = randi_range(5, 7) * 10
			robot.base_special_defense = randi_range(6, 8) * 10
			robot.base_health = randi_range(6, 9) * 10
			robot.base_speed = randi_range(11, 14) * 10

static func determine_turn_order(player_unit: CombatUnit, enemy_unit: CombatUnit) -> Array[CombatUnit]:
	# Ordem baseada em velocidade
	if player_unit.get_speed_stat() >= enemy_unit.get_speed_stat():
		return [player_unit, enemy_unit]
	else:
		return [enemy_unit, player_unit]

class SimpleAI:
	static func choose_action(ai_unit: CombatUnit, target: CombatUnit) -> Dictionary:
		# IA mais agressiva: 60% chance de especial se disponível
		
		if ai_unit.can_use_special_attack() and randf() < 0.6:
			return {
				"type": CombatUnit.AttackType.SPECIAL,
				"target": target
			}
		else:
			return {
				"type": CombatUnit.AttackType.PHYSICAL,
				"target": target
			}
	
	static func get_action_description(action: Dictionary) -> String:
		match action.type:
			CombatUnit.AttackType.PHYSICAL:
				return "Inimigo usa Ataque Básico!"
			CombatUnit.AttackType.SPECIAL:
				return "Inimigo usa Ataque Especial!"
		return "Ação desconhecida"
