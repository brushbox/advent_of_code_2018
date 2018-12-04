require 'set'

vals = $stdin.readlines.map(&:to_i)
# puts vals
puts vals.sum
seen = Set.new
freq = 0
while true do
  freqs = vals.each_with_object([0]) { |v, o| o << o.last + v }
  for v in vals
    seen.add(freq)
    freq += v
    if seen.include?(freq)
      puts freq
      exit
    end
  end
end
# puts freqs
# for v in vals
#   seen[freq] += 1
#   # seen << freq
#   freq += v
#   puts "Already seen: #{freq}" if seen.?(freq)
# end

puts freqs.sort
