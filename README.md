```rust
use starknet::ContractAddress;

#[starknet::interface]
trait ISimpleStorage<TContractState> {
    fn get_number(self: @TContractState) -> u64;
    fn store_number(ref self: TContractState, number: u64);
}

#[starknet::contract] 
mod SimpleStorage {
    use starknet::get_caller_address; // 
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        number: u64,
    }

    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractState> {
        fn get_number(self: @ContractState) -> u64 {
            let number = self.number.read();
            number
        }

        fn store_number(ref self: TContractState, number: u64) {
            self.number.write(number);
        }
    }

}

```
