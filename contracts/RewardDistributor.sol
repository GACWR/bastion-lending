// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./Comptroller.sol";
import "./CToken.sol";

contract RewardDistributorStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Active brains of Unitroller
     */
    Comptroller public comptroller;

    struct RewardMarketState {
        /// @notice The market's last updated joeBorrowIndex or joeSupplyIndex
        uint224 index;
        /// @notice The timestamp number the index was last updated at
        uint32 timestamp;
    }

    /// @notice The portion of supply reward rate that each market currently receives
    mapping(uint8 => mapping(address => uint256)) public rewardSupplySpeeds;

    /// @notice The portion of borrow reward rate that each market currently receives
    mapping(uint8 => mapping(address => uint256)) public rewardBorrowSpeeds;

    /// @notice The JOE/AVAX market supply state for each market
    mapping(uint8 => mapping(address => RewardMarketState))
        public rewardSupplyState;

    /// @notice The JOE/AVAX market borrow state for each market
    mapping(uint8 => mapping(address => RewardMarketState))
        public rewardBorrowState;

    /// @notice The JOE/AVAX borrow index for each market for each supplier as of the last time they accrued reward
    mapping(uint8 => mapping(address => mapping(address => uint256)))
        public rewardSupplierIndex;

    /// @notice The JOE/AVAX borrow index for each market for each borrower as of the last time they accrued reward
    mapping(uint8 => mapping(address => mapping(address => uint256)))
        public rewardBorrowerIndex;

    /// @notice The JOE/AVAX accrued but not yet transferred to each user
    mapping(uint8 => mapping(address => uint256)) public rewardAccrued;

    /// @notice The initial reward index for a market
    uint224 public constant rewardInitialIndex = 1e36;

    /// @notice JOE token contract address
    address[] public rewardAddresses;
}

