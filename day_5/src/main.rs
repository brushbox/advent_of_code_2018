use std::fs::File;
use std::io::prelude::*;

fn will_cancel(a : char, b : char) -> bool {
    let a_lower = a.to_lowercase().collect::<Vec<_>>()[0];
    let b_lower = b.to_lowercase().collect::<Vec<_>>()[0];
    a != b && a_lower == b_lower 
}

fn p_reduce(s : String) -> String {
    let acc : Vec<Option<char>> = vec!();
    let result : String = 
        s.chars()
            .fold(acc, |mut acc, c| {
                let len = acc.len();
                let l = if len == 0 { None } else { acc[len - 1] };

                if l.is_none() || !will_cancel(l.unwrap(), c) {
                    acc.push(Some(c));
                } else {
                    acc.truncate(len - 1);
                }
                acc
            })
            .iter()
            .map(|x| x.unwrap())
            .collect();

    result
}

fn main() -> std::io::Result<()> {
    println!("Hello, world!");
    part1()?;
    part2()?;

    Ok(())
}

fn p_reduce_without_unit(s : String, unit : char) -> String {
    let s = s.replace(unit, "").replace(unit.to_uppercase().collect::<Vec<_>>()[0], "");
    p_reduce(s)
}

fn units(s : String) -> Vec<char> {
    let mut units : String = s.clone();
    units.make_ascii_lowercase();
    let mut unit_chars : Vec<_> = units.chars().collect();
    unit_chars.sort();
    
    unit_chars.dedup();
    unit_chars
}

fn remove_and_reduce(s : String) -> Vec<(char, usize)> {
    let units = units(s.clone());

    let output = units.iter().map(|u| (*u, p_reduce_without_unit(s.clone(), *u).len()));
    let res : Vec<(char, usize)> = output.collect();
    res
}

fn part1() -> std::io::Result<()> {
    let mut f = File::open("input.txt")?;
    let mut p = String::new();
    f.read_to_string(&mut p)?;

    p = p.trim().to_string();
    let reduced = p_reduce(p);

    println!("Part1: {}", reduced.len());

    Ok(())
}

fn part2() -> std::io::Result<()> {
    let mut f = File::open("input.txt")?;
    let mut p = String::new();
    f.read_to_string(&mut p)?;

    p = p.trim().to_string();

    let mut results = remove_and_reduce(p);

    results.sort_by(|(_, s1), (_, s2)| s1.cmp(s2));

    let (_c, s) = results[0];

    println!("Part2: {}", s);

    Ok(())
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }

    #[test]
    fn a_and_A_cancel() {
        assert!(will_cancel('a', 'A'));
    }

    #[test]
    fn a_and_a_dont_cancel() {
        assert_eq!(will_cancel('a', 'a'), false);
    }

    #[test]
    fn two_different_units_wont_cancel() {
        assert_eq!(will_cancel('a', 'B'), false);
    }

    #[test]
    fn a_unit_and_its_opposite_reduce_to_nothing() {
        assert_eq!(p_reduce("aA".to_string()), "".to_string());
    }

    #[test]
    fn aBbA_reduces_to_nothing() {
        assert_eq!(p_reduce("aBbA".to_string()), "".to_string());
    }

    #[test]
    fn aabAAB_is_unchanged() {
        let s = "aabAAB".to_string();
        assert_eq!(p_reduce(s.clone()), s);
    }

    #[test]
    fn reduces_dabAcCaCBAcCcaDA_to_dabCBAcaDA() {
        assert_eq!(p_reduce("dabAcCaCBAcCcaDA".to_string()), "dabCBAcaDA".to_string());
    }

    #[test]
    fn reduce_without_a_returns_dbCBcD_for_dabAcCaCBAcCcaDA() {
        assert_eq!(p_reduce_without_unit("dabAcCaCBAcCcaDA".to_string(), 'a'), "dbCBcD".to_string());
    }

    #[test]
    fn remove_and_reduce_works() {
        let result = remove_and_reduce("dabAcCaCBAcCcaDA".to_string());
        assert_eq!(
            result,
            vec!(
                ('a', 6),
                ('b', 8),
                ('c', 4),
                ('d', 6)
            )
        );
    }
}
