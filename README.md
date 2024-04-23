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
    fn get_number(self: @TContractState, address: ContractAddress) -> u64;
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
        fn get_number(self: @ContractState, address: ContractAddress) -> u64 {
            let number = self.number.read(address);
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

Tutorial 3
Here we add a new srorage variable to our storage struct, we add events and a constructor function (which is essential!)
- added an event called StoredNumber. Every time a number is stored, this event gets emitted (according to the generate trait emit functionality)
- When there's a stored number, the storage of operations_counter has a +1, so every time we have an event emitted our storage operations_counter variable increments
- We also a new storage struct: owner. This storage is defined outside of the struct yet we're srill referring to the storage with the ```#[derive(Copy, Drop, Serde, starknet::Store)]``` attribute
- The owner has a name and an address
- We add a constructor. This is essential for smart contracts, we're telling the first values of where the contract has to start.
- We initialize the operations_counter to 1
- We map the our owner address to 0, which is the first number. The owner is also the first address
- We go back to our generate trait and add the 'user' variable, that was defined in our person struct.
- In generate_trait, ```user```is used as a key in the LegacyMap named number
 



```rust
use starknet::ContractAddress;

#[starknet::interface]
trait ISimpleStorage<TContractState> {
    fn get_number(self: @TContractState,address: ContractAddress) -> u64;
    fn store_number(ref self: TContractState, number: u64);
}

#[starknet::contract] // we add an attribure to define a module as a Starknet contract, this module tells the compiler this code is meant to run on Starknet. We also use modules to make a clear distinction between different components of the contract, such as its storage variables, the constructor, external functions and events.
mod SimpleStorage {
    use starknet::get_caller_address; // 
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        number: LegacyMap::<ContractAddress, u64>,
        owner: person,
        operations_counter: u128,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredNumber: StoredNumber,
    }

    #[derive(Drop, starknet::Event)]
    struct StoredNumber {
        #[key]
        user: ContractAddress,
        number: u64,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct person {
        name: felt252,
        address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: person) {
        self.owner.write(owner); // Person object and written into the contract's storage
        self.number.write(owner.address, 0);
        self.operations_counter.write(1);
    }


    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractState> {
        fn get_number(self: @ContractState, address: ContractAddress) -> u64 {
            let number = self.number.read(address);
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
        fn _store_number(ref self: ContractState, user: ContractAddress, number: u64) {
            let operation_counter = self.operation_counter.read();
            self.number.write(user, number);
            self.operation_counter.write(operation_counter + 1);
            self.emit(StoredNumber { user: user, number: number });
        }
    }
}


```

Tutorial 4
Finally, we want to create a new contract that is only for incrementing numbers. Our simpleStorage makes calls through a dispatcher to the sum contract in ortder to increment numbers. We seperate contract logics and keep it modular. We have 1 contract dedicated to storing a variable and another contract dedicated to performing a incrementation
- we create a seperate file called sum.cairo dedicated for performing incrementation. it's still in our /src directory
- In the SimpleStorage we'll make use of the dispatchers automatically generated by the interface from our Sum contract
- Our sum contract is fairly simple. We expose 2 funtions, 1 get and 1 set, and we create a storage variable and stores the incremented value
- The main function of Sum.cairo is increment. This function reads storage, registers as n, adds to n, writes to storage
- The interface is automatically generates for our Sum.cairo external functions, Now we can call the increment and get_sum functions from SimpleStorage
- Jumping back into our simple storage, we add ```use storage4::sum::{ISumDispatcherTrait, ISumDispatcher}```
- We add ``` sum_contract: ISumDispatcher``` within the Storage struct defined a storage slot, it holds a reference to an interface that allows the Simple Storage contract to interact our Sum.cairo
- Next we update our external function store_number
- We read the sum from the sum_contract storage variable
- Next we call the increment method on the sum_contract
- the Simple Storage contract sends a request to the Sum contract to increment its stored sum by the number specified in the store_number call.
- The increment method of the Sum contract adds the passed number to its internal sum state and returns the new sum.
- Finally, the function calls our internal private method (aka, generate_trait) _store_number within the Simple Storage contract. We pass the caller's address and the sum returned from the Sum contract.
- We also update our constructor. We first add ‘sum_contract_address: ContractAddress’ as the input of the constructor
- Then we initialize the dispatcher ```let sum = sum_contract.increment(number);```



Our SimpleStorage:
```rust
use starknet::ContractAddress;

#[starknet::interface]
trait ISimpleStorage<TContractState> {
    fn get_number(self: @TContractState,address: ContractAddress) -> u64;
    fn store_number(ref self: TContractState, number: u64);
}

#[starknet::contract] // we add an attribure to define a module as a Starknet contract, this module tells the compiler this code is meant to run on Starknet. We also use modules to make a clear distinction between different components of the contract, such as its storage variables, the constructor, external functions and events.
mod SimpleStorage {
    use starknet::get_caller_address; // 
    use starknet::ContractAddress;
    use storage4::sum::{ISumDispatcherTrait, ISumDispatcher};


    #[storage]
    struct Storage {
        number: LegacyMap::<ContractAddress, u64>,
        owner: person,
        operations_counter: u128,
        sum_contract: ISumDispatcher,

    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredNumber: StoredNumber,
    }

    #[derive(Drop, starknet::Event)]
    struct StoredNumber {
        #[key]
        user: ContractAddress,
        number: u64,
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct person {
        name: felt252,
        address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: person, sum_contract_address: ContractAddress) {
        self.owner.write(owner); // Person object and written into the contract's storage
        self.number.write(owner.address, 0);
        self.operations_counter.write(1);
         self.sum_contract.write(ISumDispatcher { contract_address: sum_contract_address }) // initialize dispatcher
    }


    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractState> {
        fn get_number(self: @ContractState, address: ContractAddress) -> u64 {
            let number = self.number.read(address);
            number
        }

       fn store_number(ref self: ContractState, number: u64) {
            let caller = get_caller_address();
            let sum_contract = self.sum_contract.read();
            let sum = sum_contract.increment(number); //dispatcher call
            self._store_number(caller, sum);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _store_number(ref self: ContractState, user: ContractAddress, number: u64) {
            let operation_counter = self.operation_counter.read();
            self.number.write(user, number);
            self.operation_counter.write(operation_counter + 1);
            self.emit(StoredNumber { user: user, number: number });
        }
    }
}
```

Our Sum:
```rust
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
```
