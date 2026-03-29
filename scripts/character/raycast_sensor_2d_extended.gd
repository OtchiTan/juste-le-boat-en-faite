@tool
extends RaycastSensor2D

class_name RaycastSensor2D_extended

##add an output with -1 (ennemy) / 0 (world) / 1 (ally) for each ray.
## if a cast is both... returns ennemy.
@export var add_friend_foe_info := false
## merge the return of raycasts to simplify the life of the AI
@export var ray_groupping := 1:
	get:
		return ray_groupping
	set(value):
		if (value >= 1) :
			ray_groupping = value
			if (value == 1) :
				rays_share_groups = false
			_update()
			
## TO BE IMPLEMENTED
## wether the ray on the border can be shared between 2 groups.
@export var rays_share_groups := false:
	get:
		return rays_share_groups
	set(value):
		if (ray_groupping >= 2) :
			rays_share_groups = value
			_update()
			
@onready var BoatOwner = get_parent()

func get_observation() -> Array:
	var rslts = self.calculate_raycasts()
	return rslts

func calculate_raycasts() -> Array:
	var result = []
	var range_squared =  ray_length * ray_length
	for i in range(0, n_rays, ray_groupping) :
		var min_dist = range_squared
		var min_d_index = i
		for j in range(i, i + ray_groupping):
			var iray = rays[j]
			iray.enabled = true
			iray.force_raycast_update()
			
			if iray.is_colliding():
				var distance = (iray.get_collision_point() - iray.global_position).length_squared()
				if distance < min_dist:
					min_dist = distance
					min_d_index = j

		result.append(min_dist / range_squared)
		
		if add_friend_foe_info:
			var ray = rays[min_d_index]
			var is_enemy = 0.0
			var is_ally = 0.0
			
			var collider = ray.get_collider()
			var is_moving = 1.0 if (collider is RigidBody2D or collider is CharacterBody2D) else 0.0
			
			if collider:
				var relation = FactionManager.get_relation(BoatOwner, collider)
				match relation:
					FactionManager.Relation.ALLY:
						is_ally = 1.0
					FactionManager.Relation.ENEMY:
						is_enemy = 1.0
					FactionManager.Relation.NEUTRAL:
						pass
					
			result.append(is_moving)
			result.append(is_enemy)
			result.append(is_ally)


	for ray in rays :
		ray.enabled = false
	return result
