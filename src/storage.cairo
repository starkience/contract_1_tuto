use starknet::ContractAddress;

#[starknet::interface]
trait ISimpleStorage<TContractState> {
    fn get_number(self: @TContractState, address: ContractAddress) -> u64;
    fn store_magic(ref self: TContractState, number: u64);
}

#[starknet::contract] // we add an attribure to define a module as a Starknet contract, this module tells the compiler this code is meant to run on Starknet. We also use modules to make a clear distinction between different components of the contract, such as its storage variables, the constructor, external functions and events.
mod SimpleStorage {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use contract_1::magic_value::{IMagicDispatcherTrait, IMagicDispatcher};

    #[storage]
    struct Storage {
        numbers: LegacyMap::<ContractAddress, u64>,
        owner: person,
        operations_counter: u128,
        magic_contract: IMagicDispatcher,
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
    fn constructor(
        ref self: ContractState, owner: person, magic_contract_address: ContractAddress) {
        self.owner.write(owner); // Person object and written into the contract's storage
        self.numbers.write(owner.address, 0);
        self.operations_counter.write(1);
        self
            .magic_contract
            .write(
                IMagicDispatcher { contract_address: magic_contract_address }
            ) // initialize dispatcher
    }


    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractState> {
        fn get_number(self: @ContractState, address: ContractAddress) -> u64 {
            let number = self.numbers.read(address);
            number
        }

        fn store_magic(ref self: ContractState, number: u64) {
            let caller = get_caller_address();
            let magic_contract = self.magic_contract.read();
            magic_contract.increment_magic(number); //dispatcher call
            self._store_magic_value(caller, magic_contract.get_magic());
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _store_magic_value(ref self: ContractState, user: ContractAddress, number: u64) {
            self.operations_counter.write(self.operations_counter.read() + 1);
            self.numbers.write(user, number);
            self.emit(StoredNumber { user: user, number: number });
        }
    }
}
