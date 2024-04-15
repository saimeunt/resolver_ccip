#[starknet::contract]
mod Resolver {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use core::array::SpanTrait;
    use starknet::{ContractAddress, get_block_timestamp};
    use ecdsa::check_ecdsa_signature;
    use resolver::interface::resolver::{IResolver, IResolverDispatcher, IResolverDispatcherTrait};
    use storage_read::{main::storage_read_component, interface::IStorageRead};
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: storage_read_component, storage: storage_read, event: StorageReadEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl StorageReadImpl = storage_read_component::StorageRead<ContractState>;
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        public_key: felt252,
        uri: LegacyMap<felt252, felt252>,
        #[substorage(v0)]
        storage_read: storage_read_component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StarknetIDOffChainResolverUpdate: StarknetIDOffChainResolverUpdate,
        #[flat]
        StorageReadEvent: storage_read_component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct StarknetIDOffChainResolverUpdate {
        uri: Span<felt252>,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, _public_key: felt252, uri: Span<felt252>
    ) {
        self.ownable.initializer(owner);
        self.public_key.write(_public_key);
        self.store_uri(uri);
        self.emit(StarknetIDOffChainResolverUpdate { uri });
    }

    #[external(v0)]
    impl ResolverImpl of IResolver<ContractState> {
        fn resolve(
            self: @ContractState, domain: Span<felt252>, field: felt252, hint: Span<felt252>
        ) -> felt252 {
            if hint.len() != 4 {
                panic(self.get_uri(array!['offchain_resolving']));
            }

            let max_validity = *hint.at(3);
            assert(get_block_timestamp() < max_validity.try_into().unwrap(), 'Signature expired');

            let hashed_domain = self.hash_domain(domain);
            let message_hash: felt252 = hash::LegacyHash::hash(
                hash::LegacyHash::hash(
                    hash::LegacyHash::hash(
                        hash::LegacyHash::hash('ccip_demo resolving', max_validity), hashed_domain
                    ),
                    field
                ),
                *hint.at(0)
            );

            let public_key = self.public_key.read();
            let is_valid = check_ecdsa_signature(
                message_hash, public_key, *hint.at(1), *hint.at(2)
            );
            assert(is_valid, 'Invalid signature');

            return *hint.at(0);
        }

        fn update_uri(ref self: ContractState, new_uri: Span<felt252>) {
            self.ownable.assert_only_owner();
            self.store_uri(new_uri);
            self.emit(StarknetIDOffChainResolverUpdate { uri: new_uri, });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn store_uri(ref self: ContractState, mut uri: Span<felt252>) {
            let mut index = 0;
            loop {
                match uri.pop_front() {
                    Option::Some(value) => {
                        self.uri.write(index, *value);
                        index += 1;
                    },
                    Option::None => { break; }
                }
            };
        }

        fn get_uri(self: @ContractState, mut res: Array<felt252>) -> Array<felt252> {
            let mut index = 0;
            loop {
                let value = self.uri.read(index);
                if value == 0 {
                    break;
                }
                res.append(value);
                index += 1;
            };
            res
        }

        fn hash_domain(self: @ContractState, domain: Span<felt252>) -> felt252 {
            if domain.len() == 0 {
                return 0;
            };
            let new_len = domain.len() - 1;
            let x = *domain[new_len];
            let y = self.hash_domain(domain.slice(0, new_len));
            let hashed_domain = pedersen::pedersen(x, y);
            return hashed_domain;
        }
    }
}
