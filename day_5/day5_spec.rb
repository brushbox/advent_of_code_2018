def cancel?(a, b)
  a != b && a.downcase == b.downcase
end

def part1
  p = File.read("input.txt").chomp
  puts string_reduce(p).size
end

def units(p)
  p.downcase.chars.sort.uniq
end

def reduce_without_unit(p, u)
  string_reduce(p.gsub(u, '').gsub(u.upcase, ''))
end

def string_reduce(s)
  s.chars.reduce([]) { |acc, c|
    acc.tap {
      # puts "acc: #{acc.inspect} c: #{c.inspect}"

      l = acc.last
      
      if l.nil? || !cancel?(l, c)
        acc << c
      else
        acc.delete_at(-1)
      end
    }
  }.join
end

def remove_and_reduce(p)
  units(p).map do |u|
    [u, reduce_without_unit(p, u).size]
  end
end

def part2
  p = File.read("input.txt").chomp
  results = remove_and_reduce(p)
  shortest = results
              .sort { |(_, s1), (_, s2)| s1 <=> s2 }
              .first.last
  puts "Part2: #{shortest}"
end

RSpec.describe "day 5" do
  context "opposites" do
    it "thinks A an a cancel" do
      expect(cancel?("A", "a")).to be true
    end

    it "thinks a and a don't cancel" do
      expect(cancel?('a', 'a')).to be false
    end

    it "thinks two different letters don't cancel" do
      expect(cancel?('a', 'B')).to be false
    end
  end

  context "single reduce" do
    it "turns aA into an empty string" do
      expect(string_reduce("aA")).to be_empty
    end

    it "abBA becomes ''" do
      expect(string_reduce("abBA")).to eq ""
    end

    it "doesn't change 'aabAAB'" do
      expect(string_reduce('aabAAB')).to eq 'aabAAB'
    end

    it "recudes 'dabAcCaCBAcCcaDA' to 'dabCBAcaDA'" do
      expect(string_reduce('dabAcCaCBAcCcaDA')).to eq 'dabCBAcaDA'
      expect(string_reduce('dabAcCaCBAcCcaDA').size).to eq 10
    end
  end

  it "calculates part1", part1: true do
    part1
  end

  context "part2" do
    context 'reduce without unit' do
      it "without 'a' returns 'dbCBcD' for 'dabAcCaCBAcCcaDA'" do
        expect(reduce_without_unit('dabAcCaCBAcCcaDA', 'a')).to eq 'dbCBcD'
      end
    end

    context "remove_and_reduce for 'dabAcCaCBAcCcaDA'" do
      it 'returns the expected values' do
        result = remove_and_reduce('dabAcCaCBAcCcaDA')
        expect(result).to eq([
          ['a', 6],
          ['b', 8],
          ['c', 4],
          ['d', 6]
        ])
      end
    end

    it "calculates part2", part2: true do
      part2
    end
  end
end
