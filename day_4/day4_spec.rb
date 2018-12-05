require_relative "day4"

RSpec.describe("day4") do
  let(:input) { <<~INPUT
      [1518-11-01 00:00] Guard #10 begins shift
      [1518-11-01 00:05] falls asleep
      [1518-11-01 00:25] wakes up
      [1518-11-01 00:30] falls asleep
      [1518-11-01 00:55] wakes up
      [1518-11-01 23:58] Guard #99 begins shift
      [1518-11-02 00:40] falls asleep
      [1518-11-02 00:50] wakes up
      [1518-11-03 00:05] Guard #10 begins shift
      [1518-11-03 00:24] falls asleep
      [1518-11-03 00:29] wakes up
      [1518-11-04 00:02] Guard #99 begins shift
      [1518-11-04 00:36] falls asleep
      [1518-11-04 00:46] wakes up
      [1518-11-05 00:03] Guard #99 begins shift
      [1518-11-05 00:45] falls asleep
      [1518-11-05 00:55] wakes up
    INPUT
  }

  context "parsing a line" do
    it "returns_a_timestamp_event_tuple()" do 
      line = "[1518-12-04 17:37] Guard #10 begins shift"
      dt, ev = parse_line(line)

      expect(dt).to eq DateTime.new(1518, 12, 4, 17, 37, 0)
    end
  end

  context "parsing lines" do
    it "can parse multiple lines" do
      lines = [
        "[2018-12-04 17:37] Guard #10 begins shift", 
        "[2018-12-03 00:00] Guard #1 blah blah", 
        "[2018-12-05 00:04] falls asleep"]

        data = parse_lines(lines)
        expect(data.size).to eq 3
    end
  end

  context "read from io" do
    it "works" do
      data = parse_string(input) 

      expect(data.size).to eq(17)
    end

    it "can sort the input" do
      data = parse_string(input) 
      expect(data.size).to eq(17)

      expect(data.first).to eq([DateTime.new(1518,11,1, 0, 0, 0), StartShift.new("10")])
      expect(data.last).to eq([DateTime.new(1518, 11, 5, 0, 55), :wake_up])
    end

    it "can read the input file" do
      data = parse_file("input.txt")
      expect(data.size).to eq(1098)
    end
  end

  context "shifts" do
    it "creates them" do
      events = parse_string(input)
      shifts = Shifts.from_events(events)

      # shifts.each do |s|
      #   puts s
      # end

      expect(shifts.shifts.first.activity).to eq ".....####################.....#########################....."
      expect(shifts.shifts.last.activity).to eq ".............................................##########....."
    end
  end

  context "guard minutes asleep" do
    it "calculates the sleep time for each guard" do
      events = parse_string(input)
      shifts = Shifts.from_events(events)

      sleeps = shifts.sleep_counts
      expect(sleeps["10"]).to eq 50
    end

    it "can find sorted sleeps" do
      events = parse_string(input)
      shifts = Shifts.from_events(events)

      sleeps = shifts.sleep_counts

      sleeps = Shift.sort_sleeps(sleeps)
      expect(sleeps.first.first).to eq "10"
    end

    it "can get a histogram of sleep minutes" do
      events = parse_string(input)
      shifts = Shifts.from_events(events)

      histogram = shifts.sleep_histogram("10")

      expect(histogram[0]).to eq 0
      expect(histogram[5]).to eq 1
      expect(histogram[24]).to eq 2
    end

    it "can calculate the guard score" do
      events = parse_string(input)
      shifts = Shifts.from_events(events)
      sleeps = shifts.sleep_counts

      sleeps = Shift.sort_sleeps(sleeps)
      guard = sleeps.first.first

      hist = shifts.sleep_histogram(guard)

      top = hist.sort { |(_, c1), (_, c2)| c2 <=> c1 }.first.first

      puts "Guard #{guard}, minute #{top}"

      expect(guard.to_i * top).to eq(240)
    end

    it "can calculate score for the input data" do
      events = parse_file("input.txt")
      shifts = Shifts.from_events(events)
      sleeps = shifts.sleep_counts

      sleeps = Shift.sort_sleeps(sleeps)
      guard = sleeps.first.first

      hist = shifts.sleep_histogram(guard)

      top = hist.sort { |(_, c1), (_, c2)| c2 <=> c1 }.first.first

      puts "Guard #{guard}, minute #{top} => #{guard.to_i * top}"
    end
  end

  context "strategy 2" do
    let(:shifts) {
      events = parse_string(input)
      Shifts.from_events(events)
    }

    it "can find the histograms for all guards" do
      hists = shifts.all_histograms
      expect(hists.size).to eq 2
    end

    it "can find the top minute for a histogram" do
      hists = shifts.all_histograms
      top = top_minute(hists["10"])
      expect(top).to eq [24, 2]
    end

    it "can find the top minutes for all guards" do
      hists = shifts.all_histograms

      guard, minute = guard_minute(hists)

      expect(guard * minute).to eq(4455)
    end

    it "can find the top minutes for all guards from input" do
      shifts = Shifts.from_events(parse_file("input.txt"))
      guard, minute = guard_minute(shifts.all_histograms)

      puts "Guard #{guard}, minute #{minute} => #{guard * minute}"
    end
  end
end
