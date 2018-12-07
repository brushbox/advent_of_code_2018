require "byebug"

def manhattan((x1, y1), (x2, y2))
  (x1 - x2).abs + (y1 - y2).abs
end

def lines_to_points(lines)
  lines.map { |line|
    line.split(", ").map(&:to_i)
  }
end

def part1
  lines = File.readlines("input.txt")
  pts = lines_to_points(lines)
  map = Map.new(pts)

  # puts map.bounds.inspect

  coord = map
            .coords
            .values
            .select { |c| !c.infinite? }
            .sort { |c1, c2| c2.closest_points.size <=> c1.closest_points.size }
            .first
  puts coord.closest_points.size
end

def part2
  lines = File.readlines("input.txt")
  pts = lines_to_points(lines)
  map = Map.new(pts)
  puts map.manhattan_sum_region(10000)
end

class Coord
  attr_reader :point, :closest_points
  attr_accessor :infinite

  alias_method :infinite?, :infinite

  def initialize(point)
    @point = point
    @closest_points = []
    @infinite = false
  end

  def id
    ' X '
  end
end

class Map
  attr_reader :coords

  def initialize(coords, bounds = [1000000, 100000, -1000000, -1000000])
    @points = {}
    @coords = {}
    @left, @top, @right, @bottom = bounds
    coords.each { |coord| add_coord(coord) }
    calculate!
  end

  def coord_at(point)
    @coords[point]
  end

  def bounds
    [@left, @top, @right, @bottom]
  end

  def manhattan_sum_region(threshold) 
    points
    .map { |x, y| manhattan_sum([x, y]) }
    .select { |sum| sum < threshold }
    .size
  end

  def manhattan_sum(point)
    @coords.keys
    .map { |cpoint| manhattan(cpoint, point) }
    .sum
  end

  private

  def add_coord(point)
    @coords[point] = Coord.new(point)
    update_bounds(point)
  end

  def update_bounds(point)
    @left = [@left, point.first].min
    @top = [@top, point.last].min
    @right = [@right, point.first].max
    @bottom = [@bottom, point.last].max
  end

  def points
    Enumerator.new do |yielder|
      x1, y1, x2, y2 = bounds
      (x1..x2).each do |x|
        (y1..y2).each do |y|
          yielder << [x, y]
        end
      end
    end
  end

  def calculate!
    points.each do |x, y|
      c = nearest_coord([x, y])
      next if c.nil?
      c.closest_points << [x, y]
      c.infinite = true if edge?([x, y])
      @points[[x, y]] = c
    end
  end

  def nearest_coord(pt)
    distances = @coords.keys.map do |c_pt|
      [manhattan(pt, c_pt), c_pt]
    end
    distances = distances.sort { |(d1, _), (d2, _)| d1 <=> d2 }

    if distances.size == 1 || distances[0][0] != distances[1][0]
      @coords[distances[0][1]]
    else 
      nil
    end
  end

  def edge?(pt)
    pt.first == @left || pt.first == @right ||
      pt.last == @top || pt.last == @bottom
  end

  def write(s)
    $stdout.write(s)
  end
end

RSpec.describe "day 6" do
  let(:input) { <<~INPUT
      1, 1
      1, 6
      8, 3
      3, 4
      5, 5
      8, 9
    INPUT
  }

  context "manhattan distance" do
    it "works" do
      expect(manhattan([1, 1], [2, 2])).to eq 2
      expect(manhattan([1, 1], [1, 10])).to eq 9
      expect(manhattan([1, 1], [10, 1])).to eq 9
      expect(manhattan([1, 1], [10, 10])).to eq 18
    end
  end

  context "lines to points" do
    it "works" do
      lines = StringIO.open(input) { |f| f.readlines }
      expect(lines_to_points(lines)).to eq [
        [1, 1],
        [1, 6],
        [8, 3],
        [3, 4],
        [5, 5],
        [8, 9],
      ]
    end
  end

  describe Map do
    subject(:map) { Map.new(coords) }

    context "adding coords" do
      let(:coords) { [[10, 10]] }

      it "adds the coord" do
        expect(map.coord_at([10, 10])).to be_instance_of(Coord)
        expect(map.coord_at([10, 10]).point).to eq [10, 10]
      end
    end

    context "areas" do
      let(:coords) {
        [
          [1, 1],
          [1, 5],
          [5, 1],
          [5, 5],
          [3, 3]
        ]
      }

      it "marks edge coords as infinite" do
        expect(map.coord_at([1, 1])).to be_infinite
        expect(map.coord_at([5, 5])).to be_infinite
        expect(map.coord_at([1, 5])).to be_infinite
        expect(map.coord_at([5, 1])).to be_infinite
        expect(map.coord_at([3, 3])).to_not be_infinite
      end
    end

    context "sample data" do
      subject(:map) { Map.new(coords, [0, 0, 370, 370]) }

      let(:d) { [3, 4] }
      let(:e) { [5, 5] }
      let(:coords) { 
        [
          [1, 1],
          [1, 6],
          [8, 3],
          d,
          e,
          [8, 9],
        ]
      }

      it "has the right value for point D" do
        coord = map.coord_at(d)
        expect(coord.closest_points.size).to eq 9
        expect(coord).to_not be_infinite
      end

      it "has the right value for point E" do
        puts map
        coord = map.coord_at(e)
        expect(coord.closest_points.size).to eq 17
        expect(coord).to_not be_infinite
      end
    end
  end

  context "part1", pt1: true do
    it "is..." do
      part1
    end
  end

  context "part2", pt2: true do
    let(:input) { <<~INPUT
        1, 1
        1, 6
        8, 3
        3, 4
        5, 5
        8, 9
      INPUT
    }

    let(:lines) { StringIO.open(input) { |f| f.readlines } }
    let(:coords) {
      [
        [1, 1],
        [1, 6],
        [8, 3],
        [3, 4],
        [5, 5],
        [8, 9],
      ]
    }

    let(:map) { Map.new(coords) }

    describe "manhattan sum" do
      it "is 30 for pt 4, 3" do
        [
          [3, 3],
          [4, 3],
          [5, 3],

          [2, 4],
          [3, 4],
          [4, 4],
          [5, 4],
          [6, 4],

          [2, 5],
          [3, 5],
          [4, 5],
          [5, 5],
          [6, 5],

          [3, 6],
          [4, 6],
          [5, 6],
        ].each do |pt|
          expect(map.manhattan_sum(pt)).to be < 32
        end
      end
    end

    describe "manhattan_sum_region" do
      it "finds a region of size 16 when the sum is limited to 32" do
        expect(map.manhattan_sum_region(32)).to eq 16
      end
    end

    describe "the real deal" do
      it "says..." do
        part2
      end
    end
  end
end
