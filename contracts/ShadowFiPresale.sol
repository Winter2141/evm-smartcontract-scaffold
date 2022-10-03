// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IShadowFiToken {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function isAirdropped(address account) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

contract ShadowFiPresale is Ownable, ReentrancyGuard {
    IShadowFiToken private token;
    uint256 private availableForSale;
    mapping(address => uint256) private totalBoughtByUser;
    uint256 private totalSold;
    uint256 private totalBNBRaised;
    uint256 private tokenCost;
    uint256 private discountPercent;
    uint256 private maxAmount;
    uint256 private minAmount;
    uint32 private startTime;
    uint32 private stopTime;
    
    event buyTokens(
        address indexed user,
        uint256 amount,
        uint256 bnb,
        bool discounted
    );

    constructor(address _token) {
        token = IShadowFiToken(_token);
        availableForSale = uint256(0);
        totalSold = uint256(0);
        totalBNBRaised = uint256(0);
        tokenCost = uint256(0);
        discountPercent = uint256(0);
        maxAmount = uint256(0);
        startTime = uint32(0);
        stopTime = uint32(0);
        uint8 decimals = token.decimals();
        minAmount = 10 ** decimals;
    }

    /*******************************************************************************************************/
    /************************************* Admin Functions *************************************************/
    /*******************************************************************************************************/

    function depositTokens(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        require(address(token) == _tokenAddress, "Invalid token is provided.");
        require(
            _amount <= token.balanceOf(address(msg.sender)),
            "Insufficient token balance in your wallet."
        );

        token.transferFrom(address(msg.sender), address(this), _amount);
        availableForSale += _amount;
    }

    function withdrawTokens(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        require(address(token) == _tokenAddress, "Invalid token is provided.");
        require(
            _amount <= token.balanceOf(address(this)),
            "Insufficient token balance in contract."
        );

        token.transfer(address(msg.sender), _amount);
        availableForSale -= _amount;
    }

    function setCost(uint256 _cost) public onlyOwner {
        tokenCost = _cost;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        require(address(token) != _tokenAddress, "Already set!");

        token = IShadowFiToken(_tokenAddress);
    }

    function setDiscount(uint256 _discountPercent) public onlyOwner {
        require(
            _discountPercent > 1 && _discountPercent < 1001,
            "Invalid percent is provided."
        );

        discountPercent = _discountPercent;
    }

    function setStartandStopTime(uint32 _startTime, uint32 _stopTime)
        public
        onlyOwner
    {
        require(_stopTime > _startTime, "Stop time must be after start time.");
        require(
            _stopTime > block.timestamp,
            "Stop time must be before current time."
        );

        startTime = _startTime;
        stopTime = _stopTime;
    }

    function setMax(uint256 _maxAmount) public onlyOwner {
        maxAmount = _maxAmount;
    }

    function setMin(uint256 _minAmount) public onlyOwner {
        minAmount = _minAmount;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*******************************************************************************************************/
    /************************************** User Functions *************************************************/
    /*******************************************************************************************************/

    function tokenAddress() public view returns (address) {
        return address(token);
    }

    function availableForSaleTokenAmount() public view returns (uint256) {
        return availableForSale;
    }

    function totalBoughtByUserTokenAmount(address account)
        public
        view
        returns (uint256)
    {
        return totalBoughtByUser[account];
    }

    function totalSoldTokenAmount() public view returns (uint256) {
        return totalSold;
    }

    function tokenCostBNB() public view returns (uint256) {
        return tokenCost;
    }

    function totalBNBRaisedSoFar() public view returns (uint256) {
        return totalBNBRaised;
    }

    function discountPercentage() public view returns (uint256) {
        return discountPercent;
    }

    function maxBuyableTokenAmount() public view returns (uint256) {
        return maxAmount;
    }

    function getStartTime() public view returns (uint32) {
        return startTime;
    }

    function getStopTime() public view returns (uint32) {
        return stopTime;
    }

    function buy(uint256 _amount) external payable nonReentrant {
        require(block.timestamp >= startTime, "Presale has not started yet.");
        require(block.timestamp <= stopTime, "Presale has ended.");
        require(
            _amount <= token.balanceOf(address(this)),
            "Insufficient token balance in contract"
        );
        require(
            _amount <= availableForSale,
            "Insufficient available for sale."
        );
        require(minAmount <= _amount, "Can not buy less than minimum amount.");
        require(
            _amount + totalBoughtByUser[msg.sender] <= maxAmount,
            "Exceeds maximum purchase."
        );

        uint8 decimals = token.decimals();
        uint256 cost = tokenCost;
        bool discounted = false;
        if (token.isAirdropped(msg.sender)) {
            cost = (tokenCost * (10000 - discountPercent)) / 10000;
            discounted = true;
        }
        uint256 totalCost = (_amount * cost) / (10**decimals);
        require(msg.value >= totalCost, "Insufficient payment provided.");

        payable(owner()).transfer(totalCost);

        uint256 excess = msg.value - totalCost;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }

        token.transfer(address(msg.sender), _amount);

        totalBoughtByUser[msg.sender] += _amount;
        availableForSale -= _amount;
        totalSold += _amount;
        totalBNBRaised += totalCost;

        emit buyTokens(msg.sender, _amount, msg.value, discounted);
    }
}
