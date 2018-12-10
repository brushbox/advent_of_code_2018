Marble = Struct.new(:value, :cw, :ccw) do
  def insert(m)
    m.ccw = self
    m.cw = self.cw
    self.cw = m
    m.cw.ccw = m 
  end

  def remove!
    self.ccw.cw = self.cw
    self.cw.ccw = self.ccw
    self.cw = self.ccw = nil 
  end

  def counter_clockwise(count)
    if count == 0
      self
    else
      self.ccw.counter_clockwise(count - 1)
    end
  end
end

class Game 
  attr_reader :current, :marbles

  def initialize(players, marbles)
    @current = Marble.new(0)
    @current.cw = @current.ccw = @current
    @players = players.times.map { |i| Player.new(i + 1) }
    @marbles = marbles.times.map { |i| i + 1 }
  end

  def insert(marble)
    current.cw.insert(marble)
    @current = marble
  end

  def play(player, number)
    if number % 23 == 0
      player.add(number)
      m = current.counter_clockwise(7)
      @current = m.cw
      m.remove!
      player.add(m.value)
    else
      insert(Marble.new(number))
    end
  end

  def play_game
    players = @players.cycle
    marbles.each do |marble|
      play(players.next, marble) 
    end

    @players.max { |p1, p2| p1.score <=> p2.score }
  end
end

class Player
  attr_reader :id, :score

  def initialize(id)
    @id = id
    @score = 0
  end

  def add(value)
    @score += value
  end
end

RSpec.describe "day 9" do
  describe Marble do
    describe '#insert' do
      context 'at start' do
        it "correcly puts the new marble in place" do
          g = Game.new(0, 0).current
          m = Marble.new(1)
          g.insert(m)
          expect(g.cw).to eq(m)
          expect(m.cw).to eq(g)
          expect(m.ccw).to eq(g)
          expect(g.ccw).to eq(m)

          n = Marble.new(2)
          m.insert(n)

          expect(n.ccw).to eq(m)
          expect(n.cw).to eq(g)
          expect(g.ccw).to eq(n)
          expect(m.cw).to eq(n)
        end
      end
    end

    describe '#remove' do
      it "cleanly removes a marble" do
        g = Game.new(0, 0).current
        m = Marble.new(1)
        n = Marble.new(2)
        g.insert(m)
        g.insert(n)

        g.remove!
        n.remove!

        expect(g.cw).to be_nil
        expect(n.cw).to be_nil

        expect(m.cw).to eq m
        expect(m.ccw).to eq m
      end
    end
  end

  describe Game do
    describe "#insert" do
      it "makes the new marble the current marble" do
        g = Game.new(0, 0)
        m = Marble.new(1)
        g.insert(m)
        expect(g.current).to eq m
      end
    end

    describe '#play' do
      context 'for a normal number' do
        let(:player) { Player.new(1) }
        subject(:game) { Game.new(0, 0) }

        it "places the marble" do
          game.play(player, 1)
          expect(game.current.value).to eq 1
        end

        it "doesn't change the player's score" do
          expect { game.play(player, 1) }.to_not change { player.score }
        end
      end
    end

    describe '#play_game' do
      let(:game) { Game.new(players, marbles) }

      subject(:winner) { game.play_game }

      [
        [9, 25, 32],
        [10, 1618, 8317],
        [13, 7999, 146373],
        [17, 1104, 2764],
        [21, 6111, 54718],
        [30, 5807, 37305]
      ].each do |ps, m, s|
        context "example #{ps}, #{m}, #{s}" do
          let(:players) { ps }
          let(:marbles) { m }

          it "has the expected winning score" do
            expect(winner.score).to eq s
          end
        end
      end

      context 'example 9, 25' do
        let(:players) { 9 }
        let(:marbles) { 25 }

        it "declares player 5 the winner" do
          expect(winner.id).to eq 5
        end

        it "has the expected winning score" do
          expect(winner.score).to eq 32
        end
      end
    end
  end

  describe "pt 1" do
    it "scores..." do
      # 476 players; last marble is worth 71657
      g = Game.new(476, 71657)
      puts g.play_game.score
    end
  end

  describe "pt 2" do
    it "scores..." do
      # 476 players; last marble is worth 7165700
      g = Game.new(476, 7165700)
      puts g.play_game.score
    end
  end
end
