//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//import "./PancakeFactory.sol";
import "./PancakeRouter.sol";
import "./Open-Zeppelin.sol";

import "hardhat/console.sol";

contract XDAO01Up is
Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable, OwnableUpgradeable {


    using SafeMath for uint256;


    /////////////////////////////////////////////////////////////////////////////////////
    //
    //                      These variables are not deployed.
    //
    /////////////////////////////////////////////////////////////////////////////////////

    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1e15 * 10 ** uint256(DECIMALS);

    /////////////////////////////////////////////////////////////////////////////////////
    //
    //                      Borrows from ERC20Upgradeable 
    //
    // _transfer(...) is overriden.
    //
    /////////////////////////////////////////////////////////////////////////////////////

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal {
        __Context_init_unchained();
        __Ownable_init();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the bep20 token owner which is necessary for binding with bep2 token
     */
	function getOwner() public view returns (address) {
		return owner();
	}

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        //unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
        //}

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        //unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        //}

        return true;
    }



    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add( amount);
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        //unchecked {
        _balances[account] = accountBalance.sub(amount);
        //}
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    /////////////////////////////////////////////////////////////////////////////////////
    //
    //                      Borrows from ERC20BurnableUpgradeable 
    //
    /////////////////////////////////////////////////////////////////////////////////////

    function __ERC20Burnable_init() internal {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        //unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
        //}
        _burn(account, amount);
    }

    /////////////////////////////////////////////////////////////////////////////////////
    //
    //                      Borrows from ERC20PresetFixedSupplyUpgradeable 
    //
    /////////////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    function __ERC20PresetFixedSupply_init(
        string memory __name,
        string memory __symbol,
        uint256 initialSupply,
        address owner
    ) internal initializer {
        __Context_init_unchained();
		__Ownable_init_unchained();
        __ERC20_init_unchained(__name, __symbol);
        __ERC20Burnable_init_unchained();
        __ERC20PresetFixedSupply_init_unchained(initialSupply, owner);
        //__XDAO_init_unchained();
    }

    function __ERC20PresetFixedSupply_init_unchained(
        uint256 initialSupply,
        address owner
    ) internal initializer {
        _mint(owner, initialSupply);
    }

	///////////////////////////////////////////////////////////////////////////////////////////////
	//
	// The state data items of this contract are packed below, after those of the base contracts.
	// The items are tightly arranged for efficient packing into 32-bytes slots.
	// See https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html for more.
	//
	// Do NOT make any changes to this packing when you upgrade this implementation.
	// See https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies for more.
	//
	//////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public constant FEE_MAGNIFIER = 100000; // Five zeroes.
    uint256 public constant FEE_HUNDRED_PERCENT = FEE_MAGNIFIER * 100;

    uint256 public constant FEES_BURNT = 31400;      // this/FEE_MAGNIFIER = 0.31400 or 31.400%
    uint256 public constant FEES_REWARDS = 1000;        // this/FEE_MAGNIFIER = 0.01000 or 1.000%
    uint256 public constant FEES_LIQUIDITY = 2300;        // this/FEE_MAGNIFIER = 0.02300 or 2.300%

    address public constant ADDR_STORES_BURN = 0x8887Df2F38888117c0048eAF9e26174F2E75B8eB; // Account1
    address public constant ADDR_STORES_REWARDS = 0x03002f489a8D7fb645B7D5273C27f2262E38b3a1; // Account2
    address public constant ADDR_STORES_LIQUIDITY = 0x10936b9eBBB82EbfCEc8aE28BAcC557c0A898E43; // Account3

    uint256 public constant PULSES_VOTE_BURN = 70;      // this/FEE_MAGNIFIER = 0.00070 or 0.070%
    uint256 public constant PULSES_ALL_BURN = 777;        // this/FEE_MAGNIFIER = 0.00777 or 0.777%
    uint256 public constant PULSES_LP_REWARDS = 690;        // this/FEE_MAGNIFIER = 0.00690 or 0.690%
    
    uint256 public constant MAX_TRANSFER_AMOUNT = 1e12 * 10**uint256(DECIMALS);
    uint256 public constant QUANTUM_BURN = 1e5 * 10**uint256(DECIMALS);
    uint256 public constant QUANTUM_REWARDS = 2e5 * 10**uint256(DECIMALS);
    uint256 public constant QUANTUM_LIQUIDITY = 3e5 * 10**uint256(DECIMALS);
    uint256 public constant MIN_HODL_TIME_SECONDS  = 31556952; // A year spans 31556952 seconds.

    address public constant ADDR_HERTZ_REWARDS = 0x5cA00f843cd9649C41fC5B71c2814d927D69Df95; // Account4

	using SafeMath for uint256;

	struct Fees {
    	uint256 burn;
		uint256 rewards;
		uint256 liquidity;
	}

	struct StoreAddresses {
		address burn;
		address rewards;
		address liquidity;
 	}

	struct StoreBalances {
		uint256 burn;
        uint256 rewards;
		uint256 liquidity;
	}

    struct Quantums {
        uint256 burn;
        uint256 rewards;
        uint256 liquidity;
    }

	struct Pulses {
    	uint256 vote_burn;
		uint256 all_burn;
		uint256 lp_rewards;
	}

    event SetFees(Fees _fees);
    event SetStoreAddresses(StoreAddresses _storeAddresses);
    event SetPulses(Pulses _pulses);
    event SetMaxTransferAmount(uint256 _maxTransferAmount);
    event SwapAndLiquify(uint256 tokenSwapped, uint256 etherReceived, uint256 tokenLiquified, uint256 etherLiquified );
    event TransferEther(address sender, address recipient, uint256 amount);

    Fees public fees;
    StoreAddresses public storeAddresses;
    Pulses public pulses;
    Quantums public quantums;
    uint256 public maxTransferAmount;

   	mapping(address => uint) public lastTransferTime;
    uint256 public minHoldTimeSec;

	IPancakeRouter02 public dexRouter;
	address public pairWithWETH;
    address public pairWithHertz;

    mapping(address => bool) public isHolder;
    address[] public holders;

    bool public autoManagement; // Place this bool type at the bottom of storage.
    address public hertztoken;
    address public hertzRewardsAddress;

	///////////////////////////////////////////////////////////////////////////////////////////////
	//
	// The logic (operational code) of the implementation.
	// You can upgrade this part of the implementation freely: 
	// - add new state data itmes.
	// - override, add, or remove.
	// You cannot make changes to the above existing state data items.
	//
	//////////////////////////////////////////////////////////////////////////////////////////////


    function initialize(address _dexRouter, address _hertztoken) public virtual initializer { // onlyOwwer is impossible call here.
        __Ownable_init();
        __ERC20PresetFixedSupply_init("XDAO Utility Token", "XO", INITIAL_SUPPLY, owner());
        __XDAO_init(_dexRouter, _hertztoken);
    }

    function __XDAO_init(address _dexRouter, address _hertztoken) public onlyOwner {
        __XDAO_init_unchained(_dexRouter, _hertztoken);
    }


    function __XDAO_init_unchained(address _dexRouter, address _hertztoken) public onlyOwner {
        revertToInitialSettings(_dexRouter, _hertztoken);
    }

    function revertToInitialSettings(address _dexRouter, address _hertztoken) public virtual onlyOwner {
        Fees memory _fese = Fees(FEES_BURNT, FEES_REWARDS, FEES_LIQUIDITY);
        setFees(_fese);

        StoreAddresses memory _addresses = StoreAddresses(ADDR_STORES_BURN, ADDR_STORES_REWARDS, ADDR_STORES_LIQUIDITY);
        setStoreAddresses(_addresses);

        Pulses memory _pulses = Pulses(PULSES_VOTE_BURN, PULSES_ALL_BURN, PULSES_LP_REWARDS);
        setPulses(_pulses);

        quantums = Quantums(QUANTUM_BURN, QUANTUM_REWARDS, QUANTUM_LIQUIDITY);

		maxTransferAmount = MAX_TRANSFER_AMOUNT;
        minHoldTimeSec = MIN_HODL_TIME_SECONDS;

        autoManagement = true;

        dexRouter = IPancakeRouter02(_dexRouter);
        pairWithWETH = createPoolWithWETH(_dexRouter);
        pairWithHertz = createPoolWithToken(_dexRouter, _hertztoken);
        hertztoken = _hertztoken;
        hertzRewardsAddress = ADDR_HERTZ_REWARDS;
    }

    function setFees(Fees memory _fees) public virtual onlyOwner {
        uint256 total;
        require(_fees.burn <= FEE_HUNDRED_PERCENT, "Burn fee out of range");
        require(_fees.rewards <= FEE_HUNDRED_PERCENT, "Rewards fee out of range");
        require(_fees.liquidity <= FEE_HUNDRED_PERCENT, "Liquidity fee out of range");
        total = _fees.burn + _fees.rewards + _fees.liquidity;
        require(total <= FEE_HUNDRED_PERCENT, "Total fee out of range");

        fees = _fees;
        emit SetFees(_fees);
    }

    function storeBalances() external view returns(StoreBalances memory balances) {
        balances.burn= _balances[storeAddresses.burn];
        balances.rewards = _balances[storeAddresses.rewards];
        balances.liquidity = _balances[storeAddresses.liquidity];
    }

	function setStoreAddresses(StoreAddresses memory _storeAddresses) virtual public onlyOwner {
        require(_storeAddresses.burn != address(0) && _storeAddresses.burn != address(this), "Invalid fee address");
        require(_storeAddresses.rewards != address(0) && _storeAddresses.burn != address(this), "Invalid fee address");
        require(_storeAddresses.liquidity != address(0) && _storeAddresses.burn != address(this), "Invalid fee address");

        storeAddresses = _storeAddresses;
        emit SetStoreAddresses(_storeAddresses);
	}

    function setPulses(Pulses memory _pulses) public virtual onlyOwner {
        require(_pulses.vote_burn <= FEE_HUNDRED_PERCENT, "Vote-burn rate of range");
        require(_pulses.all_burn <= FEE_HUNDRED_PERCENT, "All-burn rate out of range");
        require(_pulses.lp_rewards <= FEE_HUNDRED_PERCENT, "LP-rewards rate out of range");

        pulses = _pulses;
        emit SetPulses(_pulses);
    }

    function setQuantums(Quantums memory _quantums) public virtual onlyOwner {
        require(_quantums.burn > 0, "Invalid quantum");
        require(_quantums.rewards > 0, "Invalid quantum");
        require(_quantums.liquidity > 0, "Invalid quantum");

        quantums = _quantums;
    }

	function setMaxTransferAmount(uint256 _maxTransferAmount) virtual external onlyOwner {
		maxTransferAmount = _maxTransferAmount;
        emit SetMaxTransferAmount(_maxTransferAmount);
	}

    function setMinHoldTimeSec( uint256 _minHoldTimeSec ) virtual external onlyOwner {
        minHoldTimeSec = _minHoldTimeSec;
    }

    function setAutoManagement( bool _autoManagement ) external virtual onlyOwner {
        autoManagement = _autoManagement;
    }

	bool managing;
	modifier lockManaging {
		require( ! managing, "Nested managing.");
		managing = true;
		_;
		managing = false;
	}

	function createPoolWithWETH( address _routerAddress ) virtual public onlyOwner returns(address pool) {
        IPancakeRouter02 _dexRouter = IPancakeRouter02(_routerAddress);
        pool = IPancakeFactory(_dexRouter.factory()).getPair(address(this), _dexRouter.WETH());
        if(pool == address(0)) {
    		pool = IPancakeFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        }
    }   

	function createPoolWithToken(address _routerAddress, address token ) virtual public onlyOwner returns(address pool)  {
		IPancakeRouter02 _dexRouter = IPancakeRouter02(_routerAddress);
        pool = IPancakeFactory(_dexRouter.factory()).getPair(address(this), token);
        if(pool == address(0)) {
    		pool = IPancakeFactory(_dexRouter.factory()).createPair(address(this), token);
        }
    }

    //====================================================================================================

    function _sureTransfer(address sender, address recipient, uint256 amount) internal virtual {
        // No check at all.
        _balances[sender] -= amount;
        _balances[recipient] += amount;
    }

    uint256 internal _call_level;
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        _call_level += 1;

        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        if(_call_level == 1 &&  ! _isUnlimitedTransfer(sender, recipient) ) {
            require(amount <= maxTransferAmount, "Transfer exceeds limit");
        }

        _balances[sender] -= amount;

   		if(_call_level == 1 && ! _isFeeFreeTransfer(sender, recipient) ) {
            amount -= _payFees(sender, recipient, amount);
        }

        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        if(_call_level == 1 &&  autoManagement && ! _isUnmanageableTransfer(sender, recipient) ) {
            uint256 gasfee_left = gasleft() * tx.gasprice;
            bool worked = _cleanupStoresInQuantum();

            //Assuming "function receive() external payable" exists.
            if( worked == true ) {
                uint256 gasfee_used = gasfee_left - gasleft() * tx.gasprice;
                (bool sent, bytes memory data) = tx.origin.call{ value: gasfee_used } ("");
                require(sent, "Failed to compensate");
                emit TransferEther(address(this), tx.origin, gasfee_used);
            }
        }

        _afterTokenTransfer(sender, recipient, amount);

        _call_level -= 1;
    }

    function _isUnlimitedTransfer(address sender, address recipient) internal view virtual returns (bool unlimited) {
        // Start from highly frequent occurences.
        unlimited = 
            _isBidirUnlimitedAddress(sender)
            || _isBidirUnlimitedAddress(recipient);
    }

    function _isBidirUnlimitedAddress(address _address) internal view virtual returns (bool unlimited) {
        unlimited = 
               _address == owner()
            || _address == pairWithWETH
            || _address == pairWithHertz
            || _address == storeAddresses.burn
            || _address == storeAddresses.rewards
            || _address == storeAddresses.liquidity;
    }

    function _isFeeFreeTransfer(address sender, address recipient) internal view virtual returns (bool feeFree) {
        // Start from highly frequent occurences.
        feeFree = 
            _isBidirFeeFreeAddress(sender) 
            || _isBidirFeeFreeAddress(recipient);
    }

    function _isBidirFeeFreeAddress(address _address) internal view virtual returns (bool feeFree) {
        feeFree =
               _address == owner()
            || _address == pairWithWETH
            || _address == pairWithHertz
            || _address == storeAddresses.burn
            || _address == storeAddresses.rewards
            || _address == storeAddresses.liquidity;
    }

    function _isUnmanageableTransfer(address sender, address recipient) internal virtual view returns(bool _unmanageable) {
        _unmanageable =
            _isBidirUnmanageableAddress(sender)
            || _isBidirUnmanageableAddress(recipient);
    }

    function _isBidirUnmanageableAddress(address _address) internal view virtual returns (bool feeFree) {
        feeFree =
               _address == owner()
            || _address == pairWithWETH
            || _address == pairWithHertz
            || _address == storeAddresses.burn
            || _address == storeAddresses.rewards
            || _address == storeAddresses.liquidity;
    }

    function _payFees(address sender, address recipient, uint256 principal) internal virtual returns(uint256 total) {
        uint256 fee = principal.mul(fees.burn).div(FEE_MAGNIFIER);
        _balances[storeAddresses.burn] += fee;
        total += fee;
        emit Transfer(sender, storeAddresses.burn, fee);
        // console.log("marketing fee : ", fee);

        fee = principal.mul(fees.rewards).div(FEE_MAGNIFIER);
        _balances[storeAddresses.rewards] += fee;
        total += fee;
        emit Transfer(sender, storeAddresses.rewards, fee);
        // console.log("charity fee : ", fee);

        fee = principal.mul(fees.liquidity).div(FEE_MAGNIFIER);
        _balances[storeAddresses.liquidity] += fee;
        total += fee;
        emit Transfer(sender, storeAddresses.liquidity, fee);
        // console.log("lottery fee : ", fee);

        lastTransferTime[sender] = block.timestamp;
        lastTransferTime[recipient] = block.timestamp;
	}

    function _cleanupStoresInQuantum() internal virtual returns(bool worked) {
        // 1. Empty the storeAddresses.burn account completely. Do not change the order.
        if( _balances[storeAddresses.burn] > quantums.burn) {
            _cleanupBurnStore();
            worked = true;
        }

        // 2. Empty the storeAddresses.rewards account completely. Do not change the order.
        if( _balances[storeAddresses.rewards] > quantums.rewards) {
            _cleanupRewardsStore();
            worked = true;
        }

        // 3. Try and Empty the storeAddresses.liquidity account completely. Do not change the order.
        if( _balances[storeAddresses.liquidity] > quantums.liquidity) {
            _cleanupLiquidityStore();
            worked = true;
        }
    }

    function cleanupBurnStore() external virtual onlyOwner {
        _cleanupBurnStore();
    }

    function _cleanupBurnStore() internal virtual {
        _burn(storeAddresses.burn, _balances[storeAddresses.burn]); // burn all.
    }

    function cleanupRewardsStore() external virtual onlyOwner {
        _cleanupRewardsStore();
    }

    function _cleanupRewardsStore() internal virtual lockManaging {
        // No! require(_balances[address(this)] == uint256(0), "Non-empty store space");
        uint256 amount = _balances[storeAddresses.rewards];
        _sureTransfer(storeAddresses.rewards, address(this), amount);
        _swapForToken(amount, hertztoken, hertzRewardsAddress);
    }

    function cleanupLiquidityStore() external virtual onlyOwner {
        _cleanupLiquidityStore();
    }
    
    function _cleanupLiquidityStore() internal virtual lockManaging {
        uint256 etherInitial = address(this).balance;
		uint256 amountToLiquify = _balances[storeAddresses.liquidity];

		if (amountToLiquify >= quantums.liquidity) {
            uint256 tokenForEther;
            {
                uint256 _reserveToken; uint256 _reserveEther;

                address token0 = IPancakePair(pairWithWETH).token0();
                if (address(this) == token0) {
                    (_reserveToken, _reserveEther,) = IPancakePair(pairWithWETH).getReserves();
                } else {
                    (_reserveEther, _reserveToken,) = IPancakePair(pairWithWETH).getReserves();
                }
                uint256 b = 1998 * _reserveToken;

                // tokenForEther <= Ideal, leading to the token side, and not the ether side, remaining.
                tokenForEther = ( sqrt( b.mul(b) + 3992000 * _reserveToken * amountToLiquify) - b ) / 1996;
            }

            uint256 balance0 = _balances[address(this)];
            _sureTransfer(storeAddresses.liquidity, address(this), _balances[storeAddresses.liquidity]);
            _swapForEther(tokenForEther);

            uint256 tokenAfterSwap = _balances[address(this)];
            uint256 etherAfterSwap = address(this).balance;

            uint256 tokenToAddLiq = amountToLiquify - tokenForEther;
            uint256 etherToAddLiq = etherAfterSwap - etherInitial;
            _addLiquidity(tokenToAddLiq, etherToAddLiq); // No gurantee that the both amounts are deposited without refund.

            uint256 tokenAfterAddLiq = _balances[address(this)];
            uint256 etherAfterAddLiq = address(this).balance;
            require(etherAfterAddLiq >= etherInitial, "\tEther loss in address(this) account");

            console.log("\tOn-chain messages...");
            console.log("\tTotal XO wei that were provided for liquefying:      ", amountToLiquify);
            console.log("\t1. XO wei that were forwarded to the pool directly:  ", tokenToAddLiq);
            console.log("\t2. XO wei that were sold for FTM at the dex:         ", tokenForEther);
            console.log("\t3. FTM wei that were bought with the XOs at the dex: ", etherAfterSwap - etherInitial);
            console.log("\t4. FTM wei that were forwarded to the pool:          ", etherAfterSwap - etherInitial);
            console.log("\t5. XO wei that the pool didn't accept:               ", tokenAfterAddLiq - balance0);
            console.log("\t6. FTM wei that the pool didn't accept:              ", etherAfterAddLiq - etherInitial);
            console.log("\t7. PPM that failed to be accepted by the pool:       ", (tokenAfterAddLiq - balance0) * 10**6 / amountToLiquify );

            emit SwapAndLiquify(
                tokenForEther,                      // tokenSwapped. token decreased by swap
                etherAfterSwap - etherInitial,      // etherReceived. ether increased by swap
                tokenAfterAddLiq - tokenAfterSwap,  // tokenLiquified. token decreased by addLiquidity
                etherAfterAddLiq - etherAfterSwap   // etherLiquified. ether decreased by addLiquidity
            );
		}
	}

	function _swapForEther(uint256 tokenAmount) virtual internal {
        require( _balances[address(this)] >= tokenAmount, "" );

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // The router's assumption: the path[0] token has the address(this) account, and the amountIn amount belongs to that account.
        // The router tries to transferFrom( token = path[0], sender = msg.sender, recipient = pair, amount = amountIn );
        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),  // targetAccount
            block.timestamp
        );
    }

	function _swapForToken(uint256 amountIn, address targetToken, address targetAccount) virtual internal {
        require( _balances[address(this)] >= amountIn, "" );

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = targetToken;

        // The router's assumption: the path[0] token has the address(this) account, and the amountIn amount belongs to that account.
        // The router tries to transferFrom( token = path[0], sender = msg.sender, recipient = pair, amount = amountIn );
        _approve(address(this), address(dexRouter), amountIn);  

        dexRouter.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            targetAccount,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) virtual internal {
        // The router's assumption: the path[0] token has the address(this) account, and the amountIn amount belongs to that account.
        // The router tries to transferFrom( token = path[0], sender = msg.sender, recipient = pair, amount = amountIn );
        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), // What if the owner changes? Why not use a 3rd, neutral address?
            block.timestamp
        );
    }

    receive() external payable {}

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Calculate the square root of the perfect square of a power of two that is the closest to x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        //unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        //}
    }

    uint256[10] private __gap;
}
