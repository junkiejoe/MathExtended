--< Module begin >---
local MathExtended = {}

---- Const ----
local cos = math.cos
local sin = math.sin
local atan2 = math.atan2
local acos = math.acos

---- Types ----
export type PolygonProperties = {
	vertices: {Vector2},
	isConvex: boolean
}

export type S_Rect = {
	origin: Vector2,
	width: number,
	height: number,
	diagonal: number,
	-- Rotation angle (in radians)
	angle: number,
	-- Corners
	topLeft: Vector2,
	topRight: Vector2,
	bottomLeft: Vector2,
	bottomRight: Vector2,
	-- Untranslated corners
	ut_topLeft: Vector2,
	ut_topRight: Vector2,
	ut_bottomLeft: Vector2,
	ut_bottomRight: Vector2,
	polyProperties: PolygonProperties
}

export type S_Circle = {
	origin: Vector2,
	radius: number,
}

--- Module Functions -----

-- Return if point is between segment.min or segment.max.
function MathExtended.PointInSegment(point: number, min: number, max: number): boolean
	return
		point > min
		and point < max
end

-- Where:
--   L₁ = {p₁, p₂}
--   L₂ = {p₃, p₄}
-- Return true if L₁ and L₂ intersect with eachother.
-- Does not cover collinear cases.
function MathExtended.LinesIntersect(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2): boolean
	-- Where:
	--   P = intersection point
	--   L₁ (Line one) = {p₁, p₂} 
	--   L₂ (Line two) = {p₃, p₄}
	--   p... = (x..., y...)

	-- In order for lines to intersect they must cross each other.
	-- If we want to cross the axis X, we need to go from -X to positive X.
	-- This works when you have a 1D vector, but 2D lines have both X and Y.

	-- There are multiple different ways to determine whether or not a line intersects,
	-- but they won't all be covered here.

	-- Earlier, I said we need from -X to positive X,
	-- but what we really need to be is "Left" and "Right" from the origin.
	-- How do we detect if it's left or right? Using the cross product.

	-- Detect if the points of L₂ are on the left or right side of L₁ --
	local p2_new_origin = p2 - p1
	local l2_can_cross =
		-- Less than means it is on the right, and greater than means it is on the left.
		-- Subtract p1 so they share a similar origin.
		p2_new_origin:Cross(p3 - p1) > 0
		~=
		-- If they are both on the same side, that means a cross is not possible.
		p2_new_origin:Cross(p4 - p1) > 0

	if l2_can_cross == false then
		-- Don't bother computing the rest
		return false
	end

	local p4_new_origin = p4 - p3
	local l1_can_cross =
		p4_new_origin:Cross(p1 - p3) > 0
		~=
		p4_new_origin:Cross(p2 - p3) > 0
	-- At this point l1 is true, so if they are both true it will return true.

	return l1_can_cross == l2_can_cross
end

-- Return whether or not a point is within a unrotated rectangle.
function MathExtended.QueryPointInURect(point: Vector2, rect: S_Rect): boolean
	-- 	The space to query in a unrotated rectangle is X_min X_max,  and Y_min Y_max.

	-- To test if a point is within a unrotated rectangle:

	-- P_x > X_min
	-- and
	-- P_x < X_max
	-- and
	-- P_y > Y_min
	-- and
	-- P_y < Y_max

	-- Where
	--   - X_min is the x value of any point on the left side.
	--   - X_max is the x value of any point on the right side.
	--   - Y_min is the y value of any point on the bottom side.
	--   - Y_max is the y value of any point on the top side.
	local tl = rect.topLeft
	local br = rect.bottomRight
	return 
		point.X > tl.X
		and point.X < br.X
		and point.Y > br.Y
		and point.Y < tl.Y
end
	
---- Shape properties ----

-- Get the corners of a rectangle (origin, width, height).
-- The return order is:
--  1. Top left
--  2. Top right
--  3. Bottom left
--  4. Bottom right
function MathExtended.RectCorners(
	origin: Vector2,
	width: number,
	height: number,
	angle: number?): (Vector2, Vector2, Vector2, Vector2)
	-- begin
	angle = angle or 0
	local cos_a = cos(angle)
	local sin_a = sin(angle)

	-- prefix ut = untranslated
	local ut_tl_corner = -Vector2.new(width/2, height/2)
	local ut_tr_corner = ut_tl_corner * Vector2.new(-1, 1)
	
	local ut_bl_corner = ut_tl_corner * Vector2.new(1, -1)
	local ut_br_corner = -ut_tl_corner

	return
		-- Top left
		origin + Vector2.new(
		(ut_tl_corner.X * cos_a) - (ut_tl_corner.Y * sin_a),
		(ut_tl_corner.X * sin_a) + (ut_tl_corner.Y * cos_a)),
		-- Top right
		origin + Vector2.new(
		(ut_tr_corner.X * cos_a) - (ut_tr_corner.Y * sin_a),
		(ut_tr_corner.X * sin_a) + (ut_tr_corner.Y * cos_a)),
		-- Bottom left
		origin + Vector2.new(
		(ut_bl_corner.X * cos_a) - (ut_bl_corner.Y * sin_a),
		(ut_bl_corner.X * sin_a) + (ut_bl_corner.Y * cos_a)),
		-- Bottom right
		origin + Vector2.new(
		(ut_br_corner.X * cos_a) - (ut_br_corner.Y * sin_a),
		(ut_br_corner.X * sin_a) + (ut_br_corner.Y * cos_a))
		
