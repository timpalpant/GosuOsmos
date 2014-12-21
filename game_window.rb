require 'rubygems'
require 'gosu'
require 'gsl'
require 'universe'
require 'life_form'
require 'z_order'
require 'fixed_precision'
include Gosu
include GSL


ENEMIES = 15
INITIAL_SIZE = 2000

class GameWindow < Gosu::Window
	
  def initialize(width, height, fullscreen)
    super(width, height, fullscreen)
    self.caption = "Tim and Justin's Ruby Gosu Osmos"
    @background_image = Image.new(self, "media/space.png", true)
		@lg_font = Font.new(self, Gosu::default_font_name, 18)
		@sm_font = Font.new(self, Gosu::default_font_name, 12)
		@last_draw = Time.now
		@speed = 1
    
    init_ambient_universe
  end

	def update		
		unless @paused
			@speed.times do
    		# Check for collisions between LifeForms and
    		# update each LifeForm's mass, position, and color
    		# based on its momentum and collisions
    		# and prune dead LifeForms
    		@universe.update
    		
  			# Check for death
    		if @active
    			win if @universe.player_won?
  				dead if @universe.player_dead?
    		end
    		
    		# Check for hopeless
    		if @active and @universe.player_hopeless?
    			hopeless
    		end
    			
  			# Check keyboard input
    		if @active
      		@player.up if button_down?(KbUp)
  				@player.down if button_down?(KbDown)
  				@player.left if button_down?(KbLeft)
  				@player.right if button_down?(KbRight)
  				@player.mouse_click(Vector[mouse_x, mouse_y]) if button_down?(MsLeft)
    		end
			end
		end
	end

  def draw
    @background_image.draw(0, 0, ZOrder::Background)
  	@universe.draw

		if @paused
			@lg_font.draw("PAUSED", 10, 10, ZOrder::UI, 1.0, 1.0, Color::WHITE)
		elsif @msg
			@lg_font.draw(@msg, 10, 10, ZOrder::UI, 1.0, 1.0, Color::WHITE)
			@sm_font.draw("press R to restart", 10, 30, ZOrder::UI, 1.0, 1.0, Color::WHITE)
		end
		
		debug if $DEBUG
  end

  def button_down(id)
  	case id
  	when KbEscape
  		close
  	when KbR
  		init_ambient_universe
  	when KbP
  		toggle_pause
  	when KbW
  		speed_up
  	when KbS
  		slow_down
  	end
  end
  
  # Pause the game if playing
  def toggle_pause
		@paused = !@paused if @active
  end
  
  # Speed up the passage of time
  def speed_up
  	@speed *= 2
  end
  
	# Slow down the passage of time
  def slow_down
  	@speed /= 2 unless @speed == 1
  end
  
  # Respond to player death
  def dead
  	@active = false
  	@msg = "LifeForm Terminated"
  end
  
  # Respond to player situation hopeless
  def hopeless
  	@msg = "It's Not Looking Good..."
  end
  
  # Respond to player winning
  def win
		@msg = "You Win!"
  end
  
	def needs_cursor?
    true
  end
  
  
  private
  
	def debug
		@lg_font.draw("DEBUG CONSOLE", 10, height-135, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
		@sm_font.draw("Player - m: #{@player.m.to_s(6)}, p: #{@player.p}, x: #{@player.x}", 10, height-115, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
		@sm_font.draw("Absorbable: #{@universe.absorbable.to_s(6)}, next largest: #{@universe.next_largest.to_s(6)}", 10, height-100, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
		@sm_font.draw("# LifeForms: #{@universe.length}", 10, height-85, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
		@sm_font.draw("Total mass: #{@universe.total_m.to_s(6)}", 10, height-70, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
		@sm_font.draw("Total momentum: #{@universe.total_p}", 10, height-55, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
		@sm_font.draw("Speed: #{@speed}", 10, height-40, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
		elapsed = Time.now - @last_draw
		@last_draw = Time.now
		@sm_font.draw("FPS = #{(1/elapsed).round}", 10, height-25, ZOrder::DEBUG, 1.0, 1.0, Color::YELLOW)
	end
  
  def init_universe
  	@active = true
  	@paused = false
  	@msg = @msg2 = nil
  end
  
  def init_ambient_universe
  	init_universe
  	
		# Create the player's LifeForm
    @player = LifeForm.new(self, INITIAL_SIZE, :white, Vector[width/2,height/2])
    
    # Create a new Ambient Universe in this Window with enemies
    @universe = AmbientUniverse.new(self, @player, ENEMIES)
  end
end
