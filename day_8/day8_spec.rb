class Node
  def self.build(input)
    child_count = input.shift
    metadata_count = input.shift
    children = child_count.times.map { |_| build(input) }
    metadata = metadata_count.times.map { |_| input.shift } 
    new(children, metadata)
  end

  attr_reader :metadata, :children

  def initialize(children, metadata)
    @children = children
    @metadata = metadata
  end

  def metadata_sum
    metadata.sum + children.map(&:metadata_sum).sum
  end

  def value
    if children.empty?
      metadata.sum
    else
      metadata.map { |index|
        zero_index = index - 1
        if zero_index < 0 || children[zero_index].nil?
          0
        else
          children[zero_index].value
        end
      }.sum
    end
  end
end

RSpec.describe "day 8" do
  describe Node do
    let(:input) { "2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2".split(" ").map(&:to_i) }

    describe '.build' do
      it 'can build a Node hierarchy' do
        node = Node.build(input)
        expect(input).to be_empty
        expect(node.metadata).to eq [1, 1, 2]
      end

      it 'can calculate the metadata sum' do
        node = Node.build(input)

        expect(node.metadata_sum).to eq 138
      end
    end

    describe '#value' do
      context 'a node with no children' do
        it "has a value that is the sum of its metadata" do
          node = Node.new([], [10, 11, 12])

          expect(node.value).to eq 33
        end
      end

      context "a node with children" do
        it "has a value that is the sum of its indexed children's values" do
        end
      end

      context 'for the sample input' do
        it "gets the expected answer" do
          node = Node.build(input)

          expect(node.value).to eq 66
        end
      end
    end
  end

  context 'pt1' do
    let(:input) { File.read("input.txt").split(" ").map(&:to_i) }

    it "is..." do
      node = Node.build(input)
      expect(input).to be_empty
      puts node.metadata_sum
    end
  end

  context 'pt2' do
    let(:input) { File.read("input.txt").split(" ").map(&:to_i) }

    it "is..." do
      node = Node.build(input)
      puts node.value
    end
  end
end
