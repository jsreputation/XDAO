(This document has images and video.)

# Description

This project builds for the on-chain part of the XDAO programme. 

Hello,
We have developed a two token system where the governance token is either decaying, used for reputation, or used to convert to our farming token so that everyone has an option. We also need to create a dapp like k3pr on the Fantom Blockchain which will reward users with this token when they complete jobs if that job when it is verified by the "agents"/keepers to be a job which benefits the X DAO (our DAO). The Dapp will also need to have voting tiers depending on how much XDAO is staked a user will have access to verify or complete a higher security clearance of jobs and also unlock other features. Here are the more specific specifications of the token and a link to iteration syndicate (most of these functions are just changing the numbers of that token).

Providing XDAO/FTM Liquidity and then Staking your LP token will allow you to gain 10x increased farming rewards compared to an equivalent amount of HTZ Liquidity at the cost of burning your XDAO at a high rate.
31.4159265359% Fee burned on buys and sells. The fee on buys is to discourage purchasing rather than earning your tokens. The fee on sells is to encourage people to use their tokens for governance or as liquidity to farm hertz at an extremely high APR.
1–55% Fee sold to HTZ and added to XDAO lps airdrop rewards depending on how much you are purchasing or selling. This is to punish large buyers/sellers but add large rewards for our dedicated DAO members.
0.69% of XDAO/FTM LP has the XDAO side sold for FTM, then the FTM is used to buy HTZ which is added to XDAO lps airdrop rewards every 12 hours.
13.37420% fee on transfers burned. This is to dissuade transferring of reputation to others temporarily.
0.777% of tokens(not in Cyberswap/Agency dapp) burned each 24 hours from users wallets. This is to make sure people who do not actively participate or provide liquidity cannot just sit on their reputation.‌ This will not be active until the Agency dapp goes live.
0.07% of tokens in the Agency dapp actively being used for voting burned every 12 hours. This is to make sure even our actively voting members still need to complete some tasks to maintain their rank within the DAO after it has been reached.
https://iterationsyndicate.com/#/about

The Agency is the dapp that makes reputation in the X DAO function. It is a fork of KP3R, designed specifically to serve as a jobs marketplace for work that benefits the X DAO. In return for completing this work onchain or offchain users are rewarded with X DAO membership tokens similar to during the ITO. Once they reach certain ranks by staking their XDAO tokens, Agents will be able to verify whether a task is eligible for the X DAO bonus, verify if a task has been completed, create governance proposals, fund joint X DAO work with the treasury, and resolve any disputes.
By combining jobs on this dapp with upgradeable smart contracts that can be edited directly by voting, the X DAO will be truly decentralized. It will need no intermediaries in order to keep creating and building products.
You will also be able to use the jobs board for non-X DAO related work, but it will not earn you any X DAO Membership tokens. All work posted in the Agency can be paid for in any cryptocurrency token, however you will receive a discount on fees if you pay with Hertz.

Here is our website, medium, and whitepaper:
thexdao.org
https://zer0-53733.medium.com/initial-task-offering-for-the-x-dao-membership-token-e218f7efc81e
https://thexdao.org/wp-content/uploads/2021/10/The-X-DAO-Whitepaper-v1.9.pdf


# Key deliverables


# Create a local repository

- Clone this repository to your local machin and make the folder of the close the current directory.
- npm install


# Test

1. npx hardhat clean
2. npx hardhat compile
3. npx hardhat test


# Architecture ------------------- To be revised -------------------
## Requirements
<p align="center">
  <img src=".\architecture\Usecases Toplevel.PNG" width="1280" title="hover text">
</p>
## Reuse & Inheritance
<p align="center">
  <img src=".\architecture\XDAO - inheritance.PNG" width="1280" title="hover text">
</p>
<p align="center">
  <img src=".\architecture\XDAO an aggregated contract.PNG" width="1280" title="hover text">
</p>

## Transfer
<p align="center">
  <img src=".\architecture\Transfers Identification.PNG" width="1280" title="hover text">
