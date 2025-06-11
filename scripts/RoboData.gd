# RobotData.gd - Versão Simplificada MVP
extends Resource
class_name RobotData

enum Type { COBRE }  # Apenas Cobre para MVP
enum Rarity { COMUM }  # Apenas Comum para MVP

@export var serial_number: String
@export var type: Type = Type.COBRE
@export var rarity: Rarity = Rarity.COMUM

# Stats básicos
@export var base_attack: int = 100
@export var base_defense: int = 80
@export var base_special_attack: int = 90
@export var base_special_defense: int = 75
@export var base_health: int = 150
@export var base_speed: int = 60

# Peças equipadas
@export var equipped_arms: String = ""
@export var equipped_core: String = ""  # Para futuro
@export var equipped_legs: String = ""  # Para futuro

# Ciclos de vida
@export var max_cycles: int = 20
@export var remaining_cycles: int = 20

func get_final_stats() -> Dictionary:
	var stats = {
		"attack": base_attack,
		"defense": base_defense,
		"special_attack": base_special_attack,
		"special_defense": base_special_defense,
		"health": base_health,
		"speed": base_speed
	}
	
	# Aplicar bônus de peças equipadas
	apply_piece_bonuses(stats)
	
	return stats

func apply_piece_bonuses(stats: Dictionary) -> void:
	# Bônus do braço equipado
	if equipped_arms != "":
		var arm_piece = GameManager.data_manager.get_piece_by_id(equipped_arms)
		if arm_piece:
			# Stat primário (sempre Ataque Especial para braços)
			stats["special_attack"] += arm_piece.primary_stat
			
			# Stats secundários
			if arm_piece.secondary_stat_1_type != "":
				var stat_name = normalize_stat_name(arm_piece.secondary_stat_1_type)
				if stats.has(stat_name):
					stats[stat_name] += arm_piece.secondary_stat_1
			
			if arm_piece.secondary_stat_2_type != "":
				var stat_name = normalize_stat_name(arm_piece.secondary_stat_2_type)
				if stats.has(stat_name):
					stats[stat_name] += arm_piece.secondary_stat_2

func normalize_stat_name(stat_type: String) -> String:
	# Converter nomes de stats para chaves do dicionário
	match stat_type.to_lower():
		"attack":
			return "attack"
		"defense":
			return "defense"
		"special_attack", "special attack":
			return "special_attack"
		"special_defense", "special defense":
			return "special_defense"
		"health", "vida":
			return "health"
		"speed", "velocidade":
			return "speed"
		_:
			print("⚠️ Stat type não reconhecido: " + stat_type)
			return "attack"  # fallback

func to_dict() -> Dictionary:
	return {
		"serial_number": serial_number,
		"type": type,
		"rarity": rarity,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"base_special_attack": base_special_attack,
		"base_special_defense": base_special_defense,
		"base_health": base_health,
		"base_speed": base_speed,
		"equipped_arms": equipped_arms,
		"equipped_core": equipped_core,
		"equipped_legs": equipped_legs,
		"max_cycles": max_cycles,
		"remaining_cycles": remaining_cycles
	}
