# PieceData.gd - Versão Simplificada MVP
extends Resource
class_name PieceData

enum PartType { BRAÇOS }  # Apenas braços para MVP
enum Rarity { COMUM }     # Apenas comum para MVP

@export var id: String
@export var part_type: PartType = PartType.BRAÇOS
@export var rarity: Rarity = Rarity.COMUM

# Stats (primário + 2 secundários)
@export var primary_stat: int = 20  # Ataque Especial
@export var secondary_stat_1: int
@export var secondary_stat_2: int
@export var secondary_stat_1_type: String
@export var secondary_stat_2_type: String

# Durabilidade simplificada
@export var max_durability: int = 10
@export var current_durability: int = 10

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
