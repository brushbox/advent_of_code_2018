require "byebug"

class FuelCells
  def initialize(sn)
    @sn = sn
    @power_sums = {}
    @power_sums[1] = ps1 = {}
    @power_levels = (1..300).map { |y| 
      (1..300).map { |x|
        rid = rack_id(x)
        ((rid * y + @sn) * rid / 100 % 10 - 5).tap { |pl| ps1[[x, y]] = pl }
      }
    }
  end

  def power_level(x, y)
    @power_levels[y - 1][x - 1]
  end

  def rack_id(x)
    x + 10
  end

  def print(xr, yr)
    yr.each { |y|
      xr.each { |x|
        $stdout.write(format("%5d", power_level(x, y)))
      }
      puts
    }
  end

  def power_sum(x, y, square)
    (0..(square-1)).reduce(0) { |sum, iy|
      (0..(square-1)).reduce(sum) { |sum, ix| sum += power_level(x + ix, y + iy) }
    }
  end

  def power_sum2(x, y, square)
    @power_sums[square] = {} unless @power_sums.key?(square)
    if @power_sums[square].key?([x, y])
      @power_sums[square][[x, y]]
    else
      # puts "#{square}: [#{x}, #{y}]"
      # the power sum for square at [x, y] if equal to:
      # o the power sum for (square-1) at [x, y] PLUS
      #   o the sum of the rightmost column PLUS
      #   o the sum of the bottommost row EXCEPT
      #   o the bottom,right cell would be counted twice so we can subtract one of those or truncate
      #     the row or column to avoid the issue
      cx = x + square - 1
      cy = y + square - 1
      column_sum = (y..cy).map { |y1| power_level(cx, y1) }.sum 
      row_sum = (x..(cx-1)).map { |x1| power_level(x1, cy) }.sum
      @power_sums[square][[x, y]] = power_sum2(x, y, square - 1) + column_sum + row_sum
    end
  end

  def power_sums(square = 3, sums = {})
    for y in 1..(300 - square + 1)
      for x in 1..(300 - square + 1)
        sums[power_sum(x, y, square)] = [x, y, square]
      end
    end
    sums
  end

  def power_sums2(square)
    for y in 1..(300 - square + 1)
      for x in 1..(300 - square + 1)
        power_sum2(x, y, square)
      end
    end
    @power_sums[square]
  end

  def any_size_sums
    maxs = (2..300).map { |square|
      puts square
      sums = power_sums2(square)
      (x, y), val = sums.max { |(_, v1), (_, v2)| v1 <=> v2 }
      [val, x, y, square]
    }
    maxs.max { |(v1, _, _, _), (v2, _, _, _)| v1 <=> v2 }
  end
end

RSpec.describe "day 11" do
  context "pt1", pt1: true do
    describe "#power_level" do
      [
        [3, 5, 8, 4],
        [122, 79, 57, -5],
        [217, 196, 39, 0],
        [101, 153, 71, 4]
      ].each do |x, y, sn, result|
        context "for #{x}, #{y} sn #{sn}" do
          it "is #{result}" do
            cells = FuelCells.new(sn)
            expect(cells.power_level(x, y)).to eq result
          end
        end
      end
    end

    describe "#power_sums" do
      it "returns a hash" do
        cells = FuelCells.new(18)
        sums = cells.power_sums
        expect(sums[29]).to eq [33,45, 3]

        cells = FuelCells.new(42)
        sums = cells.power_sums
        expect(sums[30]).to eq [21,61, 3]

        biggest = sums.keys.max

        expect(biggest).to eq 30
        expect(sums[biggest]).to eq [21, 61, 3]
      end
    end

    describe "#power_sums2", ps2: true do
      it "returns a hash keyed by [x, y]" do
        cells = FuelCells.new(18)
        ps = cells.power_sums2(3)
        expect(ps[[33, 45]]).to eq 29

        cells = FuelCells.new(42)
        ps = cells.power_sums2(3)
        expect(ps[[21, 61]]).to eq 30

        cells = FuelCells.new(18)
        ps = cells.power_sums2(16)
        expect(ps[[90,269]]).to eq 113

        (x, y), val = ps.max { |(_, v1), (_, v2)| v1 <=> v2 }
        puts "Max is #{val} at #{x}, #{y} for sn 18, size 16"
      end
    end

    describe "pt1", pt1: true do
      it "is..." do
        cells = FuelCells.new(3214)
        sums = cells.power_sums
        biggest = sums.keys.max
        puts sums[biggest].inspect
      end
    end
  end

  # a naive attempt at part 2 involves too many calculations
  # I have two ideas for optimising this
  # o starting at size 1, memoize the calculations. That way every larger square
  #   can be calculated by summing the rightmost and bottommost rows and columns and adding that 
  #   to the calc for the next smaller size (this should significantly reduce the total calculations)
  # o realise that the maxmimum power level a square can have is (size * size * 4) - as the max value
  #   in a cell is 4, we can keep track of the potential maximum value for a square as we add things
  #   up...if the potential is ever less than the current max we have found we can stop calculating
  #   as this square can never be the candidate we are looking for.
  # Unfortunately these two strategies are incompatible. So we will need to consider both separately
  # What that means for option 2 is that we should start at 300 and work backwards - since the 
  # potential maximum size for a square is greater the larger the square is - we may be able to 
  # throw away many squares as we work down.
  context "pt2", pt2: true do
    context "examples" do
      describe "sn 18" do
        it "is 90,269,16" do
          cells = FuelCells.new(18)
          biggest = cells.any_size_sums
          # biggest = sums.keys.max
          expect(biggest[1..-1]).to eq [90, 269, 16]
        end
      end

      describe "sn 42", pt2_ex_42: true do
        it "is 232, 251, 12" do
          cells = FuelCells.new(42)
          biggest = cells.any_size_sums
          # biggest = sums.keys.max
          expect(biggest[1..-1]).to eq [232, 251, 12]
        end
      end
    end

    context "actual", actual: true do
      it "is ... [85, 230, 212, 13]" do
        cells = FuelCells.new(3214)
        biggest = cells.any_size_sums
        puts biggest.inspect
      end
    end
  end
end
