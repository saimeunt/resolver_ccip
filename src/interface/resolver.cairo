use starknet::ContractAddress;

#[starknet::interface]
trait IResolver<TContractState> {
    fn resolve(
        self: @TContractState, domain: Span<felt252>, field: felt252, hint: Span<felt252>
    ) -> felt252;
    fn update_uri(ref self: TContractState, new_uri: Span<felt252>);
}
