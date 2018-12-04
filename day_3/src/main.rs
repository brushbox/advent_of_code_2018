use std::io;

enum FabricState {
    Empty,
    Single,
    Multiple
}

struct Fabric {
    inches : Vec<Vec<FabricState>>
}

impl Fabric {
    fn new() -> Self {
        let mut is : Vec<Vec<FabricState>> = Vec::new();
        for y in 0..1000 {
            let mut row = Vec::new();
            for x in 0..1000 {
                row.push(FabricState::Empty);
            } 
            is.push(row);
        }

        Fabric { inches: is }
    }

    fn fill(&mut self, (_c, t, l, w, h) : &(String, i32, i32, i32, i32)) {
        let x1 = *l.max(&0);
        let y1 = *t.max(&0);
        let x2 = (l + w).min(999);
        let y2 = (t + h).min(999);
        // println!("Filling {},{}-{},{}", x1, y1, x2, y2);
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
}

fn main() {
    let lines = read_lines();
    // parse into the appropriate data (claim, rect)
    let claims : Vec<_> = lines.iter().map(|line| line_to_claim(line)).collect();

    // for c in claims.iter() {
    //     let (cl, t, l, w, h) = c;
    //     println!("{} @ {},{}: {}x{}", cl, t, l, w, h);
    // }
    // let fabric
    let mut fabric = Fabric::new();

    for c in claims.iter() {
        fabric.fill(c);
    }
    // count the consumed fabric

    println!("The number of inches filled multiple times: {}", fabric.count_multiples());

    // for each claim, check it against all other claims to see if it intersects
    // if any claim intersects with only 1 claim (itself) ... it is the one we want.
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
