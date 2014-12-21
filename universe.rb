require 'life_form'

# Manage LifeForms in space
class Universe < Array
	attr_reader :player
	
	def initialize(window, player)
		@window = window
		@player = player
		self << @player
	end
	
	# Win condition; can be overridden by subclasses
	def player_won?
		player_largest?
	end
	
	# Hopeless condition; can be overriden by subclasses
	def player_hopeless?
		player_smallest? or (@player.m + absorbable) < next_largest
	end
	
	# Lose condition; can be overridden by subclasses
	def player_dead?
		@player.m <= LifeForm::TOL
	end
	
	def update
		# Check for collisions between LifeForms
		check_collisions
		
		# Update the position and size of all LifeForms in the Universe
		# And remove if the radius is < TOL
		self.reject! do |lf|
			# Update the position and size and catch any ejections
			ejection = lf.update
			self << ejection if ejection
			
			# Update the LifeForm's color based on its mass relative to @player
			unless lf.equal?(@player) or player_dead?
				lf.color = mass_to_fill(lf.m)
				lf.edge = mass_to_edge(lf.m)
			end
			
			# Remove the LifeForm from the Universe if dead
			lf.m <= LifeForm::TOL
		end
		
		# Keep track of the smallest and largest LifeForm radii
		# so we know when the player has won or lost
		masses = self.collect { |lf| lf.m }.sort
		@min_m = masses.first
		@max_m = masses.last
	end
	
	# Draw all of this Universe's LifeForms to the screen
	def draw
		self.each { |lf| lf.draw }
	end
	
	# For debugging
	def to_s
		"Universe - #{self.length} LifeForms\n\ttotal mass: #{total_m}\n\ttotal momentum: #{total_p}"
	end
	
	def total_m
		self.collect { |lf| lf.m }.sum
	end
	
	def total_p
		self.collect { |lf| lf.p }.sum
	end
	
	def absorbable
		smaller = 0
		self.each { |lf| smaller += lf.m if lf.m < @player.m }
		return smaller
	end
	
	def next_largest
		larger = 0
		self.each { |lf| larger = lf.m if lf.m > @player.m and lf.m < larger }
		return larger
	end
	
	
	private
	
	def check_collisions
		self.each { |lf| lf.check_collisions(self) }
	end
	
	def player_smallest?
		@player.m == @min_m
	end
	
	def player_largest?
		@player.m == @max_m
	end
	
	# Shade reflecting the relative mass of an enemy
	def mass_to_fill(m)		
		percent_mass = m.to_f / @player.m
		red = [0, [percent_mass-0.5, 1].min].max
		blue = 1 - red
		return [red, 0, blue]
	end
	
	# Blue if < player mass, red if > player mass
	def mass_to_edge(m)
		(m > @player.m) ? :red : :blue
	end
	
end


# Constants used for generating random LifeForms
MARGIN = 10
MAX_SIZE = 4000
MAX_VEL = Vector[0.5,0.5]

# A Universe with randomly generated LifeForms
class AmbientUniverse < Universe
	def initialize(window, player, n = 0)
		super(window, player)
		populate(n)
	end
	
	# Add n randomly created LifeForms to the Universe
	def populate(n)
		n.times { self << random_lifeform }
	end
	
	def random_lifeform(max_size = MAX_SIZE, max_vel = MAX_VEL)
		x = rand(@window.width-2*MARGIN) + MARGIN
		y = rand(@window.height-2*MARGIN) + MARGIN
		vel_x = 2*max_vel[0]*rand - max_vel[0]
		vel_y = 2*max_vel[1]*rand - max_vel[1]
		LifeForm.new(@window, rand(max_size), :none, Vector[x,y], Vector[vel_x,vel_y])
	end
end