</p>

# Concepts, Entities, Objects in the XDAO token contract
    There are THREE important user/implementation concepts : _transfer, Fees, and Pulses.
<p align="center">
  <img src=".\architecture\Archtecture - XDAO contract.PNG" width="1280" title="hover text">
</p>

## Fees
    Fees are a portion of transferred amount collected by the management.
### Burn fee
    Burn fee is burnt.
### Rewards fee
    Rewards fee is sold for Hertz, and the Hertz is added to the Rewards Hertz reserve.
### Liquidity fee
    Liquidity fee is added to the liquidity pool (XDAO, FTM).
## Fees objects/data structure
### Fee rates
	struct Fees { 
    	uint256 burn;
		uint256 rewards;
		uint256 liquidity;
	}
    Fee rates can be changed by the owner only.
    Note: I consider denoting these in terms of FTM, rather than XDAO, which will not very stable in initial phases.
### Fee temporary storages
	struct StoreAddresses {
		address burn;
		address rewards;
		address liquidity;
 	}
    'burn' storage stores all tokens that will be burnt, including 'burn' fees.
    'rewards' storage currenly stores 'rewards' fees only, but it can store any amount that will be sold for Rewards Hertz.
    'liquidity' storage currently stores 'liquidity' fees only, but it can store any amount that will be added to the liquidity pool.
    StoreAddresses can be changed by the owner only.
### Fee quantums
    struct Quantums {
        uint256 burn;
        uint256 rewards;
        uint256 liquidity;
    }
    To avoid frequent yet small transactions that will incur excessive gas consumption, fees will be managed on a quantum basis. Fees will accumulate and stored in the StoreAddresses storage accounts until they grow over the given, controlled, quantum. Only then they will go to their destinations, like burn, Rewards Hertz, and the liquidity pool. You can disable quantized management by setting quantums to zero.
    Fee quantums can be changed by the owner only.
    Note: The term 'quantum' seems not adequate. 'Threshold' can do.
    Note: I consider denoting these in terms of FTM, rather than XDAO, which will not very stable in initial phases.
## Pulses
    Pulses are periodic management work.
    While fees are directlt related to transferred amount, pulses are not.
### 'vote_burn' pulse
    'vote_burn' pulse burns a certain portion of tokens used to vote.
### 'all_burn' pulse
    'all_burn' pulse burns a certain portion of tokens of all holders.
### 'lp_rewards' pulse
    'lp_rewards' pulse convert a certain portion of the existing (XDAO, FTM) liquidity to Rewards Hertz.
### Pulse rates
	struct Pulses {
    	uint256 vote_burn;
		uint256 all_burn;
		uint256 lp_rewards;
	}
    'vote_burn' is the portion parameter for the 'vote_burn' pulse.
    'all_burn' is the portion parameter for the 'all_burn' pulse.
    'lp_rewards' is the portion parameter for the 'lp_rewards' pulse.
    Pulse rate can be modified by the owner only.
## MaxTransferAmount
    MaxTansferAmount is the maximum allowed amount of transfer.
## Policies and rules
    There are three main policies/rules a transfer is subject to.
### MaxTransferAmount policy/rule
    Defines what (sender, recipient) pair of transfer is subject to the MaxTransferAmount check.
    The rule code is separated for easy look-up and maintenance.

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
### FeeFree policy/rule
    Defines what (sender, recipient) pair of transfer has to pay fees.
    The rule code is separated for easy look-up and maintenance, simlilarly to the above.

### FeeManagement policy/rule
    Defines what (sender, recipient) pair of transfer is forced to perform the task of fee management.
    The rule code is separated for easy look-up and maintenance, simlilarly to the above.

