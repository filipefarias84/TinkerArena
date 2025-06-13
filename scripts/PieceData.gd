# PieceData.gd - Sistema de Raridades Completo
extends Resource
class_name PieceData

enum PartType { BRAÇOS }  # Apenas braços para MVP

# 🆕 SISTEMA DE RARIDADES COMPLETO
enum Rarity { 
	COMUM,     # 1.0x ± 5%
	INCOMUM,   # 1.15x ± 7%
	RARO,      # 1.35x ± 8%
	EPICO,     # 1.6x ± 10%
	LENDARIO   # 2.0x ± 12% + efeito especial
}

@export var id: String
@export var part_type: PartType = PartType.BRAÇOS
@export var rarity: Rarity = Rarity.COMUM

# Stats (primário + 2 secundários)
@export var primary_stat: int = 20  # Ataque Especial
@export var secondary_stat_1: int
@export var secondary_stat_2: int
@export var secondary_stat_1_type: String
@export var secondary_stat_2_type: String

# Durabilidade baseada na raridade
@export var max_durability: int = 10
@export var current_durability: int = 10

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

# 🆕 CICLOS POR RARIDADE (conforme database)
const RARITY_CYCLES = {
	Rarity.COMUM: 15,
	Rarity.INCOMUM: 25,
	Rarity.RARO: 35,
	Rarity.EPICO: 50,
	Rarity.LENDARIO: 65
}

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

# 🆕 EFEITOS ESPECIAIS LENDÁRIOS
func get_legendary_effect() -> Dictionary:
	if rarity != Rarity.LENDARIO:
		return {}
	
	# Efeitos baseados no database de Arms
	return {
		"name": "Tempestade Acumulativa",
		"description": "Cada Special Attack sucessivo aumenta o dano do próximo em +20% (máximo 3 stacks)",
		"type": "combat_bonus"
	}

func to_dict() -> Dictionary:
	return {
		"id": id,
		"part_type": part_type,
		"rarity": rarity,
		"primary_stat": primary_stat,
		"secondary_stat_1": secondary_stat_1,
		"secondary_stat_2": secondary_stat_2,
		"secondary_stat_1_type": secondary_stat_1_type,
		"secondary_stat_2_type": secondary_stat_2_type,
		"max_durability": max_durability,
		"current_durability": current_durability
	}
