use timestamps::{Date, Time, Timestamp};

pub struct Activity {
  started_at : Timestamp
}

impl Activity {
  fn new(ts : Timestamp) -> Activity {
    Activity { started_at: ts }
  }

  fn chart(&self) -> String {
    "............................................................".to_string()
  }

  fn shift_date(&self) -> (u32, u32) {
    if self.is_before_shift(&self.started_at.time) {
      (self.started_at.date.month, self.started_at.date.day + 1)
    } else {
      (self.started_at.date.month, self.started_at.date.day)
    }
  }

  fn is_before_shift(&self, time : &Time) -> bool {
    time.hour != 0
  }

  fn record_sleep(&mut self, start : &Time, stop : &Time) {
    
  }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_blank_activity_is_awake_for_the_whole_shift() {
      let activity = Activity::new(Timestamp{date:Date{year:2018,month:11,day:1},time:Time{hour:23,minute:56}});

      assert_eq!(activity.chart(), "............................................................".to_string());
    }

    #[test]
    fn the_date_of_a_shift_reflects_the_next_or_current_midnight_period() {
      let activity = Activity::new(Timestamp{date:Date{year:2018,month:11,day:1},time:Time{hour:23,minute:56}});

      assert_eq!(activity.shift_date(), (11,2));

      let activity = Activity::new(Timestamp{date:Date{year:2018,month:11,day:1},time:Time{hour:00,minute:06}});
      assert_eq!(activity.shift_date(), (11,1));
    }
}
