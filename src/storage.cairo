use starknet::ContractAddress;

#[starknet::interface]
trait ISimpleStorage<TContractState> {
    fn get_number(self: @TContractState) -> u64;
    fn store_number(ref self: TContractState, number: u64);
}

#[starknet::contract] // we add an attribure to define a module as a Starknet contract, this module tells the compiler this code is meant to run on Starknet. We also use modules to make a clear distinction between different components of the contract, such as its storage variables, the constructor, external functions and events.
mod SimpleStorage {
    use starknet::get_caller_address; // 
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        number: LegacyMap::<ContractAddress, u64>,
        operations_counter: u128,
    }

    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractState> {
        fn get_number(self: @ContractState) -> u64 {
            let number = self.number.read();
            number
        }

        fn store_number(ref self: TContractState, number: u64) {
            let caller = get_caller_address();
            self.number.write(number);
            self._store_number(caller);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _store_number(ref self: ContractState, number: u64) {
            let operations_counter = self.operations_counter.read();
            self.number.write(number);
            self.operations_counter.write(operations_counter + 1);
        }
    }
}

