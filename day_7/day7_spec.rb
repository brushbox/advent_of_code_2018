LINE_RE = /^Step ([^\s]+) must be finished before step ([^\s]+) can begin\./

def parse_line(line)
  match = LINE_RE.match(line)
  [match[1], match[2]]
end

def pt1
  lines = File.readlines("input.txt")
  g = Graph.build(lines)
  l = g.linearize.join
  puts l
end

class Graph
  def self.build(lines)
    nodes = Set.new
    hash = lines
      .map { |line| parse_line(line) }
      .each_with_object(Hash.new { [] }) do |(from, to), graph|
        nodes.add(from)
        nodes.add(to)
        # puts "#{from} => #{to}"

        ary = graph[from] << to
        graph[from] = ary
      end
    new(nodes, hash)
  end

  attr_reader :graph

  def initialize(nodes, hash)
    @nodes = nodes
    @graph = hash
  end

  def reverse
    @graph.each_with_object(Hash.new { [] }) { |(from, to), rgraph|
      to.each_with_object(rgraph) { |new_from|
        ary = rgraph[new_from] << from
        rgraph[new_from] = ary
      }
    }
  end

  def start_nodes
    r = reverse
    @nodes.select { |node|
      !r.key?(node)
    }.sort
  end

  def next_nodes(node)
    @graph[node].sort
  end

  def linearize
    nodes = start_nodes
    pre_requisites = reverse
    line = []
    while !nodes.empty?
      node, nodes = find_next_ready_node(nodes, line, pre_requisites)
      next_nodes = next_nodes(node)
      line << node
      nodes += next_nodes(node)
      nodes.sort!
      nodes.uniq!
    end
    line
  end

  def find_next_ready_node(nodes, processed, pre_requisites)
    node = nodes.find { |n| pre_requisites[n].all? { |pr| processed.include?(pr) }}
    nodes.delete(node)
    [node, nodes]
  end
end

RSpec.describe "day 7" do
  let(:lines) { 
    [
      "Step C must be finished before step A can begin.",
      "Step C must be finished before step F can begin.",
      "Step A must be finished before step B can begin.",
      "Step A must be finished before step D can begin.",
      "Step B must be finished before step E can begin.",
      "Step D must be finished before step E can begin.",
      "Step F must be finished before step E can begin.",
    ]
  }

  describe "part 1" do
    context "parse line" do
      it "returns a (from, to) tuple" do
        line = "Step C must be finished before step A can begin."
        expect(parse_line(line)).to eq(['C', 'A'])
      end
    end

    context "multiple lines" do
      it "builds a graph" do
        expected_graph = {
          'C' => ['A', 'F'],
          'A' => ['B', 'D'],
          'B' => ['E'],
          'D' => ['E'],
          'F' => ['E']
        }
        expect(Graph.build(lines).graph).to eq(expected_graph)
      end

      it "can reverse a graph" do
        expected_graph = {
          'E' => ['B', 'D', 'F'],
          'B' => ['A'],
          'D' => ['A'],
          'A' => ['C'],
          'F' => ['C']
        }
        g = Graph.build(lines).reverse
        expect(g).to eq(expected_graph)
      end

      it "can find the first node" do
        g = Graph.build(lines)

        expect(g.start_nodes).to eq ['C']
      end
    end

    describe "#next_nodes" do
      let(:graph) { Graph.build(lines) }

      context "given a start node" do
        it "returns the set of next nodes" do
          expect(graph.next_nodes('C')).to eq ['A', 'F']
        end
      end
    end

    describe "#linearize" do
      let(:graph) { Graph.build(lines) }

      it "linearizes correctly" do
        expect(graph.linearize.join).to eq "CABDFE"
      end
    end

    describe "and the answer is" do
      it "is..." do
        pt1
      end
    end
  end

  context "pt2" do
    # we start with an empty list of completed nodes (paired with when they were completed)
    # we start with a full list of nodes to work on
    # we have a list of workers
    # at a given time:
    # - find any incomplete nodes that have their pre-reqs satisfied
    # - find any workers that are available to do work
    # - assign the nodes to workers, output the nodes and when they will be completed
    # we start at time (0 or 1?) - we only check times that correspond to when nodes are completed
    # as that is the only time there is a possibility for a change in the readiness of a node to be
    # worked on
    
  end
end
