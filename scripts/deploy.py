# %% Imports
import logging
from asyncio import run

from starknet_py.cairo.felt import encode_shortstring
from utils.constants import COMPILED_CONTRACTS, ETH_TOKEN_ADDRESS
from utils.starknet import (
    deploy_v2,
    declare_v2,
    dump_declarations,
    get_starknet_account,
    dump_deployments,
)

logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


# %% Main
async def main():
    # %% Declarations
    account = await get_starknet_account()
    logger.info("ℹ️  Using account %s as deployer", hex(account.address))

    class_hash = {
        contract["contract_name"]: await declare_v2(contract["contract_name"])
        for contract in COMPILED_CONTRACTS
    }
    dump_declarations(class_hash)

    print("class_hash: ", class_hash)

    deployments = {}
    deployments["resolver_Resolver"] = await deploy_v2(
        "resolver_Resolver",
        # public key,
        [184555836509371486644303486690696490826338471053535799928930015955655750516, 1797578980074678282596] # external uri
    )
    # https://goerli.api.ccip-demo.st
    # arknet.id
    dump_deployments(deployments)


# %% Run
if __name__ == "__main__":
    run(main())
