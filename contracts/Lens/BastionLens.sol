pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../CErc20.sol";
import "../CToken.sol";
import "../PriceOracle.sol";
import "../EIP20Interface.sol";
import "../ExponentialNoError.sol";

interface RewardDistributorInterface {

    struct RewardMarketState {
        /// @notice The market's last updated joeBorrowIndex or joeSupplyIndex
        uint224 index;
        /// @notice The timestamp number the index was last updated at
        uint32 timestamp;
    }

    // address[] public rewardAddresses;
    function rewardAddresses(uint) external view returns (address);


    /// @notice The portion of supply reward rate that each market currently receives
    function rewardSupplySpeeds(uint8, address) external view returns (uint256);

    /// @notice The portion of borrow reward rate that each market currently receives
    function rewardBorrowSpeeds(uint8, address) external view returns (uint256);

    /// @notice The JOE/AVAX market supply state for each market
    function rewardSupplyState(uint8, address) external view returns (RewardMarketState memory);

    /// @notice The JOE/AVAX market borrow state for each market
    function rewardBorrowState(uint8, address) external view returns (RewardMarketState memory);

    /// @notice The JOE/AVAX borrow index for each market for each supplier as of the last time they accrued reward
    function rewardSupplierIndex(uint8, address, address) external view returns (uint256);

    /// @notice The JOE/AVAX borrow index for each market for each borrower as of the last time they accrued reward
    function rewardBorrowerIndex(uint8, address, address) external view returns (uint256);

    /// @notice The JOE/AVAX accrued but not yet transferred to each user
    function rewardAccrued(uint8, address) external view returns (uint256);
}

interface ComptrollerLensInterface {
    function rewardDistributor() external view returns (address payable);
    function markets(address) external view returns (bool, uint);
    function oracle() external view returns (PriceOracle);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (CToken[] memory);
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
    function compSpeeds(address) external view returns (uint);
    function compSupplySpeeds(address) external view returns (uint);
    function compBorrowSpeeds(address) external view returns (uint);
    function borrowCaps(address) external view returns (uint);
}