end


---- Vector operations ----

--

-- Get phi and theta (also known as pitch and yaw) from a 3D vector and the world origin.
-- Return order
--   1. Radius (vector magnitude)
--   2. Theta (pitch)
--   3. Phi (yaw)
function MathExtended.V3SphereProperties(vec: Vector3): (number, number, number)
	local radius = vec.Magnitude
	local x,y,z = vec.X, vec.Y, vec.Z
	return
		radius,
		acos(y/radius),
		atan2(z,x)
end

function MathExtended.VNSphereProperties(vec: vector): (number, number, number)
	local radius = vec.magnitude
	local x,y,z = vec.x, vec.y, vec.z
	return
		radius,
		acos(y/radius),
		atan2(z,x)
end

-- Rotate point around world origin from rotation (in radians) --
-- Note that this ROTATES it, not sets the rotation

function MathExtended.V2RotatePoint(point: Vector2, angle: number): Vector2
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	return Vector2.new(
		(point.X * cos_a) - (point.Y * sin_a),
		(point.X * sin_a) + (point.Y * cos_a))
end

function MathExtended.V3RotatePitch(point: Vector3, angle: number): Vector3
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	local x, y = point.Z, point.Y
	return Vector3.new(
		point.X,
		-y * cos(angle) + x * sin(angle),
		y * sin(angle) + x * cos(angle))
end

function MathExtended.V3RotateYaw(point: Vector3, angle: number): Vector3
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	local x, y = point.Z, point.Y
	return Vector3.new(
		x * cos(angle) - y * sin(angle),
		point.Y,
		x * sin(angle) + y * cos(angle))
end


function MathExtended.VNRotatePitch(point: vector, angle: number): vector
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	local x, y = point.z, point.y
	return vector.create(
		point.x,
		-y * cos(angle) + x * sin(angle),
		y * sin(angle) + x * cos(angle))
end

function MathExtended.VNRotateYaw(point: vector, angle: number): vector
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	local x, y = point.z, point.y
	return vector.create(
		x * cos(angle) - y * sin(angle),
		point.y,
		x * sin(angle) + y * cos(angle))
end

-- Rotate point around origin vector --

function MathExtended.V2RotateAroundPoint(point: Vector2, origin: Vector2, angle: number): Vector2
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	point -= origin
	local x,y = point.X, point.Y
	return Vector2.new(
		(x * cos_a) - (y * sin_a),
		(x * sin_a) + (y * cos_a))
		+ origin
end

function MathExtended.V3RotatePitchAroundOrigin(point: Vector3, origin: Vector3, angle: number): Vector3
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	point -= origin
	local x, y = point.Z, point.Y
	return Vector3.new(
		point.X,
		-y * cos(angle) + x * sin(angle),
		y * sin(angle) + x * cos(angle))
		+ origin
end

function MathExtended.V3RotateYaw(point: Vector3, origin: Vector3, angle: number): Vector3
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	point -= origin
	local x, y = point.Z, point.Y
	return Vector3.new(
		x * cos(angle) - y * sin(angle),
		point.Y,
		x * sin(angle) + y * cos(angle))
		+ origin
end


function MathExtended.VNRotatePitch(point: vector, origin: vector, angle: number): vector
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	local x, y = point.z, point.y
	return vector.create(
		point.x,
		-y * cos(angle) + x * sin(angle),
		y * sin(angle) + x * cos(angle))
end

function MathExtended.VNRotateYaw(point: vector, origin: vector, angle: number): vector
	local cos_a = cos(angle)
	local sin_a = sin(angle)
	point -= origin
	local x, y = point.z, point.y
	return vector.create(
		x * cos(angle) - y * sin(angle),
		point.y,
		x * sin(angle) + y * cos(angle))
		+ origin
end

---- 2D collision tests ----

function MathExtended.QueryPointInRect(point: Vector2, rect: Rect): boolean
	local tl, tr, bl, br = GetRectCorners(rect)
	local min_x = math.min(tl.X, tr.X, bl.X, br.X)
	local max_x = math.max(tl.X, tr.X, bl.X, br.X)
	local min_y = math.min(tl.Y, tr.Y, bl.Y, br.Y)
	local max_y = math.max(tl.Y, tr.Y, bl.Y, br.Y)
	
	local px, py = point.X , point.Y

	return
		px > min_x and px < max_x
		and py > min_y and py < max_y
end


---- Misc ----

--> Set reference functions
GetRectCorners = MathExtended.RectCorners
GetDiagonal = MathExtended.Diagonal

--< Module end >---
return MathExtended
