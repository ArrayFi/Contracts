pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../../library/Array.sol";
import "../../access/WhitelistedRole.sol";
import "../interface/IAggregator.sol";
import "../interface/IUniswap.sol";


contract ExchangeRates is WhitelistedRole {
    using SafeMath for uint256;

    uint private UNIT = 10 ** 18;

    struct UniContract {
        address uniContract;
        uint256 decimal;
    }

    uint256 public uniCo = 2 ** 192;
    bool public uniEnable = true;

    mapping(bytes32 => UniContract) private _uniContracts;

    mapping(bytes32 => uint256) private myPrice;

    constructor() public {
    }

    function uniContract(bytes32 node) public view returns (address, uint256) {

        return (_uniContracts[node].uniContract, _uniContracts[node].decimal);
    }

    function setUniEable(bool enable) public onlyOwner {
        uniEnable = enable;
    }

    function setMyPrice(bytes32 node, uint256 price) public onlyOwner {
        myPrice[node] = price * UNIT;
    }

    function _setUniContract(bytes32 node, address content, uint256 decimal) internal {
        UniContract memory uniContract = UniContract(content, decimal);
        _uniContracts[node] = uniContract;
    }

    function setUniContracts(bytes32[] memory nodes, address[] memory contents, uint256[] memory decimals) public onlyOwner {
        require(nodes.length == contents.length, "ExchangeRates: nodes and contents length mismatched");
        require(nodes.length == decimals.length, "ExchangeRates: nodes and decimals length mismatched");

        for (uint256 index = 0; index < nodes.length; index++) {
            _setUniContract(nodes[index], contents[index], decimals[index]);
        }
    }

    function ratio(bytes32 source, uint256 amount, bytes32 destination) public view returns (uint256) {
        if (source == destination) {
            return amount;
        }
        return amount.wmulRound(getUniPrice(source)).wdivRound(getUniPrice(destination));
    }

    function getUniPrice(bytes32 currency) public view returns (uint256) {
        if (!uniEnable) {
            return myPrice[currency];
        }
        if(currency == "USDR"){
            return UNIT;
        }
        (address uniContract,) = uniContract(currency);
        require(uniContract != address(0), "ExchangeRates: currency illegal");
        uint256 price = getPrice(IUniswap(uniContract));
        return price;

    }

    function getPrice(IUniswap uniContract) public view returns (uint256 price) {
        return _getPrice(uniContract);
    }

    function _getPrice(IUniswap uniContract) public view returns (uint256 price) {
        (uint160 sqrtPriceX96,,,,,,) = uniContract.slot0();
        uint256 sqrtPriceX96Uint256 = uint256(sqrtPriceX96);
        price = (sqrtPriceX96Uint256 ** 2).div(uniCo.div(UNIT));
        uint256 token0Decimals = 18;
        uint256 token1Decimals = 18;
        if (token0Decimals >= token1Decimals) {
            uint256 delta = token0Decimals - token1Decimals;
            price = price.mul(10 ** delta);
        } else {
            uint256 delta = token1Decimals - token0Decimals;
            price = price.div(10 ** delta);
        }
    }
}