contract BastionLens is ExponentialNoError {
    struct CTokenMetadata {
        address cToken;
        uint price;
        uint exchangeRateCurrent;
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint reserveFactorMantissa;
        uint totalBorrows;
        uint totalReserves;
        uint totalSupply;
        uint totalCash;
        bool isListed;
        uint collateralFactorMantissa;
        address underlyingAssetAddress;
        uint8 cTokenDecimals;
        uint8 underlyingDecimals;
        uint borrowCap;
        uint marketBorrowIndex;
        RewardSpeed[] rewardSpeed;
    }

    struct RewardSpeed {
        uint8 rewardType;
        address token;
        uint supplySpeed;
        uint borrowSpeed;
    }

     function getCompSpeeds(ComptrollerLensInterface comptroller, CToken cToken, uint8 rewardType) internal returns (RewardSpeed memory) {
        // Getting comp speeds is gnarly due to not every network having the
        // split comp speeds from Proposal 62 and other networks don't even
        // have comp speeds.
        RewardDistributorInterface rewardDistributor = RewardDistributorInterface(comptroller.rewardDistributor());
        address token = rewardDistributor.rewardAddresses(rewardType);

        uint compSupplySpeed = 0;
        (bool compSupplySpeedSuccess, bytes memory compSupplySpeedReturnData) =
            address(rewardDistributor).call(
                abi.encodePacked(
                    rewardDistributor.rewardSupplySpeeds.selector,
                    abi.encode(rewardType, address(cToken))
                )
            );
        if (compSupplySpeedSuccess) {
            compSupplySpeed = abi.decode(compSupplySpeedReturnData, (uint));
        }

        uint compBorrowSpeed = 0;
        (bool compBorrowSpeedSuccess, bytes memory compBorrowSpeedReturnData) =
            address(rewardDistributor).call(
                abi.encodePacked(
                    rewardDistributor.rewardBorrowSpeeds.selector,
                    abi.encode(rewardType, address(cToken))
                )
            );
        if (compBorrowSpeedSuccess) {
            compBorrowSpeed = abi.decode(compBorrowSpeedReturnData, (uint));
        }

        // If the split comp speeds call doesn't work, try the  oldest non-spit version.
        // if (!compSupplySpeedSuccess || !compBorrowSpeedSuccess) {
        //     (bool compSpeedSuccess, bytes memory compSpeedReturnData) =
        //     address(rewardDistributor).call(
        //         abi.encodePacked(
        //             rewardDistributor.compSpeeds.selector,
        //             abi.encode(address(cToken))
        //         )
        //     );
        //     if (compSpeedSuccess) {
        //         compSupplySpeed = compBorrowSpeed = abi.decode(compSpeedReturnData, (uint));
        //     }
        // }
        return RewardSpeed({
            rewardType: rewardType,
            token: token,
            supplySpeed: compSupplySpeed,
            borrowSpeed: compBorrowSpeed
        });
    }

    function cTokenMetadata(CToken cToken, uint8 rewardCount) public returns (CTokenMetadata memory) {
        uint exchangeRateCurrent = cToken.exchangeRateStored();
        ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(cToken.comptroller()));
        (bool isListed, uint collateralFactorMantissa) = comptroller.markets(address(cToken));
        address underlyingAssetAddress;
        uint8 underlyingDecimals;

        RewardSpeed[] memory rewardSpeed = new RewardSpeed[](rewardCount);

        for (uint8 rewardType = 0; rewardType < rewardCount; rewardType++) {
            rewardSpeed[rewardType] = getCompSpeeds(comptroller, cToken, rewardType);
        }

        if (compareStrings(cToken.symbol(), "cETH")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            CErc20 cErc20 = CErc20(address(cToken));
            underlyingAssetAddress = cErc20.underlying();
            underlyingDecimals = EIP20Interface(cErc20.underlying()).decimals();
        }

        PriceOracle oracle = comptroller.oracle();
        uint price = oracle.getUnderlyingPrice(cToken);

        // uint borrowCap = 0;
        // (bool borrowCapSuccess, bytes memory borrowCapReturnData) =
        //     address(comptroller).staticcall(
        //         abi.encodePacked(
        //             comptroller.borrowCaps.selector,
        //             abi.encode(address(cToken))
        //         )
        //     );
        // if (borrowCapSuccess) {
        //     borrowCap = abi.decode(borrowCapReturnData, (uint));
        // }

        return CTokenMetadata({
            cToken: address(cToken),
			price: price,
            exchangeRateCurrent: exchangeRateCurrent,
            supplyRatePerBlock: cToken.supplyRatePerBlock(),
            borrowRatePerBlock: cToken.borrowRatePerBlock(),
            reserveFactorMantissa: cToken.reserveFactorMantissa(),
            totalBorrows: cToken.totalBorrows(),
            totalReserves: cToken.totalReserves(),
            totalSupply: cToken.totalSupply(),
            totalCash: cToken.getCash(),
            isListed: isListed,
            collateralFactorMantissa: collateralFactorMantissa,
            underlyingAssetAddress: underlyingAssetAddress,
            cTokenDecimals: cToken.decimals(),
            underlyingDecimals: underlyingDecimals,
            borrowCap: 0,
            marketBorrowIndex: cToken.borrowIndex(),
            rewardSpeed: rewardSpeed
        });
    }

    function cTokenMetadataAll(CToken[] calldata cTokens, uint8 rewardCount) external returns (CTokenMetadata[] memory) {
        uint cTokenCount = cTokens.length;
        CTokenMetadata[] memory res = new CTokenMetadata[](cTokenCount);
        for (uint i = 0; i < cTokenCount; i++) {
            res[i] = cTokenMetadata(cTokens[i], rewardCount);
        }
        return res;
    }

    uint rewardInitialIndex = 1e36;
    struct RewardBalances {
        uint8 rewardType;
        address token;
        address holder;
        uint rewardAccrue;
        uint rewardEstimate;
        uint borrowSpeed;
        uint supplySpeed;
    }

    struct CTokenBalances {
        address cToken;
        uint balanceOf;
        uint borrowBalanceStored;
        uint exchangeRateStored;
        uint tokenBalance;
        uint tokenAllowance;
        uint borrowIndex;
        RewardBalances[] rewardBalances;
    }

    function getUpdateRewardSupplyIndex(
        RewardDistributorInterface.RewardMarketState memory supplyState,
        uint supplySpeed,
        address cToken
    )
        internal view returns (RewardDistributorInterface.RewardMarketState memory)
    {
        uint256 blockTimestamp = block.timestamp;
        uint256 deltaTimestamps = sub_(
            blockTimestamp,
            uint256(supplyState.timestamp)
        );
        uint256 supplyTokens = CToken(cToken).totalSupply();
        uint256 rewardAccrued = mul_(deltaTimestamps, supplySpeed);
        Double memory ratio = supplyTokens > 0
            ? fraction(rewardAccrued, supplyTokens)
            : Double({mantissa: 0});
        Double memory index = add_(
            Double({mantissa: supplyState.index}),
            ratio
        );
        return RewardDistributorInterface.RewardMarketState({
            index: safe224(index.mantissa, "new index exceeds 224 bits"),
            timestamp: safe32(
                blockTimestamp,
                "block timestamp exceeds 32 bits"
            )
        });
    }

    function calculateSupplierDelta(
        RewardDistributorInterface.RewardMarketState memory supplyState,
        uint supplierIndexMantissa,
        address cToken,
        address supplier
    ) internal view returns (uint) {
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({
            mantissa: supplierIndexMantissa
        });

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = rewardInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint256 supplierTokens = CToken(cToken).balanceOf(supplier);
        uint256 supplierDelta = mul_(supplierTokens, deltaIndex);
        return supplierDelta;
    }

    function getUpdateRewardBorrowIndex(
        RewardDistributorInterface.RewardMarketState memory borrowState,
        uint borrowSpeed,
        address cToken,
        uint marketBorrowIndexMantissa
    ) internal view returns (RewardDistributorInterface.RewardMarketState memory) {
        Exp memory marketBorrowIndex = Exp({ mantissa: marketBorrowIndexMantissa });
        uint256 blockTimestamp = block.timestamp;
        uint256 deltaTimestamps = sub_(
            blockTimestamp,
            uint256(borrowState.timestamp)
        );
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
        return RewardDistributorInterface.RewardMarketState({
            index: safe224(index.mantissa, "new index exceeds 224 bits"),
            timestamp: safe32(
                blockTimestamp,
                "block timestamp exceeds 32 bits"
            )
        });
    }

    function calculateBorrowerDelta(
        RewardDistributorInterface.RewardMarketState memory borrowState,
        uint borrowerIndexMantissa,
        address cToken,
        address borrower,
        uint marketBorrowIndexMantissa
    ) internal view returns (uint) {
        Exp memory marketBorrowIndex = Exp({ mantissa: marketBorrowIndexMantissa });
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({
            mantissa: borrowerIndexMantissa
        });

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
        return borrowerDelta;
    }

    function cTokenBalances(CToken cToken, address payable account, uint8 rewardCount) public view returns (CTokenBalances memory) {
        CTokenBalances memory balances;
        balances.cToken = address(cToken);
        balances.balanceOf = cToken.balanceOf(account);
        balances.borrowBalanceStored = cToken.borrowBalanceStored(account);
        balances.exchangeRateStored = cToken.exchangeRateStored();
        balances.borrowIndex = cToken.borrowIndex();
        ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(cToken.comptroller()));
        RewardDistributorInterface rewardDistributor = RewardDistributorInterface(comptroller.rewardDistributor());

        RewardBalances[] memory rewardBalances = new RewardBalances[](rewardCount);
        for (uint8 rewardType; rewardType < rewardCount; rewardType++) {
            rewardBalances[rewardType].rewardType = rewardType;
            rewardBalances[rewardType].token = rewardDistributor.rewardAddresses(rewardType);
            rewardBalances[rewardType].holder = account;
            rewardBalances[rewardType].supplySpeed = rewardDistributor.rewardSupplySpeeds(rewardType, address(cToken));
            rewardBalances[rewardType].borrowSpeed = rewardDistributor.rewardBorrowSpeeds(rewardType, address(cToken));
            
            rewardBalances[rewardType].rewardAccrue = rewardDistributor.rewardAccrued(rewardType, account);
            rewardBalances[rewardType].rewardEstimate = 
                calculateSupplierDelta(
                    getUpdateRewardSupplyIndex(
                        rewardDistributor.rewardSupplyState(rewardType, address(cToken)),
                        rewardDistributor.rewardSupplySpeeds(rewardType, address(cToken)),
                        address(cToken)
                    ),
                    rewardDistributor.rewardSupplierIndex(rewardType, address(cToken), account),
                    address(cToken),
                    account
                ) +
                calculateBorrowerDelta(
                    getUpdateRewardBorrowIndex(
                        rewardDistributor.rewardBorrowState(rewardType, address(cToken)),
                        rewardDistributor.rewardBorrowSpeeds(rewardType, address(cToken)),
                        address(cToken),
                        cToken.borrowIndex()
                    ),
                    rewardDistributor.rewardBorrowerIndex(rewardType, address(cToken), account),
                    address(cToken),
                    account,
                    cToken.borrowIndex()
                );
        }
        balances.rewardBalances = rewardBalances;

        if (compareStrings(cToken.symbol(), "cETH")) {
            balances.tokenBalance = account.balance;
            balances.tokenAllowance = account.balance;
        } else {
            CErc20 cErc20 = CErc20(address(cToken));
            EIP20Interface underlying = EIP20Interface(cErc20.underlying());
            balances.tokenBalance = underlying.balanceOf(account);
            balances.tokenAllowance = underlying.allowance(account, address(cToken));
        }

        return balances;
    }

    function cTokenBalancesAll(CToken[] calldata cTokens, address payable account, uint8 rewardCount) external view returns (CTokenBalances[] memory) {
        uint cTokenCount = cTokens.length;
        CTokenBalances[] memory res = new CTokenBalances[](cTokenCount);
        for (uint i = 0; i < cTokenCount; i++) {
            res[i] = cTokenBalances(cTokens[i], account, rewardCount);
        }
        return res;
    }

    struct CTokenUnderlyingPrice {
        address cToken;
        uint underlyingPrice;
    }

    function cTokenUnderlyingPrice(CToken cToken) public view returns (CTokenUnderlyingPrice memory) {
        ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(cToken.comptroller()));
        PriceOracle priceOracle = comptroller.oracle();

        return CTokenUnderlyingPrice({
            cToken: address(cToken),
            underlyingPrice: priceOracle.getUnderlyingPrice(cToken)
        });
    }

    function cTokenUnderlyingPriceAll(CToken[] calldata cTokens) external view returns (CTokenUnderlyingPrice[] memory) {
        uint cTokenCount = cTokens.length;
        CTokenUnderlyingPrice[] memory res = new CTokenUnderlyingPrice[](cTokenCount);
        for (uint i = 0; i < cTokenCount; i++) {
            res[i] = cTokenUnderlyingPrice(cTokens[i]);
        }
        return res;
    }

    struct AccountLimits {
        CToken[] markets;
        uint liquidity;
        uint shortfall;
    }

    function getAccountLimits(ComptrollerLensInterface comptroller, address account) public view returns (AccountLimits memory) {
        (uint errorCode, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({
            markets: comptroller.getAssetsIn(account),
            liquidity: liquidity,
            shortfall: shortfall
        });
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }
}
