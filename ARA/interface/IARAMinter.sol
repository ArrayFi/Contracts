pragma solidity >=0.5.0 <0.7.0;

interface IARAMinter {
    function mintMortgageReward(address _address, uint256 _amount) external;
    function mintLiquidity(address _address, uint256 _amount) external;
    function mintRankReward(address _address, uint256 _amount) external;
    function mintOthers(address _address, uint256 _amount) external;
}