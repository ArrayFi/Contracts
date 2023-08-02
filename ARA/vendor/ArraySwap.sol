pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../../interface/IERC20.sol";
import "../../library/SafeMath.sol";
import "../../common/Ownable.sol";
import "../../access/WhitelistedRole.sol";

interface IV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface ISwapPool {
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);

    function liquidity() external view returns (uint128);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);
}

contract ArraySwapProd is WhitelistedRole {

    using SafeMath for uint256;

    IV3SwapRouter public swapRouter;
    ISwapPool public swapPool;
    // USDR
    address public token0;
    // ARA
    address public token1;
    // For this example, we will set the pool fee to 1% when poolFee = 10000. 0.05% when poolFee = 500
    uint24 public poolFee;
    uint8 public token0Decimals;
    uint8 public token1Decimals;

    uint24 public constant poolFeeMax = 1000000;

    constructor(IV3SwapRouter _swapRouter, ISwapPool _swapPool) public {
        swapRouter = _swapRouter;
        swapPool = _swapPool;
        token0 = swapPool.token1();
        token1 = swapPool.token0();
        poolFee = swapPool.fee();
        token0Decimals = IERC20(token0).decimals();
        token1Decimals = IERC20(token1).decimals();
    }

    /// @notice swapExactInputSingle swaps a fixed amount of one token for a maximum possible amount the others
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its token for this function to succeed.
    /// @param amountIn The exact amount that will be swapped.
    /// @return amountOut The amount received.
    function swapExactInputSingle(uint256 amountIn, uint256 amountOutMin, address token) external onlyWhitelisted {
        // plat approve this contract
        require(IERC20(token).allowance(msg.sender, address(this)) >= amountIn, "ArraySwap: allowance not enough for ArraySwap");
        require(IERC20(token).balanceOf(msg.sender) >= amountIn, "ArraySwap: balance not enough to ArraySwap");

        require(token == token0 || token == token1, "ArraySwap: tokenIn not in this pool");
        address tokenIn;
        address tokenOut;
        uint8 decimalsIn;
        uint8 decimalsOut;
        if (token == token0) {
            tokenIn = token0;
            decimalsIn = token0Decimals;
            tokenOut = token1;
            decimalsOut = token1Decimals;
        } else {
            tokenIn = token1;
            decimalsIn = token1Decimals;
            tokenOut = token0;
            decimalsOut = token0Decimals;
        }

        // Transfer the specified amount of input token to this contract.
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve the router to spend.
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
        tokenIn : tokenIn,
        tokenOut : tokenOut,
        fee : poolFee,
        recipient : msg.sender,
        amountIn : amountIn,
        amountOutMinimum : amountOutMin,
        sqrtPriceLimitX96 : 0
        });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);

        require(amountOut >= amountOutMin, "ArraySwapMaker: amountOut not enough");

        emit Swap(amountIn, decimalsIn, amountOut, decimalsOut, tokenIn, tokenOut, msg.sender);
    }

    uint private constant UNIT = 10 ** 18;
    uint256 public constant uniCo = 2 ** 192;
    uint256 public constant q96 = 2 ** 96;

    /**
     * P
     * @notice uniswap
     */
    function getToken0ByToken1Price() public view returns (uint256 price) {
        uint256 stdPrice = getStdPrice();
        return (UNIT ** 2).div(stdPrice);
    }

    function getStdPrice() public view returns (uint256 price) {
        (uint160 sqrtPriceX96,,,,,,) = swapPool.slot0();
        uint256 sqrtPriceX96Uint256 = uint256(sqrtPriceX96);
        price = (sqrtPriceX96Uint256 ** 2).div(uniCo.div(UNIT));
        if (token0Decimals >= token1Decimals) {
            uint256 delta = token0Decimals - token1Decimals;
            price = price.mul(10 ** delta);
        } else {
            uint256 delta = token1Decimals - token0Decimals;
            price = price.div(10 ** delta);
        }
    }



    /**
     * L
     */
    function poolLiquidity() public view returns (uint256) {
        return swapPool.liquidity();
    }

    /**
     * Δx = Δ(1/√P) * L
     */
    function token0Reverses() public view returns (uint256) {
        return IERC20(token0).balanceOf(address(swapPool));
    }

    /**
     * Δy = Δ(√P) * L
     */
    function token1Reverses() public view returns (uint256) {
        return IERC20(token1).balanceOf(address(swapPool));
    }


    /// @notice _priceNextInputToken1
    /// @dev calculate sqrt price next
    /// @param token1Amount amount of token1
    function _priceNextInputToken1(uint256 token1Amount) internal view returns (uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price) {
        liq = poolLiquidity();
        uint256 priceDiff = token1Amount.mul(q96).div(liq);
        (uint160 sqrtPriceX96,,,,,,) = swapPool.slot0();
        sqrtP = uint(sqrtPriceX96);
        sqrPNext = sqrtP.add(priceDiff);
        price = (sqrPNext ** 2).div(uniCo.div(UNIT));
        if (token0Decimals >= token1Decimals) {
            uint256 delta = token0Decimals - token1Decimals;
            price = price.mul(10 ** delta);
        } else {
            uint256 delta = token1Decimals - token0Decimals;
            price = price.div(10 ** delta);
        }
    }

    /// @notice _priceNextOutputToken1
    /// @dev calculate sqrt price next
    /// @param token1Amount amount of token1
    function _priceNextOutputToken1(uint256 token1Amount) internal view returns (uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price) {
        liq = poolLiquidity();
        uint256 priceDiff = token1Amount.mul(q96).div(liq);
        (uint160 sqrtPriceX96,,,,,,) = swapPool.slot0();
        sqrtP = uint(sqrtPriceX96);
        sqrPNext = sqrtP.sub(priceDiff);
        price = (sqrPNext ** 2).div(uniCo.div(UNIT));
        if (token0Decimals >= token1Decimals) {
            uint256 delta = token0Decimals - token1Decimals;
            price = price.mul(10 ** delta);
        } else {
            uint256 delta = token1Decimals - token0Decimals;
            price = price.div(10 ** delta);
        }
    }

    /// @notice _priceNextInputToken0
    /// @dev calculate sqrt price next
    /// @param token0Amount amount of token0
    function _priceNextInputToken0(uint256 token0Amount) internal view returns (uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price) {
        liq = poolLiquidity();
        (uint160 sqrtPriceX96,,,,,,) = swapPool.slot0();
        sqrtP = uint(sqrtPriceX96);
        uint256 a = liq.mul(q96).div(UNIT).mul(sqrtP);
        uint256 b = (liq.mul(q96).add(token0Amount.mul(sqrtP))).div(UNIT);
        sqrPNext = a.div(b);
        price = (sqrPNext ** 2).div(uniCo.div(UNIT));
        if (token0Decimals >= token1Decimals) {
            uint256 delta = token0Decimals - token1Decimals;
            price = price.mul(10 ** delta);
        } else {
            uint256 delta = token1Decimals - token0Decimals;
            price = price.div(10 ** delta);
        }
    }

    /// @notice _priceNextOutputToken0
    /// @dev calculate sqrt price next
    /// @param token0Amount amount of token0
    function _priceNextOutputToken0(uint256 token0Amount) internal view returns (uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price) {
        liq = poolLiquidity();
        (uint160 sqrtPriceX96,,,,,,) = swapPool.slot0();
        sqrtP = uint(sqrtPriceX96);
        uint256 a = liq.mul(q96).div(UNIT).mul(sqrtP);
        uint256 b = (liq.mul(q96).sub(token0Amount.mul(sqrtP))).div(UNIT);
        sqrPNext = a.div(b);
        price = (sqrPNext ** 2).div(uniCo.div(UNIT));
        if (token0Decimals >= token1Decimals) {
            uint256 delta = token0Decimals - token1Decimals;
            price = price.mul(10 ** delta);
        } else {
            uint256 delta = token1Decimals - token0Decimals;
            price = price.div(10 ** delta);
        }
    }

    /// @notice _calcAmount0
    /// @dev calculate the token0 amount change
    /// @param pa sqrt p next
    /// @param pb sqrt p current
    function _calcAmount0(uint256 liq, uint256 pa, uint256 pb) internal view returns (uint256 token0Amount) {
        if (pa > pb) {
            uint256 tmp = pa;
            pa = pb;
            pb = tmp;
        }
        liq = poolLiquidity();
        uint256 a = liq.mul(q96).div(UNIT).mul(pb.sub(pa));
        uint256 b = pa.mul(pb).div(UNIT);
        token0Amount = a.div(b);
    }

    /// @notice calcAmount0
    /// @dev calculate the token1 amount change
    /// @param token1Amount amount of token1
    function calcOutAmount1(uint256 token1Amount) public view returns (uint256 token0Amount, uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price){
        token1Amount = token1Amount.sub(token1Amount.mul(poolFee).div(poolFeeMax));
        //step1. get sqrtP
        (liq, sqrtP, sqrPNext, price) = _priceNextInputToken1(token1Amount);
        //step2. get token0 amount
        uint256 pa = sqrPNext;
        uint256 pb = sqrtP;
        token0Amount = _calcAmount0(liq, pa, pb);
    }


    /// @notice calcAmount0
    /// @dev calculate the token1 amount change
    /// @param token1Amount amount of token1
    function calcInAmount1(uint256 token1Amount) public view returns (uint256 token0Amount, uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price){
        //step1. get sqrtP
        (liq, sqrtP, sqrPNext, price) = _priceNextOutputToken1(token1Amount);
        //step2. get token0 amount
        uint256 pa = sqrPNext;
        uint256 pb = sqrtP;
        token0Amount = _calcAmount0(liq, pa, pb);
        token0Amount = token0Amount.add(token0Amount.mul(poolFee).div(poolFeeMax));
    }

    /// @notice calcAmount1
    /// @dev calculate the token1 amount change
    /// @param pa sqrt p next
    /// @param pb sqrt p current
    function _calcAmount1(uint256 liq, uint256 pa, uint256 pb) internal view returns (uint256 token1Amount){
        if (pa > pb) {
            uint256 tmp = pa;
            pa = pb;
            pb = tmp;
        }
        liq = poolLiquidity();
        uint256 a = liq.mul(pb.sub(pa));
        uint256 b = q96;
        token1Amount = a.div(b);
    }

    /// @notice calcAmount0
    /// @dev calculate the token0 amount change
    /// @param token0Amount amount of token0
    function calcOutAmount0(uint256 token0Amount) public view returns (uint256 token1Amount, uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price){
        token0Amount = token0Amount.sub(token0Amount.mul(poolFee).div(poolFeeMax));
        //step1. get sqrtP
        (liq, sqrtP, sqrPNext, price) = _priceNextInputToken0(token0Amount);
        //step2. get token0 amount
        uint256 pa = sqrPNext;
        uint256 pb = sqrtP;
        token1Amount = _calcAmount1(liq, pa, pb);
    }

    /// @notice calcAmount0
    /// @dev calculate the token0 amount change
    /// @param token0Amount amount of token0
    function calcInAmount0(uint256 token0Amount) public view returns (uint256 token1Amount, uint256 liq, uint256 sqrtP, uint256 sqrPNext, uint256 price){
        //step1. get sqrtP
        (liq, sqrtP, sqrPNext, price) = _priceNextOutputToken0(token0Amount);
        //step2. get token0 amount
        uint256 pa = sqrPNext;
        uint256 pb = sqrtP;
        token1Amount = _calcAmount1(liq, pa, pb);
        token1Amount = token1Amount.add(token1Amount.mul(poolFee).div(poolFeeMax));
    }

    event Swap(uint256 amountIn, uint8 decimalsIn, uint256 amountOut, uint8 decimalsOut, address tokenIn, address tokenOut, address plat);
}
