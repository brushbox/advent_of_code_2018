
def sizes(str)
  sizes = str.chars.group_by { |c| c }.map { |_, els| els.size }.select { |s| s == 2 || s == 3 }
  [sizes.include?(2), sizes.include?(3)]
end

lines = $stdin.readlines.map(&:chomp)
ss = lines.map { |l| sizes(l) }
twos = ss.map { |s| s.first }.select { |x| x }.size
threes = ss.map { | s| s.last }.select { |x| x }.size
puts twos * threes

# def str_diffs(str1, str2) 
#   str1.chars.zip(str2.chars).map { |a, b| a != b ? 1 : 0 }
# end

# def diff_map(lines, str)
#   lines.map { |line| [line, str_diffs(str, line).sum] }
# end

# while !lines.empty? do
#   str = lines.pop
#   dm = diff_map(lines, str).select { |_, c| c == 1 }
#   if !dm.empty?
#     diff = str_diffs(str, dm.first.first)
#     puts str.tap { |s| s.slice!(diff.index(1)) }
#     exit
#   end
# end

def str_diffs(str1, str2) 
  str1.chars.zip(str2.chars).map { |a, b| a != b ? 1 : 0 }
end

def diff_map(lines, str)
  lines.map { |line| str_diffs(str, line) }
end

while !lines.empty? do
  str = lines.pop
  dm = diff_map(lines, str).select { |d| d.sum == 1 }
  if !dm.empty?
    diff = dm.first
    puts str.tap { |s| s.slice!(diff.index(1)) }
    exit
  end
end

puts "End"
