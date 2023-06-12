import brownie
import time
from brownie import chain
import pytest


def test_upkeepTwice(admin, poker, upkeep_caller, rate_providers):
    poker.addRateProviders(rate_providers, {"from": admin})
    admin.transfer(poker, 1 * 10 ** 18)
    (upkeepNeeded, performData) = poker.checkUpkeep(b"")
    assert upkeepNeeded, "Poker doesn't want to poke when it's got eth, never run, and has things to poke"
    tx = poker.performUpkeep(performData, {"from": upkeep_caller})
    with brownie.reverts("not ready"):
        tx2 = poker.performUpkeep(performData, {"from": upkeep_caller})

def test_pokeMany(admin, poker, upkeep_caller, rate_providers):
    poker.addRateProviders(rate_providers, {"from": admin})
    admin.transfer(poker, 1*10**18)
    (upkeepNeeded, performData) = poker.checkUpkeep(b"")
    assert upkeepNeeded, "Poker doesn't want to poke when it's got eth, never run, and has things to poke"
    tx = poker.performUpkeep(performData, {"from": upkeep_caller})
    (upkeepNeeded, performData) = poker.checkUpkeep(b"")
    assert upkeepNeeded is False, "Poker wants to poke a second time right after poking."
    poker.setMinWaitPeriodSeconds(1000, {"from": admin})
    chain.sleep(500)
    chain.mine()
    (upkeepNeeded, performData) = poker.checkUpkeep(b"")
    assert upkeepNeeded is False, "Poker wants to poke a second time after not enough time has passed."
    chain.sleep(501)
    chain.mine()
    (upkeepNeeded, performData) = poker.checkUpkeep(b"")
    assert upkeepNeeded, "Poker not ready to run again after alloted time has passed"
    tx = poker.performUpkeep(performData, {"from": upkeep_caller})

