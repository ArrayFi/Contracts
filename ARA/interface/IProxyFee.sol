pragma solidity >=0.5.0 <0.7.0;

interface IProxyFee {
    function payNewGame(address proxy) external;
    function payNewBind(address proxy) external;
}