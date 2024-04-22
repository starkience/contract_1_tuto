#[starknet::interface]
pub trait ISum<T> {
    fn increment(ref self: T, incr_value: u64) -> u64;
    fn get_sum(self: @T) -> u64;
}

#[starknet::contract]
mod sum {
    #[storage]
    struct Storage {
        sum: u64
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.sum.write(0);
    }


    #[abi(embed_v0)]
    impl Sum of super::ISum<ContractState> {
        fn increment(ref self: ContractState, incr_value: u64) -> u64 {
            let mut n = self.sum.read();
            n += incr_value;
            self.sum.write(n);
            n
        }
        fn get_sum(self: @ContractState) -> u64 {
            self.sum.read()
        }
    }
}