## High-level logic of transfer (Code sketch)
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = _balances[sender];

        if( ! _isUnlimitedTransfer(sender, recipient) ) {
            require(amount <= maxTransferAmount, "Transfer exceeds limit");
        }

        _balances[sender] -= amount;

   		if(! _isFeeFreeTransfer(sender, recipient) ) {
            amount -= _payFees(sender, recipient, amount);
        }

        _balances[recipient] += amount;

        if( autoManagement && ! _isUnmanageableTransfer(sender, recipient) ) {
            _manageFeesInQuantum();
        }
    }
## Quantized fee management (Code skecth)
    function _manageFeesInQuantum() internal virtual {
        if( _balances[storeAddresses.burn] > quantums.burn) {
            _manageBurn();
        }
        if( _balances[storeAddresses.rewards] > quantums.rewards) {
            _manageRewards();
        }
        if( _balances[storeAddresses.liquidity] > quantums.liquidity) {
            _manageLiquidity();
        }
    }
    Note: This function will be improved to compensate the msg.sender the amount of gas fee they paid for the management work.
## Upgradeability
    The contract of XDAO token is upgradeable. It can be replaced with improved one without having to change other on/off-chain objects relying on it.
    The Openzeppelin upgradeability mechanism is used.

# Testing
    The purpose of testing is to demonstrate the functionality for chosen examples of major use cases.
    Although testing can not prove mathematically the consistency of the functionality, it can detect major errors that are easilly overlooked reading the design and source code.
    Automatic testing is powerful in that it can repeat testing, without incuring cost, whenever there is a change to the source code.

    Testing is split into tow parts: testing initial contracts and testing upgraded contracts.
## Testing architecture
   1. Connect to Provider-Wallet-Network.
   2. Check or build a test bed for the contract of the XDAO token.
   3. Deploy the initial upgradeable contract of XDAO token.
   4. Complete the test bed of the contract, with liquidity pools.
   5. Check administrative funcitons for parameter control.
   6. Check owner-to-user transfers and fees collection.
   7. Check user-to-user transfers and fees collection.
   8. Check quantized management of fees. Under construction.
   9. Check auto-periodic pulses management.
   10. Upgrade the current contract to a new contract at the same address.
   11. Check administrative funcitons for parameter control.
   12. Check owner-to-user transfers and fees collection.
   13. Check user-to-user transfers and fees collection.
   14. Check quantized management of fees. Under construction.
   15. Check auto-periodic pulses management.
## Testing principle, followed
    1. Test cases should be re-usable.
    2. Test cases should be as independent as possible with each other.
    3. The number of test cases should be as small as possible.
    4. The combination of test cases should cover as many use cases as possible.
    5. Automatic testing should produce test reports.
## Automatic testing code sample
	expect(BigInt(totalSupply1)).to.equal(BigInt(totalSupply0));
	console.log("\tThe total supply is preserverd to be: %s EXs", weiToEthEn(totalSupply1));
	expect(BigInt(balance0_Alice)-BigInt(balance1_Alice)).to.equal(BigInt(wAmount));
	console.log("\tThe sender's balance was reduced by the amount passed to the transfer function: %s EXs.",  weiToEthEn(wAmount));
## Automatic testing - video demonstration
<video width="1280" height="800" controls>
  <source src=".\test\Test Report 09 Dec 2021.mp4" type="video/mp4">
