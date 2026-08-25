// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TetherUSD (USDT) — TRC-20 Token on TRON Network
 * @dev Full TRC-20 implementation with minting, burning, pause, blacklist, and trading lock.
 */

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ─────────────────────────────────────────────
//  Ownable
// ─────────────────────────────────────────────

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// ─────────────────────────────────────────────
//  Pausable
// ─────────────────────────────────────────────

abstract contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!_paused, "Pausable: token transfers are paused");
        _;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() external onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// ─────────────────────────────────────────────
//  TetherUSD — Main Contract
// ─────────────────────────────────────────────

contract TetherUSD is ITRC20, Pausable {

    // ── Token metadata ──────────────────────
    string  public constant name     = "TetherUSD";
    string  public constant symbol   = "USDT";
    uint8   public constant decimals = 6;          // USDT uses 6 decimal places

    // ── State ───────────────────────────────
    uint256 private _totalSupply;

    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool)                        private _blacklisted;

    // ── Modifiers ───────────────────────────
    modifier notBlacklisted(address account) {
        require(!_blacklisted[account], "TetherUSD: address is blacklisted");
        _;
    }

    // ── Trading lock ────────────────────────
    bool public tradingEnabled = false;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event DestroyedBlackFunds(address indexed blackListedUser, uint256 balance);
    event TradingEnabled();

    modifier tradingAllowed(address from, address to) {
        require(tradingEnabled, "Trading is disabled");
        _;
    }

    // ── Constructor ─────────────────────────
    /**
     * @param initialSupply  Amount of USDT to mint at deployment (in whole tokens; will be scaled by decimals).
     *                       Example: pass 1_000_000 to mint 1,000,000 USDT.
     */
    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals)));
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        emit TradingEnabled();
    }

    // ════════════════════════════════════════
    //  TRC-20 Core
    // ════════════════════════════════════════

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        whenNotPaused
        tradingAllowed(msg.sender, recipient)
        notBlacklisted(msg.sender)
        notBlacklisted(recipient)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        whenNotPaused
        tradingAllowed(msg.sender, spender)
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        override
        whenNotPaused
        tradingAllowed(sender, recipient)
        notBlacklisted(sender)
        notBlacklisted(recipient)
        notBlacklisted(msg.sender)
        returns (bool)
    {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "TRC20: transfer amount exceeds allowance");
        unchecked { _approve(sender, msg.sender, currentAllowance - amount); }
        _transfer(sender, recipient, amount);
        return true;
    }

    // ── Allowance helpers ───────────────────

    function increaseAllowance(address spender, uint256 addedValue)
        external
        whenNotPaused
        tradingAllowed(msg.sender, spender)
        returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        whenNotPaused
        tradingAllowed(msg.sender, spender)
        returns (bool)
    {
        uint256 current = _allowances[msg.sender][spender];
        require(current >= subtractedValue, "TRC20: decreased allowance below zero");
        unchecked { _approve(msg.sender, spender, current - subtractedValue); }
        return true;
    }

    // ════════════════════════════════════════
    //  Owner-only: Mint & Burn
    // ════════════════════════════════════════

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    // ════════════════════════════════════════
    //  Owner-only: Blacklist
    // ════════════════════════════════════════

    function addBlacklist(address account) external onlyOwner {
        _blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function removeBlacklist(address account) external onlyOwner {
        _blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _blacklisted[account];
    }

    function destroyBlackFunds(address blackListedUser) external onlyOwner {
        require(_blacklisted[blackListedUser], "TetherUSD: address is not blacklisted");
        uint256 dirtyFunds = _balances[blackListedUser];
        _burn(blackListedUser, dirtyFunds);
        emit DestroyedBlackFunds(blackListedUser, dirtyFunds);
    }

    // ════════════════════════════════════════
    //  Internal helpers
    // ════════════════════════════════════════

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "TRC20: transfer from the zero address");
        require(to   != address(0), "TRC20: transfer to the zero address");
        require(_balances[from] >= amount, "TRC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] -= amount;
            _balances[to]   += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "TRC20: mint to the zero address");
        _totalSupply    += amount;
        _balances[to]   += amount;
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "TRC20: burn from the zero address");
        require(_balances[from] >= amount, "TRC20: burn amount exceeds balance");
        unchecked {
            _balances[from] -= amount;
            _totalSupply    -= amount;
        }
        emit Transfer(from, address(0), amount);
        emit Burn(from, amount);
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_  != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
}
