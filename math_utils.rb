require 'Gosu'

module Enumerable
	def sum
		compacted = self.compact
		compacted.inject { |sum, elem| sum + elem } unless compacted.length == 0
	end
end

module Geometry
	# Return the area of intersection for two circles with distance d between the centers and radii r1, r2
	# Adapted from: http://mathworld.wolfram.com/Circle-CircleIntersection.html
	def self.circle_intersection(d, r1, r2)
		return r1**2 * Math.acos((d**2 + r1**2 - r2**2)/(2*d*r1)) + r2**2 * Math.acos((d**2 + r2**2 - r1**2)/(2*d*r2)) - 0.5*Math.sqrt((-d+r1+r2)*(d+r1-r2)*(d-r1+r2)*(d+r1+r2))
	end
end