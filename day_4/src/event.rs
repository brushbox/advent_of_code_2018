#[derive(Debug)]
#[derive(PartialEq)]
pub enum Event {
    StartShift(u32),
    FallAsleep,
    WakeUp
}

impl Event {
    pub fn parse(s : &str) -> Event {
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

