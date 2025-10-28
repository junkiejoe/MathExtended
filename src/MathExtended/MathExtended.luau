--< Module begin >---
local MathExtended = {}

---- Const ----
--> Alias of module functions
local V2RotateVector
local EdgeNormal
local V2RotateVectorAroundPoint
local LineIntersectsXAALine
local LineIntersectsYAALine
local QueryPointInAABB
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
	-- The vertex count is 4,
	-- the order is:
	-- Top left, top right,
	-- Bottom left, bottom right.
	-- And rectangles are convex.
	polyProperties: PolygonProperties
}

export type S_Circle = {
	origin: Vector2,
	radius: number,
}
---- Module functions ----
----------------------------------
-- Finding the points of a circle
----------------------------------

-- Return the vector from an angle θ in radians.
function MathExtended.VectorFromAngle(angle: number): Vector2
	return Vector2.new(math.cos(angle), math.sin(angle))
end

-- Return the angle θ from the vector.
function MathExtended.AngleFromVector(vec: Vector2): number
  	return math.atan2(vec.Y, vec.X)
end

-- Return the point from an angle θ in radians, and the radius of the Unit circle
function MathExtended.UnitCirclePoint(angle: number, radius: number): Vector2
	return Vector2.new(math.cos(angle), math.sin(angle)) * radius
end

-- Return the point from an angle θ in radians, and the radius of the Unit circle
function MathExtended.PointOnCircle(origin: Vector2, angle: number, radius: number): Vector2
	return Vector2.new(math.cos(angle), math.sin(angle)) * radius + origin
end

----------------------------------
-- Finding the points of a sphere
----------------------------------

----------------------------------
-- Rotating vectors
----------------------------------

-- Rotate a vector by an angle.
function MathExtended.V2RotateVector(vec: Vector2, angle: number): Vector2
	local x, y = vec.X, vec.Y
	return Vector2.new(
		x * math.cos(angle) - (y * math.sin(angle)),
		x * math.sin(angle) + (y * math.cos(angle)))
end

-- Rotate a vector by an angle relative a point.
function MathExtended.V2RotateVectorAroundPoint(vect: Vector2, point: Vector2, angle: number): Vector2
	return V2RotateVector(vect - point, angle) + point
end

----------------------------------
-- Properties of a rectangle
----------------------------------

-- Return the corners of an axis aligned rectangle.
-- Return order:
-- 1. Top left
-- 2. Top right
-- 3. Bottom left
-- 4. Bottom right
function MathExtended.AABBCorners(width: number, height: number, origin: Vector2): (Vector2, Vector2, Vector2, Vector2)
	local half_width = width/2
	local half_height = height/2	
	return
		-- Top left
		origin + Vector2.new(-half_width, half_height),
		-- Top right
		origin + Vector2.new(half_width, half_height),
		-- Bottom left
		origin + Vector2.new(-half_width, -half_height),
		-- Bottom right
		origin + Vector2.new(half_width, -half_height)
end

-- Return the corners of an orientated rectangle.
-- Return order:
-- 1. Top left
-- 2. Top right
-- 3. Bottom left
-- 4. Bottom right
function MathExtended.OBBCorners(width: number, height: number, origin: Vector2, angle: number): (Vector2, Vector2, Vector2, Vector2)
	local cos, sin = math.cos(angle), math.sin(angle)
	local adjacent  = Vector2.new(cos, sin) * (width/2)
	local opposite = Vector2.new(-sin, cos) * (height/2)
	return
		origin - (adjacent - opposite),
		origin + (adjacent + opposite),
		origin - (adjacent + opposite),
		origin + (adjacent - opposite)
end

-- Create a new rectangle object
function MathExtended.NewRectangle(width: number, height: number, origin: Vector2, angle: number?): S_Rect
	local ut_tl, ut_tr, ut_bl, ut_br = MathExtended.AABBCorners(width, height, origin)
	local tl, tr, bl, br
	angle = (angle and angle or 0)
	if angle ~= 0 then
		-- Set translated corners from angle
		tl, tr, bl, br = MathExtended.OBBCorners(width, height, origin, angle :: number)
	else
		tl, tr, bl, br = ut_tl, ut_tr, ut_bl, ut_br
	end

	return {
		width = width,
		height = height,
		origin = origin,
		diagonal = Vector2.new(width, height).Magnitude,
		angle = angle :: number,
		-- Corners
		topLeft = tl, topRight = tr,
		bottomLeft = bl, bottomRight = br,
		-- Untranslated corners
		ut_topLeft = ut_tl, ut_topRight = ut_tr,
		ut_bottomLeft = ut_bl, ut_bottomRight = ut_br,
		polyProperties = {
			vertices = {tl, tr, bl, br},
			isConvex = true
		}
	}
end

