LINE_RE = /^\[(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d)\] (.*)$/

$stdin.readlines.sort.map { |l| LINE_RE.match(l)[1..-1] }
