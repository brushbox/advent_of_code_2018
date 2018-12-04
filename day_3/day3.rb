Rect = Struct.new(:l, :t, :w, :h) do
  def intersects?(rect)
    if l + w < rect.l || rect.l + rect.w < l ||
      t + h < rect.t || rect.t + rect.h < t
      false
    else
      true
    end
  end

  def r
    l + w
  end

  def b
    t + h
  end
end

claims = $stdin.readlines.map { |line|
  s = line.split(" " )
  id = s.first
  left,top = s[2].split(",").map(&:to_i)
  width,height = s[3].split("x").map(&:to_i)
  [id, Rect.new(left, top, width, height)]
}

def claim(fabric, left, top, width, height)
  x = left
  y = top
  x1 = [0, left].max
  y1 = [0, top].max
  x2 = [999, left + width].min
  y2 = [999, top + height].min
  puts "Filling #{x1},#{y1}-#{x2},#{y2}"
  width.times do |h|
    height.times do |v|
      plot(fabric, x + h, y + v)
    end
  end
end

def plot(fabric, x, y)
  return if x < 0 || y < 0 || x >= 1000 || y >= 1000
  fabric[y][x] = case fabric[y][x]
                  when :empty then :filled
                  when :filled then :multiple
                  when :multiple then :multiple
                 end
end

def count(fabric, what)
  fabric.map { |row|
    row.select { |inch| inch == what }.size
  }.sum
end

def consumed(fabric)
  count(fabric, :multiple)
end

def singles(fabric)
  count(fabric, :filled)
end

fabric = Array.new(1000) { Array.new(1000, :empty) }

claims.each do |claim, r|
  claim(fabric, r.l, r.t, r.w, r.h)
end
puts consumed(fabric)

overlaps = (0...claims.size).map do |index|
  claim, rect = claims[index]
  [claim, rect, claims.map { |x, r| rect.intersects?(r) }.select { |x| x }.size]
end

puts overlaps.find { |c, r, os| os == 1 }

