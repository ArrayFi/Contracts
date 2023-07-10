pragma solidity >=0.5.0 <0.7.0;


interface IRewardDistribution {
    function distribute(uint256 amount) external returns (bool);
}
