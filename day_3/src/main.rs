use std::io;

#[derive(Clone)]
struct Rect {
    left : i32,
    top : i32,
    width : i32,
    height : i32
}

impl Rect {
    fn new(left : i32, top : i32, width : i32, height : i32) -> Rect {
        Rect {left: left, top: top, width: width, height: height }
    }

    fn left(&self) -> i32 {
        self.left
    }

    fn top(&self) -> i32 {
        self.top
    }

    fn right(&self) -> i32 {
        self.left + self.width
    }

    fn bottom(&self) -> i32 {
        self.top + self.height
    }

    fn area(&self) -> i32 {
        self.width * self.height
    }

    fn intersects_with(&self, other : &Rect) -> bool {
        if self.right() < other.left() || other.right() < self.left() ||
            self.bottom() < other.top() || other.bottom() < self.top() { 
                false
        }
        else {
            true
        }
    }
}

#[derive(Clone)]
struct Claim {
    id : String,
    rect : Rect
}

impl Claim {
    fn new(id : String, left : i32, top : i32, width : i32, height : i32) -> Claim {
        Claim { id: id, rect: Rect::new(left, top, width, height) }
    }

    fn parse(s : String) -> Claim {
        let chunks : Vec<_> = s.split(' ').collect();
        let claim = chunks[0];
        let size = chunks[2].len();
        let mut tls : String = chunks[2].to_string();
        tls.truncate(size - 1);
        let tl : Vec<_> = tls.split(',').map(|v| v.parse::<i32>().unwrap()).collect();
        let wh : Vec<_> = chunks[3].split('x').map(|v| v.parse::<i32>().unwrap()).collect();
        return Claim::new(claim.to_string(), tl[0], tl[1], wh[0], wh[1]);
    }
}

#[derive(Debug)]
enum FabricState {
    Empty,
    Single,
    Multiple
}

#[derive(Debug)]
struct Fabric {
    width : usize,
    height : usize,
    inches : Vec<Vec<FabricState>>
}

impl Fabric {
    fn new(width : usize, height : usize) -> Self {
        let mut is : Vec<Vec<FabricState>> = Vec::new();
        for _y in 0..height {
            let mut row = Vec::new();
            for _x in 0..width {
                row.push(FabricState::Empty);
            } 
            is.push(row);
        }

        Fabric { width: width, height: height, inches: is }
    }

    fn fill(&mut self, claim : &Claim) {
        let x1 = claim.rect.left().max(0);
        let y1 = claim.rect.top().max(0);
        let x2 = claim.rect.right().min((self.width - 1) as i32);
        let y2 = claim.rect.bottom().min((self.height - 1) as i32);
        println!("Filling {},{}-{},{}", x1, y1, x2, y2);
        for y in y1..y2 {
            for x in x1..x2 {
                self.plot(x as usize, y as usize);
            }
        }
    }

    fn plot(&mut self, x : usize, y : usize) {
        let val = match self.inches[y][x] {
            FabricState::Empty => FabricState::Single,
            FabricState::Single => FabricState::Multiple,
            FabricState::Multiple => FabricState::Multiple,
        };
        self.inches[y][x] = val;
    }

    fn count_multiples(&self) -> i32 {
        self.inches.iter().map(|row| {
            row.iter().map(|cell| {
                match cell {
                    FabricState::Multiple => 1,
                    _ => 0,
                }
            }).sum::<i32>()
        }).sum()
    }

    fn count_singles(&self) -> i32 {
        self.inches.iter().map(|row| {
            row.iter().map(|cell| {
                match cell {
                    FabricState::Single => 1,
                    _ => 0,
                }
            }).sum::<i32>()
        }).sum()
    }

    fn debug(&self) {
        println!("Fabric {}x{}", self.width, self.height);
        for row in self.inches.iter() {
            for cell in row.iter() {
                let c = match cell {
                    FabricState::Empty => ' ',
                    FabricState::Single => '.',
                    FabricState::Multiple => 'X',
                };
                print!("{}", c);
            }
            println!("");
        }
    }
}

