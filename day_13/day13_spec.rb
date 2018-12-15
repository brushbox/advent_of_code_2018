class Cart
  DIRECTIONS = [:up, :right, :down, :left]
  TURN_STATES = [:left, :straight, :right]

  attr_reader :direction, :turn_state
  attr_accessor :position

  def initialize(position: [0, 0], direction: :up)
    @position = position
    @direction = direction
    @turn_index = 0
  end

  def move(track)
    move_forward
    case track.at(position)
    when '|', '_'
    when '/'
      turn_corner('/')
    when '\\'
      turn_corner('\\')
    when '+'
      junction
    end
  end

  def move_forward
    vx = vy = 0
    case direction
    when :up
      vy = -1
    when :down
      vy = 1
    when :left
      vx = -1
    when :right
      vx = 1
    end

    @position = [position[0] + vx, position[1] + vy]
  end

  def junction
    case TURN_STATES[@turn_index % 3]
    when :left
      turn(-1)
    when :right
      turn(1)
    when :straight
    end

    @turn_index += 1
  end

  def turn_corner(slant)
    case slant
    when '/'
      case direction
      when :left, :right
        turn(-1)
      when :up, :down
        turn(1)
      end
    when '\\'
      case direction
      when :left, :right
        turn(1)
      when :up, :down
        turn(-1)
      end
    end
  end

  def turn(dir)
    ix = DIRECTIONS.index(direction)
    @direction = direction_ix(ix + dir)
  end

  def direction_ix(ix)
    DIRECTIONS[(ix + DIRECTIONS.size) % DIRECTIONS.size]
  end
end

class Track
  attr_reader :carts, :tick

  def initialize(lines)
    @tick = 0
    @track = lines
    # find carts
    @carts = find_carts
    puts "#{@carts.size} carts"
    # replace carts with track in the map
    fix_tracks
  end

  def at(pos)
    x, y = pos
    @track[y][x]
  end

  def move
    @tick +=1
    [].tap do |collisions|
      current_carts = @carts.map { |cart| [cart.position, cart] }.to_h
      collision_map = Set.new
      carts.each do |cart| 
        cart.move(self)
        collisions << cart.position if collision_map.include?(cart.position)
        collision_map.add(cart.position)
      end
      # # now that all the carts have moved we need to check if any have passed through each other
      # # and if they have we add those two positions as collisions.
      # # how do we know if carts have passed through each other?
      # # If a cart is now in a position that was occupied by another cart AND that other cart is
      # # now in the same position as the first cart was then they should have collided too.
      # # so we want to add both those positions to the collision list.
      # carts.each do |cart|
      #   next if collisions.include?(cart.position) # don't need to check a cart that is already smashed
      #   if current_carts.key?(cart.position) && current_carts[cart.position] != cart
      #     other = current_carts[cart.position]
      #     if current_carts.key?(other.position) && current_carts[other.position] == cart
      #       collisions << cart.position
      #       collisions << other.position
      #     end
      #   end
      # end
    end
  end

  def track_with_carts
    track = @track.map { |line| line.dup }
    carts.each do |cart|
      x, y = cart.position
      track[y][x] = dir_to_cart_char(cart.direction)
    end
    track.join("\n")
  end

  def first_hit
    loop do
      collisions = move
      return collisions.first unless collisions.empty?
    end
  end

  def last_man_standing
    while carts.size != 1
      collisions = move
      remove_carts(collisions) unless collisions.empty?
    end
    carts.first.position
  end

  private

  def remove_carts(collisions)
    @carts = carts.select { |cart| !collisions.include?(cart.position) }
    puts "#{tick}: removing #{collisions.inspect} #{@carts.size} remain"
  end

  CART_CHARS = "<>^v"

  def find_carts
    lxs = @track.map { |line| 
      (0...line.size)
      .zip(line.chars) 
      .select { |x, c| CART_CHARS.include?(c) }
    }
    ly = (0...lxs.size).zip(lxs).select { |y, lx| lx.size > 0 }
    carts = ly.reduce([]) { |acc, (y, lx)| lx.reduce(acc) { |acc, (x, c)| acc << [x, y, c]; acc }}
    carts.map { |x, y, c| Cart.new(position: [x, y], direction: char_to_dir(c)) }
  end

  def char_to_dir(c)
    case c
    when '<' then :left
    when '>' then :right 
    when '^' then :up
    when 'v' then :down 
    end
  end

  def fix_tracks
    carts.each do |cart|
      x, y = cart.position
      @track[y][x] = dir_to_track(cart.direction)
    end
  end

  def dir_to_track(dir)
    case dir
    when :left, :right then '-'
    when :up, :down then '|'
    end
  end

  def dir_to_cart_char(dir)
    case dir
    when :left then '<'
    when :right then '>'
    when :up then '^'
    when :down then 'v'
    end
  end
