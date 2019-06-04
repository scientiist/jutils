--[[
	jutils library /// written by josh madscientist

	this library is a compilation of common utilities
	that are needed in game programming, such as extra
	math functions, table manipulation, basic datatypes,
	and more.

	https://love2d.org/wiki/General_math
  
	\

----------------
module reference:

	jutils

		math
			lerp()
			multiple()
			round()
			sign()
			clamp()
		table
			copy()
			construct()
			iterateAs2D()
		string
			explode(string input, string divider)
		
	-- datatypes below

		color
			new()
			fromRGB()
			fromHSL()
			fromHex()


		line
			new()
			lerp()
			intersects()
			getIntersectPoint()

		point
			new()
			lerp()
			distance()

		rect
			new()

]]

local jutils = {}

-- Color datatype
local color = {}
do
	color.__index = color

	function color.new(r, g, b, a)
		local self = setmetatable({}, color)
		self.r = r or 0
		self.g = g or 0
		self.b = b or 0
		self.a = a or 1
		return self
	end

	function color.fromRGB(r, g, b, a)
		return color.new(r/255, g/255, g/255, (alpha or 255)/255)
	end

	function color.fromHSL(h, s, l, a)
		if s == 0 then return l,l,l end
		h, s, l = h/256*6, s/255, l/255
		local c = (1-math.abs(2*l-1))*s
		local x = (1-math.abs(h%2-1))*c
		local m,r,g,b = (l-.5*c), 0,0,0
		if h < 1     then r,g,b = c,x,0
		elseif h < 2 then r,g,b = x,c,0
		elseif h < 3 then r,g,b = 0,c,x
		elseif h < 4 then r,g,b = 0,x,c
		elseif h < 5 then r,g,b = x,0,c
		else              r,g,b = c,0,x
		end
		local r, g, b = r+m, g+m, b+m
		return color.new(r, g, b, (a or 255)/255)
	end

	function color. fromHex(hex, a)
		local hex = hex:gsub("#","")

		local r, g, b
		if hex:len() == 3 then
		  r, g, b = (tonumber("0x"..hex:sub(1,1))*17)/255, (tonumber("0x"..hex:sub(2,2))*17)/255, (tonumber("0x"..hex:sub(3,3))*17)/255
		else
		  r, g, b = tonumber("0x"..hex:sub(1,2))/255, tonumber("0x"..hex:sub(3,4))/255, tonumber("0x"..hex:sub(5,6))/255
		end
	
		return color.new(r, g, b, (alpha or 255)/255)
	end

	function color.__call(c)
		return {c.r, c.g, c.b, c.a}
	end
	
end
jutils.color = color

-- Point datatype
local point = {}
do
	point.__index = point
	function point.new(x, y)
		local self = setmetatable({}, point)

		self.x = x
		self.y = y
		return self
	end

	function point.__eq(pointA, pointB)
		return (pointA.x == pointB.x and pointA.y == pointB.y)
	end

	function point.__tostring(point)
		return "Point"
	end

	function point.lerp(pointA, pointB, alpha)
		local x = jutils.math.lerp(pointA.x, pointB.x, alpha)
		local y = jutils.math.lerp(pointA.y, pointB.y, alpha)

		return point.new(x, y)
	end

	function point.distance(pointA, pointB)
		local x1 = pointA.x
		local x2 = pointB.x

		local y1 = pointA.y
		local y2 = pointB.y

		return ((x2-x1)^2+(y2-y1)^2)^0.5
	end
	
end
jutils.point = point

