use std::fs::File;
use std::io::{self, BufRead, BufReader};
use std::cmp::Ordering;

#[derive(Debug)]
#[derive(PartialEq)]
enum Event {
    StartShift(u32),
    FallAsleep,
    WakeUp
}

impl Event {
    fn parse(s : &str) -> Event {
        match s.chars().next().unwrap() {
            'G' => {
                let split : Vec<_> = s.split(' ').collect();
                let guard_id_str : String = split[1].chars().skip(1).collect();
                let guard_id : u32 = guard_id_str.parse().unwrap();
                Event::StartShift(guard_id)
            },
            'f' => Event::FallAsleep,
            'w' => Event::WakeUp,
            _ => panic!("Unexpected event")
        }
    }
}


#[derive(Debug)]
#[derive(PartialEq)]
#[derive(Eq)]
struct Date {
    year : u32,
    month : u32,
    day : u32,
}

impl Date {
    fn parse(s : &str) -> Date {
        let pieces : Vec<_> = s.split('-').map(|comp| comp.parse::<u32>().unwrap()).collect();
        Date { year: pieces[0], month: pieces[1], day: pieces[2] }
    }
}

impl Ord for Date {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.year.cmp(&other.year) {
            Ordering::Equal => {
                match self.month.cmp(&other.month) {
                    Ordering::Equal => self.day.cmp(&other.day),
                    order => order
                }
            },
            order => order
        }
    }
}

impl PartialOrd for Date {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

#[derive(Debug)]
#[derive(PartialEq)]
#[derive(Eq)]
struct Time {
    hour: u32,
    minute: u32
}

impl Time {
    fn parse(s : &str) -> Time {
        let pieces : Vec<_> = s.split(':').map(|comp| comp.parse::<u32>().unwrap()).collect();
        Time { hour: pieces[0], minute: pieces[1] }
    }
}

impl Ord for Time {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.hour.cmp(&other.hour) {
            Ordering::Equal => self.minute.cmp(&other.minute),
            order => order
        }
    }
}

impl PartialOrd for Time {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

#[derive(Debug)]
#[derive(PartialEq)]
#[derive(Eq)]
struct Timestamp {
    date : Date,
    time : Time
    // year : u32,
    // month : u32,
    // day : u32,
    // hour : u32,
    // minute : u32
}

impl Timestamp {
    fn parse(s : &str) -> Timestamp {
        let ts_pieces : Vec<_> = s.split(' ').collect();
        let ymd = ts_pieces[0];
        let hm = ts_pieces[1];

        let date = Date::parse(ymd);
        let time = Time::parse(hm);
        // let (y, mo, d) = parse_ymd(ymd);
        // let (h, mi) = parse_hm(hm);

        Timestamp {date: date, time: time }
    }
}

impl Ord for Timestamp {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.date.cmp(&other.date) {
            Ordering::Equal => self.time.cmp(&other.time),
            order => order
        }
    }
}

impl PartialOrd for Timestamp {
    fn partial_cmp(&self, other :&Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

fn main() {
    println!("Hello, world!");
}

fn parse_line(line : &str) -> (Timestamp, Event) {
    let pieces : Vec<_> = line.split(']').collect();

    let ts_str : String = pieces[0].chars().skip(1).collect();
    let ts = Timestamp::parse(&ts_str);

    let ev_str : String = pieces[1].chars().skip(1).collect();
    let ev = Event::parse(&ev_str);

    (ts, ev)
}

fn parse_lines(lines : Vec<String>) -> Vec<(Timestamp, Event)> {
    let mut entries = lines.iter().map(|line| parse_line(line)).collect::<Vec<_>>();
    entries.sort_by(|(a,_), (b,_)| a.cmp(b));
    entries
}

fn lines_from_file(filename : &str) -> Vec<String> {
    let file = File::open(filename).unwrap();
    let buf_reader = BufReader::new(file);
    buf_reader.lines().map(|l| l.unwrap()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parsing_a_line_returns_a_timestamp_event_tuple() {
        let line = "[2018-12-04 17:37] Guard #10 begins shift";
        let (ts, ev)= parse_line(line);

        assert_eq!(ts, Timestamp{date: Date{year: 2018, month: 12, day: 4}, time: Time {hour: 17, minute: 37}});
        assert_eq!(ev, Event::StartShift(10));
    }

    #[test]
    fn can_read_multiple_lines() {
        let lines = vec!("[2018-12-04 17:37] Guard #10 begins shift", "[2018-12-03 00:00] Guard #1 blah blah", "[2018-12-05 00:04] falls asleep")
            .iter().map(|s| s.to_string()).collect::<Vec<_>>();
        let data = parse_lines(lines);

        assert_eq!(3, data.len());
    }

    #[test]
    fn can_read_from_input() {
        let input = io::Cursor::new(
"[1518-11-01 00:00] Guard #10 begins shift
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
[1518-11-05 00:55] wakes up".as_bytes());
        let lines = input.lines().map(|l| l.unwrap()).collect::<Vec<_>>();
        assert_eq!(17, lines.len());

        let data = parse_lines(lines);
        assert_eq!(17, data.len());
    }

    #[test]
    fn can_sort_data() {
        let input = io::Cursor::new(
"[1518-11-01 00:00] Guard #10 begins shift
[1518-11-02 00:40] falls asleep
[1518-11-02 00:50] wakes up
[1518-11-03 00:29] wakes up
[1518-11-03 00:05] Guard #10 begins shift
[1518-11-03 00:24] falls asleep
[1518-11-04 00:02] Guard #99 begins shift
[1518-11-04 00:36] falls asleep
[1518-11-04 00:46] wakes up
[1518-11-05 00:03] Guard #99 begins shift
[1518-11-01 00:05] falls asleep
[1518-11-01 00:25] wakes up
[1518-11-05 00:55] wakes up
[1518-11-01 00:30] falls asleep
[1518-11-01 00:55] wakes up
[1518-11-01 23:58] Guard #99 begins shift
[1518-11-05 00:45] falls asleep".as_bytes());

        let lines = input.lines().map(|l| l.unwrap()).collect::<Vec<_>>();
        let data = parse_lines(lines);

        let (ts_first, _) = &data[0];
        let (ts_last, _) = &data[data.len()-1];

        println!("{:?}", data);
        assert_eq!(*ts_first, Timestamp{date: Date{year:1518, month: 11, day: 1}, time: Time {hour: 0, minute: 0}});
        assert_eq!(*ts_last, Timestamp{date: Date{year:1518, month: 11, day: 5}, time: Time {hour: 0, minute: 55}});
    }

    #[test]
    fn can_read_input_file() {
        let lines = lines_from_file("input.txt");
        let data = parse_lines(lines);

        assert_eq!(1098, data.len());

    }

    #[test]
    fn input_always_has_start_shift_first() {
        let lines = lines_from_file("input.txt");
        let data = parse_lines(lines);
        let (_, ref ev) = data[0];

        assert_eq!(true, match ev { Event::StartShift(_) => true, _ => false});
    }
}
