class Turing
  def initialize(lines)
    @index = 0
    @line = lines[0].chomp[15..-1]
    @state = compute_state(@line, @index)
    @rules = read_rules(lines[2..-1])
  end

  def compute_state(line, index)
    (0...(line.size))
      .zip(line.chars)
      .select { |(_, c)| c == '#' }
      .each_with_object(Hash.new('.')) { |(ix, c), state| state[ix + index] = c }
  end

  RULE_RE = /(.....) => (.)/

  def read_rules(lines)
    lines.map { |line|
      m = RULE_RE.match(line)
      pattern = m[1]
      result = m[2]
      [pattern, result]
    }.each_with_object(Hash.new('.')) { |(pattern, result), rules| rules[pattern] = result }
  end

  def line(range)
    range.map { |ix| pot(ix) }.join
  end

  def pot(index)
    @state[index]
  end

  def pattern(index)
    (-2..2).map { |i| pot(index + i) }.join
  end

  def pot_sum
    @state.keys.sum
  end

  def next_gen
    # we need to know the index of the leftmost # - and we can start calculating from -2 before that
    # as that is the earliest pot that can be affected by a rule (apart from a degenerate rule like
    # ..... => # - which can match the infinite collection of pots)
    # to work out the index of the leftmost # we need to know what the first index of the string is
    # this is captured in @index ... and will need to be updated in the next gen.

    first_plant = @line.index('#') + @index
    last_plant = @line.rindex('#') + @index
    first_index = first_plant - 2
    last_index = last_plant + 2

    new_line = (first_index..last_index).map { |ix|
      @rules[pattern(ix)]
    }.join

    @line = new_line
    @index = first_index
    @state = compute_state(@line, @index)
  end
end

RSpec.describe "day 12" do
  let(:example_data) {
    <<~EXAMPLE
      initial state: #..#.#..##......###...###

      ...## => #
      ..#.. => #
      .#... => #
      .#.#. => #
      .#.## => #
      .##.. => #
      .#### => #
      #.#.# => #
      #.### => #
      ##.#. => #
      ##.## => #
      ###.. => #
      ###.# => #
      ####. => #
    EXAMPLE
  }

  let(:lines) {
    StringIO.new(example_data.chomp, "r").readlines
  }

  context "initial state" do
    it "can be read from the input" do
      expect { Turing.new(lines) }.to_not raise_error
    end
  end

  describe "#pot" do
    subject(:turing) { Turing.new(lines) }

    it "returns . for anything out-of-bounds" do
      expect(turing.pot(-3)).to eq '.'
      expect(turing.pot(1000)).to eq '.'
    end

    it "returns the value for anything in the current state" do
      expect(turing.pot(0)).to eq '#'
      expect(turing.pot(3)).to eq '#'
      expect(turing.pot(4)).to eq '.'
    end
  end

  describe "#pattern" do
    subject(:turing) { Turing.new(lines) }

    it "returns the pattern around an index" do
      expect(turing.pattern(0)).to eq '..#..'
      expect(turing.pattern(-10)).to eq '.....'
      expect(turing.pattern(4)).to eq '.#.#.'
    end
  end

  describe '#nex_gen' do
    subject(:turing) { Turing.new(lines) }

    it "computes the next line from the current one" do
      turing.next_gen
      expect(turing.line(-3..35)).to eq '...#...#....#.....#..#..#..#...........'
      turing.next_gen
      expect(turing.line(-3..35)).to eq '...##..##...##....#..#..#..##..........'
    end
  end

  describe "pt1, example", pt1: true do
    subject(:turing) { Turing.new(lines) }

    context "example" do
      it "is..." do
        20.times { turing.next_gen }
        expect(turing.pot_sum).to eq 325
      end
    end

    describe "real input" do
      let(:lines) { File.readlines("input.txt") }

      it "is..." do
        20.times { turing.next_gen }
        puts turing.pot_sum
      end
    end
  end

  describe "pt2" do
    subject(:turing) { Turing.new(lines) }
    let(:lines) { File.readlines("input.txt") }

    it "is..." do
      # from running the calculations below it becomes apparent that generation "settles down"
      # such that it increases in count by a constant factor after it reaches generation 92
      # so, knowing that we can do simple arithmetic to calculate the final answer.
      # i = 0
      # prev = 0
      # 50_000_000_000.times { |i|
      #   turing.next_gen 
      #   sum = turing.pot_sum
      #   puts "#{i + 1} #{sum} : #{sum - prev}"
      #   prev = sum
      # }
      # #=> 92 8646 : 72
      puts (50_000_000_000 - 92) * 72 + 8646
    end
  end
end
