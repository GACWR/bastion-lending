pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../CErc20.sol";
import "../CToken.sol";
import "../PriceOracle.sol";
import "../EIP20Interface.sol";
import "../LockdropVaultV2.sol";

interface RewardDistributorInterface {
    struct RewardMarketState {
        /// @notice The market's last updated joeBorrowIndex or joeSupplyIndex
        uint224 index;
        /// @notice The timestamp number the index was last updated at
        uint32 timestamp;
    }

    function rewardAddresses(uint256) external view returns (address);

    /// @notice The portion of supply reward rate that each market currently receives
    function rewardSupplySpeeds(uint8, address) external view returns (uint256);

    /// @notice The portion of borrow reward rate that each market currently receives
    function rewardBorrowSpeeds(uint8, address) external view returns (uint256);

    /// @notice The JOE/AVAX market supply state for each market
    function rewardSupplyState(uint8, address)
        external
        view
        returns (RewardMarketState memory);

    /// @notice The JOE/AVAX market borrow state for each market
    function rewardBorrowState(uint8, address)
        external
        view
        returns (RewardMarketState memory);

    /// @notice The JOE/AVAX borrow index for each market for each supplier as of the last time they accrued reward
    function rewardSupplierIndex(
        uint8,
        address,
        address
    ) external view returns (uint256);

    /// @notice The JOE/AVAX borrow index for each market for each borrower as of the last time they accrued reward
    function rewardBorrowerIndex(
        uint8,
        address,
        address
    ) external view returns (uint256);

    /// @notice The JOE/AVAX accrued but not yet transferred to each user
    function rewardAccrued(uint8, address) external view returns (uint256);
}

interface ComptrollerLensInterface {
    function rewardDistributor() external view returns (address payable);

    function markets(address) external view returns (bool, uint256);

    function oracle() external view returns (PriceOracle);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAssetsIn(address) external view returns (CToken[] memory);

    function claimComp(address) external;

    function compAccrued(address) external view returns (uint256);

    function compSpeeds(address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);
}

contract LockdropLens {
    struct LockdropAssets {
        CToken cToken;
        LockdropVaultV2[] lockdropVaults;
    }
    struct LockdropAssetsMetadata {
        CToken cToken;
        VaultMetadata[] vaultMetadata;
    }
    struct VaultMetadata {
        LockdropVaultV2 lockdropVault;
        uint256 allowance;
        uint256 cTokenBalance;
        uint256 claimUnlockTime;
        uint256 deposit;
        uint256 totalDeposit;
    }

    function vaultMetadata(
        CToken cToken,
        LockdropVaultV2 lockdropVault,
        address account
    ) public view returns (VaultMetadata memory vault) {
        vault.lockdropVault = lockdropVault;
        vault.allowance = cToken.allowance(account, address(lockdropVault));
        vault.cTokenBalance = cToken.balanceOf(account);
        vault.claimUnlockTime = lockdropVault.claimUnlockTime();
        vault.deposit = lockdropVault.balanceOf(account);
        vault.totalDeposit = cToken.balanceOf(address(lockdropVault));
    }

    function lockdropMetadata(
        CToken cToken,
        LockdropAssets memory lockdropAsset,
        address account
    ) public view returns (VaultMetadata[] memory) {
        uint256 vaultsCount = lockdropAsset.lockdropVaults.length;
        VaultMetadata[] memory vaultsMetadata = new VaultMetadata[](
            vaultsCount
        );
        for (uint256 i = 0; i < vaultsCount; i++) {
            vaultsMetadata[i] = vaultMetadata(
                cToken,
                lockdropAsset.lockdropVaults[i],
                account
            );
        }
        return vaultsMetadata;
    }

    function lockDropMetadataAll(
        LockdropAssets[] memory lockdropAssets,
        address account
    ) public view returns (LockdropAssetsMetadata[] memory) {
        uint256 lockdropAssetsCount = lockdropAssets.length;
        LockdropAssetsMetadata[]
            memory lockDropAssetsMetadata = new LockdropAssetsMetadata[](
                lockdropAssetsCount
            );
        for (uint256 i = 0; i < lockdropAssetsCount; i++) {
            LockdropAssets memory lockdropAsset = lockdropAssets[i];
            lockDropAssetsMetadata[i].cToken = lockdropAsset.cToken;
            lockDropAssetsMetadata[i].vaultMetadata = lockdropMetadata(
                lockdropAsset.cToken,
                lockdropAsset,
                account
            );
        }
        return lockDropAssetsMetadata;
    }
}
