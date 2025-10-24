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

return MathExtended