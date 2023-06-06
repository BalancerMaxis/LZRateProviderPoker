// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// See: https://github.com/witherblock/gyarados/blob/main/contracts/CrossChainRateProvider.sol
interface CrossChainRateProvider {
    function updateRate() external payable;
}

/**
 * @title The LZRateProviderPoker Contract
 * @author tritium.eth
 * @notice This is a simple contract to hold some eth and a list of LayerZeroRateProviders that need to be poked on mainnet
 * @notice When called by a set keeper, it uses it's internal eth balance to call updateRate() on all the listed providers.
 * @notice The contract includes the ability to withdraw eth and sweep all ERC20 to the owner address (owner only)
 * see https://github.com/witherblock/gyarados/blob/main/contracts/CrossChainRateProvider.sol
 */
contract LZRateProviderPoker is ConfirmedOwner, Pausable {
    event poked(address[] gaugelist, uint256 cost);


    // events below here are debugging and should be removed
    event wrongCaller(address sender, address registry);
    event rateProviderListSet(address[] oldList, address[] newList);
    event minWaitPeriodUpdated(uint256 minWaitSeconds);
    event gasTokenWithdrawn(uint256 amount, address recipient);
    event ERC20Swept(address token, address recipient, uint256 amount);
    event KeeperAddressUpdated(address oldAddress, address newAddress);
    error OnlyKeeperRegistry(address sender);


    address public KeeperAddress;
    address[] public LZRateProviders;
    uint256 MinWaitPeriodSeconds;
    uint256 LastRun;

     /**
   * @param keeperAddress The address of the keeper that will call the poke
   * @param minWaitPeriodSeconds The minimum wait period for address between funding (for security)
   * @param lzRateProviders A list of cross chain rate providers to poke (https://github.com/witherblock/gyarados/blob/main/contracts/CrossChainRateProvider.sol)
   */
    constructor(address keeperAddress, address[] memory lzRateProviders, uint256 minWaitPeriodSeconds)
    ConfirmedOwner(msg.sender) {
        setKeeperAddress(keeperAddress);
        setRateProviderList(lzRateProviders);
        setMinWaitPeriodSeconds(minWaitPeriodSeconds);
    }

    function pokeAll() public onlyKeeper whenNotPaused {
        address[] memory rateProviders = LZRateProviders;
        for (uint i=0; i<rateProviders.length; i++){
            CrossChainRateProvider(rateProviders[i]).updateRate();
        }
    }
    /**
     * @notice Sets the list of addresses to watch
   * @param lzRateProviders the list of addresses to watch
   */
    function setRateProviderList(
        address[] memory lzRateProviders
    ) public onlyOwner {
        emit rateProviderListSet(LZRateProviders, lzRateProviders);
        LZRateProviders = lzRateProviders;
    }

    /**
     * @notice Withdraws the contract balance back to the owner
   * @param amount The amount of eth (in wei) to withdraw
   */
    function withdrawGasToken(uint256 amount) external onlyOwner {
        emit gasTokenWithdrawn(amount, owner());
        payable(owner()).transfer(amount);
    }

    /**
     * @notice Sweep the full contract's balance for a given ERC-20 token back to the owner
   * @param token The ERC-20 token which needs to be swept
   */
    function sweep(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit ERC20Swept(token, owner(), balance);
        SafeERC20.safeTransfer(IERC20(token), owner(), balance);
    }

    /**
     * @notice Sets the keeper registry address
   */
    function setKeeperAddress(address keeperAddress) public onlyOwner {
        emit KeeperAddressUpdated(KeeperAddress, keeperAddress);
        KeeperAddress = keeperAddress;
    }

    /**
     * @notice Sets the minimum wait period (in seconds) for addresses between injections
   */
    function setMinWaitPeriodSeconds(uint256 minWaitSeconds) public onlyOwner {
        emit minWaitPeriodUpdated(MinWaitPeriodSeconds);
        MinWaitPeriodSeconds = minWaitSeconds;
    }

    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
   */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
   */
    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyKeeper() {
        if (msg.sender != KeeperAddress && msg.sender != owner()) {
            emit wrongCaller(msg.sender, KeeperAddress);
            revert OnlyKeeperRegistry(msg.sender);
        }
        _;
    }
}
