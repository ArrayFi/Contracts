pragma solidity >=0.5.0 <0.7.0;

interface IUniswap {
    function slot0() external view returns (uint160,int24,uint16,uint16,uint16,uint8,bool);
}