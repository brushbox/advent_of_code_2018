use std::cmp::Ordering;

#[derive(Debug)]
#[derive(PartialEq)]
#[derive(Eq)]
pub struct Date {
    pub year : u32,
    pub month : u32,
    pub day : u32,
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
pub struct Time {
    pub hour: u32,
    pub minute: u32
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
pub struct Timestamp {
    pub date : Date,
    pub time : Time
}

impl Timestamp {
    pub fn parse(s : &str) -> Timestamp {
        let ts_pieces : Vec<_> = s.split(' ').collect();
        let ymd = ts_pieces[0];
        let hm = ts_pieces[1];

        let date = Date::parse(ymd);
        let time = Time::parse(hm);

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
