pragma solidity >=0.5.0 <0.7.0;


import "../../access/WhitelistedRole.sol";
import "../common/MixinResolver.sol";
import "../../library/SafeMath.sol";


contract ARAMinter is WhitelistedRole, MixinResolver {
    using SafeMath for uint256;

    uint256 public total = 0;
    uint256 public mortgageReward = 0;
    uint256 public liquidity = 0;
    uint256 public rankReward = 0;
    uint256 public others = 0;
    
    constructor() public {}


    function mintMortgageReward(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        mortgageReward = mortgageReward.add(_amount);
        araToken().mint(_address, _amount);

        emit MortgageReward(_address, _amount);
    }

    function mintLiquidity(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        liquidity = liquidity.add(_amount);
        araToken().mint(_address, _amount);

        emit Liquidity(_address, _amount);
    }

    function mintRankReward(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        rankReward = rankReward.add(_amount);
        araToken().mint(_address, _amount);

        emit RankReward(_address, _amount);
    }

    function mintOthers(address _address, uint256 _amount) public onlyWhitelisted {
        require(_address != address(0), "ARAMinter: mint address is the zero address");
        total = total.add(_amount);
        others = others.add(_amount);
        araToken().mint(_address, _amount);
    }

    event RankReward(address account, uint256 amount);
    event Liquidity(address account, uint256 amount);
    event MortgageReward(address account, uint256 amount);
}
