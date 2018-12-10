require "byebug"

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

        ary = graph[from] << to
        graph[from] = ary
      end
    new(nodes, hash)
  end

  attr_reader :graph, :nodes

  def initialize(nodes, hash)
    @nodes = nodes
    @graph = hash
    @pre_requisites = reverse
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

  def pre_requisites_for(node)
    @pre_requisites[node]
  end
end

class WorkerPool
  def initialize(time, workers)
    @time = time
    @workers = workers
    @jobs = []
  end

  def assign(job)
    return false if @jobs.any? { |j| j.node == job.node }
    @jobs << job
    true
  end

  # returns the set of nodes that are completed at a certain time
  def completed_by(time)
    jobs_by_completed_at.select { |job| job.complete <= time }.map(&:node)
  end

  def jobs_by_completed_at
    @jobs.sort { |j1, j2| j1.complete <=> j2.complete }
  end

  def workers_available_at(time)
    @workers - workers_busy_at(time)
  end

  def jobs_in_progress_at(time)
    @jobs.select { |j| j.busy_at?(time) }
  end

  def workers_busy_at(time)
    jobs_in_progress_at(time).map(&:worker).sort
  end


  def node_in_progress_at?(node, time)
    # select all jobs that are working at time
    # see if any are working on node
    @jobs.select { |job| job.busy_at?(time) }
         .any? { |job| job.node == node }
  end
end

class Job
  attr_reader :node, :complete, :worker

  def initialize(worker:, node:, start:, complete:)
    @worker = worker
    @node = node
    @start = start
    @complete = complete
  end

  def busy
    @start...@complete
  end

  def busy_at?(time)
    busy.include?(time)
  end
end

