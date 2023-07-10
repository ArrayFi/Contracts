pragma solidity >=0.5.0 <0.7.0;

interface IFoundryExtend {
    function araBalanceOf(address account) external view returns (uint256);
    function flux(address sender, address recipient, uint256 amount) external;
    function move(address sender, address recipient, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function payReward(uint256 amount) external;
}
