import pytest
import time
from brownie import (
    interface,
    accounts,
    LZRateProviderPoker,
    Contract

)
from dotmap import DotMap
import pytest
from bal_addresses import AddrBook


##  Accounts

r = AddrBook("mainnet").flatbook

LZRateProviders = [
    "0xB385BBc8Bfc80451cDbB6acfFE4D95671f4C051c", #zkEVM RETH
    "0xaD78CD17D3A4a3dc6afb203ef91C0E54433b3b9d" #zkEVM wstETH
]

@pytest.fixture(scope="module")
def rate_providers():
    return LZRateProviders
@pytest.fixture(scope="module")
def admin():
    return accounts[1]

@pytest.fixture(scope="module")
def upkeep_caller():
    return accounts[2]

@pytest.fixture(scope="module")
def deployer():
    return accounts[0]


@pytest.fixture()
def poker(deploy):
    return deploy



@pytest.fixture(scope="module")
def deploy(deployer, admin, upkeep_caller):
    """
    Deploys, vault and test strategy, mock token and wires them up.
    """
    poker = LZRateProviderPoker.deploy(60,upkeep_caller, {"from": deployer})
    poker.transferOwnership(admin, {"from": deployer})
    poker.acceptOwnership({"from": admin})
    return poker

