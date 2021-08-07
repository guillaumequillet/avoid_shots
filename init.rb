require 'gosu'

class Ennemy
  @@size = 16
  def initialize(window, x, y)
    @window = window
    @x, @y = x, y
    @shots = []
    
    # sera utilisée pour tirer des missiles
    @max_cooldown = 20
    @cooldown = @max_cooldown 
  end

  def self.size
    @@size
  end

  def update(hero_x, hero_y)
    # on tire un missile si le cooldown est arrivé à 0
    if @cooldown <= 0
      angle = Gosu.angle(@x, @y, hero_x, hero_y)
      @shots.push(Shot.new(@window, @x, @y, angle))
      @cooldown = @max_cooldown
    else
      @cooldown -= 1
    end

    # shots update
    @shots.each {|shot| shot.update}
    
    # on efface les tirs sortis
    @shots.delete_if {|shot| shot.to_destroy?}
  end

  def draw
    # ennemy drawing
    Gosu.draw_rect(@x - @@size / 2, @y - @@size / 2, @@size, @@size, Gosu::Color::RED)

    # shots drawing
    @shots.each {|shot| shot.draw}
  end
end

class Shot
  def initialize(window, x, y, angle)
    @window, @x, @y, @angle = window, x, y, angle
    @speed = 5
    @size = 8
  end

  def update
    # on fait avancer le missile en suivant l'angle lors de la création
    @x += Gosu.offset_x(@angle, @speed)
    @y += Gosu.offset_y(@angle, @speed)

    if @window.hits_hero?(@x - @size/2, @y - @size/2, @size, @size)
      @window.game_over
    end
  end

  def to_destroy?
    # on détruit le missile s'il sort de l'écran
    return (@x > @window.width || @x < 0 || @y > @window.height || @y < 0)
  end

  def draw
    Gosu.draw_rect(@x - @size / 2, @y - @size / 2, @size, @size, Gosu::Color::WHITE)
  end
end

class Window < Gosu::Window
  def initialize
    super(640, 480, false)
    @game_over = false
    @hero_size = 16
    @font = Gosu::Font.new(24)
    # sera utilisée pour pop des ennemis
    @max_cooldown = 200
    @cooldown = @max_cooldown
    start_game 
  end

  def needs_cursor?; false; end

  def game_over
    @game_time = (Gosu::milliseconds - @start_time) / 1000.0
    @game_over = true
  end

  def start_game
    @ennemies = {}
    add_ennemy
    @start_time = Gosu::milliseconds
    @game_over = false
  end

  def add_ennemy
    loop do
      x = Gosu.random(0, self.width / Ennemy.size).floor
      y = Gosu.random(0, self.height / Ennemy.size).floor
      unless @ennemies.keys.include?([x, y])
        @ennemies[[x, y]] = Ennemy.new(self, x * Ennemy.size, y * Ennemy.size)
        break
      end
    end
  end

  def hits_hero?(x, y, w, h)
    hero_x = @hero_x - @hero_size/2
    hero_y = @hero_y - @hero_size/2
    return x >= hero_x && x <= hero_x + @hero_size && y >= hero_y && y <= hero_y + @hero_size
  end

  def button_down(id)
    # pour fermer le jeu si ECHAP est pressé
    close! if id == Gosu::KB_ESCAPE

    start_game if @game_over && id == Gosu::KB_RETURN
  end

  def update
    unless @game_over
      # on met à jour les coordonnées du héros
      @hero_x = self.mouse_x
      @hero_y = self.mouse_y

      # on ne laisse pas le héros sortir de l'écran
      @hero_x = @hero_x.clamp(0, self.width)
      @hero_y = @hero_y.clamp(0, self.height)

      # on met à jour les ennemis
      @ennemies.each_value {|ennemy| ennemy.update(@hero_x, @hero_y)}

      # on ajoute un ennemi si le cooldown est arrivé à 0
      if @cooldown <= 0
        add_ennemy
        @cooldown = @max_cooldown
      else
        @cooldown -= 1
      end
    end
  end

  def draw
    if @game_over
      @font.draw_text("GAME OVER", 20, 20, 2)
      @font.draw_text("You survived #{@game_time.ceil} seconds ! Press enter to restart", 20, 80, 2)
    end

    # on dessine les ennemis
    @ennemies.each_value {|ennemy| ennemy.draw}

    # on dessine le héros (j'ai centré le rectangle sur sa position)
    Gosu.draw_rect(@hero_x - @hero_size / 2, @hero_y - @hero_size / 2, @hero_size, @hero_size, Gosu::Color::GREEN)
  end
end

Window.new.show