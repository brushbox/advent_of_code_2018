require 'date'
LINE_RE = /^\[([^\]]*)\] (.*)$/

StartShift = Struct.new(:guard)

def guard_minute(hists)
  tops = top_minutes(hists)

  guard = tops.first.first.to_i
  minute = tops.first.last.first

  [guard, minute]
end

def top_minutes(hists)
  hists
  .map { |guard, hist| [guard, top_minute(hist)] }
  .sort { |(_, (_, c1)), (_, (_, c2))| c2 <=> c1 }
end

def top_minute(hist)
  hist.sort { |(_, c1), (_, c2)| c2 <=> c1 }.first || [0,0]
end

def parse_file(file)
  parse_lines(File.readlines(file).sort)
end

def parse_string(str)
  StringIO.open(str, "r") do |io|
    parse_lines(io.readlines.sort)
  end
end

def parse_lines(lines)
  lines.map { |l| parse_line(l) }
end

def parse_line(line) 
  m = LINE_RE.match(line)
  [DateTime.parse(m[1]), parse_event(m[2])]
end

def parse_event(event) 
  if event.start_with?("falls")
    :fall_asleep
  elsif event.start_with?("wakes")
    :wake_up
  else
    id = /#(\d+)/.match(event)[1]
    StartShift.new(id)
  end
end

class Shifts
  def self.from_events(events)
    return new([]) if events.empty?
    shifts, shift = events.reduce([[], nil]) { |(shifts, shift), event|
      dt, ev = event
      case ev
      when :fall_asleep
        shift.fall_asleep(dt)
      when :wake_up
        shift.wake_up(dt)
      when StartShift
        unless shift.nil?
          shift.finish
          shifts << shift
        end
        shift = Shift.new(dt, ev.guard)
      end
      [shifts, shift]
    }
    shift.finish
    shifts << shift
    new(shifts)
  end

  attr_reader :shifts

  def initialize(shifts)
    @shifts = shifts
  end

  def sleep_counts
    shifts.each_with_object(Hash.new(0)) do |shift, sleeps|
      sleeps[shift.guard] += shift.sleep_count
    end
  end

  def all_histograms
    guards.each_with_object({}) { |guard, h|
      h[guard] = sleep_histogram(guard)
    }
  end

  def sleep_histogram(guard)
    histogram = Hash.new(0)
    shifts
    .select { |shift| shift.guard == guard }
    .each_with_object(Hash.new(0)) { |shift, hist|
      shift.each_minute { |min, v|
        hist[min] += 1 if v
      }
    }
  end

  private

  def guards
    shifts.map { |shift| shift.guard }.uniq
  end
end

class Shift
  def self.sort_sleeps(sleeps)
    sleeps.sort { |(_, c1), (_, c2)| c2 <=> c1 }
  end


  attr_reader :start_time, :guard

  def initialize(dt, guard)
    @start_time = dt 
    @guard = guard
    @activity = Hash.new(false)
    @state = :awake
    @sleep_start = nil
  end

  def each_minute
    (0..59).each do |min|
      yield min, @activity[min]
    end
  end

  def sleep_count
    @activity.values.select { |v| v }.size
  end

  def fall_asleep(dt)
    if @state == :awake
      @state = :asleep
      @sleep_start = dt
    end
  end

  def wake_up(dt)()
    if @state == :asleep
      @state = :awake
      record_sleep(@sleep_start, dt)
    end
  end

  def finish
    stop = shift_end
    wake_up(stop);
  end

  def record_sleep(start, stop)
    start = clamp_start(start).min
    stop = clamp_stop(stop).min
    (start...stop).each { |m| @activity[m] = true }
  end

  def to_s
    format("%02d-%02d #%s %s", shift_start.month, shift_start.day, guard, activity)
  end

  def activity
    (0..59).map { |i|
      @activity[i] ? '#' : '.'
    }.join
  end

  private

  def shift_start
    if before_shift?(@start_time)
      start = @start_time + 1
    else
      start = @start_time
    end
    DateTime.new(start.year, start.month, start.day, 0, 0)
  end

  def shift_end
    start = shift_start
    DateTime.new(start.year, start.month, start.day, 1, 0)
  end
  
  def clamp_start(dt)
    [dt, shift_start].max
  end

  def clamp_stop(dt)
    [dt, shift_end].min
  end

  def before_shift?(dt)
    dt.hour != 0
  end
end
