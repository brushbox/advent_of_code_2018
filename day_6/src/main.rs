use std::collections::HashMap;
use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn main() {
    println!("Hello, world!");
}

type Point = (i32, i32);

fn manhattan((x1, y1) : Point, (x2, y2) : Point) -> i32 {
    (x1 - x2).abs() + (y1 - y2).abs()
}

fn line_to_point(line : String) -> Point {
    let pair = line.split(", ").map(|s| s.parse::<i32>().unwrap()).collect::<Vec<_>>();
    (pair[0], pair[1])
}

fn lines_to_points(lines : Vec<String>) -> Vec<Point> {
    lines.iter().map(|line| line_to_point(line.to_string())).collect::<Vec<_>>()
}

fn lines_from_file(filename : &str) -> Vec<String> {
    let file = File::open(filename).unwrap();
    let buf_reader = BufReader::new(file);
    buf_reader.lines().map(|l| l.unwrap()).collect()
}

struct Coord {
    point: Point,
    is_infinite: bool,
    closest_points: Vec<Point>
}

impl Coord {
    fn new(pt : Point) -> Coord {
        Coord { 
            point: pt, 
            is_infinite: false,
            closest_points: Vec::new()
        }
    }

    fn add_closest(&mut self, pt : Point) {

    }

    fn set_infinite(&mut self) {
        self.is_infinite = true;
    }
}

struct Map {
    coords : HashMap<Point, Coord>,
    points : HashMap<Point, Point>, // maps a point to the point of Coord to which it is closest
    left : i32,
    top : i32,
    right : i32,
    bottom : i32
}

impl Map {
    fn new(points : Vec<Point>) -> Map {
        let mut map = Map { 
            coords: HashMap::new(), 
            points: HashMap::new(),
            left: 1000000, 
            top: 1000000, 
            right: -1000000, 
            bottom: -1000000 
        };

        for point in points {
            map.add_coord(point);
        }

        map.calculate();
        map
    }

    fn calculate(&mut self) {
        for y in self.top..self.bottom {
            for x in self.left..self.right {
                let pt = (x, y);
                match self.nearest_coord(pt) {
                    Some(c) => {
                        c.add_closest(pt);
                        if self.is_edge(pt) { c.set_infinite() }
                        self.points.insert(pt, c.point);
                    },
                    None => {}
                }
            }
        }
    }

    fn add_coord(&mut self, pt : Point) {
        self.coords.insert(pt, Coord::new(pt));
        self.update_bounds(pt);
    }

    fn update_bounds(&mut self, point : Point) {
        self.left = self.left.min(point.0);
        self.top = self.top.min(point.1);
        self.right = self.right.max(point.0);
        self.bottom = self.bottom.max(point.1);
    }

    fn nearest_coord(&mut self, pt : Point) -> Option<&mut Coord> {
        None
    }

    fn is_edge(&self, pt : Point) -> bool {
        false
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn manhattan_distance_works() {
        assert_eq!(manhattan((1, 1), (2, 2)), 2);
        assert_eq!(manhattan((1, 1), (1, 10)), 9);
        assert_eq!(manhattan((1, 1), (10, 1)), 9);
        assert_eq!(manhattan((1, 1), (10, 10)), 18);
    }

    #[test]
    fn can_parse_input() {
        let lines = lines_from_file("input.txt");
        let pts = lines_to_points(lines);
        assert_eq!(pts.len(), 50);
    }

    fn test_coords() -> Vec<Point> {
        return vec!(
            (1, 1),
            (1, 6),
            (8, 3),
            (3, 4),
            (5, 5),
            (8, 9)
        )
    }

    #[test]
    fn can_make_a_map() {
        let map = Map::new(test_coords());
    }

//     RSpec.describe "day 6" do
//   let(:input) { <<~INPUT
//       1, 1
//       1, 6
//       8, 3
//       3, 4
//       5, 5
//       8, 9
//     INPUT
//   }

//   describe Map do
//     subject(:map) { Map.new(coords) }

//     context "adding coords" do
//       let(:coords) { [[10, 10]] }

//       it "adds the coord" do
//         expect(map.coord_at([10, 10])).to be_instance_of(Coord)
//         expect(map.coord_at([10, 10]).point).to eq [10, 10]
//       end
//     end

//     context "areas" do
//       let(:coords) {
//         [
//           [1, 1],
//           [1, 5],
//           [5, 1],
//           [5, 5],
//           [3, 3]
//         ]
//       }

//       it "marks edge coords as infinite" do
//         expect(map.coord_at([1, 1])).to be_infinite
//         expect(map.coord_at([5, 5])).to be_infinite
//         expect(map.coord_at([1, 5])).to be_infinite
//         expect(map.coord_at([5, 1])).to be_infinite
//         expect(map.coord_at([3, 3])).to_not be_infinite
//       end
//     end

//     context "sample data" do
//       subject(:map) { Map.new(coords, [0, 0, 370, 370]) }

//       let(:d) { [3, 4] }
//       let(:e) { [5, 5] }
//       let(:coords) { 
//         [
//           [1, 1],
//           [1, 6],
//           [8, 3],
//           d,
//           e,
//           [8, 9],
//         ]
//       }

//       it "has the right value for point D" do
//         coord = map.coord_at(d)
//         expect(coord.closest_points.size).to eq 9
//         expect(coord).to_not be_infinite
//       end

//       it "has the right value for point E" do
//         puts map
//         coord = map.coord_at(e)
//         expect(coord.closest_points.size).to eq 17
//         expect(coord).to_not be_infinite
//       end
//     end
//   end

//   # context "part1" do
//   #   it "is..." do
//   #     part1
//   #   end
//   # end

//   context "part2", pt2: true do
//     let(:input) { <<~INPUT
//         1, 1
//         1, 6
//         8, 3
//         3, 4
//         5, 5
//         8, 9
//       INPUT
//     }

//     let(:lines) { StringIO.open(input) { |f| f.readlines } }
//     let(:coords) {
//       [
//         [1, 1],
//         [1, 6],
//         [8, 3],
//         [3, 4],
//         [5, 5],
//         [8, 9],
//       ]
//     }

//     let(:map) { Map.new(coords) }

//     describe "manhattan sum" do
//       it "is 30 for pt 4, 3" do
//         [
//           [3, 3],
//           [4, 3],
//           [5, 3],

//           [2, 4],
//           [3, 4],
//           [4, 4],
//           [5, 4],
//           [6, 4],

//           [2, 5],
//           [3, 5],
//           [4, 5],
//           [5, 5],
//           [6, 5],

//           [3, 6],
//           [4, 6],
//           [5, 6],
//         ].each do |pt|
//           expect(map.manhattan_sum(pt)).to be < 32
//         end
//       end
//     end

//     describe "manhattan_sum_region" do
//       it "finds a region of size 16 when the sum is limited to 32" do
//         expect(map.manhattan_sum_region(32)).to eq 16
//       end
//     end

//     describe "the real deal" do
//       it "says..." do
//         part2
//       end
//     end1
//   end
// end

}
