// credit to tarot finance

pragma solidity =0.5.16;

import "./UQ112x112.sol";
import "../Interface/IUniswapV2Pair.sol";
import "../PriceOracle.sol";
import "../CErc20.sol";
import "../EIP20Interface.sol";

contract TwapFeed {
    using UQ112x112 for uint224;

    // For Integrating with Flux Oracle
    uint8 public decimals = 18;
    uint8 public pairDecimalsDelta;

    uint32 public constant MIN_T = 1200;

    struct Pair {
        uint256 priceCumulativeSlotA;
        uint256 priceCumulativeSlotB;
        uint32 lastUpdateSlotA;
        uint32 lastUpdateSlotB;
        bool latestIsSlotA;
        bool initialized;
        bool asToken0;
    }
    Pair public pair;
    address public uniswapV2Pair;

    event PriceUpdate(
        address indexed pair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool latestIsSlotA
    );

    constructor (address _uniswapV2Pair, bool asToken0) public {
        uniswapV2Pair = _uniswapV2Pair;
           pair.asToken0 = asToken0;

		EIP20Interface token0 = EIP20Interface(IUniswapV2Pair(uniswapV2Pair).token0());
		EIP20Interface token1 = EIP20Interface(IUniswapV2Pair(uniswapV2Pair).token1());
        pairDecimalsDelta = asToken0 ? 18 + token1.decimals() - token0.decimals() : 18 + token0.decimals() - token1.decimals();

        require(
            !pair.initialized,
            "TrisolarisPriceOracle: ALREADY_INITIALIZED"
        );

        uint256 priceCumulativeCurrent =
            getPriceCumulativeCurrent(pair.asToken0);

        uint32 blockTimestamp = getBlockTimestamp();
        pair.priceCumulativeSlotA = priceCumulativeCurrent;
        pair.priceCumulativeSlotB = priceCumulativeCurrent;
        pair.lastUpdateSlotA = blockTimestamp;
        pair.lastUpdateSlotB = blockTimestamp;
        pair.latestIsSlotA = true;
        pair.initialized = true;
        emit PriceUpdate(
            uniswapV2Pair,
            priceCumulativeCurrent,
            blockTimestamp,
            true
        );
    }

    function latestAnswer() public view returns (uint) {
        uint256 priceCumulativeCurrent =
            getPriceCumulativeCurrent(pair.asToken0);

        uint priceCumulativeLast = pair.latestIsSlotA
                ? pair.priceCumulativeSlotB
                : pair.priceCumulativeSlotA;
        
        uint32 blockTimestamp = getBlockTimestamp();
        uint32 lastUpdateTimestamp =
            pair.latestIsSlotA ? pair.lastUpdateSlotB : pair.lastUpdateSlotA;
        uint32 T = blockTimestamp - lastUpdateTimestamp; // overflow is desired
        // / is safe, and - overflow is desired
        uint224 price = toUint224((priceCumulativeCurrent - priceCumulativeLast) / T); 
        
        // convert decimals to 18 (not use pairDecimalsDelta because wBTC-wNEAR has only 2 decimals)
        if (pairDecimalsDelta > decimals) {
            return price / uint(10**uint(pairDecimalsDelta - decimals)) / 5192296858534816;
        } else {
            return price * uint(10**uint(decimals - pairDecimalsDelta)) / 5192296858534816;
        }
    }

    function toUint224(uint256 input) internal pure returns (uint224) {
        require(input <= uint224(-1), "TrisolarisPriceOracle: UINT224_OVERFLOW");
        return uint224(input);
    }

    function getPriceCumulativeCurrent(bool asToken0)
        internal
        view
        returns (uint256 priceCumulative)
    {
        priceCumulative = 
            asToken0 ? IUniswapV2Pair(uniswapV2Pair).price0CumulativeLast() : IUniswapV2Pair(uniswapV2Pair).price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) =
            IUniswapV2Pair(uniswapV2Pair).getReserves();
        
        uint224 priceLatest = asToken0 ? UQ112x112.encode(reserve1).uqdiv(reserve0) : UQ112x112.encode(reserve0).uqdiv(reserve1);

        uint32 timeElapsed = getBlockTimestamp() - blockTimestampLast; // overflow is desired
        // * never overflows, and + overflow is desired
        priceCumulative += uint256(priceLatest) * timeElapsed;
    }

    function update()
        external
        returns (uint224 price, uint32 T)
    {
        require(pair.initialized, "TrisolarisPriceOracle: NOT_INITIALIZED");

        uint32 blockTimestamp = getBlockTimestamp();
        uint32 lastUpdateTimestamp =
            pair.latestIsSlotA ? pair.lastUpdateSlotA : pair.lastUpdateSlotB;
        uint256 priceCumulativeCurrent =
            getPriceCumulativeCurrent(pair.asToken0);
        uint256 priceCumulativeLast;

        if (blockTimestamp - lastUpdateTimestamp >= MIN_T) {
            // update price
            priceCumulativeLast = pair.latestIsSlotA
                ? pair.priceCumulativeSlotA
                : pair.priceCumulativeSlotB;
            if (pair.latestIsSlotA) {
                pair.priceCumulativeSlotB = priceCumulativeCurrent;
                pair.lastUpdateSlotB = blockTimestamp;
            } else {
                pair.priceCumulativeSlotA = priceCumulativeCurrent;
                pair.lastUpdateSlotA = blockTimestamp;
            }
            pair.latestIsSlotA = !pair.latestIsSlotA;
            emit PriceUpdate(
                uniswapV2Pair,
                priceCumulativeCurrent,
                blockTimestamp,
                !pair.latestIsSlotA
            );
        } else {
            // don't update; return price using previous priceCumulative
            lastUpdateTimestamp = pair.latestIsSlotA
                ? pair.lastUpdateSlotB
                : pair.lastUpdateSlotA;
            priceCumulativeLast = pair.latestIsSlotA
                ? pair.priceCumulativeSlotB
                : pair.priceCumulativeSlotA;
        }

        T = blockTimestamp - lastUpdateTimestamp; // overflow is desired
        require(T >= MIN_T, "TrisolarisPriceOracle: NOT_READY"); //reverts only if the pair has just been initialized
        // / is safe, and - overflow is desired
        price = toUint224((priceCumulativeCurrent - priceCumulativeLast) / T);
    }

    /*** Utilities ***/

    function getBlockTimestamp() public view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }
}