fn main() {
    let lines = read_lines();
    let claims : Vec<_> = lines.iter().map(|line| Claim::parse(line.to_string())).collect();

    let mut fabric = Fabric::new(1000, 1000);

    for c in claims.iter() {
        fabric.fill(c);
    }

    println!("The number of inches filled multiple times: {}", fabric.count_multiples());

    // for each claim, check it against all other claims to see if it intersects
    // if any claim intersects with only 1 claim (itself) ... it is the one we want.

    // overlaps = (0...claims.size).map do |index|
    //     claim, rect = claims[index]
    //     [claim, rect, claims.map { |x, r| rect.intersects?(r) }.select { |x| x }.size]
    // end

    // puts overlaps.find { |c, r, os| os == 1 }
    let cclaims = claims.clone();
    let overlaps : Vec<_> = cclaims.iter().map(|claim| {
        (
            claim, 
            claims
            .clone()
            .iter()
            .map(|c1| c1.rect.intersects_with(&claim.rect))
            .filter(|tf| *tf).count()
        )
    }).collect();

    let (claim, _) = overlaps.iter().find(|(_, count)| *count == 1).unwrap();

    println!("Claim that doesn't overlap: {}", claim.id);
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

fn line_to_claim(s : &String) -> (String, i32, i32, i32, i32) {
    let chunks : Vec<_> = s.split(' ').collect();
    let claim = chunks[0];
    let size = chunks[2].len();
    let mut tls : String = chunks[2].to_string();
    tls.truncate(size - 1);
    let tl : Vec<_> = tls.split(',').map(|v| v.parse::<i32>().unwrap()).collect();
    let wh : Vec<_> = chunks[3].split('x').map(|v| v.parse::<i32>().unwrap()).collect();
    return (claim.to_string(), tl[0], tl[1], wh[0], wh[1]);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }

    #[test]
    fn an_empty_fabric_has_a_count_of_zero() {
        let fabric = Fabric::new(10, 10);
        assert_eq!(0, fabric.count_multiples());
    }

    #[test]
    fn a_fabric_with_only_1_rect_has_a_count_of_zero() {
        let mut fabric = Fabric::new(10, 10);
        fabric.fill(&("one".to_string(), 1, 1, 5, 5));
        assert_eq!(0, fabric.count_multiples());
    }

    #[test]
    fn a_fabric_with_the_same_rect_twice_has_a_count_of_the_area() {
        let mut fabric = Fabric::new(10, 10);
        fabric.fill(&("one".to_string(), 1, 1, 5, 5));
        fabric.fill(&("one".to_string(), 1, 1, 5, 5));
        assert_eq!(25, fabric.count_multiples());
    }

    #[test]
    fn a_fabric_with_the_same_rect_thrice_has_a_count_of_the_area() {
        let mut fabric = Fabric::new(10, 10);
        fabric.fill(&("one".to_string(), 1, 1, 5, 5));
        fabric.fill(&("one".to_string(), 1, 1, 5, 5));
        fabric.fill(&("one".to_string(), 1, 1, 5, 5));
        assert_eq!(25, fabric.count_multiples());
    }


    #[test]
    fn a_fabric_with_two_non_overlapping_rects_has_count_zero() {
        let mut fabric = Fabric::new(10, 10);
        fabric.fill(&("one".to_string(), 0, 0, 2, 2));
        fabric.fill(&("two".to_string(), 2, 2, 3, 3));
        assert_eq!(0, fabric.count_multiples());
    }

    #[test]
    fn a_fabric_with_two_overlapping_rects_counts_the_overlap() {
        let mut fabric = Fabric::new(10, 10);
        fabric.fill(&("one".to_string(), 0, 0, 2, 2));
        fabric.fill(&("two".to_string(), 1, 1, 3, 3));
        // fabric.debug();
        assert_eq!(1, fabric.count_multiples());
    }

    #[test]
    fn example_from_aoc_works() {
        let mut fabric = Fabric::new(8, 8);
        fabric.fill(&("one".to_string(), 1, 3, 4, 4));
        fabric.fill(&("two".to_string(), 3, 1, 4, 4));
        fabric.fill(&("three".to_string(), 5, 5, 2, 2));
        // fabric.debug();
        assert_eq!(4, fabric.count_multiples());
    }
}
