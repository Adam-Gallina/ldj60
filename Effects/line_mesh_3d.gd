extends MeshInstance3D
class_name LineMesh3D

@export var point_offset : Vector3 = Vector3.ZERO
@export var MaxWidth : float = .35
## 0 = start, 1 = end
@export var Width : Curve
@export var DisplayBillboard = false


func _ready():
	mesh = ImmediateMesh.new()

func set_point_offset(offset : Vector3): point_offset = offset
func set_color(color : Color):
	material_overlay = StandardMaterial3D.new()
	material_overlay.albedo_color = color
func set_max_width(width:float): MaxWidth = width

func clear():
	mesh.clear_surfaces()

func calc_width(t:float):
	if t < 0: t = 0
	elif t > 1: t = 1

	return Width.sample(t) * MaxWidth

func display_line(positions : PackedVector3Array):
	var widths : Array[float] = []
	for i in range(positions.size()):
		widths.append(calc_width(float(i) / (positions.size()-1)))

	display_varying_line(positions, widths)

func display_varying_line(positions : PackedVector3Array, widths : Array[float]):
	if widths.size() == 0:
		printerr('display_line: too many widths in input, some will be ignored')
	if widths.size() > positions.size():
		printerr('display_line: too many widths in input, some will be ignored')
	elif widths.size() < positions.size():
		printerr('display_line: not enough widths in input, final width will be reused')
		while widths.size() < positions.size():
			widths.append(widths[-1])

	mesh.clear_surfaces()
	mesh.surface_begin(PrimitiveMesh.PRIMITIVE_TRIANGLE_STRIP)

	for i in range(positions.size()):
		var normal = Vector3.UP if not DisplayBillboard else (get_viewport().get_camera_3d().global_position - global_position).normalized()

		var dir = Vector3()
		if i < positions.size() - 1:
			var to_next = positions[i+1] - positions[i]
			var normal_next = to_next.cross(normal).normalized()
			dir += normal_next
		if i > 0:
			var to_prev = positions[i-1] - positions[i]
			var normal_prev = to_prev.cross(normal).normalized()
			dir -= normal_prev
		dir = dir.normalized()



		mesh.surface_set_normal(Vector3.UP) 
		mesh.surface_add_vertex(positions[i] + dir * widths[i] / 2 + point_offset)
		mesh.surface_set_normal(Vector3.UP)
		mesh.surface_add_vertex(positions[i] - dir * widths[i] / 2 + point_offset)

	mesh.surface_end()


func display_donut(center : Vector3, inner_radius : float, max_points : int = 18):
	var points : PackedVector3Array = []
	var ang = 2 * PI / (max_points-1)

	var p = Vector3.FORWARD * (inner_radius + MaxWidth / 2)
	for i in range(max_points):
		points.append(center + p + point_offset)
		p = p.rotated(Vector3.UP, ang)
	
	display_line(points)


## start_ang and end_ang in degrees
func display_arc(center:Vector3, inner_radius:float, start_ang:float, end_ang:float, max_points:int = 18):
	var points : PackedVector3Array = []
	var ang = deg_to_rad(end_ang - start_ang) / (max_points-1)

	var p = Vector3.FORWARD * (inner_radius + MaxWidth / 2)
	p = p.rotated(Vector3.UP, deg_to_rad(start_ang))
	for i in range(max_points):
		points.append(center + p + point_offset)
		p = p.rotated(Vector3.UP, ang)
	
	display_line(points)