-- Line segment datatype
local line = {}
do
	line.__index = line

	function line.new(pointA, pointB)
		assert(tostring(pointA) == "Point", "Lines can only be constructed using points")
		assert(tostring(pointB) == "Point")


		local self = setmetatable({}, line)

		self.pointA = pointA
		self.pointB = pointB
		return self
	end

	function line.__eq(lineA, lineB)
		return (lineA.pointA == lineB.pointA and lineA.pointB == lineA.pointB)
	end

	function line.__tostring(point)
		return "Line"
	end

	function line.lerp(lineA, lineB, alpha)

		local pointA = point.lerp(lineA.pointA, lineB.pointA, alpha)
		local pointB = point.lerp(lineA.pointB, lineB.pointB, alpha)

		return line.new(pointA, pointB)
	end

	function line.slope(line)
		-- y2-y1 / x2-x1
		local y = line.pointB.y - line.pointA.y
		local x = line.pointB.x - line.pointA.x
		return (y/x)
	end

	local function lineIntersect(p0, p1, p2, p3)

		-- stolen from Coding Math: Episode 33

		local A1 = p1.y - p0.y
		local B1 = p0.x - p1.x
		local C1 = A1 * p0.x + B1 * p0.y
		local A2 = p3.y - p2.y
		local B2 = p2.x - p3.y
		local C2 = A2 * p2.x + B2 * p2.y

		local denominator = A1 * B2 - A2 * B1

		if (denominator == 0) then -- parallel and/or colinear lines
			return false
		end

		local x = (B2 * C1 - B1 * C2) / denominator
		local y = (A1 * C2 - A2 * C1) / denominator


		local rx0 = (x - p0.x) / (p1.x - p0.x)
		local ry0 = (y - p0.y) / (p1.y - p0.y)

		local rx1 = (x - p2.x) / (p3.x - p2.x)
		local ry1 = (y - p2.y) / (p3.y - p2.y)

		if ((rx0 >= 0 and rx0 <= 0) or (ry0 >= 0 and ry0 <= 1)) and  ((rx1 >= 0 and rx1 <= 0) or (ry1 >= 0 and ry1 <= 1)) then

			return true, x, y
		end

		return false
	end

	function line.intersects(lineA, lineB)
		local p0 = lineA.pointA
		local p1 = lineA.pointB

		local p2 = lineB.pointA
		local p3 = lineB.pointB


		return lineIntersect(p0, p1, p2, p3)

	end
end
jutils.line = line


-- Rect datatype
local rect = {}
do
	rect.__index = rect

	function rect.new(pointA, pointB)

	end


end
jutils.rect = rect

-- Math module
jutils.math = {}
do
	


	function jutils.math.lerp(start, finish, alpha)
		return (1-alpha)*start + alpha*finish
	end

	-- returns the closest multiple of "size" in respect to "n"
	function jutils.math.multiple(n, size)
		size = size or 10
		return math.round(n/size)*size
	end

	-- returns "n" rounded to the nearest decimal place
	function jutils.math.round(n, decimals)
		decimals = 10^(decimals or 0) 
		return math.floor(n*decimals+.5)/decimals
	end

	function jutils.math.sign(n)
		return n>0 and 1 or n<0 and -1 or 0
	end

	function jutils.math.clamp(low, n, high)
		return math.max()
	end
end

-- Table Module
jutils.table = {}
do

	--
	function jutils.table.copy(orig)
		local orig_type = type(orig)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key)] = deepcopy(orig_value)
			end
			setmetatable(copy, deepcopy(getmetatable(orig)))
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
	end


	function jutils.table.construct(construction, size)
		local t = {}
		for i = 1, size do
			t[i] = jutils.table.copy(construction)
		end
		return t
	end

	--[[ 
		this function is to be used with a 1-dimensional table,
		allowing you to iterate through it as if it were
		a 2D grid

		example:

		local map = {...} -- some 1-dimensional table


		for x, y, value in jutils.table.iterateAs2D(map, mapwidth, mapheight) do
			if value == 1 then
				love.graphics.rectangle("fill", x*8, y*8, 8, 8)
			end
		end
	]]

	function jutils.table.iterateAs2D(t, width, height)
		local index = 0
		return function()
			index = index+1
		
		
			if index > (width*height) then return end
			local val = t[index]
		
			local i = index - 1
			local x = i%width
			local y = (i - x)/width
			x, y = x + 1, y + 1
		
			return x, y, val
		end
	end
end


-- String module
jutils.string = {}
do
	

	function jutils.string.explode(str, divider)
		assert(type(str) == "string" and type(divider) == "string", "Invalid arguments, type must be string!")

		local o = {}

		while true do
			local pos1, pos2 = str:find(divider)
			if not pos1 then
				o[#o+1] = str
				break
			end
			o[#o+1], str = str:sub(1, pos1-1), str:sub(pos2+1)
		end
		return o
	end
end

return jutils