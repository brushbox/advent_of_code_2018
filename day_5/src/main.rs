fn main() {
    println!("Hello, world!");
}

#[cfg(test)]
mod test {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