class Solver
  attr_reader :graph, :pool, :cost
  def initialize(graph, worker_pool, fixed_cost)
    @graph = graph
    @pool = worker_pool
    @cost = fixed_cost
  end

  def solve
    time = 0
    completed = pool.completed_by(time)
    while Set.new(completed) != graph.nodes
      # find an available workers at the current time
      w = available_workers(time)
      if w.empty?
        puts "#{time}: No workers available"
        time = next_completed_time(time)
        completed = pool.completed_by(time)
        next
      end
      # find nodes that are ready to be done
      ready = ready_nodes(completed, time)
      # assign nodes to available workers
      w.zip(ready).each do |w, n|
        next if n.nil?
        job = make_job(w, n, time)
        pool.assign(job)
      end
      puts "#{time} : About to go around again - completed: #{completed.inspect}"
      time = next_completed_time(time)
      completed = pool.completed_by(time)
    end
    # completed.join
    time
  end

  def available_workers(time)
    pool.workers_available_at(time).tap { |a| puts "#{time} : Available workers: #{a.inspect}" }
  end

  def ready_nodes(completed, time)
    # all nodes not in `completed`, and not in progress, for which all their pre-reqs _are_ in `completed`
    nodes = graph.nodes.dup
    # nodes.select { |n| !completed.include?(n) && !in_progress?(n, time) && graph.pre_requisites_for(n).all? { |pr| completed.include?(pr) }}
    nodes.select { |n| !completed.include?(n) }.tap { |ns| puts "#{time} : not completed #{ns.inspect}"}
         .select { |n| !in_progress?(n, time) }.tap { |ns| puts "#{time} : not in progress #{ns.inspect}"}
         .select { |n| graph.pre_requisites_for(n).all? { |pr| completed.include?(pr) }}
  end

  def make_job(worker, node, start_time)
    completed_at = start_time + cost + node.ord - 64
    puts "Job(#{worker}, #{node}, #{start_time}, #{completed_at})"
    Job.new(worker: worker, node: node, start: start_time, complete: completed_at)
  end

  def next_completed_time(time)
    # look through the pool for the first job (ordered by end time) that is completed after time
    job = pool.jobs_by_completed_at.find { |j| j.complete > time }
    raise "No next completed event after #{time}" if job.nil?

    job.complete
  end

  def in_progress?(node, time)
    pool.jobs_in_progress_at(time).any? { |j| j.node == node }
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

  context "pt2", pt2: true do
    subject(:pool) { described_class.new(time, [1, 2]) }

    describe WorkerPool do
      let(:time) { 0 }

      it "is initialised with a time a list of worker IDs" do
        expect(pool).to be_instance_of(WorkerPool)
      end

      context "#assign" do
        it "assigns a worker to do a job" do
          job = Job.new(worker: 1, node: 'C', start: 0, complete: 3)
          expect(pool.assign(job)).to be true
        end

        it "won't assign twice" do
          job = Job.new(worker: 1, node: 'C', start: 0, complete: 3)
          expect(pool.assign(job)).to be true
          expect(pool.assign(job)).to be false
        end
      end

      describe '#completed_by' do
        subject { pool.completed_by(time) }

        context 'at time 0' do
          let(:time) { 0 }

          it { should be_empty }
        end

        context 'with some jobs allocated' do
          let(:jobs) {
            [
              [1, 'C', 0],
              [1, 'A', 3],
              [2, 'F', 3],
              [1, 'B', 4],
              [1, 'D', 6],
              [1, 'E', 10]
            ]
          }
          before do
            jobs.each do |id, node, start|
              complete = start + node.ord - 64
              pool.assign(Job.new(worker: id, node: node, start: start, complete: complete))
            end
          end

          context 'at time 0' do
            let(:time) { 0 }

            it { should be_empty }
          end

          context 'at time 3' do
            let(:time) { 3 }

            it { should eq ['C'] }
          end

          context 'at time 6' do
            let(:time) { 6 }

            it { should eq ['C', 'A', 'B'] }
          end

          context 'at time 20' do
            let(:time) { 20 }

            it { should eq ['C', 'A', 'B', 'F', 'D', 'E'] }
          end
        end
      end

      describe '#workers_available_at' do
        let(:jobs) {
          [
            [1, 'C', 0],
            [1, 'A', 3],
            [2, 'F', 3],
            [1, 'B', 4],
            [1, 'D', 6],
            [1, 'E', 10]
          ]
        }
        before do
          jobs.each do |id, node, start|
            complete = start + node.ord - 64
            pool.assign(Job.new(worker: id, node: node, start: start, complete: complete))
          end
        end

        context 'at time 0' do
          let(:time) { 0 }

          it "is is [2]" do
            expect(pool.workers_available_at(0)).to eq [2]
          end
        end

        context 'at time 8' do
          let(:time) { 8 }

          it "is is []" do
            expect(pool.workers_available_at(8)).to eq []
          end
        end

        context 'at time 20' do
          let(:time) { 20 }

          it "is is [1, 2]" do
            expect(pool.workers_available_at(20)).to eq [1, 2]
          end
        end
      end

      describe '#workers_busy_at', focus: true do
        let(:jobs) {
          [
            [1, 'C', 0],
            [1, 'A', 3],
            [2, 'F', 3],
            [1, 'B', 4],
            [1, 'D', 6],
            [1, 'E', 10]
          ]
        }
        before do
          jobs.each do |id, node, start|
            complete = start + node.ord - 64
            pool.assign(Job.new(worker: id, node: node, start: start, complete: complete))
          end
        end

        context 'at time 0' do
          it "is is [1]" do
            expect(pool.workers_busy_at(0)).to eq [1]
          end
        end

        context 'at time 8' do
          it "is is [1, 2]" do
            expect(pool.workers_busy_at(8)).to eq [1, 2]
          end
        end

        context 'at time 20' do
          it "is is []" do
            expect(pool.workers_busy_at(20)).to eq []
          end
        end
      end
    end

    context "example" do
      let(:workers) { 2 }
      let(:fixed_cost) { 0 }
      let(:graph) { Graph.build(lines) }
      let(:worker_pool) { WorkerPool.new(0, (1..workers).to_a)}

      let(:solver) { Solver.new(graph, worker_pool, 0) }

      it "gets the right answer" do
        expect(solver.solve).to eq 15
      end
    end

    context "example 2" do
      let(:workers) { 2 }
      let(:fixed_cost) { 60 }
      let(:graph) { Graph.build(lines) }
      let(:worker_pool) { WorkerPool.new(0, (1..workers).to_a)}

      let(:solver) { Solver.new(graph, worker_pool, fixed_cost) }

      it "gets the right answer" do
        puts solver.solve
      end
    end

    context "and the solution is..." do
      let(:workers) { 5 }
      let(:fixed_cost) { 60 }
      let(:graph) { Graph.build(lines) }
      let(:worker_pool) { WorkerPool.new(0, (1..workers).to_a)}

      let(:solver) { Solver.new(graph, worker_pool, fixed_cost) }

      let(:lines) { File.readlines("input.txt") }

      it "gets an answer" do
        puts solver.solve
      end
    end
  end
end
