require 'texplay'
require 'gsl'
require 'math_utils'
include GSL

class LifeForm
	
	# Mass, position, and momentum
	attr_reader :m, :x, :p
	
	# Constants used for LifeForm physics
	DENSITY = 1
	IMPULSE = 40
	EJECTION_FRAC = 400*IMPULSE
	EJECT_TICKS = 10
	LEFT = Vector[-IMPULSE, 0]
	RIGHT = Vector[IMPULSE, 0]
	UP = Vector[0, -IMPULSE]
	DOWN = Vector[0, IMPULSE]
	# Minimum mass of a LifeForm
	TOL = 0
	
	def initialize(window, mass, color, x = Vector[0,0], d_x = Vector[0,0])
		@window = window
		@edge = @color = color
		@edge_changed = @color_changed = true
		
		# Mass
		@m = mass.to_f
		@m_changed = true
		# Time derivative of @m
		@delta_m = 0
		# Position
		@x = x
		# Compute momentum from the given velocity and mass
		@p = d_x * @m
		# Time derivative of momentum is 0
		@delta_p = Vector[0,0]
		@ejection = Vector[0,0]
		@tick = 0
		
		@image = TexPlay.create_image(@window, 2*r+1, 2*r+1)
	end
	
	# Compute the radius from the current mass
	def r
		# Cache for performance
		if @m_changed
			@r = mass_to_radius(@m)
			@m_changed = false
			@r_changed = true
		end
		
		return @r
	end
	
	# Compute the velocity from the current mass and momentum
	def delta_x
		@p / @m
	end
	
	# Apply an impulse to @delta_p
	def impulse(i)
		@delta_p += i
		# Queue an ejection with opposite impulse (Newton's 3rd Law)
		@ejection -= i
	end

	# Impulse left
	def left
		impulse(LEFT)
	end

	# Impulse right
	def right
		impulse(RIGHT)
	end

	# Impulse up
	def up
		impulse(UP)
	end

	# Impulse down
	def down
		impulse(DOWN)
	end
	
	# Impulse in the opposite direction of the mouse click
	def mouse_click(x)
		impulse((@x-x).normalize * IMPULSE)
	end
	
	# Respond to collisions with others
	def check_collisions(others)
		others.each do |other|
			# LifeForms cannot collide with themselves
			next if self.equal?(other)
			
			# Distance between the centers of the two LifeForms
			distance = Gosu.distance(@x[0], @x[1], other.x[0], other.x[1])
			# One circle is completely contained within the other (should completely absorb or die)
			if distance <= (r - other.r).abs
				if @m > other.m
					@delta_m += other.m
					@delta_p += other.p
				elsif @m < other.m
					@delta_m -= other.m
					@delta_p -= @p
				end
			# The circles are partially overlapping
			elsif distance <= r + other.r
				overlap = DENSITY * Geometry.circle_intersection(distance, r, other.r)
				if @m > other.m
					@delta_m += overlap
					@delta_p += other.delta_x * overlap
				elsif @m < other.m
					@delta_m -= overlap
					@delta_p -= delta_x * overlap
				end
			end
		end
	end
	
	# Update the current position and size based on @delta_m and @delta_p
	def update
		grow
		move
		eject if eject?
	end
	
	def color=(c)
		@color = c
		@color_changed = true
	end
	
	def edge=(c)
		@edge = c
		@edge_changed = true
	end

	# Draw the LifeForm on the Window
	def draw
		# Redraw the image with the current r and color if necessary
		if @color_changed or @r_changed
			@color_changed = false
			@r_changed = false
			@image.circle(r, r, r, :color => @color, :fill => true)
		end
		
		if @edge_changed or @r_changed
			@edge_changed = false
			@r_changed = false
			@image.circle(r, r, r, :color => @edge, :fill => false)
		end
		
		@image.draw(@x[0] - r, @x[1] - r, ZOrder::LifeForm)
	end
	
	# Debugging
	def to_s
		"LifeForm - x: #{@x}, m: #{@m}, p: #{@p}, r: #{r}, d_x: #{delta_x}"
	end
	
	
	private
	
	def eject?
		tick == 0 and @ejection.norm > 0
	end
	
	def tick
		@tick = (@tick+1) % EJECT_TICKS
	end
		
	# Eject new LifeForms based on impulses
	def eject
		eject_m = @ejection.norm * @m / EJECTION_FRAC
		eject_vel = @ejection / eject_m
		
		@delta_m -= eject_m
		lf = LifeForm.new(@window, eject_m, :none, @x + @ejection.normalize*(r+mass_to_radius(eject_m)+1), eject_vel)
		@ejection = Vector[0,0]
		return lf
	end
	
	# Move the current position based on the momentum
	def move
		# LifeForm terminated and should be removed
		return if @m <= TOL
				
		@p += @delta_p
    @x += delta_x
		# Reset the delta since we have enacted the change
		@delta_p = Vector[0,0]
		
		# Elastically bounce off the edges of the window
		if @x[0] - r < 0
			@x[0] = 2*r - @x[0]
			@p[0] = -@p[0]
		elsif @x[0] + r > @window.width
			@x[0] = 2*(@window.width - r) - @x[0]
			@p[0] = -@p[0]
		end
		
		if @x[1] - r < 0
			@x[1] = 2*r - @x[1]
			@p[1] = -@p[1]
		elsif @x[1] + r > @window.height
			@x[1] = 2*(@window.height - r) - @x[1]
			@p[1] = -@p[1]
		end
	end
	
	# Alter the mass and momentum based on the current @delta_m and @delta_p
	def grow
    # Optimization so that we do not regenerate the image unless a change occured
    return if @delta_m == 0
    
    # Flag the mass as changed so that the radius is recomputed
    @m_changed = true
    # Apply the change in mass
    @m += @delta_m
		# Reset the delta since we have enacted the change
		@delta_m = 0
		# LifeForm terminated and should be removed
		return if @m <= TOL		
		
		# Make a new image based on the new mass
		@image = TexPlay.create_image(@window, 2*r+1, 2*r+1)
	end
	
	# Convert mass to radius based on density
	def mass_to_radius(m)
		Math.sqrt(m / (DENSITY*Math::PI)).round
	end

end


# A LifeForm with AI
class Organism < LifeForm
end

# A LifeForm with gravity
class Attractor < LifeForm
end