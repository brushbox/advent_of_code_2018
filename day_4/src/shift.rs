use activity::Activity;
use event::Event;
use chrono::prelude::*;
// use chrono::DateTime;
// use chrono::offset::Local;

#[derive(Debug)]
#[derive(Clone)]
enum GuardState {
  Asleep(DateTime<Local>),
  Awake
}

#[derive(Debug)]
#[derive(Clone)]
// #[derive(PartialEq)]
// #[derive(Eq)]
struct Shift {
  when : DateTime<Local>,
  guard_id : u32,
  activity : Activity,
  state : GuardState
}

impl Shift {
    fn new(dt : DateTime<Local>, id : u32) -> Shift {
      Shift { when: dt, guard_id: id, activity: Activity::new(dt), state: GuardState::Awake }
    }

    fn from_events(events : &Vec<(DateTime<Local>, Event)>) -> Vec<Shift> {
      let mut result : Vec<Shift> = Vec::new();

      if events.is_empty() {
        return result;
      }

      let (dt, ref ev) = events[0];
      let id : Option<u32> = match ev {
        Event::StartShift(id) => Some(*id),
        _ => None
      };
      let events_i = events.iter().skip(1);
      let mut shift : Shift = Shift::new(dt, id.unwrap());

      for (dt, ev) in events_i {
        match ev {
          Event::StartShift(id) => {
                shift.finish();
                result.push(shift);
                shift = Shift::new(*dt, *id);
          },
          Event::FallAsleep => {
            shift.fall_asleep(*dt);
          },
          Event::WakeUp => {
            shift.wake_up(*dt);
          }
        } 
      }

      shift.finish();
      result.push(shift);

      (*result).to_vec()
    }

    pub fn guard(&self) -> u32 {
      self.guard_id
    }

    fn chart(&self) -> String {
      self.activity.chart()
    }

    fn finish(&mut self) {
      let stop = self.activity.shift_date().and_hms(1,0,0);
      self.wake_up(stop);
    }

    fn is_awake(&self) -> bool {
      match self.state {
        GuardState::Awake => true,
        _ => false
      }
    }

    fn is_asleep(&self) -> bool {
      !self.is_awake()
    }

    fn fall_asleep(&mut self, dt : DateTime<Local>) {
      if let GuardState::Awake = self.state { 
        self.state = GuardState::Asleep(dt) 
      }
    }

    fn wake_up(&mut self, dt :DateTime<Local>) {
      if let GuardState::Asleep(start) = self.state { 
        println!("Recording sleep...");
        self.activity.record_sleep(&start, &dt);
        self.state = GuardState::Awake
      }
    }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn it_works() {
    assert_eq!(2 + 2, 4);
  }

  #[test]
  fn an_empty_input_generates_an_empty_output() {
    let events : Vec<(DateTime<Local>, Event)> = Vec::new();
    let shifts = Shift::from_events(&events);

    assert!(shifts.is_empty());
  }

  #[test]
  fn a_single_shift_start_means_one_entry_wide_awake() {
    let events : Vec<(DateTime<Local>, Event)> = vec!(
      (Local.ymd(2018, 12, 5).and_hms(23, 56, 0), Event::StartShift(10))
    );
    let shifts = Shift::from_events(&events);

    assert_eq!(1, shifts.len());
    let shift = &shifts[0];
    assert_eq!(10, shift.guard());
  }

  #[test]
  fn two_shifts_means_two_wide_awake_entries() {
    let events : Vec<(DateTime<Local>, Event)> = vec!(
      (Local.ymd(2018, 12, 5).and_hms(23, 56, 0), Event::StartShift(10)),
      (Local.ymd(2018, 12, 7).and_hms(0, 3, 0), Event::StartShift(11))
    );
    let shifts = Shift::from_events(&events);
    assert_eq!(2, shifts.len());

    let shift = &shifts[0];
    assert_eq!(10, shift.guard());

    let shift = &shifts[1];
    assert_eq!(11, shift.guard());
  }

  #[test]
  fn a_guard_always_starts_awake_on_a_shift() {
    let shift = Shift::new(Local.ymd(2018, 1, 1).and_hms(0, 0, 0), 1);

    assert!(shift.is_awake());
  }

  #[test]
  fn when_a_guard_falls_asleep_their_state_is_asleep() {
    let mut shift = Shift::new(Local.ymd(2018, 1, 1).and_hms(0, 0, 0), 1);
    shift.fall_asleep(Local.ymd(2018, 1, 1).and_hms(0, 55, 0));

    assert!(shift.is_asleep());
  }

  #[test]
  fn when_a_guard_wakes_up_after_sleeping_the_sleep_is_recorded() {
    let mut shift = Shift::new(Local.ymd(2018, 1, 1).and_hms(0, 0, 0), 1);
    shift.fall_asleep(Local.ymd(2018, 1, 1).and_hms(0, 55, 0));

    assert!(shift.is_asleep());

    shift.wake_up(Local.ymd(2018, 1, 1).and_hms(0, 58, 0));

    assert_eq!(shift.chart(), ".......................................................###..".to_string());
  }

  #[test]
  fn when_a_guard_finished_their_shift_asleep_the_sleep_is_recorded() {
    let mut shift = Shift::new(Local.ymd(2018, 1, 1).and_hms(0, 0, 0), 1);
    shift.fall_asleep(Local.ymd(2018, 1, 1).and_hms(0, 55, 0));

    shift.finish();
    assert_eq!(shift.chart(), ".......................................................#####".to_string());
  }
}
