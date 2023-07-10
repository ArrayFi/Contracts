pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../common/MixinResolver.sol";

contract RewardDistribution is MixinResolver {
    using SafeMath for uint256;

    Reward[] public rewards;

    struct Reward {
        address account;
        uint256 amount;
    }

    constructor() public {}

    function getRewardsLength() public view returns (uint256) {
        return rewards.length;
    }

    function addRewardHook(address account, uint256 amount) public onlyOwner returns (bool) {
        require(account != address(0), "RewardDistribution: account is the zero address");
        require(amount != 0, "RewardDistribution: amount can not be zero");

        Reward memory reward = Reward(account, amount);
        rewards.push(reward);

        emit AddRewardHook(rewards.length - 1, account, amount);

        return true;
    }

    function revRewardHook(uint256 index, address account, uint256 amount) public onlyOwner returns (bool) {
        require(rewards.length != 0, "RewardDistribution: rewards length can not be zero");
        require(index < rewards.length, "RewardDistribution: index out of bounds");
        require(account != address(0), "RewardDistribution: account is the zero address");
        require(amount != 0, "RewardDistribution: amount can not be zero");

        rewards[index].account = account;
        rewards[index].amount = amount;

        emit RevRewardHook(index, account, amount);

        return true;
    }

    function delRewardHook(uint256 index) public onlyOwner returns (bool) {
        require(rewards.length != 0, "RewardDistribution: rewards length can not be zero");
        require(index < rewards.length, "RewardDistribution: index out of bounds");

        Reward memory reward = rewards[index];
        for (uint256 i = index; i < rewards.length - 1; i++) {
            rewards[i] = rewards[i + 1];
        }
        rewards.length--;

        emit DelRewardHook(index, reward.account, reward.amount);

        return true;
    }

    function distribute(uint256 amount) public onlyAuthorized returns (bool) {
        require(amount > 0, "RewardDistribution: amount can not be zero");
        require(foundry().balanceOf(address(this)) >= amount, "RewardDistribution: distribute amount exceeds balance");

        uint256 remainder = amount;

        for (uint256 index = 0; index < rewards.length; index++) {
            if (rewards[index].account != address(0) && rewards[index].amount != 0) {
                remainder = remainder.sub(rewards[index].amount);
                foundry().transfer(rewards[index].account, rewards[index].amount);
            }
        }

        foundry().transfer(address(reward()), remainder);

        emit RewardDistributed(amount, address(reward()), remainder);

        return true;
    }

    function isAuthorized() public view returns (bool) {
        return msg.sender == address(foundry());
    }


    modifier onlyAuthorized() {
        require(isAuthorized(), "RewardDistribution: caller is not the authorized");
        _;
    }


    event AddRewardHook(uint256 indexed index, address indexed account, uint256 indexed amount);
    event RevRewardHook(uint256 indexed index, address indexed account, uint256 indexed amount);
    event DelRewardHook(uint256 indexed index, address indexed account, uint256 indexed amount);
    event RewardDistributed(uint256 indexed amount, address indexed escrow, uint256 indexed remainder);
}
