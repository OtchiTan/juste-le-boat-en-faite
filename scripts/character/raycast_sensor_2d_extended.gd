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
			
@onready var BoatOwner : Boat = get_parent()

func get_observation() -> Array:
	var rslts = self.calculate_raycasts()
	return rslts

func _spawn_nodes():
	for ray in rays:
		ray.queue_free()
	rays = []

	_angles = []
	var step = cone_width / (n_rays)
	var start = cone_width / ray_groupping / 2

	for i in n_rays:
		var angle = start + i * step
		var ray = RayCast2D.new()
		ray.set_target_position(
			Vector2(ray_length * cos(deg_to_rad(angle)), ray_length * sin(deg_to_rad(angle)))
		)
		ray.set_name("node_" + str(i))
		ray.enabled = false
		ray.collide_with_areas = collide_with_areas
		ray.collide_with_bodies = collide_with_bodies
		ray.collision_mask = collision_mask
		add_child(ray)
		rays.append(ray)

		_angles.append(start + i * step)

func calculate_raycasts() -> Array:
	var result = []
	var range_squared =  ray_length * ray_length
	var Id_Already_Collid = []
	
	var first_angle = BoatOwner.global_transform.x.angle_to(rays[0].target_position)
	var inv_of_range :float= 1.0 / sqrt(ray_length)
	for i in range(0, n_rays, ray_groupping) :
		var min_dist = range_squared
		var min_d_index = i
		for j in range(i, i + ray_groupping):
			var iray = rays[j]
			iray.enabled = true
			iray.force_raycast_update()
			
			if iray.is_colliding():
				var collider_t = iray.get_collider()
				if not Id_Already_Collid.has(collider_t.get_instance_id()):
					if collider_t as Boat : 
						Id_Already_Collid.append(collider_t.get_instance_id())
					
					var distance = (iray.get_collision_point() - iray.global_position).length_squared()
					if distance < min_dist:
						min_dist = distance
						min_d_index = j
		var normalized_min_dist = sqrt(sqrt(min_dist)) * inv_of_range
		result.append(normalized_min_dist)
		
		if not add_friend_foe_info:
			continue
			
		var ray = rays[min_d_index]
		var is_enemy = 0.0
		var is_ally = 0.0
		
		var collider = ray.get_collider()
		var is_moving = 0.0
		
		var norm_relative_target_rotation = 0
		var norm_target_velocity :Vector2 = Vector2(0,0)
		
		var targetHP = 0
		
		var norm_target_angle = -1
		
		if collider:
			var relation = FactionManager.get_relation(BoatOwner, collider)
			match relation:
				FactionManager.Relation.ALLY:
					is_ally = 1.0
				FactionManager.Relation.ENEMY:
					is_enemy = 1.0
				FactionManager.Relation.NEUTRAL:
					pass
					
			var moving_collider = collider as RigidBody2D
			if moving_collider :
				is_moving = 1
				var relative_targ_rot = BoatOwner.rotation - moving_collider.rotation
				
				
				norm_relative_target_rotation =(fmod(relative_targ_rot+3*PI,2*PI)-PI)/PI
				
				
				var owner_forward = BoatOwner.global_transform.x
				var relative_t_pos = moving_collider.global_position - BoatOwner.global_position
				var angle_to_target = Vector2.from_angle(owner_forward.angle_to_point(relative_t_pos))
				norm_target_velocity.x = moving_collider.linear_velocity.dot(angle_to_target) / 250
				norm_target_velocity.y = (moving_collider.linear_velocity).dot(angle_to_target.rotated(PI/2)) /250
				
				norm_target_angle = fmod(owner_forward.angle_to_point(relative_t_pos) + 2*PI + first_angle, 2*PI/(n_rays/ray_groupping))/(2*PI/(n_rays/ray_groupping))
				
				
			if "life" in collider and "original_life" in collider :
				targetHP = collider.life / collider.original_life
		result.append(is_moving)
		result.append(is_enemy)
		result.append(is_ally)
		result.append(norm_target_velocity.x)
		result.append(norm_target_velocity.y)
		result.append(norm_relative_target_rotation)
		result.append(norm_target_angle)
		result.append(targetHP)

	for ray in rays :
		ray.enabled = false
	return result