-- Update the position and corners of the rectangle.
function MathExtended.UpdateRectPosition(rect: S_Rect, new_pos: Vector2)
	-- Properties
	local width, height = rect.width, rect.height
	local angle = rect.angle
	-- Corners
	local ut_tl, ut_tr, ut_bl, ut_br = MathExtended.AABBCorners(width, height, new_pos)
	local tl, tr, bl, br
	
	if angle ~= 0 then
		-- Set translated corners from angle
		tl, tr, bl, br = MathExtended.OBBCorners(width, height, new_pos, angle)
	else
		tl, tr, bl, br = ut_tl, ut_tr, ut_bl, ut_br
	end

	rect.topLeft = tl; rect.topRight = tr
	rect.bottomLeft = bl; rect.bottomRight = br
	
	rect.ut_topLeft = ut_tl; rect.ut_topRight = ut_tr
	rect.ut_bottomLeft = ut_bl; rect.ut_bottomRight = ut_br

	rect.origin = new_pos
end
-----------------------------------------
-- Collision and intersection queries
-----------------------------------------

-- Query if a Line and a X axis aligned line intersect.
function MathExtended.LineIntersectsXAALine(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2): boolean
	local fixed_p2 = p2 - p1 
	return
		-- L₂ crosses L₁
		(fixed_p2:Cross(p3 - p1) > 0)
		~=
		(fixed_p2:Cross(p4 - p1) > 0)
		and
		-- L₁ crosses L₂
		(p1.Y > p4.Y)
		~=
		(p2.Y > p4.Y)
end

-- Query if a Line and a Y axis aligned line intersect.
function MathExtended.LineIntersectsYAALine(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2): boolean
	local fixed_p2 = p2 - p1 
	return
		-- L₂ crosses L₁
		(fixed_p2:Cross(p3 - p1) > 0)
		~=
		(fixed_p2:Cross(p4 - p1) > 0)
		and
		-- L₁ crosses L₂
		(p1.X > p4.X)
		~=
		(p2.X > p4.X)
end

-- Query if two line segments intersect.
function MathExtended.LineIntersectsLine(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2): boolean
	local fixed_p2 = p2 - p1
	local fixed_p4 = p4 - p3
	return
		-- L₁ crosses L₂
		(fixed_p2:Cross(p3 - p1) > 0)
		~=
		(fixed_p2:Cross(p4 - p1) > 0)
		and
		-- L₂ crosses L₁
		(fixed_p4:Cross(p1 - p3) > 0)
		~=
		(fixed_p4:Cross(p2 - p3) > 0)
end

---- AABB collision ----

-- Query if a point is within the space defined by an axis aligned rectangle.
function MathExtended.QueryPointInAABB(point: Vector2, rect: S_Rect): boolean
	local tl = rect.ut_topLeft
	local br = rect.ut_bottomRight
	return 
		point.X > tl.X
		and point.X < br.X
		and point.Y > br.Y
		and point.Y < tl.Y
end

-- Query if a line intersects the rectangle, or if the origin of the line is inside the rectangle.
function MathExtended.QueryLineInAABB(p1: Vector2, p2: Vector2, rect: S_Rect): boolean
	local tl = rect.topLeft
	local tr = rect.topRight
	local bl = rect.bottomLeft
	local br = rect.bottomRight
	-- Order of most likely scenario
	return
		LineIntersectsXAALine(p1, p2, bl, br)
		or LineIntersectsYAALine(p1, p2, tl, bl)
		or LineIntersectsYAALine(p1, p2, tr, br)
		or LineIntersectsXAALine(p1, p2, tl, tr)
		or QueryPointInAABB(p1, rect)
end

-- Query if two axis aligned rectangles collide.
function MathExtended.QueryAABBInAABB(r1: S_Rect, r2: S_Rect): boolean
	local tl1, br1 = r1.ut_topLeft, r1.ut_bottomRight
	local tl2, br2 = r2.ut_topLeft, r2.ut_bottomRight
	return
		-- Check collision in x space
		tl1.X < br2.X
		and
		br1.X > tl2.X
		and
		-- Check collision in y space
		tl1.Y > br2.Y
		and
		br1.Y < tl2.Y
end

---- OBB collision ----

-- This will not return an actual normalized (-1, 0, 1) unit vector.
-- To get the vector normalized, get the .Unit vector from the return value.
function MathExtended.EdgeNormal(p1: Vector2, p2:Vector2): Vector2
	-- Direction vector
	local v = p2 - p1
	-- Vector perpendicular to V
	return Vector2.new( -v.Y, v.X).Unit
end

-- Return in order:
-- Top normal
-- Bottom normal
-- Left normal
-- Right normal
function MathExtended.RectNormals(rect: S_Rect): (Vector2, Vector2, Vector2, Vector2)
	local tl, tr, bl, br = rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight
	return
		EdgeNormal(tl, tr),
		EdgeNormal(bl, br),
		EdgeNormal(tl, bl),
		EdgeNormal(tr, br)