contract RewardDistributor is RewardDistributorStorage, Exponential {
    /// @notice Emitted when a new reward supply speed is calculated for a market
    event RewardSupplySpeedUpdated(
        uint8 rewardType,
        CToken indexed cToken,
        uint256 newSpeed
    );

    /// @notice Emitted when a new reward borrow speed is calculated for a market
    event RewardBorrowSpeedUpdated(
        uint8 rewardType,
        CToken indexed cToken,
        uint256 newSpeed
    );

    event RewardAdded(uint8 rewardType, address newRewardAddress);

    event RewardAddressChanged(
        uint8 rewardType,
        address oldRewardAddress,
        address newRewardAddress
    );

    /// @notice Emitted when JOE/AVAX is distributed to a supplier
    event DistributedSupplierReward(
        uint8 rewardType,
        CToken indexed cToken,
        address indexed supplier,
        uint256 rewardDelta,
        uint256 rewardSupplyIndex
    );

    /// @notice Emitted when JOE/AVAX is distributed to a borrower
    event DistributedBorrowerReward(
        uint8 rewardType,
        CToken indexed cToken,
        address indexed borrower,
        uint256 rewardDelta,
        uint256 rewardBorrowIndex
    );

    /// @notice Emitted when JOE is granted by admin
    event RewardGranted(uint8 rewardType, address recipient, uint256 amount);

    bool private initialized;

    constructor() public {
        admin = msg.sender;
    }

    function initialize() public {
        require(!initialized, "RewardDistributor already initialized");
        comptroller = Comptroller(msg.sender);
        initialized = true;
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == address(comptroller);
    }

    /**
     * @notice Set JOE/AVAX speed for a single market
     * @param rewardType 0 = QI, 1 = AVAX
     * @param cToken The market whose reward speed to update
     * @param rewardSupplySpeed New reward supply speed for market
     * @param rewardBorrowSpeed New reward borrow speed for market
     */
    function _setRewardSpeed(
        uint8 rewardType,
        CToken cToken,
        uint256 rewardSupplySpeed,
        uint256 rewardBorrowSpeed
    ) public {
        require(rewardType < rewardAddresses.length, "rewardType is invalid");
        require(adminOrInitializing(), "only admin can set reward speed");
        setRewardSpeedInternal(
            rewardType,
            cToken,
            rewardSupplySpeed,
            rewardBorrowSpeed
        );
    }

    /**
     * @notice Set JOE/AVAX speed for a single market
     * @param rewardType  0: JOE, 1: AVAX
     * @param cToken The market whose speed to update
     * @param newSupplySpeed New JOE or AVAX supply speed for market
     * @param newBorrowSpeed New JOE or AVAX borrow speed for market
     */
    function setRewardSpeedInternal(
        uint8 rewardType,
        CToken cToken,
        uint256 newSupplySpeed,
        uint256 newBorrowSpeed
    ) internal {
        // Handle new supply speeed
        uint256 currentRewardSupplySpeed = rewardSupplySpeeds[rewardType][
            address(cToken)
        ];
        if (currentRewardSupplySpeed != 0) {
            // note that JOE speed could be set to 0 to halt liquidity rewards for a market
            updateRewardSupplyIndex(rewardType, address(cToken));
        } else if (newSupplySpeed != 0) {
            // Add the JOE market
            require(
                comptroller.isMarketListed(address(cToken)),
                "reward market is not listed"
            );

            if (
                rewardSupplyState[rewardType][address(cToken)].index == 0 &&
                rewardSupplyState[rewardType][address(cToken)].timestamp == 0
            ) {
                rewardSupplyState[rewardType][
                    address(cToken)
                ] = RewardMarketState({
                    index: rewardInitialIndex,
                    timestamp: safe32(
                        getBlockTimestamp(),
                        "block timestamp exceeds 32 bits"
                    )
                });
            }
        }

        if (currentRewardSupplySpeed != newSupplySpeed) {
            rewardSupplySpeeds[rewardType][address(cToken)] = newSupplySpeed;
            emit RewardSupplySpeedUpdated(rewardType, cToken, newSupplySpeed);
        }

        // Handle new borrow speed
        uint256 currentRewardBorrowSpeed = rewardBorrowSpeeds[rewardType][
            address(cToken)
        ];
        if (currentRewardBorrowSpeed != 0) {
            // note that JOE speed could be set to 0 to halt liquidity rewards for a market
            Exp memory borrowIndex = Exp({mantissa: cToken.borrowIndex()});
            updateRewardBorrowIndex(rewardType, address(cToken), borrowIndex);
        } else if (newBorrowSpeed != 0) {
            // Add the JOE market
            require(
                comptroller.isMarketListed(address(cToken)),
                "reward market is not listed"
            );

            if (
                rewardBorrowState[rewardType][address(cToken)].index == 0 &&
                rewardBorrowState[rewardType][address(cToken)].timestamp == 0
            ) {
                rewardBorrowState[rewardType][
                    address(cToken)
                ] = RewardMarketState({
                    index: rewardInitialIndex,
                    timestamp: safe32(
                        getBlockTimestamp(),
                        "block timestamp exceeds 32 bits"
                    )
                });
            }
        }

        if (currentRewardBorrowSpeed != newBorrowSpeed) {
            rewardBorrowSpeeds[rewardType][address(cToken)] = newBorrowSpeed;
            emit RewardBorrowSpeedUpdated(rewardType, cToken, newBorrowSpeed);
        }
    }

    /**
     * @notice Accrue JOE/AVAX to the market by updating the supply index
     * @param rewardType  0: JOE, 1: AVAX
     * @param cToken The market whose supply index to update
     */
    function updateRewardSupplyIndex(uint8 rewardType, address cToken)
        internal
    {
        require(rewardType < rewardAddresses.length, "rewardType is invalid");
        RewardMarketState storage supplyState = rewardSupplyState[rewardType][
            cToken
        ];
        uint256 supplySpeed = rewardSupplySpeeds[rewardType][cToken];
        uint256 blockTimestamp = getBlockTimestamp();
        uint256 deltaTimestamps = sub_(
            blockTimestamp,
            uint256(supplyState.timestamp)
        );
        if (deltaTimestamps > 0 && supplySpeed > 0) {
            uint256 supplyTokens = CToken(cToken).totalSupply();
            uint256 rewardAccrued = mul_(deltaTimestamps, supplySpeed);
            Double memory ratio = supplyTokens > 0
                ? fraction(rewardAccrued, supplyTokens)
                : Double({mantissa: 0});
            Double memory index = add_(
                Double({mantissa: supplyState.index}),
                ratio
            );
            rewardSupplyState[rewardType][cToken] = RewardMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                timestamp: safe32(
                    blockTimestamp,
                    "block timestamp exceeds 32 bits"
                )
            });
        } else if (deltaTimestamps > 0) {
            supplyState.timestamp = safe32(
                blockTimestamp,
                "block timestamp exceeds 32 bits"
            );
        }
    }

    /**
     * @notice Accrue JOE/AVAX to the market by updating the borrow index
     * @param rewardType  0: JOE, 1: AVAX
     * @param cToken The market whose borrow index to update
     * @param marketBorrowIndex Current index of the borrow market
     */
    function updateRewardBorrowIndex(
        uint8 rewardType,
        address cToken,
        Exp memory marketBorrowIndex
    ) internal {
        require(rewardType < rewardAddresses.length, "rewardType is invalid");
        RewardMarketState storage borrowState = rewardBorrowState[rewardType][
            cToken
        ];
        uint256 borrowSpeed = rewardBorrowSpeeds[rewardType][cToken];
        uint256 blockTimestamp = getBlockTimestamp();
        uint256 deltaTimestamps = sub_(
            blockTimestamp,
            uint256(borrowState.timestamp)
        );
        if (deltaTimestamps > 0 && borrowSpeed > 0) {
            uint256 borrowAmount = div_(
                CToken(cToken).totalBorrows(),
                marketBorrowIndex
            );
            uint256 rewardAccrued = mul_(deltaTimestamps, borrowSpeed);
            Double memory ratio = borrowAmount > 0
                ? fraction(rewardAccrued, borrowAmount)
                : Double({mantissa: 0});
            Double memory index = add_(
                Double({mantissa: borrowState.index}),
                ratio
            );
            rewardBorrowState[rewardType][cToken] = RewardMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                timestamp: safe32(
                    blockTimestamp,
                    "block timestamp exceeds 32 bits"
                )
            });
        } else if (deltaTimestamps > 0) {
            borrowState.timestamp = safe32(
                blockTimestamp,
                "block timestamp exceeds 32 bits"
            );
        }
    }

    /**
     * @notice Calculate JOE/AVAX accrued by a supplier and possibly transfer it to them
     * @param rewardType  0: JOE, 1: AVAX
     * @param cToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute JOE/AVAX to
     */
    function distributeSupplierReward(
        uint8 rewardType,
        address cToken,
        address supplier
    ) internal {
        require(rewardType < rewardAddresses.length, "rewardType is invalid");
        RewardMarketState storage supplyState = rewardSupplyState[rewardType][
            cToken
        ];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({
            mantissa: rewardSupplierIndex[rewardType][cToken][supplier]
        });


        // TODO: dialution
        rewardSupplierIndex[rewardType][cToken][supplier] = supplyIndex
            .mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = rewardInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint256 supplierTokens = CToken(cToken).balanceOf(supplier);
        uint256 supplierDelta = mul_(supplierTokens, deltaIndex);
        uint256 supplierAccrued = add_(
            rewardAccrued[rewardType][supplier],
            supplierDelta
        );
        rewardAccrued[rewardType][supplier] = supplierAccrued;
        emit DistributedSupplierReward(
            rewardType,
            CToken(cToken),
            supplier,
            supplierDelta,
            supplyIndex.mantissa
        );
    }

    /**
     * @notice Calculate JOE/AVAX accrued by a borrower and possibly transfer it to them
     * @param rewardType  0: JOE, 1: AVAX
     * @param cToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute JOE/AVAX to
     * @param marketBorrowIndex Current index of the borrow market
     */
    function distributeBorrowerReward(
        uint8 rewardType,
        address cToken,
        address borrower,
        Exp memory marketBorrowIndex
    ) internal {
        require(rewardType < rewardAddresses.length, "rewardType is invalid");
        RewardMarketState storage borrowState = rewardBorrowState[rewardType][
            cToken
        ];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({
            mantissa: rewardBorrowerIndex[rewardType][cToken][borrower]
        });
        rewardBorrowerIndex[rewardType][cToken][borrower] = borrowIndex
            .mantissa;

        if (borrowerIndex.mantissa == 0 && borrowIndex.mantissa >= rewardInitialIndex) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with COMP accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex.mantissa = rewardInitialIndex;
        }

        Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
        uint256 borrowerAmount = div_(
            CToken(cToken).borrowBalanceStored(borrower),
            marketBorrowIndex
        );
        uint256 borrowerDelta = mul_(borrowerAmount, deltaIndex);
        uint256 borrowerAccrued = add_(
            rewardAccrued[rewardType][borrower],
            borrowerDelta
        );
        rewardAccrued[rewardType][borrower] = borrowerAccrued;
        emit DistributedBorrowerReward(
            rewardType,
            CToken(cToken),
            borrower,
            borrowerDelta,
            borrowIndex.mantissa
        );
    }

    /**
     * @notice Refactored function to calc and rewards accounts supplier rewards
     * @param cToken The market to verify the mint against
     * @param supplier The supplier to be rewarded
     */
    function updateAndDistributeSupplierRewardsForToken(
        address cToken,
        address supplier
    ) external {
        require(
            adminOrInitializing(),
            "only admin can update and distribute supplier rewards"
        );
        for (
            uint8 rewardType = 0;
            rewardType < rewardAddresses.length;
            rewardType++
        ) {
            updateRewardSupplyIndex(rewardType, cToken);
            distributeSupplierReward(rewardType, cToken, supplier);
        }
    }

    /**
     * @notice Refactored function to calc and rewards accounts supplier rewards
     * @param cToken The market to verify the mint against
     * @param borrower Borrower to be rewarded
     * @param marketBorrowIndex Current index of the borrow market
     */
    function updateAndDistributeBorrowerRewardsForToken(
        address cToken,
        address borrower,
        Exp calldata marketBorrowIndex
    ) external {
        require(
            adminOrInitializing(),
            "only admin can update and distribute borrower rewards"
        );
        for (
            uint8 rewardType = 0;
            rewardType < rewardAddresses.length;
            rewardType++
        ) {
            updateRewardBorrowIndex(rewardType, cToken, marketBorrowIndex);
            distributeBorrowerReward(
                rewardType,
                cToken,
                borrower,
                marketBorrowIndex
            );
        }
    }

    /*** User functions ***/

    /**
     * @notice Claim all the JOE/AVAX accrued by holder in all markets
     * @param holder The address to claim JOE/AVAX for
     */
    function claimReward(uint8 rewardType, address payable holder) public {
        return claimReward(rewardType, holder, comptroller.getAllMarkets());
    }

    /**
     * @notice Claim all the JOE/AVAX accrued by holder in the specified markets
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to claim JOE/AVAX for
     * @param cTokens The list of markets to claim JOE/AVAX in
     */
    function claimReward(
        uint8 rewardType,
        address payable holder,
        CToken[] memory cTokens
    ) public {
        address payable[] memory holders = new address payable[](1);
        holders[0] = holder;
        claimReward(rewardType, holders, cTokens, true, true);
    }

    /**
     * @notice Claim all JOE/AVAX  accrued by the holders
     * @param rewardType  0 = JOE, 1 = AVAX
     * @param holders The addresses to claim JOE/AVAX for
     * @param cTokens The list of markets to claim JOE/AVAX in
     * @param borrowers Whether or not to claim JOE/AVAX earned by borrowing
     * @param suppliers Whether or not to claim JOE/AVAX earned by supplying
     */
    function claimReward(
        uint8 rewardType,
        address payable[] memory holders,
        CToken[] memory cTokens,
        bool borrowers,
        bool suppliers
    ) public payable {
        require(rewardType < rewardAddresses.length, "rewardType is invalid");
        for (uint256 i = 0; i < cTokens.length; i++) {
            CToken cToken = cTokens[i];
            require(
                comptroller.isMarketListed(address(cToken)),
                "market must be listed"
            );
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa: cToken.borrowIndex()});
                updateRewardBorrowIndex(
                    rewardType,
                    address(cToken),
                    borrowIndex
                );
                for (uint256 j = 0; j < holders.length; j++) {
                    distributeBorrowerReward(
                        rewardType,
                        address(cToken),
                        holders[j],
                        borrowIndex
                    );
                    rewardAccrued[rewardType][holders[j]] = grantRewardInternal(
                        rewardType,
                        holders[j],
                        rewardAccrued[rewardType][holders[j]]
                    );
                }
            }
            if (suppliers == true) {
                updateRewardSupplyIndex(rewardType, address(cToken));
                for (uint256 j = 0; j < holders.length; j++) {
                    distributeSupplierReward(
                        rewardType,
                        address(cToken),
                        holders[j]
                    );
                    rewardAccrued[rewardType][holders[j]] = grantRewardInternal(
                        rewardType,
                        holders[j],
                        rewardAccrued[rewardType][holders[j]]
                    );
                }
            }
        }
    }

    /**
     * @notice Transfer JOE/AVAX to the user
     * @dev Note: If there is not enough JOE/AVAX, we do not perform the transfer all.
     * @param rewardType 0 = JOE, 1 = AVAX.
     * @param user The address of the user to transfer JOE/AVAX to
     * @param amount The amount of JOE/AVAX to (possibly) transfer
     * @return The amount of JOE/AVAX which was NOT transferred to the user
     */
    function grantRewardInternal(
        uint8 rewardType,
        address payable user,
        uint256 amount
    ) internal returns (uint256) {
        address rewardAddress = rewardAddresses[rewardType];
        EIP20Interface reward = EIP20Interface(rewardAddress);
        uint256 rewardRemaining = reward.balanceOf(address(this));
        if (amount > 0 && amount <= rewardRemaining) {
            reward.transfer(user, amount);
            return 0;
        }

        return amount;
    }

    /*** Joe Distribution Admin ***/

    /**
     * @notice Transfer JOE to the recipient
     * @dev Note: If there is not enough JOE, we do not perform the transfer all.
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param recipient The address of the recipient to transfer JOE to
     * @param amount The amount of JOE to (possibly) transfer
     */
    function _grantReward(
        uint8 rewardType,
        address payable recipient,
        uint256 amount
    ) public {
        require(adminOrInitializing(), "only admin can grant reward");
        uint256 amountLeft = grantRewardInternal(rewardType, recipient, amount);
        require(amountLeft == 0, "insufficient reward for grant");
        emit RewardGranted(rewardType, recipient, amount);
    }

    /**
     * @notice Set the Reward token address
     */
    function addRewardAddress(address newRewardAddress) public {
        require(msg.sender == admin, "only admin can add new reward address");
        rewardAddresses.push(newRewardAddress);
        uint8 rewardType = uint8(rewardAddresses.length - 1);
        emit RewardAdded(rewardType, newRewardAddress);
    }

    /**
     * @notice Set the Reward token address
     */
    function getRewardAddress(uint256 rewardType)
        public
        view
        returns (address)
    {
        return rewardAddresses[rewardType];
    }

    /**
     * @notice Set the Reward token address
     */
    function setRewardAddress(uint8 rewardType, address newRewardAddress)
        public
    {
        require(msg.sender == admin, "only admin can set reward address");
        address oldRewardAddress = rewardAddresses[rewardType];
        rewardAddresses[rewardType] = newRewardAddress;
        emit RewardAddressChanged(
            rewardType,
            oldRewardAddress,
            newRewardAddress
        );
    }

    /**
     * @notice Set the Comptroller address
     */
    function setComptroller(address _comptroller) public {
        require(msg.sender == admin, "only admin can set Comptroller");
        comptroller = Comptroller(_comptroller);
    }

    /**
     * @notice Set the admin
     */
    function setAdmin(address _newAdmin) public {
        require(msg.sender == admin, "only admin can set admin");
        admin = _newAdmin;
    }

    /**
     * @notice payable function needed to receive AVAX
     */
    function() external payable {}

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}