</video>

    If the video clip does not play, browse and play the ".\test\Test Report 09 Dec 2021.mp4" file.


  1. Connect to Provider-Wallet-Network.

        theOwner's address = f39F, balance = 10,000 FTM.
        Alice's address = 7099, balance = 10,000 FTM.
        Bob's address = 3C44, balance = 10,000 FTM.
        Charlie's address = 90F7, balance = 10,000 FTM.
    √ Test signers, defined in your hardhat.config.js, are ready. (953ms)

  2. Check or build a test bed for the contract of the XDAO token.

        A clone Hertz deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    √ A clone of Hertz token contract was deployed and is ready for use. (167ms)
        !!! Source code signature = 
         2de75715eaadc263f93ae31df0472548254992f701bb9830d9ed08b3e5f4fa21
        !!! Please make sure the pairFor(...) function of PancakeRouter.sol file has the same code.
    √ A clone of PancakeFactory contract was deployed and is ready for use. (149ms)
    √ A a WETH token contract was deployed and is ready for use. (53ms)
        A clone PancakeRouter deployed to: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
    √ A clone of PancakeRouter was deployed with the PancakeFactory and WETH. (65ms)
    √ The PancakeFactory and PancakeRouter are checked matching.

  3. Deploy the initial upgradeable contract of XDAO token.

        Upgradeable initial contract of XDAO token deployed to:  0165...
    √ The initial contract of XDAO token was deployed. (401ms)
        Token name: XDAO Utility Token
        Token symbol: XO
        Total supply: 1,000,000,000,000,000

        theOwner is the current owner: f39F...
        Current owner's balance: 1,000,000,000,000,000 XO.
    √ The basic existence of the contract was checked for. (41ms)

        BurnFee: 31.4% of transfer amount is correctly set to be burnt.
        RewardsFee: 31.4% of transfer amount is correctly set to be converted to Hertz rewards.
        LiquidityFee: 1% of transfer amount is correctly set to be liquified paired with FTM.

        BurnFee Address: 8887... is correctly set.
        RewardsFee Address: 0300... is correctly set.
        LiquidityFee Address: 1093... is correctly set.

        VoteBurnPulse: 0.07% of tokens used to vote is correctly set to be burnt.
        AllBurnPulse: 0.777% of all holdings is correctly set to be burnt.
        LiquidityPulse: 0.69% of LP is correctly set to be converted to Hertz rewards.

        maxTransferAmount 1,000,000,000,000 XO is correctly set.
        burnQuantum 100,000 XO is correctly set.
        rewardsQuantum 200,000 XO is correctly set.
        liquidityQuantum 300,000 XO is correctly set.

        Dex Router address Cf7E... is correctly set.
        Liquidity Pool (XDAO, FTM) is found at its due address: 0ACa....
        Liquidity Pool (XDAO, HTZ) is found at its due address: 5CCF....

        autoManagement is currently set to:  true
    √ The parameters of the contract were checked. (72ms)

  4. Complete the test bed of the contract, with liquidity pools.

        The (XDAO, FTM) pool contract is located at: 0ACa...
        The (XDAO, FTM) pool contract's off-chain handle was built and checked.
    √ The (XDAO, FTM) pool contract's off-chain handle was built.
        The (XDAO, FTM) pool, now, has neither reserves nor LP tokens.
        The pool should accept any ratio of tokens as the 1s liquidity.
        (199,999,999,999,999.97 XO, 1,999.994 FTM) added to the (XDAO, FTM) pool.
        It's 20% of the theOwner's initial balance.
    √ The (XDAO, FTM) pool was added with liquidity. (101ms)
        The (XDAO, HTZ) pool contract is located at: 5CCF...
        The (XDAO, HTZ) pool contract's off-chain handle was built and checked.
    √ The (XDAO, HTZ) pool contract's off-chain handle was built.
        The (XDAO, HTZ) pool, now, has neither reserves nor LP tokens.
        The pool should accept any ratio of tokens as the 1s liquidity.
        (160,000,000,000,000 XO, 199,999,999,999,999.97 HTZ) added to the (XDAO, HTZ) pool.
        It's 20% of the theOwner's initial balance.
    √ The (XDAO, HTZ) pool was added with liquidity. (120ms)

  5. Check administrative functions for parameter control.

        SetFees function works, changing fee rates correctly, called by the owner.
        SetFees function does NOT work, when called by a non-owner user.

        SetStoreAddresses function works when called by the owner.
        SetStoreAddresses function does NOT work when called by a non-owner user.

        SetPulses function works correctly, when called by the owner.
        SetPulse function does NOT work, when called by a non-owner user.

        SetMaxTransferAmount function works correctly, when called by the owner.
        SetMaxTransferAmount function does NOT work, when called by a non-owner user.

        SetQauntums function works correctly, when called by the owner.
        SetQuantums function does NOT work, when called by a non-owner user.
    √ The administrative functions for parameter control were checked. (396ms)

        BurnFee: 31.4% of transfer amount is correctly set to be burnt.
        RewardsFee: 31.4% of transfer amount is correctly set to be converted to Hertz rewards.
        LiquidityFee: 1% of transfer amount is correctly set to be liquified paired with FTM.

        BurnFee Address: 8887... is correctly set.
        RewardsFee Address: 0300... is correctly set.
        LiquidityFee Address: 1093... is correctly set.

        VoteBurnPulse: 0.07% of tokens used to vote is correctly set to be burnt.
        AllBurnPulse: 0.777% of all holdings is correctly set to be burnt.
        LiquidityPulse: 0.69% of LP is correctly set to be converted to Hertz rewards.

        maxTransferAmount 1,000,000,000,000 XO is correctly set.
        burnQuantum 100,000 XO is correctly set.
        rewardsQuantum 200,000 XO is correctly set.
        liquidityQuantum 300,000 XO is correctly set.

        Dex Router address Cf7E... is correctly set.
        Liquidity Pool (XDAO, FTM) is found at its due address: 0ACa....
        Liquidity Pool (XDAO, HTZ) is found at its due address: 5CCF....

        autoManagement is currently set to:  true
    √ The parameters of the contract were checked reverted back to their initial values. (64ms)

  6. Check owner-to-user transfers and fees collection.

        Assumption: the state variable 'totalSupply' is always the real total supply.
    √ Test design was described.
        The maximum amount that will NOT trigger the MaxTransferAmount 
        and quantized fee management, is 100,000 XO
        Alice is not the current owner.
        theOwner transferred 100,000 XO to Alice.
        The total supply is preserved to be: 1,000,000,000,000,000 XO
        The sender's balance was reduced by the transfer amount: 100,000 XO.
        Owner-Any transfer is free of fees, hence the fee rates: { burn: 0, rewards: 0, liquidity: 0 }
        Burn fee is paid correctly. Burn fee collection was increased by: 0 XO.
        Rewards fee is paid correctly. Rewards fee collection was increased by: 0 XO.
        Liquidity fee is paid correctly. Liquidity fee collection was increased by: 0 XO.
        The amount sent - the amount received = total fees: 0
        Cash flow on owner-to-user transfer is correct and precise.
    √ An owner-to-user transfer is called. (108ms)

  7. Check user-to-user transfers and fees collection.

        Assumption: the state variable 'totalSupply' is always the real total supply.
    √ Test design was described.
        The current maximum amount that will trigger the MaxTransferAmount 
        and quantized fee management is 100,000 XO
        Testing with the siginer Alice, who is not the current owner.
        Bot is not the current owner, either.
        Alice, a non-owner, transferred 100,000 XO to Bob.
        The total supply is preserved to be: 1,000,000,000,000,000 XO
        The sender's balance was reduced by the transfer amount: 100,000 XO.
        Burn fee is paid correctly. Burn fee collection was increased by: 31,400 XO.
        Rewards fee is paid correctly. Rewards fee collection was increased by: 1,000 XO.
        Liquidity fee is paid correctly. Liquidity fee collection was increased by: 1,000 XO.
        The amount sent - the amount received = total fees: 33,400
        Cash flow on owner-to-user transfer is correct and precise.
    √ An user-to-user transfer was called and the fees were correctly collected. (95ms)

  8. Check quantized management of fees. Under construction.

        Tokens collected in the 'storeAddresses.rewards' should be spent
        on a quantum basis (to buy Hertz for Rewards),
        to avoid frequent small transfers and to save gas fees.
        You can't spend 23000 gas to buy 5 weies of Hertz.
    √ Test design was described.
        The current minimum amount that WILL trigger 
        all the quantized management sub-functions, is 1,000,000,000,001 XO.
        Alice's balance was supplemented to be 1,000,000,000,001 XO, 
        to trigger the quantized fees management.
        MaxTransferAmount is set to Alice's balance: 1,000,000,000,001 XO, for this test.
        10 FTM was transferred to the XDAO contract.
        Alice is not the current owner of the contract.
        Bos is not the current owner of the contract.
        Alice and Bob are not of the same address.

        Alice is transfering Bob all her balance...

        Total XOs that were provided for liquidation:      10000001000010000000000000000
        1. XOs that were forwarded to the pool directly:   4995058055447864278428732895
        2. XOs that were sold for FTM at the dex:          5004942944562135721571267105
        3. FTMs that were bought with the XOs at the dex:  49922920780707118
        4. FTMs that were forwarded to the pool:           49922920780707118
        5. XOs that the pool didn't accept:                2502534095915790116731133
        6. FTMs that the pool didn't accept:               0
        7. PPM that failed to be accepted by the pool:     250

        We have an innovative implementation of token liquidation.
        Problem: When we add a sum of Utility tokens to liquidity pool
        <Utility token, Buddy token>, we first assemble a new chunk of liquidity 
        <Utility amount, Buddy amount> using the sum, before forwarding the liquidity chunk
        to the liquidity pool. A typical solution is to let the new chunk equal to
        <1st half of the sum, BuddyTokensSwappedWith(2nd half of the sum>
        The flaw is they ignore that the ratio of reserves in the pool changes by the swap.
        This leads to the Buddy side of the chunk not fully accepted to the pool.
        The remainder is significant if the chunk is significant compared to the total liquidity.
        Solution: Instead of a half-half split, We calculate the best split.
        Achievement: The remainder is reduced to a few hundredths.
        A smaller remainder is impossible due to numerical errors in integer calculation.
        The cost of calculation is justified by our quantum liquidation.

        XDAO tokens were burnt.
        totalSupply decrement ==
        tokens that were waiting to be burnt + tokens newly collected fee to be burnt.
        They each amount to 314,000,031,400.314 XO.
        No tokens remain waiting to be burnt. 314,000,031,400.314

        XDAO tokens were sold for Hertz tokens, adding to the Rewards Hertz account.
        1,000 XO were sold for Hertz.
        Rewards Hertz account's balance was increased by 12,467,973,946.559 HTZ
        The amount should be correct, as we trust the Dex's swap operation.
        No XDAO tokens are still waiting to be sold for Hertz.

        XDAO tokens were liquified to the (XDAO, FTM) liquidity pool,
        in exchange for LP tokens minted to the current owner.
        1,000 XO were waiting to be liquified.
        15,787.43 XO were went to the liquidity pool.
        The owner's LP tokens were increased by 15,787.43 units.
        The amount should be correct, as we trust the Dex operations.
        No XDAO tokens are still waiting to be liquified.

        0.001 FTM wei's, or 0.001 FTM, were transferred
        from 0165..., the XDAO contract, to 7099..., Alice the transaction sender.
        This is the compensation for Alice having done a round of fee management task.

        MaxTransferAmount is restored to: 1,000,000,000,000 XO.
    √ A transfer triggered and did a round of management work, and got compensated. (350ms)

  9. Check auto-periodic pulses management.

        Portions of tokens used to vote or held, should be automatically burnt,
        and a portion of liquidity should be periodically converted to Rewards Hertz.
        The gas payer 'unlucky' to perform the pulses, are compensated for the extra.
    √ Test design was described.

  10. Upgrade the current contract to a new contract at the same address.

        The new upgradeable contract of Pledge token was deployed to:  0165...
    √ deployed the new upgradeable contract, replacing the existing contract. (168ms)

  ======= From now on, the new contract that inherited the initial contract is tested. =====

        Exactly the same test cases will be repeated on the new contract.
    √ 

  5. Check administrative functions for parameter control.

        SetFees function works, changing fee rates correctly, called by the owner.
        SetFees function does NOT work, when called by a non-owner user.

        SetStoreAddresses function works when called by the owner.
        SetStoreAddresses function does NOT work when called by a non-owner user.

        SetPulses function works correctly, when called by the owner.
        SetPulse function does NOT work, when called by a non-owner user.

        SetMaxTransferAmount function works correctly, when called by the owner.
        SetMaxTransferAmount function does NOT work, when called by a non-owner user.

        SetQauntums function works correctly, when called by the owner.
        SetQuantums function does NOT work, when called by a non-owner user.
    √ The administrative functions for parameter control were checked. (304ms)

        BurnFee: 31.4% of transfer amount is correctly set to be burnt.
        RewardsFee: 31.4% of transfer amount is correctly set to be converted to Hertz rewards.
        LiquidityFee: 1% of transfer amount is correctly set to be liquified paired with FTM.

        BurnFee Address: 8887... is correctly set.
        RewardsFee Address: 0300... is correctly set.
        LiquidityFee Address: 1093... is correctly set.

        VoteBurnPulse: 0.07% of tokens used to vote is correctly set to be burnt.
        AllBurnPulse: 0.777% of all holdings is correctly set to be burnt.
        LiquidityPulse: 0.69% of LP is correctly set to be converted to Hertz rewards.

        maxTransferAmount 1,000,000,000,000 XO is correctly set.
        burnQuantum 100,000 XO is correctly set.
        rewardsQuantum 200,000 XO is correctly set.
        liquidityQuantum 300,000 XO is correctly set.

        Dex Router address Cf7E... is correctly set.
        Liquidity Pool (XDAO, FTM) is found at its due address: 0ACa....
        Liquidity Pool (XDAO, HTZ) is found at its due address: 5CCF....

        autoManagement is currently set to:  true
    √ The parameters of the contract were checked reverted back to their initial values. (60ms)

  6. Check owner-to-user transfers and fees collection.

        Assumption: the state variable 'totalSupply' is always the real total supply.
    √ Test design was described.
        The maximum amount that will NOT trigger the MaxTransferAmount 
        and quantized fee management, is 100,000 XO
        Alice is not the current owner.
        theOwner transferred 100,000 XO to Alice.
        The total supply is preserved to be: 999,685,999,968,599.6 XO
        The sender's balance was reduced by the transfer amount: 100,000 XO.
        Owner-Any transfer is free of fees, hence the fee rates: { burn: 0, rewards: 0, liquidity: 0 }
        Burn fee is paid correctly. Burn fee collection was increased by: 0 XO.
        Rewards fee is paid correctly. Rewards fee collection was increased by: 0 XO.
        Liquidity fee is paid correctly. Liquidity fee collection was increased by: 0 XO.
        The amount sent - the amount received = total fees: 0
        Cash flow on owner-to-user transfer is correct and precise.
    √ An owner-to-user transfer is called. (77ms)

  7. Check user-to-user transfers and fees collection.

        Assumption: the state variable 'totalSupply' is always the real total supply.
    √ Test design was described.
        The current maximum amount that will trigger the MaxTransferAmount 
        and quantized fee management is 100,000 XO
        Testing with the siginer Alice, who is not the current owner.
        Bot is not the current owner, either.
        Alice, a non-owner, transferred 100,000 XO to Bob.
        The total supply is preserved to be: 999,685,999,968,599.6 XO
        The sender's balance was reduced by the transfer amount: 100,000 XO.
        Burn fee is paid correctly. Burn fee collection was increased by: 31,400 XO.
        Rewards fee is paid correctly. Rewards fee collection was increased by: 1,000 XO.
        Liquidity fee is paid correctly. Liquidity fee collection was increased by: 1,000 XO.
        The amount sent - the amount received = total fees: 33,400
        Cash flow on owner-to-user transfer is correct and precise.
    √ An user-to-user transfer was called and the fees were correctly collected. (101ms)

  8. Check quantized management of fees. Under construction.

        Tokens collected in the 'storeAddresses.rewards' should be spent
        on a quantum basis (to buy Hertz for Rewards),
        to avoid frequent small transfers and to save gas fees.
        You can't spend 23000 gas to buy 5 weies of Hertz.
    √ Test design was described.
        The current minimum amount that WILL trigger 
        all the quantized management sub-functions, is 1,000,000,000,001 XO.
        Alice's balance was supplemented to be 1,000,000,000,001 XO, 
        to trigger the quantized fees management.
        MaxTransferAmount is set to Alice's balance: 1,000,000,000,001 XO, for this test.
        10 FTM was transferred to the XDAO contract.
        Alice is not the current owner of the contract.
        Bos is not the current owner of the contract.
        Alice and Bob are not of the same address.

        Alice is transfering Bob all her balance...

        Total XOs that were provided for liquidation:      10000001000010000000000000000
        1. XOs that were forwarded to the pool directly:   4995058052320833838536783931
        2. XOs that were sold for FTM at the dex:          5004942947689166161463216069
        3. FTMs that were bought with the XOs at the dex:  49920425477300891
        4. FTMs that were forwarded to the pool:           49920425477300891
        5. XOs that the pool didn't accept:                2502534094349148136213946
        6. FTMs that the pool didn't accept:               0
        7. PPM that failed to be accepted by the pool:     250

        We have an innovative implementation of token liquidation.
        Problem: When we add a sum of Utility tokens to liquidity pool
        <Utility token, Buddy token>, we first assemble a new chunk of liquidity 
        <Utility amount, Buddy amount> using the sum, before forwarding the liquidity chunk
        to the liquidity pool. A typical solution is to let the new chunk equal to
        <1st half of the sum, BuddyTokensSwappedWith(2nd half of the sum>
        The flaw is they ignore that the ratio of reserves in the pool changes by the swap.
        This leads to the Buddy side of the chunk not fully accepted to the pool.
        The remainder is significant if the chunk is significant compared to the total liquidity.
        Solution: Instead of a half-half split, We calculate the best split.
        Achievement: The remainder is reduced to a few hundredths.
        A smaller remainder is impossible due to numerical errors in integer calculation.
        The cost of calculation is justified by our quantum liquidation.

        XDAO tokens were burnt.
        totalSupply decrement == 
        tokens that were waiting to be burnt + tokens newly collected fee to be burnt.
        They each amount to 314,000,031,400.314 XO.
        No tokens remain waiting to be burnt. 314,000,031,400.314

        XDAO tokens were sold for Hertz tokens, adding to the Rewards Hertz account.
        1,000 XO were sold for Hertz.
        Rewards Hertz account's balance was increased by 12,466,417,592.082 HTZ
        The amount should be correct, as we trust the Dex's swap operation.
        No XDAO tokens are still waiting to be sold for Hertz.

        XDAO tokens were liquified to the (XDAO, FTM) liquidity pool,
        in exchange for LP tokens minted to the current owner.
        1,000 XO were waiting to be liquified.
        15,787.035 XO were went to the liquidity pool.
        The owner's LP tokens were increased by 15,787.035 units.
        The amount should be correct, as we trust the Dex operations.
        No XDAO tokens are still waiting to be liquified.

        0 FTM wei's, or 0 FTM, were transferred
        from 0165..., the XDAO contract, to 7099..., Alice the transaction sender.
        This is the compensation for Alice having done a round of fee management task.

        MaxTransferAmount is restored to: 1,000,000,000,000 XO.
    √ A transfer triggered and did a round of management work, and got compensated. (343ms)

  9. Check auto-periodic pulses management.

        Portions of tokens used to vote or held, should be automatically burnt,
        and a portion of liquidity should be periodically converted to Rewards Hertz.
        The gas payer 'unlucky' to perform the pulses, are compensated for the extra.
    √ Test design was described.


  33 passing (4s)


D:\HARDHAT\xado-on-chain>

# Contact

##  jsreputation@gmail.com

##  Skype Name: live:.cid.28c38f00dbf6e04c

