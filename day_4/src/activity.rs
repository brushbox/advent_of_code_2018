// use timestamps::{Date, Time, Timestamp};
use chrono::prelude::*;

pub struct Activity {
  started_at : DateTime<Local>
}

impl Activity {
  fn new(ts : DateTime<Local>) -> Activity {
    Activity { started_at: ts }
  }

  fn chart(&self) -> String {
    "............................................................".to_string()
  }

  fn shift_date(&self) -> Date<Local> {
    if self.is_before_shift(&self.started_at) {

      self.started_at.date().succ()
      // (self.started_at.date.month, self.started_at.date.day + 1)
    } else {
      self.started_at.date()
      // (self.started_at.date.month, self.started_at.date.day)
    }
  }

  fn is_before_shift(&self, date_time : &DateTime<Local>) -> bool {
    date_time.hour() != 0
  }

  fn record_sleep(&mut self, start : &DateTime<Local>, stop : &DateTime<Local>) {

  }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_blank_activity_is_awake_for_the_whole_shift() {
      let activity = Activity::new(Local.ymd(2018, 11, 1).and_hms(23, 25, 0));

      assert_eq!(activity.chart(), "............................................................".to_string());
    }

    #[test]
    fn the_date_of_a_shift_reflects_the_next_or_current_midnight_period() {
      let activity = Activity::new(Local.ymd(2018, 11, 1).and_hms(23, 56, 0));

      assert_eq!(activity.shift_date(), Local.ymd(2018, 11, 2));

      let activity = Activity::new(Local.ymd(2018, 11, 1).and_hms(0, 6, 0));
      assert_eq!(activity.shift_date(), Local.ymd(2018, 11, 1));
    }
}
