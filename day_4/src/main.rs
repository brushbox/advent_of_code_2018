extern crate chrono;

mod activity;
mod shift;

use chrono::prelude::*;

use std::fs::File;
use std::io::{self, BufRead, BufReader};

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

// #[derive(Debug)]
// #[derive(PartialEq)]
// #[derive(Eq)]
// struct Shift {
//     month: u32,
//     day: u32,
//     guard: u32,
//     activity: String
// }

// impl Shift {
//     fn from_events(events : &Vec<(Timestamp, Event)>) -> Vec<Shift> {
//         let (ts,ev) = events[0];
//         let current_guard = match ev {
//             Event::StartShift(id) => id,
//             _ => panic!("first event should be StartShift");
//         };
//         // let mut guard_awake_at = (ts.date.month,ts.date.day,ts.time.hour,ts.time.minute);
//         let mut result = Vec::new();
//         let evs = events.iter().skip(1);
//         let mut activity = Activity::new(ts);
//         // let mut activity = "............................................................".to_string();
//         let mut first_date = ts;
//         let mut current_date = first_date;
//         let mut sleep_starts : Option<Timestamp> = None;

//         for (ts, ev) in evs {
//             match ev {
//                 Event::StartShift(id) => {
//                     if let Some(start_time) = sleep_starts {
//                         activity.sleep_period(start_time, ts);
//                     }
//                     result.push(
//                         Shift{
//                             month: shift_month(first_date, current_date),
//                             day: shift_day(first_date, current_date),
//                             guard: current_guard,
//                             activity: activity
//                         });

//                     current_guard = id;
//                     current_date = ts;
//                     first_date = current_date;
//                     activity = Activity::new(ts); //"............................................................".to_string();
//                     sleep_starts = None;
//                 },
//                 Event::FallAsleep => {
//                     sleep_starts = Some(ts);
//                 },
//                 Event::WakeUp => {
//                     activity.sleep_period(sleep_starts, ts);
//                 },
//             }
//         }
//         result
//     }
// }

fn main() {
    println!("Hello, world!");
}

fn parse_datetime(s : &str) -> DateTime<Local> {
    let ts_pieces : Vec<_> = s.split(' ').collect();
    let ymd = ts_pieces[0];
    let hm = ts_pieces[1];

    let d_pieces : Vec<_> = ymd.split('-').map(|comp| comp.parse::<u32>().unwrap()).collect();
    let y = d_pieces[0] as i32;
    let m = d_pieces[1];
    let d = d_pieces[2];

    let t_pieces : Vec<_> = hm.split(':').map(|comp| comp.parse::<u32>().unwrap()).collect();
    let h = t_pieces[0];
    let min = t_pieces[1];

    Local.ymd(y, m, d).and_hms(h, min, 0)
}

fn parse_line(line : &str) -> (DateTime<Local>, Event) {
    let pieces : Vec<_> = line.split(']').collect();

    let ts_str : String = pieces[0].chars().skip(1).collect();
    let dt = parse_datetime(&ts_str);

    let ev_str : String = pieces[1].chars().skip(1).collect();
    let ev = Event::parse(&ev_str);

    (dt, ev)
}

fn parse_lines(lines : Vec<String>) -> Vec<(DateTime<Local>, Event)> {
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
    // use timestamps::*;

    #[test]
    fn parsing_a_line_returns_a_timestamp_event_tuple() {
        let line = "[2018-12-04 17:37] Guard #10 begins shift";
        let (dt, ev)= parse_line(line);

        assert_eq!(dt, Local.ymd(2018, 12, 4).and_hms(17, 37, 0)); 
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
        assert_eq!(*ts_first, Local.ymd(1518, 11, 1).and_hms(0, 0, 0)); // Timestamp{date: Date{year:1518, month: 11, day: 1}, time: Time {hour: 0, minute: 0}});
        assert_eq!(*ts_last, Local.ymd(1518, 11, 5).and_hms(0, 55, 0)); // Timestamp{date: Date{year:1518, month: 11, day: 5}, time: Time {hour: 0, minute: 55}});
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

    // #[test]
    // fn shifts_are_calculated_properly() {
    //     let lines = lines_from_file("input.txt");
    //     let data = parse_lines(lines);
    //     let shifts = Shift::from_events(&data);

    //     assert_eq!(shifts[0], Shift{month:11,day:1,guard:10, activity: ".....####################.....#########################.....".to_string()});
    //     assert_eq!(shifts[shifts.len()-1], Shift{month:11,day:5,guard:99, activity: ".............................................##########.....".to_string()});
    // }
}
