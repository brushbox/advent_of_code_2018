use std::collections::HashMap;
use std::io;

/*
def str_diffs(str1, str2) 
  str1.chars.zip(str2.chars).map { |a, b| a != b ? 1 : 0 }
end

def diff_map(lines, str)
  lines.map { |line| str_diffs(str, line) }
end

while !lines.empty? do
  str = lines.pop
  dm = diff_map(lines, str).select { |d| d.sum == 1 }
  if !dm.empty?
    diff = dm.first
    puts str.tap { |s| s.slice!(diff.index(1)) }
    exit
  end
end
*/

fn main() {
    let lines = read_lines();
    let mut llines = lines.clone();
    let counts = lines.iter().map(|line| count_chars(line));
    let twos : i32 = counts.clone().map( |(b, _)| if b { 1 } else { 0 }).sum();
    let threes : i32 = counts.map( |(_, b)| if b { 1 } else { 0 }).sum();
    println!("{}", twos * threes);

    // let line = "Some text".to_string();
    // let sd = str_diffs(&"Same text".to_string(), &line);
    // let s : i32 = sd.into_iter().sum();
    // println!("XXX: 🏯 {}", s);

    while !llines.is_empty() {
        let len = llines.len();
        let s = llines.remove(len-1);
        let dm_all = diff_map(&&llines, &s);
        let dm : Vec<_> = dm_all.iter().filter(|diff| {
            let s : i32 = diff.iter().sum();
            s == 1
        }).collect();
        if !dm.is_empty() {
            let diff = dm.first().expect("dm is not empty");
            let index : usize = index_of(&diff, 1) as usize;
            let left = s.chars().take(index as usize).collect::<String>();
            let right = s.chars().skip((index as usize) + 1).take(s.len() - index - 1).collect::<String>();
            println!("{}{}", left, right);
            return;
        }
    }
}

fn index_of(vec : &Vec<i32>, val : i32) -> i32 {
    let (_, index) = vec.into_iter().zip(0..).find(|(v, _)| **v == val).expect("Don't call this function if the diff doesn't have a match");
    return index;
}

fn str_diffs(str1 : &String, str2 : &String) -> Vec<i32> {
    str1.chars().zip(str2.chars()).map(|(a, b)| if a != b { 1 } else { 0 }).collect()
}

fn diff_map(lines : &Vec<String>, s : &String) -> Vec<Vec<i32>> {
    // let mut res = Vec::new();
    lines.iter().map(|l| str_diffs(s, l)).collect()
    // return res;
}

fn read_lines() -> Vec<String> {
    let mut lines = Vec::new();
    let mut done = false;
    while !done {
        let mut input = String::new();
        match io::stdin().read_line(&mut input) {
            Ok(n) => {
                if n == 0 {
                    done = true;
                } else {
                    lines.push(input.trim().to_string());
                }
            }
            Err(error) => {
                panic!("Error encountered: {}", error);
            }
        }
    }
    lines
}

fn count_chars(str : &String) -> (bool, bool) {
    let mut map : HashMap<char, u32> = HashMap::new();
    for c in str.chars() {
        let count = *map.get(&c).unwrap_or(&0);
        map.insert(c, count + 1);
    }
    return (value_of(&map, 2), value_of(&map, 3));
}

fn value_of(map : &HashMap<char, u32>, size : u32) -> bool {
    for (_k, v) in map.iter() {
        if *v == size {
            return true;
        }
    }
    return false;
}
