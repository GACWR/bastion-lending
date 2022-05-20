pragma solidity =0.5.16;

import "./AggregatorV2V3Interface.sol";
import "../SafeMath.sol";

contract StNearFeed {
	using SafeMath for uint;
	address public admin;
	event NewAdmin(address oldAdmin, address newAdmin);
	// Price Feed
	AggregatorV2V3Interface public nearFeed;

	// Interface for Bastion Oracle
	uint8 public decimals = 18;
	uint public stNearPrice;

	constructor (uint _stNearPrice, address _nearFeed) public {
		admin = msg.sender;
		nearFeed = AggregatorV2V3Interface(_nearFeed);
		stNearPrice = _stNearPrice;
	}

	// Interface for Bastion Oracle
	function latestAnswer() public view returns (uint) {
		uint nearPrice = uint(nearFeed.latestAnswer());
		return nearPrice.mul(stNearPrice);
	}

	function setNearFeed(address _nearFeed) public onlyAdmin {
		nearFeed = AggregatorV2V3Interface(_nearFeed);
	}

	function setStNearPrice(uint _stNearPrice) public onlyAdmin {
		require(_stNearPrice > 1.06e10, "StNearPrice too low");
		require(_stNearPrice < 1.1e10, "StNearPrice too high");
		stNearPrice = _stNearPrice;
	}

	function setAdmin(address newAdmin) external onlyAdmin() {
		address oldAdmin = admin;
		admin = newAdmin;

		emit NewAdmin(oldAdmin, newAdmin);
	}

	modifier onlyAdmin() {
		require(msg.sender == admin, "only admin may call");
		_;
	}
}