Tutorial 1
- create a contract module
- set number as a u64 storage variable
- we want to manipulate this variable
- so we create 2 functions: get_number and store_number
- Both are specified in the interface trait
- this trait ins implement inside of the contract module. The implementation involes specifying the logic of the functions (reading and writing to the storage)



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

Tutorial 2
Let's add some stuff to our simple storage contract
- Our goal is to associate a number to a storage input. So we use a LegacyMap in our storage variable
- we would also like to have more information  when a number is added to the storage. We modify the store_number function to include a operations_counter. This variable writes to the storage operations_counter everytime there is a new number input
- In the future, we want to register these oerations as events, to let everyone know that we store a number
- To expand on the logic of the store_number function, we do a generate_trait. It's in here that we specify the operations_counter
- The external function storre_number does a call to the generate trait function _store_number and says "hey, with this caller address and number there is an increment


```rust
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

```
