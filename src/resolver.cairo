#[starknet::contract]
mod Resolver {
    use core::array::SpanTrait;
    use starknet::ContractAddress;
    use ecdsa::check_ecdsa_signature;
    use resolver::interface::resolver::{IResolver, IResolverDispatcher, IResolverDispatcherTrait};

    #[storage]
    struct Storage {
        public_key: felt252,
        uri: LegacyMap<felt252, felt252>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _public_key: felt252, uri: Span<felt252>) {
        self.public_key.write(_public_key);
        self.store_uri(uri);
    }

    #[external(v0)]
    impl ResolverImpl of IResolver<ContractState> {
        fn resolve(
            self: @ContractState, domain: Span<felt252>, field: felt252, hint: Span<felt252>
        ) -> felt252 {
            if hint.len() < 3 {
                panic(self.get_uri(array!['offchain_resolving']));
            }

            let hashed_domain = self.hash_domain(domain);
            let message_hash: felt252 = hash::LegacyHash::hash(
                hash::LegacyHash::hash(hashed_domain, field), *hint.at(0)
            );
            let public_key = self.public_key.read();
            let is_valid = check_ecdsa_signature(
                message_hash, public_key, *hint.at(1), *hint.at(2)
            );
            assert(is_valid, 'Invalid signature');

            return *hint.at(0);
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
