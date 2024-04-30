#[starknet::interface]
pub trait IMagic<T> {
    fn increment_magic(ref self: T, incr_value: u64);
    fn get_magic(self: @T) -> u64;
}

#[starknet::contract]
mod magic_value {
    #[storage]
    struct Storage {
        magic_value: u64
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.magic_value.write(0);
    }


    #[abi(embed_v0)]
    impl Magic of super::IMagic<ContractState> {
        fn increment_magic(ref self: ContractState, incr_value: u64) {
            self.magic_value.write(self.magic_value.read() + incr_value);
        }

        fn get_magic(self: @ContractState) -> u64 {
            self.magic_value.read()
        }
    }
}