end

-- Query if a point is within the space defined by an axis aligned rectangle.
function MathExtended.QueryPointInOBB(point: Vector2, rect: S_Rect): boolean
	local rotated_point = point - rect.origin
	rotated_point = V2RotateVector(rotated_point, -rect.angle)
	rotated_point += rect.origin
	return MathExtended.QueryPointInAABB(rotated_point, rect)
end

-- Query if a line intersects the rectangle, or if the origin of the line is inside the rectangle.
function MathExtended.QueryLineInOBB(p1: Vector2, p2: Vector2, rect: S_Rect): boolean
	local rotated_p1 = V2RotateVectorAroundPoint(p1, rect.origin, -rect.angle)
	local rotated_p2 = V2RotateVectorAroundPoint(p2, rect.origin, -rect.angle)
	return MathExtended.QueryLineInAABB(rotated_p1, rotated_p2, rect)
end

-- Seperating axis theorem --

-- Return the min and max of the corner projection
local function ProjectOBBCorners(p1:  Vector2, p2:  Vector2, p3:  Vector2, p4:  Vector2, projection_vector: Vector2): (number, number)
	local projection1 = p1:Dot(projection_vector)
	local projection2 = p2:Dot(projection_vector)
	local projection3 = p3:Dot(projection_vector)
	local projection4 = p4:Dot(projection_vector)
	return
		math.min(projection1, projection2, projection3, projection4),
		math.max(projection1, projection2, projection3, projection4)
end

function MathExtended.QueryOBBInOBB(rect1: S_Rect, rect2: S_Rect): boolean
	-- Top corners
	local tl1, tr1, tl2, tr2 =
		rect1.topLeft, rect1.topRight,
		rect2.topLeft, rect2.topRight
	
	-- Bottom corners
	local bl1, br1, bl2, br2 =
		rect1.bottomLeft, rect1.bottomRight,
		rect2.bottomLeft, rect2.bottomRight
	-- Because there are two parallel lines, we only need two normals from each rect
	
	local n1, n2, n3, n4 =
		-- First rect normals
		EdgeNormal(tl1, tr1),
		EdgeNormal(tr1, br1),
		-- Second rect normals
		EdgeNormal(br2, bl2),
		EdgeNormal(tl2, bl2)
	print(`\n n1 = {n1}\n n2 = {n2}\n n3 = {n3}\n n4 = {n4}`)
	print("Nigger: ", br2, bl2)
	-- Project corners onto rectangle
	-- rx = rectangle (x)
	-- px = projection (x)
	local r1_p1_min, r1_p1_max = ProjectOBBCorners(tl1, tr1, bl1, br1, n1)
	local r2_p1_min, r2_p1_max = ProjectOBBCorners(tl2, tr2, bl2, br2, n1)

	-- Check if it is too far right or too far left to intersect.
	if r1_p1_min > r2_p1_max or r1_p1_max < r2_p1_min then
		return false
	end
	
	-- Rect₁ normal 2
	local r1_p2_min, r1_p2_max = ProjectOBBCorners(tl1, tr1, bl1, br1, n2)
	local r2_p2_min, r2_p2_max = ProjectOBBCorners(tl2, tr2, bl2, br2, n2)

	if r1_p2_min > r2_p2_max or r1_p2_max < r2_p2_min then
		print("2")
		return false
	end
	-- Second rect
	-- Rect₂ normal 1
	local r1_p3_min, r1_p3_max = ProjectOBBCorners(tl1, tr1, bl1, br1, n3)
	local r2_p3_min, r2_p3_max = ProjectOBBCorners(tl2, tr2, bl2, br2, n3)

	if r1_p3_min > r2_p3_max or r1_p3_max < r2_p3_min then
		print("3")
		return false
	end

	-- Rect₂ normal 2
	local r1_p4_min, r1_p4_max = ProjectOBBCorners(tl1, tr1, bl1, br1, n4)
	local r2_p4_min, r2_p4_max = ProjectOBBCorners(tl2, tr2, bl2, br2, n4)

	if r1_p4_min > r2_p4_max or r1_p4_max < r2_p4_min then
		print("4")
		return false
	end
	-- If all these tests passed, there is a collision 
	return true
end

---- Misc ----
EdgeNormal = MathExtended.EdgeNormal
V2RotateVector = MathExtended.V2RotateVector
V2RotateVectorAroundPoint = MathExtended.V2RotateVectorAroundPoint
LineIntersectsXAALine = MathExtended.LineIntersectsXAALine
LineIntersectsYAALine = MathExtended.LineIntersectsYAALine
QueryPointInAABB = MathExtended.QueryPointInAABB

return MathExtended

--[[
	MIT License

	Copyright (c) 2025 junkiejoe

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]--