use array::ArrayTrait;
use debug::PrintTrait;
use zeroable::Zeroable;
use traits::Into;

use starknet::ContractAddress;
use starknet::testing;
use starknet::contract_address::ContractAddressZeroable;
use starknet::contract_address_const;
use starknet::testing::set_contract_address;
use super::utils;

use openzeppelin::token::erc20::{
    erc20::ERC20, interface::{IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait}
};
use identity::{
    identity::main::Identity, interface::identity::{IIdentityDispatcher, IIdentityDispatcherTrait}
};
use naming::interface::naming::{INamingDispatcher, INamingDispatcherTrait};
use naming::interface::pricing::{IPricingDispatcher, IPricingDispatcherTrait};
use naming::naming::main::Naming;
use naming::pricing::Pricing;
use resolver::interface::resolver::{IResolver, IResolverDispatcher, IResolverDispatcherTrait};
use resolver::resolver::Resolver;

fn deploy() -> (
    IERC20CamelDispatcher,
    IPricingDispatcher,
    IIdentityDispatcher,
    INamingDispatcher,
    IResolverDispatcher
) {
    //erc20
    // 0, 1 = low and high of ETH supply
    let eth = utils::deploy(ERC20::TEST_CLASS_HASH, array!['ether', 'ETH', 0, 1, 0x123]);

    // pricing
    let pricing = utils::deploy(Pricing::TEST_CLASS_HASH, array![eth.into()]);

    // identity
    let identity = utils::deploy(Identity::TEST_CLASS_HASH, array![0]);

    // naming
    let admin = 0x123;
    let address = utils::deploy(
        Naming::TEST_CLASS_HASH, array![identity.into(), pricing.into(), 0, admin]
    );

    let resolver = utils::deploy(
        Resolver::TEST_CLASS_HASH,
        array![
            0x64018d8ea7829641419aff38ea79efd3eafedf3a5c1fe001d35339b889d48f4,
            1,
            'http://0.0.0.0:8090'
        ]
    );
    (
        IERC20CamelDispatcher { contract_address: eth },
        IPricingDispatcher { contract_address: pricing },
        IIdentityDispatcher { contract_address: identity },
        INamingDispatcher { contract_address: address },
        IResolverDispatcher { contract_address: resolver }
    )
}

#[test]
#[available_gas(20000000000)]
#[should_panic(
    expected: (
        'offchain_resolving', 'http://0.0.0.0:8090', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'
    )
)]
fn test_offchain_resolving_no_hint() {
    // setup
    let (eth, pricing, identity, naming, resolver) = deploy();
    let caller = contract_address_const::<0x123>();
    set_contract_address(caller);
    let id1: u128 = 1;
    let iris: felt252 = 999902;
    let notion: felt252 = 1059716045;

    //we mint an identity
    identity.mint(id1);

    // we check how much a domain costs
    let (_, price) = pricing.compute_buy_price(6, 365);

    // we allow the naming to take our money
    eth.approve(naming.contract_address, price);

    // we buy with a resolver, no sponsor, no discount and empty metadata
    naming.buy(id1, notion, 365, resolver.contract_address, ContractAddressZeroable::zero(), 0, 0);

    // we call resolve on the naming contract for subdomain iris.notion.stark
    // It should panic with 'offchain_resolving' and the external uri to call
    let result = naming
        .resolve(array![999902, 1059716045].span(), 121424973492078, array![].span());
}

#[test]
#[available_gas(20000000000)]
fn test_offchain_resolving_with_hint() {
    // setup
    let (eth, pricing, identity, naming, resolver) = deploy();
    let caller = contract_address_const::<0x123>();
    set_contract_address(caller);
    let id1: u128 = 1;
    let notion: felt252 = 1059716045;
    let iris: felt252 = 999902;

    //we mint an identity
    identity.mint(id1);

    // we check how much a domain costs
    let (_, price) = pricing.compute_buy_price(6, 365);

    // we allow the naming to take our money
    eth.approve(naming.contract_address, price);

    // we buy with a resolver, no sponsor, no discount and empty metadata
    naming.buy(id1, notion, 365, resolver.contract_address, ContractAddressZeroable::zero(), 0, 0);

    // we call resolve on the naming contract for subdomain iris.notion.stark
    // It should return the address of the user
    let result = naming
        .resolve(
            array![999902, 1059716045].span(),
            'starknet',
            array![
                0x04a8173e2F008282aC9793FB929974Cc7CEd6cEb76c79A0A9e0D163e60d08b6f,
                2089118561466072516921896590836512635522628730170556232409568333563898398738,
                2604946082720653006262636424654687283228219984561005042815724129995170496140
            ]
                .span()
        );
    assert(
        result == 0x04a8173e2F008282aC9793FB929974Cc7CEd6cEb76c79A0A9e0D163e60d08b6f,
        'wrong address'
    );
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('Invalid signature', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
fn test_offchain_resolving_with_hint_invalid_sig() {
    // setup
    let (eth, pricing, identity, naming, resolver) = deploy();
    let caller = contract_address_const::<0x123>();
    set_contract_address(caller);
    let id1: u128 = 1;
    let notion: felt252 = 1059716045;
    let iris: felt252 = 999902;

    //we mint an identity
    identity.mint(id1);

    // we check how much a domain costs
    let (_, price) = pricing.compute_buy_price(6, 365);

    // we allow the naming to take our money
    eth.approve(naming.contract_address, price);

    // we buy with a resolver, no sponsor, no discount and empty metadata
    naming.buy(id1, notion, 365, resolver.contract_address, ContractAddressZeroable::zero(), 0, 0);

    // we call resolve on the naming contract for subdomain iris.notion.stark
    // It should panic as signature is invalid
    let result = naming
        .resolve(
            array![999902, 1059716045].span(),
            'starknet',
            array![0x04a8173e2F008282aC9793FB929974Cc7CEd6cEb76c79A0A9e0D163e60d08b6f, 1, 2].span()
        );
}

