use std::io;
use std::collections::HashSet;

fn main() {
    let mut lines = Vec::new();
    let mut done = false;
    // let mut freq = 0;
    // let mut seen = HashSet::new();
    while !done {
        let mut input = String::new();
        match io::stdin().read_line(&mut input) {
            Ok(n) => {
                if n == 0 {
                    done = true;
                } else {
                    lines.push(input);
                }
            }
            Err(error) => {
                println!("Error encountered: {}", error);
                done = true;
            }        
        }
    }
    let drifts = lines.iter().map(|str| {
        str.trim().parse::<i32>().unwrap()
    });

    println!("Drift is {}", drifts.clone().sum::<i32>());
    // find_repeat(drifts);
    let mut freq = 0;
    let mut seen = HashSet::new();
    loop {
        for drift in drifts.clone() {
            seen.insert(freq);
            freq = freq + drift;
            if seen.contains(&freq) {
                println!("First repeated frequency: {}", freq);
                panic!("breaking out!");
            }
        }
    }
}
