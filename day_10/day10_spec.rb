require "set"

class Star 
  attr_reader :position, :velocity

  LINE_RE = /position=<([^>]+)> velocity=<([^>]+)>/

  def self.from_line(line)
    m = LINE_RE.match(line)
    pos = m[1].split(",").map(&:strip).map(&:to_i)
    vel = m[2].split(",").map(&:strip).map(&:to_i)

    new(pos, vel)
  end

  def initialize(position, velocity)
    @position = position
    @velocity = velocity
  end

  def position_at(time)
    x, y = position
    vx, vy = velocity

    [x + vx * time, y + vy * time]
  end
end

class Sky 
  attr_reader :positions, :dimensions

  def initialize(time, stars)
    @positions = Set.new(stars.map { |s| s.position_at(time) })

    xs = positions.map(&:first)
    ys = positions.map(&:last)
    xa = xs.sum / xs.size
    ya = ys.sum / ys.size

    @centre = [xa, ya]

    @dimensions = [[xs.min, ys.min], [xs.max, ys.max]]
  end

  def area
    width * height
  end

  def width
    (x1, y1), (x2, y2) = dimensions
    (x2 - x1).abs
  end

  def height
    (x1, y1), (x2, y2) = dimensions
    (y2 - y1).abs
  end

  def render(centre = nil, width = 30, height = 30)
    centre ||= @centre
    x1 = centre.first - width / 2
    y1 = centre.last - height / 2
    x2 = centre.first + width / 2
    y2 = centre.last + height / 2

    (y1..y2).map { |y|
      (x1..x2).map { |x|
        if positions.include?([x, y])
          '#'
        else
          '.'
        end
      }.join
    }.join("\n")
  end
end

RSpec.describe "day 10" do
  describe Star do
    subject(:star) { Star.new([10, 10], [1, 1]) }

    it "can be made from a line" do
      line = "position=<-2,  2> velocity=< 2,  0>"
      star = Star.from_line(line)
      expect(star.position).to eq [-2, 2]
      expect(star.velocity).to eq [2, 0]
    end

    it "has a position" do
      expect(star.position).to eq [10, 10]
    end

    it "has a velocity" do
      expect(star.velocity).to eq [1, 1]
    end

    it "can tell its position at time t" do
      expect(star.position_at(5)).to eq [15, 15]
    end
  end

  describe Sky do
    subject(:sky) { Sky.new(3, stars) }

    let(:stars) {
      [
        Star.new([0, 0], [0, 0]),
        Star.new([0, 0], [0, 1]),
        Star.new([0, 0], [1, 1])
      ]
    }

    it "has dimensions that encompass all the stars" do
      expect(sky.dimensions).to eq([[0, 0], [3, 3]])
    end

    it "can be rendered" do
      expect(sky.render).to eq <<~STARS.chomp
       #...
       ....
       ....
       #..#
      STARS
    end
  end

  context "pt1" do
    let(:stars) { lines.map { |line| Star.from_line(line) } }

    context "sample" do
      let(:sample) { <<~SAMPLE
          position=< 9,  1> velocity=< 0,  2>
          position=< 7,  0> velocity=<-1,  0>
          position=< 3, -2> velocity=<-1,  1>
          position=< 6, 10> velocity=<-2, -1>
          position=< 2, -4> velocity=< 2,  2>
          position=<-6, 10> velocity=< 2, -2>
          position=< 1,  8> velocity=< 1, -1>
          position=< 1,  7> velocity=< 1,  0>
          position=<-3, 11> velocity=< 1, -2>
          position=< 7,  6> velocity=<-1, -1>
          position=<-2,  3> velocity=< 1,  0>
          position=<-4,  3> velocity=< 2,  0>
          position=<10, -3> velocity=<-1,  1>
          position=< 5, 11> velocity=< 1, -2>
          position=< 4,  7> velocity=< 0, -1>
          position=< 8, -2> velocity=< 0,  1>
          position=<15,  0> velocity=<-2,  0>
          position=< 1,  6> velocity=< 1,  0>
          position=< 8,  9> velocity=< 0, -1>
          position=< 3,  3> velocity=<-1,  1>
          position=< 0,  5> velocity=< 0, -1>
          position=<-2,  2> velocity=< 2,  0>
          position=< 5, -2> velocity=< 1,  2>
          position=< 1,  4> velocity=< 2,  1>
          position=<-2,  7> velocity=< 2, -2>
          position=< 3,  6> velocity=<-1, -1>
          position=< 5,  0> velocity=< 1,  0>
          position=<-6,  0> velocity=< 2,  0>
          position=< 5,  9> velocity=< 1, -2>
          position=<14,  7> velocity=<-2,  0>
          position=<-3,  6> velocity=< 2, -1>
        SAMPLE
      }

      let(:lines) { sample.split("\n") }

      it "can display the sky" do
        (0..5).each do |time|
          sky = Sky.new(time, stars)
          puts "Time #{time}:"
          puts sky.render
          puts "\n\n"
        end
      end
    end

    context "input.txt", pt1: true do
      let(:lines) { File.readlines("input.txt") }

      it "can display the sky" do
        # (10000..10200).each do |time|
          # puts "Time #{time}:"
          time = 10144
          sky = Sky.new(time, stars)
          puts "Sky created. Dimensions: #{sky.dimensions.inspect}"
          pos = stars.first.position_at(time)
          # puts "Centering on #{pos.inspect}"
          # puts sky.render(pos, 60, 60)
          puts sky.render(pos, 200, 60)
          puts "\n\n"
        # end

        min_area = 1_000_000_000_000
        min_time = 0
        (0..50000).each do |time|
          sky = Sky.new(time, stars)
          area = sky.area
          if area < min_area
            min_area = area
            min_time = time
            puts "Area: #{min_area} at #{time}"
          end
        end
        puts "Final Area: #{min_area} at #{min_time}"
      end
    end
  end
end
