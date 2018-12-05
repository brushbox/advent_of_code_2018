// use timestamps::{Date, Time, Timestamp};
use chrono::prelude::*;
use chrono::Duration;
use std::collections::HashMap;

#[derive(Debug)]
#[derive(Clone)]
pub struct Activity {
  started_at : DateTime<Local>,
  activity : HashMap<u32, bool>
}

impl Activity {
  pub fn new(dt : DateTime<Local>) -> Activity {
    let a = HashMap::new();
    Activity { 
      started_at: dt,
      activity:  a
    }
  }

  pub fn record_sleep(&mut self, start : &DateTime<Local>, stop : &DateTime<Local>) {
    let first = self.clamp_start(start);
    let last = self.clamp_stop(stop);

    println!("Between {} and {}", first, last);

    let one_minute = Duration::minutes(1);
    let mut now = first;
    while now < last {
      self.activity.insert(now.minute(), true);
      // self.activity[now.minute()] = '#';
      now = now.checked_add_signed(one_minute).unwrap();
    }
  }

  pub fn chart(&self) -> String {
    let mut result = String::with_capacity(60);
    for m in 0..60 {
      if *self.activity.get(&m).unwrap_or(&false) {
        result.push('#');
      }
      else {
        result.push('.');
      }
    }
    result
  }

  pub fn shift_date(&self) -> Date<Local> {
    if self.is_before_shift(&self.started_at) {
      self.started_at.date().succ()
    } else {
      self.started_at.date()
    }
  }

  fn is_before_shift(&self, date_time : &DateTime<Local>) -> bool {
    date_time.hour() != 0
  }

  fn clamp_start(&self, start : &DateTime<Local>) -> DateTime<Local> {
    if start < &self.shift_date().and_hms(0, 0, 0) {
      self.shift_date().and_hms(0, 0, 0)
    }
    else {
      *start
    }
  }

  fn clamp_stop(&self, stop : &DateTime<Local>) -> DateTime<Local> {
    if stop >= &self.shift_date().and_hms(1, 0, 0) {
      self.shift_date().and_hms(1, 0, 0)
    }
    else {
      *stop
    }
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

    #[test]
    fn sleep_is_recorded() {
      let mut activity = Activity::new(Local.ymd(2018, 11, 1).and_hms(23, 56, 0));
      activity.record_sleep(
        &Local.ymd(2018, 11, 2).and_hms(0, 12, 0),
        &Local.ymd(2018, 11, 2).and_hms(0, 20, 0));

      assert_eq!(activity.chart(), "............########........................................".to_string());
    }

    #[test]
    fn out_of_bounds_sleeps_are_truncated() {
      let mut activity = Activity::new(Local.ymd(2018, 11, 1).and_hms(23, 45, 0));
      activity.record_sleep(
        &Local.ymd(2018, 11, 1).and_hms(23, 56, 0),
        &Local.ymd(2018, 11, 2).and_hms(0, 6, 0));
      activity.record_sleep(
        &Local.ymd(2018, 11, 2).and_hms(0, 58, 0),
        &Local.ymd(2018, 11, 2).and_hms(1, 3, 0));

      assert_eq!(activity.chart(), "######....................................................##".to_string());
    }
}
