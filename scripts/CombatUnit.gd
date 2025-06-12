# CombatUnit.gd - Representa um robô em combate (CORRIGIDO)
extends Resource
class_name CombatUnit

enum Position { FRONT, BACK }
enum AttackType { PHYSICAL, SPECIAL }

# Referência ao robô original
@export var robot_data: RobotData

# Estado atual de combate
@export var current_hp: int
@export var max_hp: int
@export var current_position: Position = Position.FRONT

# Status de combate
@export var special_attack_cooldown: int = 0

func _init(robot: RobotData = null):
	if robot:
		robot_data = robot
		var stats = robot.get_final_stats()
		max_hp = stats.health
		current_hp = max_hp

func get_attack_stat() -> int:
	if robot_data:
		return robot_data.get_final_stats().attack
	return 50

func get_defense_stat() -> int:
	if robot_data:
		return robot_data.get_final_stats().defense
	return 50

func get_special_attack_stat() -> int:
	if robot_data:
		return robot_data.get_final_stats().special_attack
	return 50

func get_special_defense_stat() -> int:
	if robot_data:
		return robot_data.get_final_stats().special_defense
	return 50

func get_speed_stat() -> int:
	if robot_data:
		return robot_data.get_final_stats().speed
	return 50

func can_use_special_attack() -> bool:
	# Verifica se tem arm equipado E não está em cooldown
	if not robot_data:
		return false
	
	var has_arm = (robot_data.equipped_arms != "")
	var no_cooldown = (special_attack_cooldown <= 0)
	
	print("🔍 Verificando special attack: braço=%s, cooldown=%d, pode_usar=%s" % [
		has_arm, special_attack_cooldown, (has_arm and no_cooldown)
	])
	
	return has_arm and no_cooldown

func apply_damage(damage: int) -> bool:
	current_hp = max(0, current_hp - damage)
	return current_hp <= 0  # retorna true se morreu

func get_element() -> String:
	if robot_data:
		var element_type = robot_data.get_element_type()
		match element_type:
			"COBRE":
				return "COPPER"
			"FERRO":
				return "IRON"
			"ALUMINIO":
				return "ALUMINUM"
		return "COPPER"
	return "COPPER"

func get_model() -> String:
	if robot_data:
		return robot_data.get_model_type()
	return "LIGHTNING"

func get_arm_element() -> String:
	# Por enquanto, retorna mesmo elemento do robô
	# TODO: Implementar quando tivermos arms com elementos diferentes
	return get_element()

func is_alive() -> bool:
	return current_hp > 0

func get_hp_percentage() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)

func get_display_name() -> String:
	if robot_data:
		return robot_data.get_model_display_name() + " (" + robot_data.serial_number + ")"
	return "Robô Desconhecido"

func reduce_cooldowns():
	if special_attack_cooldown > 0:
		special_attack_cooldown -= 1
		print("🔄 Cooldown reduzido para: %d" % special_attack_cooldown)

func use_special_attack():
	special_attack_cooldown = 2  # 2 turnos de cooldown
	print("🔥 Special attack usado! Cooldown definido para: %d" % special_attack_cooldown)
