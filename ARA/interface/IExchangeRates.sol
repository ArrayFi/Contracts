pragma solidity >=0.5.0 <0.7.0;


interface IExchangeRates {
    function ratio(bytes32 source, uint256 amount, bytes32 destination) external view returns (uint256);

    function getFeedPrice(bytes32 currency) external view returns (uint256);
}
