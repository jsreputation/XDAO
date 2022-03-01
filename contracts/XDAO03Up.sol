//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PancakeRouter.sol";
import "./Open-Zeppelin.sol";
import "./AnalyticMath.sol";

import "hardhat/console.sol";

contract XDAO03Up is
Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable, OwnableUpgradeable, AnalyticMath {
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

    uint256 public constant MAGPOWER = 5;
    uint256 public constant MAGNIFIER = 10 ** MAGPOWER;
    uint256 public constant HUNDRED_PERCENT = MAGNIFIER * 100;

    uint256 public constant FEE_TRADE_BURN = 31416;     // this/MAGNIFIER = 0.31416 or 31.416%
    uint256 public constant FEE_SHIFT_BURN = 13374;     // this/MAGNIFIER = 0.13374 or 13.374%
    uint256 public constant FEE_TRADE_REWARDS = 10000;  // this/MAGNIFIER = 0.10000 or 10,000%

    uint256 public constant INTERVAL_VOTE_BURN = 3600 * 12;
    uint256 public constant INTERVAL_ALL_BURN = 3600 * 24;
    uint256 public constant INTERVAL_LP_REWARDS = 3600 * 12;
    uint256 public constant MIN_INTERVAL_SEC = 60;      // 

    uint256 public constant IMPACT_VOTE_BURN = 70;      // this/MAGNIFIER = 0.00070 or 0.070%
    uint256 public constant IMPACT_ALL_BURN = 777;        // this/MAGNIFIER = 0.00777 or 0.777%
    uint256 public constant IMPACT_LP_REWARDS = 690;        // this/MAGNIFIER = 0.00690 or 0.690%    

    address public constant ADDR_HERTZ_REWARDS = 0x5cA00f843cd9649C41fC5B71c2814d927D69Df95; // Account4

	using SafeMath for uint256;

    enum TransferType {
        OTHER, SELL_SURE, BUY_SURE, SWAP_SURE, SELL_PRESUMED, BUY_PRESUMED, SWAP_PRESUMED, SHIFT_SEND, SHIFT_RECEIVE, SHIFT_TRANSCEIVE }
    enum FeeType { TRADE_BURN, SHIFT_BURN, TRADE_REWARDS }
    enum PulseType { VOTE_BURN, ALL_BURN, LP_REWARDS }
    struct Fees {
        uint256 trade_burn;
        uint256 shift_burn;
        uint256 trade_rewards;
    }
    struct Pulse {
        uint256 intervalSec;
        uint256 impactScale;
    }
    struct Holder {
        uint256 lastTransferTime;
        uint256 lastCheckTimeSec;
    }
    event SetFees(Fees _fees);
    event SetPulse_VoteBurn(Pulse _pulse);
    event SetPulse_AllBurn(Pulse _pulse);
    event SetPulse_LpRewards(Pulse _pulse);
    event SwapAndLiquify(uint256 tokenSwapped, uint256 etherReceived, uint256 tokenLiquified, uint256 etherLiquified );

    uint256 public fee_trade_burn;
    uint256 public fee_shift_burn;
    uint256 public fee_trade_rewards;

    Pulse public pulse_vote_burn;
    Pulse public pulse_all_burn;
    Pulse public pulse_lp_rewards;

   	mapping(address => Holder) public holders;
    uint256 public beginingTimeSec;

	IPancakeRouter02 public dexRouter;
	address public pairWithWETH;
    address public pairWithHertz;

    mapping(address => bool) public knownDexContracts;

    bool public autoPulse; // Place this bool type at the bottom of storage.

    address public hertztoken;
    address public hertzRewardsAddress;
    AnalyticMath public math;

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

        beginingTimeSec = block.timestamp;
    }

    function revertToInitialSettings(address _dexRouter, address _hertztoken) public virtual onlyOwner {

        uint256 _fee_trade_burn = FEE_TRADE_BURN;
        uint256 _fee_shift_burn = FEE_SHIFT_BURN;
        uint256 _fee_lp_rewards = FEE_TRADE_BURN;

        Fees memory _fees = Fees(_fee_trade_burn, _fee_shift_burn, _fee_lp_rewards);
        setFees(_fees);

        Pulse memory _pulse = Pulse(INTERVAL_VOTE_BURN, IMPACT_VOTE_BURN);
        setPulse_VoteBurn(_pulse);

        _pulse = Pulse(INTERVAL_ALL_BURN, IMPACT_ALL_BURN);
        setPulse_AllBurn(_pulse);

        _pulse = Pulse(INTERVAL_LP_REWARDS, IMPACT_LP_REWARDS);
        setPulse_LpRewards(_pulse);

        autoPulse = true;

        dexRouter = IPancakeRouter02(_dexRouter);
        pairWithWETH = createPoolWithWETH(_dexRouter);
        pairWithHertz = createPoolWithToken(_dexRouter, _hertztoken);
        hertztoken = _hertztoken;
        hertzRewardsAddress = ADDR_HERTZ_REWARDS;
        //math = AnalyticMath(_math);

        knownDexContracts[_dexRouter] = true;
        knownDexContracts[pairWithWETH] = true;
        knownDexContracts[pairWithHertz] = true;
    }

    function setFees(Fees memory _fees) public virtual onlyOwner {
        uint256 total;
        require(_fees.trade_burn <= HUNDRED_PERCENT, "Fee rate out of range");
        require(_fees.shift_burn <= HUNDRED_PERCENT, "Fee rate out of range");
        require(_fees.trade_rewards <= HUNDRED_PERCENT, "Fee rate out of range");
        total = _fees.trade_burn + _fees.shift_burn + _fees.trade_rewards;
        require(total <= HUNDRED_PERCENT, "Fee rate out of range");

        fee_trade_burn = _fees.trade_burn;
        fee_shift_burn = _fees.shift_burn;
        fee_trade_rewards = _fees.trade_rewards;

        emit SetFees(_fees);
    }

    function setPulse_VoteBurn(Pulse memory _pulse) public virtual onlyOwner {
        require(_pulse.intervalSec > MIN_INTERVAL_SEC, "IntervalSec out of range");
        require(_pulse.impactScale <= HUNDRED_PERCENT, "ImpactScale out of range");

        pulse_vote_burn = _pulse;
        emit SetPulse_VoteBurn(_pulse);
    }

    function setPulse_AllBurn(Pulse memory _pulse) public virtual onlyOwner {
        require(_pulse.intervalSec > MIN_INTERVAL_SEC, "IntervalSec out of range");
        require(_pulse.impactScale <= HUNDRED_PERCENT, "ImpactScale out of range");

        pulse_all_burn = _pulse;
        emit SetPulse_AllBurn(_pulse);
    }

    function setPulse_LpRewards(Pulse memory _pulse) public virtual onlyOwner {
        require(_pulse.intervalSec > MIN_INTERVAL_SEC, "IntervalSec out of range");
        require(_pulse.impactScale <= HUNDRED_PERCENT, "ImpactScale out of range");

        pulse_all_burn = _pulse;
        emit SetPulse_LpRewards(_pulse);
    }

    function setAutoPulse( bool _autoPulse ) external virtual onlyOwner {
        autoPulse = _autoPulse;
    }

	bool hooked;
	modifier lockHook {
		require( ! hooked, "Nested hook");
		hooked = true;
		_;
		hooked = false;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _hookForPulses(from);
        _hookForPulses(to);
    }

   
    uint256 internal _call_level;
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        _call_level += 1;

        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

		if(_call_level == 1 && ! _isFeeFreeTransfer(sender, recipient) ) {
            amount -= _payFees2(sender, recipient, amount); // May revert if it's a swap transfer.
        }

        _balances[sender] = _balances[sender].sub( amount); // May revert if sender is a swapper and paid outside of original "amount"
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);

        holders[sender].lastTransferTime = block.timestamp;
        holders[recipient].lastTransferTime = block.timestamp;

        _call_level -= 1;
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
            || _address == pairWithHertz;
    }

    function _isHookable(address sender, address recipient) internal virtual view returns(bool _unmanageable) {
        _unmanageable =
            _isBidirHookableAddress(sender)
            || _isBidirHookableAddress(recipient);
    }

    function _isBidirHookableAddress(address _address) internal view virtual returns (bool feeFree) {
        feeFree =
               _address == owner()
            || _address == pairWithWETH
            || _address == pairWithHertz;
    }

    /**
    * This function is followed by the following lines, in the _transfer function.
    *  amount -= _payFees2(sender, recipient, amount);
    *  _balances[sender] = _balances[sender].sub( amount);
    *  _balances[recipient] = _balances[recipient].add(amount);
    **/
    function _payFees2(address sender, address recipient, uint256 principal) internal virtual returns(uint256 feesPaid) {
        TransferType tType = _getTransferType(sender, recipient);

        if(
            tType == TransferType.SELL_SURE
            || tType == TransferType.SELL_PRESUMED
            || tType == TransferType.BUY_SURE
            || tType == TransferType.BUY_PRESUMED
        ) {
            // If it's SELL, then the Seller == sender will pay 'feedPaid' > 0, effectively.
            // If it's BUY, then the Buyer == recipient will pay 'feesPaid' > 0, effiectively.
            // In both cases, payments are safe because they are debited from the 'principal', 
            // which is available from the sender's balance.
            // The underlying assumption: sending goes ahead of receiving in a Dex-mediated swap.
            // The assumption is quite natural, is the case in all known Dexes, and might be proven.


            // 31.4159265359% Fee burned on buys and sells.
            uint256 fee;
            fee = principal.mul(fee_trade_burn).div(MAGNIFIER);
            burnFrom(sender, fee); // burnt
            feesPaid += fee;

            // 1–55% Fee sold to HTZ and added to XDAO lps airdrop rewards depending on how much you are purchasing or selling. 
            fee = principal.mul(fee_trade_rewards).div(MAGNIFIER);
            _transfer(sender, address(this), fee);
            _swapForToken(fee, hertztoken, hertzRewardsAddress);
            feesPaid += fee;

        } else if (
            tType == TransferType.SWAP_SURE
            || tType == TransferType.SWAP_PRESUMED
        ) {
            // Both the Seller == sender and Buyer == recipient should pay.
            // We do not know who will pay 'feesPaid' > 0 effectively.
            // The Seller and Buyer have to pay outside of the principal.
            // So, the recipient's payment is not guaranteed.

            // 13.37420% fee on transfers burned.

            uint256 fee;
            fee = principal.mul(fee_trade_burn).div(MAGNIFIER);
            burnFrom(sender, fee); // sender pays for burn
            burnFrom(recipient, fee); // recipient pays for burn. // May revert.

            fee = principal.mul(fee_trade_rewards).div(MAGNIFIER);
            _transfer(sender, address(this), fee);
            _transfer(recipient, address(this), fee); // May revert.
            _swapForToken(fee, hertztoken, hertzRewardsAddress);

            feesPaid = 0; // just confirm.

        } else if(
            tType == TransferType.SHIFT_SEND
            || tType == TransferType.SHIFT_RECEIVE
            || tType == TransferType.SHIFT_TRANSCEIVE
        ) {
            // This is a uni-directional transaction.
            // The transfer itself pays, or the sender and recipient share the payment.
            uint256 fee;
            fee = principal.mul(fee_shift_burn).div(MAGNIFIER);
            burnFrom(sender, fee); // burnt
            feesPaid += fee;
        }
    }


    function _isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function _getTransferType(address sender, address recipient) internal virtual returns(TransferType) {
        if(! _isContract(msg.sender) ) {
            if( ! _isContract(sender) ) {
                if ( ! _isContract(recipient) ) {
                    return TransferType.SHIFT_TRANSCEIVE;
                } else {
                    return TransferType.SHIFT_SEND;
                }
            } else {
                if ( ! _isContract(recipient) ) {
                    return TransferType.SHIFT_RECEIVE;
                } else {
                    return TransferType.OTHER;
                }
            }
        } else {
            if( ! _isContract(sender) ) {
                if( ! _isContract(recipient) ) {
                    if (knownDexContracts[msg.sender] == true ) {
                        return TransferType.SWAP_SURE;
                    } else {
                        return TransferType.SWAP_PRESUMED;
                    }
                } else {
                    if(knownDexContracts[recipient] == true || knownDexContracts[msg.sender] == true) {
                        return TransferType.SELL_SURE;
                    } else {
                        return TransferType.SELL_PRESUMED;
                    }
                }
            } else {
                if( ! _isContract(recipient) ) {
                    if(knownDexContracts[sender] == true || knownDexContracts[msg.sender] == true) {
                        return TransferType.BUY_SURE;
                    } else {
                        return TransferType.BUY_PRESUMED;
                    }
                } else {
                    return TransferType.OTHER;
                }
            }
        }
    }

    function getBalanceInCyberswap(address holderAddress) virtual public returns(uint256) {
        return 0;
    }

    function debitBalanceInCyberswap(address holderAddress, uint256 amount) virtual public {
    }

    function getBalanceInAgency(address holderAddress) virtual public returns(uint256) {
        return 0;
    }
    function debitBalanceInAgency(address holderAddress, uint256 amount) virtual public {
    }

    function _hookForPulses(address holderAddress) virtual internal returns (bool worked) {
       Holder storage holder = holders[holderAddress];
       if(holder.lastCheckTimeSec == block.timestamp) return false;

        uint256 timeLapsed = block.timestamp - (holder.lastCheckTimeSec != 0 ? holder.lastCheckTimeSec : beginingTimeSec);
        uint256 missingChecks; uint256 rate_p; uint256 rate_q; uint256 tokens; uint256 agencyTokens; uint tokensToBurn;

        //---------------------- vote_burn, 12 hours ------------------------------
        // 0.07% of tokens in the Agency dapp actively being used for voting burned every 12 hours.
        missingChecks = timeLapsed / pulse_all_burn.intervalSec;
        if(missingChecks > 0) {
            (rate_p, rate_q) = pow(MAGNIFIER.mul(MAGNIFIER - pulse_vote_burn.impactScale), MAGNIFIER, missingChecks, uint256(1));
            require(rate_p <= rate_q, "Invalid rate");
            agencyTokens = getBalanceInAgency(holderAddress);
            tokens = agencyTokens.mul(rate_p).div(rate_q);
            debitBalanceInAgency(holderAddress, tokens);
            burnFrom(holderAddress, tokens);
            agencyTokens -= tokens;
            worked = true;
        }

        //---------------------- all_burn, 24 hours, burn tokens (not in Cyberswap/Agency) ------------------------------
        // 0.777% of tokens(not in Cyberswap/Agency dapp) burned each 24 hours from users wallets. 
        missingChecks = timeLapsed / pulse_all_burn.intervalSec;
        if(missingChecks > 0) {
            (rate_p, rate_q) = pow(MAGNIFIER.mul(MAGNIFIER - pulse_all_burn.impactScale), MAGNIFIER, missingChecks, uint256(1));
            require(rate_p <= rate_q, "Invalid rate");
            tokens = worked == true? agencyTokens : getBalanceInAgency(holderAddress);
            tokens += getBalanceInCyberswap(holderAddress);
            tokens = balanceOf(holderAddress).sub(tokens);
            tokens = tokens.mul(rate_p).div(rate_q);
            burnFrom(holderAddress, tokens);
            worked = true;
        }

        //---------------------- lp_rewards, 12 hours ------------------------------
        // 0.69% of XDAO/FTM LP has the XDAO side sold for FTM, then the FTM is used to buy HTZ which is added to XDAO lps airdrop rewards every 12 hours.
        missingChecks = timeLapsed / pulse_lp_rewards.intervalSec;
        if(missingChecks > 0) {
            (rate_p, rate_q) = pow(MAGNIFIER.mul(MAGNIFIER - pulse_lp_rewards.impactScale), MAGNIFIER, missingChecks, uint256(1));

            uint256 reserveThis; uint256 reserveWeth;
            bool thisIsToken0 = IPancakePair(pairWithWETH).token0() == address(this);
            (uint256 reserve0, uint256 reserve1, ) = IPancakePair(pairWithWETH).getReserves();
            (reserveThis, reserveWeth) = thisIsToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
            tokens = IPancakePair(pairWithWETH).totalSupply();
            tokens = tokens.mul(rate_p).div(rate_q);

            //------------------ Under construction --------------------


            // // No! require(_balances[address(this)] == uint256(0), "Non-empty store space");
            // uint256 amount = _balances[storeAddresses.rewards];
            // _sureTransfer(storeAddresses.rewards, address(this), amount);

            // _swapForToken(amount, hertztoken, hertzRewardsAddress);


            worked = true;
        }

        if( worked == true ) {
            holder.lastCheckTimeSec = block.timestamp;
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
