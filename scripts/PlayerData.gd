# PlayerData.gd - Versão Simplificada MVP
extends Resource
class_name PlayerData

@export var tinker_name: String = "Tinker"
@export var level: int = 1
@export var sucata: int = 0

# Progresso simplificado das fábricas
@export var fundição_level: int = 1
@export var arsenal_level: int = 1

func to_dict() -> Dictionary:
	return {
		"tinker_name": tinker_name,
		"level": level,
		"sucata": sucata,
		"fundição_level": fundição_level,
		"arsenal_level": arsenal_level
	}

func from_dict(data: Dictionary):
	tinker_name = data.get("tinker_name", "Tinker")
	level = data.get("level", 1)
	sucata = data.get("sucata", 0)
	fundição_level = data.get("fundição_level", 1)
	arsenal_level = data.get("arsenal_level", 1)