end

RSpec.describe "day 13" do
  let(:input) {
    <<~INPUT
    /->-\\        
    |   |  /----\\
    | /-+--+-\\  |
    | | |  | v  |
    \\-+-/  \\-+--/
      \\------/   
    INPUT
  }

  let(:lines) { input.split("\n") }

  describe Cart do
    subject(:cart) { Cart.new(position: position, direction: direction) }
    let(:position) { [0, 0] }
    let(:direction) { :up }

    let(:track) { Track.new(lines) }

    it "has a position" do
      expect(cart).to respond_to(:position)
    end

    it "has a direction" do
      expect(cart).to respond_to(:direction)
    end

    it "has a state to manage its turns" do
      expect(cart).to respond_to(:turn_state)
    end

    context "movement" do
      subject(:move) { cart.move(track) }

      context "when the cart is facing up" do
        let(:direction) { :up }

        it "moves up" do
          expect { move }.to change { cart.position[1] }.by(-1)
        end

        context "and the track is /" do
          let(:position) { [0, 1] }

          it "turns right" do
            expect { move }.to change { cart.direction }.from(:up).to(:right)
          end
        end

        context "and the track is \\" do
          let(:position) { [12, 2] }

          it "turns left" do
            expect { move }.to change { cart.direction }.from(:up).to(:left)
          end
        end

        context "and the track is +" do
          let(:position) { [4, 3] }
          it "turns left" do
            expect { move }.to change { cart.direction }.from(:up).to(:left)
            cart.position = [5, 2]
            expect { cart.move(track) }.to_not change { cart.direction }
            cart.position = [5, 2]
            expect { cart.move(track) }.to change { cart.direction }.from(:left).to(:up)
            cart.position = [4, 3]
            expect { cart.move(track) }.to change { cart.direction }.from(:up).to(:left)
          end
        end
      end

      context "when the cart is facing right" do
        let(:direction) { :right }

        it "moves right" do
          expect { move }.to change { cart.position[0] }.by(1)
        end
      end

      context "when the cart is facing down" do
        let(:direction) { :down }

        it "moves down" do
          expect { move }.to change { cart.position[1] }.by(1)
        end
      end

      context "when the cart is facing left" do
        let(:direction) { :left }

        it "moves left" do
          expect { move }.to change { cart.position[0] }.by(-1)
        end
      end
    end
  end

  describe Track do
    subject(:track) { Track.new(lines) }

    it "loads a track from a text file" do
      expect { track }.to_not raise_error
    end

    it "identifies the track at coords" do
      expect(track.at([0, 0])).to eq "/"
      expect(track.at([1, 0])).to eq "-"
      expect(track.at([3, 0])).to eq "-"
      expect(track.at([4, 0])).to eq "\\"
      expect(track.at([4, 2])).to eq "+"
      expect(track.at([4, 3])).to eq "|"
    end

    it "finds the carts" do
      expect(track.carts.size).to eq 2
    end

    it "correctly identifies the track under a cart" do
      expect(track.at([2, 0])).to eq '-'
    end

    it "moves the carts as expected" do
      13.times do 
        track.move
        puts track.track_with_carts
      end
    end

    describe "collisions" do
      context "when the carts are one space apart" do
        let(:input) {
          <<~INPUT
          ->-<-
          INPUT
        }

        it "they collide" do
          collisions = track.move

          expect(collisions.size).to eq 1
        end
      end

      context "when the carts are adjacent", :focus do
        let(:input) {
          <<~INPUT
          -><-
          INPUT
        }

        it "they collide" do
          # require "byebug"
          # byebug
          collisions = track.move

          expect(collisions.size).to eq 2
        end
      end 
    end
  end

  describe "pt1" do
    let(:lines) { File.readlines("input.txt") }
    subject(:track) { Track.new(lines) }

    it "finds a collision" do
      puts track.first_hit.inspect
    end
  end

  describe "pt2", :pt2 do
    let(:lines) { File.readlines("input.txt") }
    subject(:track) { Track.new(lines) }

    it "finds the last cart" do
      puts track.last_man_standing.inspect
      track.move
      puts track.carts.first.position.inspect
    end
  end
end
