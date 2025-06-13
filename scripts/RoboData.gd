# RobotData.gd - Sistema de Raridades Completo + Modelos Dirigidos
extends Resource
class_name RobotData

enum Type { 
	COBRE_LIGHTNING,
	COBRE_GUARDIAN,
	COBRE_SWIFT,
	FERRO_LIGHTNING,
	FERRO_GUARDIAN,
	FERRO_SWIFT,
	ALUMINIO_LIGHTNING,
	ALUMINIO_GUARDIAN,
	ALUMINIO_SWIFT
}

# 🆕 SISTEMA DE RARIDADES COMPLETO
enum Rarity { 
	COMUM,     # 1.0x ± 5%
	INCOMUM,   # 1.15x ± 7%
	RARO,      # 1.35x ± 8%
	EPICO,     # 1.6x ± 10%
	LENDARIO   # 2.0x ± 12% + habilidade única
}

@export var serial_number: String
@export var type: Type = Type.COBRE_LIGHTNING
@export var rarity: Rarity = Rarity.COMUM

# Stats básicos (ranges base do database)
@export var base_attack: int = 70
@export var base_defense: int = 60
@export var base_special_attack: int = 75
@export var base_special_defense: int = 55
@export var base_health: int = 120
@export var base_speed: int = 50

# Peças equipadas
@export var equipped_arms: String = ""
@export var equipped_core: String = ""
@export var equipped_legs: String = ""

# Ciclos de vida
@export var max_cycles: int = 20
@export var remaining_cycles: int = 20

# 🆕 MULTIPLICADORES DE RARIDADE
const RARITY_MULTIPLIERS = {
	Rarity.COMUM: 1.0,
	Rarity.INCOMUM: 1.15,
	Rarity.RARO: 1.35,
	Rarity.EPICO: 1.6,
	Rarity.LENDARIO: 2.0
}

const RARITY_VARIATIONS = {
	Rarity.COMUM: 0.05,      # ± 5%
	Rarity.INCOMUM: 0.07,    # ± 7%
	Rarity.RARO: 0.08,       # ± 8%
	Rarity.EPICO: 0.10,      # ± 10%
	Rarity.LENDARIO: 0.12    # ± 12%
}

func get_element_type() -> String:
	match type:
		Type.COBRE_LIGHTNING, Type.COBRE_GUARDIAN, Type.COBRE_SWIFT:
			return "COBRE"
		Type.FERRO_LIGHTNING, Type.FERRO_GUARDIAN, Type.FERRO_SWIFT:
			return "FERRO"
		Type.ALUMINIO_LIGHTNING, Type.ALUMINIO_GUARDIAN, Type.ALUMINIO_SWIFT:
			return "ALUMINIO"
		_:
			return "COBRE"

func get_model_type() -> String:
	match type:
		Type.COBRE_LIGHTNING, Type.FERRO_LIGHTNING, Type.ALUMINIO_LIGHTNING:
			return "LIGHTNING"
		Type.COBRE_GUARDIAN, Type.FERRO_GUARDIAN, Type.ALUMINIO_GUARDIAN:
			return "GUARDIAN"
		Type.COBRE_SWIFT, Type.FERRO_SWIFT, Type.ALUMINIO_SWIFT:
			return "SWIFT"
		_:
			return "LIGHTNING"

func get_model_display_name() -> String:
	var element = get_element_type()
	var model = get_model_type()
	return "%s %s" % [element, model]

func get_rarity_name() -> String:
	match rarity:
		Rarity.COMUM: return "Comum"
		Rarity.INCOMUM: return "Incomum"
		Rarity.RARO: return "Raro"
		Rarity.EPICO: return "Épico"
		Rarity.LENDARIO: return "Lendário"
		_: return "Comum"

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMUM: return Color.WHITE
		Rarity.INCOMUM: return Color.GREEN
		Rarity.RARO: return Color.BLUE
		Rarity.EPICO: return Color.PURPLE
		Rarity.LENDARIO: return Color.GOLD
		_: return Color.WHITE

# 🆕 APLICAR MULTIPLICADORES DE RARIDADE
func apply_rarity_multiplier(base_value: int) -> int:
	var multiplier = RARITY_MULTIPLIERS[rarity]
	var variation = RARITY_VARIATIONS[rarity]
	
	# Aplicar multiplicador + variação aleatória
	var min_mult = multiplier - variation
	var max_mult = multiplier + variation
	var final_multiplier = randf_range(min_mult, max_mult)
	
	return int(base_value * final_multiplier)

func get_final_stats() -> Dictionary:
	# Stats base já com multiplicador aplicado
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

# 🆕 HABILIDADES LENDÁRIAS (para futuro)
func get_legendary_ability() -> Dictionary:
	if rarity != Rarity.LENDARIO:
		return {}
	
	match get_model_type():
		"LIGHTNING":
			return {
				"name": "Eco Eterno",
				"description": "30% chance de +30% dano baseado em dano acumulado",
				"proc_chance": 0.3
			}
		"GUARDIAN":
			return {
				"name": "Força Absoluta", 
				"description": "30% chance de +50% ATK por 3 turnos após kill",
				"proc_chance": 0.3
			}
		"SWIFT":
			return {
				"name": "Velocidade Temporal",
				"description": "30% chance de turno duplo (cooldown 3)",
				"proc_chance": 0.3
			}
		_:
			return {}

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
