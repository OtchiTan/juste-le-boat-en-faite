@tool
extends RaycastSensor2D

class_name RaycastSensor2D_extended

##add an output with -1 (ennemy) / 0 (world) / 1 (ally) for each ray.
## if a cast is both... returns ennemy.
@export var add_friend_foe_info := false
## collision on this layer will return 1
@export_flags_2d_physics var friend_layer = 2:
	get:
		return friend_layer
	set(value):
		friend_layer = value
		_update()

## collision on this layer will return -1
@export_flags_2d_physics var foe_layer = 3:
	get:
		return foe_layer
	set(value):
		foe_layer = value
		_update()
## collision on this layer will return 0
@export_flags_2d_physics var world_layer = 8:
	get:
		return world_layer
	set(value):
		world_layer = value
		_update()
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

func get_observation() -> Array:
	var rslts = self.calculate_raycasts()
	return rslts

func calculate_raycasts() -> Array:
	var result = []
	for i in range(0, n_rays, ray_groupping) :
		var iray = rays[i]
		iray.enabled = true
		iray.force_raycast_update()
		var min_dist = _get_raycast_distance(iray)
		var min_d_index = i
		for j in range(i+1, i+ray_groupping) :
			iray = rays[j]
			iray.enabled = true
			iray.force_raycast_update()
			var distance = _get_raycast_distance(iray)
			if (distance > min_dist) :
				min_dist = distance
				min_d_index = j

		result.append(min_dist)
		if add_friend_foe_info:
			var ray = rays[min_d_index]
			var hit_class: float = 0
			if ray.get_collider():
				var hit_collision_layer = ray.get_collider().collision_layer
				if (hit_collision_layer & foe_layer) :
					hit_class = -1
				elif (hit_collision_layer & friend_layer) :
					hit_class = 1
			result.append(float(hit_class))

	for ray in rays :
		ray.enabled = false
	return result
