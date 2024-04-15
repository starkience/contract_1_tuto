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
        number: u64,
    }


    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractSate> {
        fn get_number(self: @ContractState) -> u64 {
            let number = self.number.read();
            number
        }    

        fn store_number(ref self: TContractState, number: u64) {
            self.number.write(number);
        }
    }
}

