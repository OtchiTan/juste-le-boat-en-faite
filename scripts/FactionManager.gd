extends Node

enum Relation { NEUTRAL, ALLY, ENEMY }

# { player_id: { cible_id: Relation } }
var diplomacy_matrix = {}

func _ready():
	register_faction(0) #faction neutre random ??? (pour le lol)

# Ajoute une nouvelle faction au système
func register_faction(player_id: int):
	if not diplomacy_matrix.has(player_id):
		diplomacy_matrix[player_id] = {}

func set_relation(player_a: int, player_b: int, relation: Relation):
	register_faction(player_a)
	register_faction(player_b)
	diplomacy_matrix[player_a][player_b] = relation
	diplomacy_matrix[player_b][player_a] = relation

func get_relation(observer: Node, target: Node) -> Relation:
	# 1. si c'est pas un truc d'une faction...
	
	var obs_id = -1
	var t_id = -1
	
	if "player_id" in observer:
			obs_id = observer.player_id
	if "target_id" in target:
		t_id = target.target_id
	elif "player_id" in target:
		t_id = target.player_id
	if (obs_id > -1 and t_id > -1) :
		return get_player_relation(obs_id, t_id)
	
	return Relation.NEUTRAL

func get_player_relation(obs_player_id: int, target_player_id: int) -> Relation:
	if obs_player_id == target_player_id:
		return Relation.ALLY
	
	if diplomacy_matrix.has(obs_player_id) and diplomacy_matrix[obs_player_id].has(target_player_id):
		return diplomacy_matrix[obs_player_id][target_player_id]
	
	return Relation.ENEMY
	
