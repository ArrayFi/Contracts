pragma solidity >=0.5.0 <0.7.0;


interface IPrivatePlacement {
    function entrust(address seller, address buyer, uint256 lot) external returns (uint256);
}