const { BN, constants, expectEvent, expectRevert} = require('@openzeppelin/test-helpers')
const { expect, assert } = require("chai");
const { ethers, upgrades, network } = require("hardhat");
// var Web3 = require('web3');
// var web3 = new Web3(ethers.provider);

const abi_erc20 = require("../artifacts/contracts/PancakeFactory.sol/IERC20.json").abi;
const addr_factory_original_bscmainnet = '0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;'
const addr_factory_original_bsctestnet = '0x6725F303b657a9451d8BA641348b6761A6CC7a17';
const addr_router_original_bscmainnet = '0x10ed43c718714eb63d5aa57b78b54704e256024e';
const addr_router_original_bsctestnet = '0xD99D1c33F9fC3444f8101754aBC46c52416550D1';
const addr_hertz_original_fantommainnet = '0x68F7880F7af43a81bEf25E2aE83802Eb6c2DdBFD';
// const addr_router_clone = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';
// const abi_router_clone = require("../artifacts/contracts/PancakeRouter.sol/IPancakeRouter02.json").abi;
const abi_factory_original = require("../abi_pancakeFactory_original.json");
const abi_router_original = require("../abi_pancakeRouter_original.json");
const abi_pair_original = require("../abi_pancakePair_original.json");

var abi_pair_clone; // loads later in an async function. Ugly code.
//PancakePair abi is available af https://bscscan.com/address/0x0ed7e52944161450477ee417de9cd3a859b14fd0#code.

var routerContract;
var factoryContract;
var XFPairContract;
var XHPairContract;
var wETHContract;
var hertzContract;

var XDAOWithOwnerSigner;
var theOwner, Alice, Bob, Charlie;

var eth_power = 12; // 12 is the maximum possible value on hardhat default network.
var eth_gas_fee_power = 17;

const DECIMALS = 18;
const N_DECIMALS = 18n;

const FEE_MAGNIFIER = 100000; // Five zeroes.
const FEE_HUNDRED_PERCENT = FEE_MAGNIFIER * 100;

const FEES_BURN = 31400;      // this/FEE_MAGNIFIER = 0.31400 or 31.400%
const FEES_REWARDS = 1000;        // this/FEE_MAGNIFIER = 0.01000 or 1.000%
const FEES_LIQUIDITY = 2300;        // this/FEE_MAGNIFIER = 0.02300 or 2.300%

const ADDR_STORES_BURN = "0x8887Df2F38888117c0048eAF9e26174F2E75B8eB"; // Account1
const ADDR_STORES_REWARDS = "0x03002f489a8D7fb645B7D5273C27f2262E38b3a1"; // Account2
const ADDR_STORES_LIQUIDITY = "0x10936b9eBBB82EbfCEc8aE28BAcC557c0A898E43"; // Account3

const PULSES_VOTE_BURN = 70;      // this/FEE_MAGNIFIER = 0.00070 or 0.070%
const PULSES_ALL_BURN = 777;        // this/FEE_MAGNIFIER = 0.00777 or 0.777%
const PULSES_LP_REWARDS = 690;        // this/FEE_MAGNIFIER = 0.00690 or 0.690%

const MAX_TRANSFER_AMOUNT = 1e12;
const QUANTUM_BURN = 1e5;
const QUANTUM_REWARDS = 2e5;
const QUANTUM_LIQUIDITY = 3e5;
const MIN_HODL_TIME_SECONDS  = 31556952; // A year spans 31556952 seconds.

const ADDR_HERTZ_REWARDS = "0x5cA00f843cd9649C41fC5B71c2814d927D69Df95"; // Account4

const zero_address = "0x0000000000000000000000000000000000000000";

function weiToEthEn(wei) { return Number(ethers.utils.formatUnits(wei.toString(), DECIMALS)).toLocaleString('en') }
function weiToEth(wei) { return Number(ethers.utils.formatUnits(wei.toString(), DECIMALS)) }
function ethToWei(eth) { return ethers.utils.parseUnits(eth.toString(), DECIMALS); }
function uiAddr(address) { return "{0x" + address.substring(2, 6).concat('...') + "}" ; }
async function myExpectRevert(promise, revert_string) { 
	await promise.then(()=>expect(true).to.equal(false))
	.catch((err)=>{
		if( ! err.toString().includes(revert_string) )	{
			expect(true).to.equal(false);
		}
	})
};

function findEvent(receipt, eventName, args) {
	var event;
	for(let i = 0; i < receipt.events.length; i++) {
		if(receipt.events[i].event == eventName) {
			event = receipt.events[i];
			break;
		}
	}
	let matching;
	if(event != undefined) {
		matching = true;
		for(let i = 0; i < Object.keys(args).length; i++) {
			let arg = Object.keys(args)[i];
			if(event.args[arg] != undefined && parseInt(event.args[arg]) != parseInt(args[arg])) {
				matching = false;
				break;
			} else if( event.args[0][arg] != undefined && parseInt(event.args[0][arg]) != parseInt(args[arg]) ) {
				matching = false;
				break;
			}
		}
	} else {
		matching = false;
	}
	return matching;
}

function retrieveEvent(receipt, eventName) {
	var event;
	for(let i = 0; i < receipt.events.length; i++) {
		if(receipt.events[i].event == eventName) {
			event = receipt.events[i];
			break;
		}
	}
	var args;
	if(event != undefined) {
		if(Array.isArray(event.args)) {
			if(Array.isArray(event.args[0])) {
				args = event.args[0];
			} else {
				args = event.args;
			}
		} else {
			args = event.args;
		}
	}
	return args;
}

async function Check_For_Basic_Existence(contract) {
	var name = await contract.name();
	expect(await contract.name()).to.equal("XDAO Utility Token");
	console.log("\tToken name: %s", name);

	var symbol = await contract.symbol();
	expect(symbol).to.equal("XO");
	console.log("\tToken symbol: %s", symbol);

	var totalSupply = await contract.totalSupply();
	expect(Number(ethers.utils.formatUnits(totalSupply, DECIMALS))).to.equal(1e15);
	console.log("\tTotal supply: %s", weiToEthEn(totalSupply));// ethers.utils.formatUnits(totalSupply, DECIMALS).toLocaleString('en'));

	var ownerAddress = await contract.owner();
	expect(ownerAddress).to.equal(theOwner.address);
	console.log("\n\ttheOwner is the current owner: %s", uiAddr(ownerAddress));

	var ownerBalance = await contract.balanceOf(ownerAddress);
	console.log("\tCurrent owner's balance: %s XO.", weiToEthEn(ownerBalance) );	
}

async function Check_Contract_Parameters(contract) {
	function rate_pct(rate_magnified) { return rate_magnified * 100 / FEE_MAGNIFIER; }

	var fees = await contract.fees();

	expect(fees.burn).to.equal(FEES_BURN);
	console.log("\n\tBurnFee: %s% of transfer amount is correctly set to be burnt.", rate_pct(fees.burn));

	expect(fees.rewards).to.equal(FEES_REWARDS);
	console.log("\tRewardsFee: %s% of transfer amount is correctly set to be converted to Rewards Hertz.", rate_pct(fees.burn));
	
	expect(fees.liquidity).to.equal(FEES_LIQUIDITY);
	console.log("\tLiquidityFee: %s% of transfer amount is correctly set to be liquefied in pair with FTM.", rate_pct(fees.liquidity));

	storeAddresses = await contract.storeAddresses();

	expect(storeAddresses.burn).to.equal(ADDR_STORES_BURN);
	console.log("\n\tBurnStore Address: %s is correctly set.", uiAddr(storeAddresses.burn));

	expect(storeAddresses.rewards).to.equal(ADDR_STORES_REWARDS);
	console.log("\tRewardsStore Address: %s is correctly set.", uiAddr(storeAddresses.rewards));
	
	expect(storeAddresses.liquidity).to.equal(ADDR_STORES_LIQUIDITY);
	console.log("\tLiquidityStore Address: %s is correctly set.", uiAddr(storeAddresses.liquidity));

	var pulses = await contract.pulses();

	expect(pulses.vote_burn).to.equal(PULSES_VOTE_BURN);
	console.log("\n\tVoteBurnPulse: %s% of tokens used to vote are correctly set to be burnt.", rate_pct(pulses.vote_burn));

	expect(pulses.all_burn).to.equal(PULSES_ALL_BURN);
	console.log("\tAllBurnPulse: %s% of all holdings is correctly set to be burnt.", rate_pct(pulses.all_burn));
	
	expect(pulses.lp_rewards).to.equal(PULSES_LP_REWARDS);
	console.log("\tLiquidityPulse: %s% of LP is correctly set to be converted to Rewards Hertz.", rate_pct(pulses.lp_rewards));

	var maxTransferAmount = await contract.maxTransferAmount();
	expect(maxTransferAmount).to.equal(ethToWei(MAX_TRANSFER_AMOUNT));
	console.log("\n\tmaxTransferAmount %s XO is correctly set.", MAX_TRANSFER_AMOUNT.toLocaleString('En'));

	var quantums = await contract.quantums();
	expect(quantums.burn).to.equal(ethToWei(QUANTUM_BURN));
	console.log("\tburnQuantum %s XO is correctly set.", QUANTUM_BURN.toLocaleString('En'));
	expect(quantums.rewards).to.equal(ethToWei(QUANTUM_REWARDS));
	console.log("\trewardsQuantum %s XO is correctly set.", QUANTUM_REWARDS.toLocaleString('En'));
	expect(quantums.liquidity).to.equal(ethToWei(QUANTUM_LIQUIDITY));
	console.log("\tliquidityQuantum %s XO is correctly set.", QUANTUM_LIQUIDITY.toLocaleString('En'));

	var dexRouterAddress = await contract.dexRouter();
	expect(dexRouterAddress).to.equal(routerContract.address);
	console.log("\n\tDex Router address %s is correctly set.", uiAddr(dexRouterAddress));

	var pairWithWETH_addr = await factoryContract.getPair(contract.address, await routerContract.WETH());
	expect(await contract.pairWithWETH()).to.equal(pairWithWETH_addr);
	console.log("\tLiquidity Pool (XDAO, FTM) is found at its due address: %s.", uiAddr(pairWithWETH_addr));

	var pairWithHertz_addr = await factoryContract.getPair(contract.address, hertzContract.address);
	expect(await contract.pairWithHertz()).to.equal(pairWithHertz_addr);
	console.log("\tLiquidity Pool (XDAO, HTZ) is found at its due address: %s.", uiAddr(pairWithHertz_addr));

	var autoManagement = await contract.autoManagement();
	console.log("\n\tautoManagement is currently set to: ", autoManagement);
}

async function Check_Administrative_Funcitons_For_Parameters(XDAOWithOwnerSigner, userContract) {
	assert(XDAOWithOwnerSigner.signer.address != userContract.signer.address, "The same signer.");

	//------------------------------------ Check fees(.) function, from owner user.
	var fees_org = await XDAOWithOwnerSigner.fees();
	var fees_new = {
		burn: FEES_BURN * 2,
		rewards: FEES_REWARDS * 2,
		liquidity: FEES_LIQUIDITY * 2
	}
	var tx = await XDAOWithOwnerSigner.setFees(fees_new);
	var receipt = await tx.wait();
	expect(findEvent(receipt, 'SetFees', fees_new)).to.equal(true);
	var fees = await XDAOWithOwnerSigner.fees();
	expect(fees.burn).to.equal(fees_new.burn);
	expect(fees.rewards).to.equal(fees_new.rewards);
	expect(fees.liquidity).to.equal(fees_new.liquidity);
	console.log("\tSetFees function works, changing fee rates correctly, called by the owner.");
	var tx = await XDAOWithOwnerSigner.setFees(fees_org);
	var receipt = await tx.wait();

	//------------------------------------ Check fees(.) function, from non-owner user.
	var fees_new = {
		burn: FEES_BURN * 3,
		rewards: FEES_REWARDS * 3,
		liquidity: FEES_LIQUIDITY * 3
	}
	await expect(userContract.setFees(fees_new)).to.be.revertedWith('Ownable: caller is not the owner');
	console.log("\tSetFees function does NOT work, when called by a non-owner user.");

	//------------------------------------ Check storeAddresses(.) function, from owner user.
	var storeAddresses_org = await XDAOWithOwnerSigner.storeAddresses();
	storeAddresses_new = {
		burn: '0xe609FeDa78B646d9A430b071b5D0bA175d787C75',
		rewards: '0x11316bE1351EA3eF2Ab20fC6a8e336cf3f9619C0',
		liquidity: '0x95F2FB2DE5B51aef39a41AC248f1696348302deA',
	}
	var tx = await XDAOWithOwnerSigner.setStoreAddresses(storeAddresses_new);
	var receipt = await tx.wait();
	expect(findEvent(receipt, 'SetStoreAddresses', storeAddresses_new)).to.equal(true);
	var storeAddresses = await XDAOWithOwnerSigner.storeAddresses();
	expect(storeAddresses.vote_burn).to.equal(storeAddresses_new.vote_burn);
	expect(storeAddresses.all_burn).to.equal(storeAddresses_new.all_burn);
	expect(storeAddresses.lp_rewards).to.equal(storeAddresses_new.lp_rewards);
	console.log("\n\tSetStoreAddresses function works when called by the owner.")
	var tx = await XDAOWithOwnerSigner.setStoreAddresses(storeAddresses_org);
	var receipt = await tx.wait();

	//------------------------------------ Check storeAddresses(.) function, from non-owner user.
	storeAddresses_new = {
		burn: '0x11316bE1351EA3eF2Ab20fC6a8e336cf3f9619C0',
		rewards: '0x95F2FB2DE5B51aef39a41AC248f1696348302deA',
		liquidity: '0xe609FeDa78B646d9A430b071b5D0bA175d787C75',
	}
	await expect(userContract.setStoreAddresses(storeAddresses_new)).to.be.revertedWith('Ownable: caller is not the owner');
	console.log("\tSetStoreAddresses function does NOT work when called by a non-owner user.");

	//------------------------------------ Check pulse(.) function, from owner user.
	var pulses_org = await XDAOWithOwnerSigner.pulses();
	var pulses_new = {
		vote_burn: PULSES_VOTE_BURN * 2,
		all_burn: PULSES_ALL_BURN * 2,
		lp_rewards: PULSES_LP_REWARDS * 2
	}
	var tx = await XDAOWithOwnerSigner.setPulses(pulses_new);
	var receipt = await tx.wait();
	expect(findEvent(receipt, 'SetPulses', pulses_new)).to.equal(true);
	var pulses = await XDAOWithOwnerSigner.pulses();
	expect(pulses.vote_burn).to.equal(pulses_new.vote_burn);
	expect(pulses.all_burn).to.equal(pulses_new.all_burn);
	expect(pulses.lp_rewards).to.equal(pulses_new.lp_rewards);
	console.log("\n\tSetPulses function works correctly, when called by the owner.");
	var tx = await XDAOWithOwnerSigner.setPulses(pulses_org);
	var receipt = await tx.wait();

	//------------------------------------ Check pulse(.) function, from non-owner user.
	var pulses_new = {
		vote_burn: PULSES_VOTE_BURN * 3,
		all_burn: PULSES_ALL_BURN * 3,
		lp_rewards: PULSES_LP_REWARDS * 3
	}
	await expect(userContract.setPulses(pulses_new)).to.be.revertedWith('Ownable: caller is not the owner');
	console.log("\tSetPulse function does NOT work, when called by a non-owner user.");

	//------------------------------------ Check setMaxTransferAmount(.) function, from owner user.
	var maxTransferAmount_org = await XDAOWithOwnerSigner.maxTransferAmount();
	var amount = 1e10;
	var maxTransferAmount_new = ethToWei(amount);
	var tx = await XDAOWithOwnerSigner.setMaxTransferAmount( maxTransferAmount_new );
	var receipt = await tx.wait();
	expect(findEvent(receipt, 'SetMaxTransferAmount', {_maxTransferAmount: maxTransferAmount_new } )).to.equal(true);
	var maxTransferAmount = await XDAOWithOwnerSigner.maxTransferAmount();
	expect(maxTransferAmount).to.equal(maxTransferAmount_new);
	console.log("\n\tSetMaxTransferAmount function works correctly, when called by the owner.");
	var tx = await XDAOWithOwnerSigner.setMaxTransferAmount(maxTransferAmount_org);
	var receipt = await tx.wait();

	//------------------------------------ Check setMaxTransferAmount(.) function, from non-owner user.
	var amount = 1e11;
	var maxTransferAmount_new = ethToWei(amount);
	await expect(userContract.setMaxTransferAmount(maxTransferAmount_new)).to.be.revertedWith('Ownable: caller is not the owner');
	// await userContract.setMaxTransferAmount(maxTransferAmount_new).then(expect(false).to.equal(false))
	// .catch((err)=>{});
	// await myExpectRevert(userContract.setMaxTransferAmount(maxTransferAmount_new), "'Ownable: caller is not the owner'");
	 console.log("\tSetMaxTransferAmount function does NOT work, when called by a non-owner user.");

	//------------------------------------ Check setQuantums(.) function, from owner user.
	var quantums_org = await XDAOWithOwnerSigner.quantums();
	var quantums_new = {
		burn: ethToWei(QUANTUM_BURN * 2),
		rewards: ethToWei(QUANTUM_REWARDS * 2),
		liquidity: ethToWei(QUANTUM_LIQUIDITY * 2),
	}
	var tx = await XDAOWithOwnerSigner.setQuantums( quantums_new );
	var receipt = await tx.wait();
	var quantums = await XDAOWithOwnerSigner.quantums();
	expect(quantums.burn).to.equal(quantums_new.burn);
	expect(quantums.rewards).to.equal(quantums_new.rewards);
	expect(quantums.liquidity).to.equal(quantums_new.liquidity);
	console.log("\n\tSetQuantums function works correctly, when called by the owner.");
	var tx = await XDAOWithOwnerSigner.setQuantums(quantums_org);
	var receipt = await tx.wait();

	//------------------------------------ Check setQuantums(.) function, from non-owner user.
	var quantums_new = {
		burn: ethToWei(QUANTUM_BURN * 3),
		rewards: ethToWei(QUANTUM_REWARDS * 3),
		liquidity: ethToWei(QUANTUM_LIQUIDITY * 3),
	}
	// var quantums_new = {
	// 	burn: FEES_BURN * 3,
	// 	rewards: FEES_REWARDS * 3,
	// 	liquidity: FEES_LIQUIDITY * 3
	// }
	await expect(userContract.setQuantums(quantums_new)).to.be.revertedWith('Ownable: caller is not the owner');
	// await myExpectRevert(userContract.setQuantums(quantums_new), "'Ownable: caller is not the owner'");
	console.log("\tSetQuantums function does NOT work, when called by a non-owner user.");
}

async function Check_Owner_to_User_Transfer(contract, wAmount) {
	XDAOWithOwnerSigner = contract.connect(theOwner);
	expect(theOwner.address).equal(XDAOWithOwnerSigner.signer.address);
	expect(XDAOWithOwnerSigner.signer.address).not.equal(Alice.address);
	console.log("\tAlice is not the current owner.");

	var totalSupply0 = await XDAOWithOwnerSigner.totalSupply();
	var balance0_owner = await XDAOWithOwnerSigner.balanceOf(theOwner.address);
	var balance0_Alice = await XDAOWithOwnerSigner.balanceOf(Alice.address);
	var storeBalances0 = await XDAOWithOwnerSigner.storeBalances();
	var tx = await XDAOWithOwnerSigner.transfer(Alice.address, wAmount);
	await tx.wait();
	var totalSupply1 = await XDAOWithOwnerSigner.totalSupply();
	var balance1_owner = await XDAOWithOwnerSigner.balanceOf(theOwner.address);
	var balance1_Alice = await XDAOWithOwnerSigner.balanceOf(Alice.address);
	var storeBalances1 = await XDAOWithOwnerSigner.storeBalances();
	console.log("\ttheOwner transferred %s XO to Alice.", weiToEthEn(wAmount));

	expect(BigInt(totalSupply1)).to.equal(BigInt(totalSupply0));
	console.log("\tThe total supply is preserved to be: %s XO", weiToEthEn(totalSupply1));
	expect(BigInt(balance0_owner)-BigInt(balance1_owner)).to.equal(BigInt(wAmount));
	console.log("\tThe sender's balance was reduced by the transfer amount: %s XO.", weiToEthEn(wAmount));

	//fees = await XDAOWithOwnerSigner.fees();
	fees = { burn: 0, rewards: 0, liquidity: 0 };
	console.log("\tOwner-Any transfer is free of fees, \n\thence the fee rates: %s", fees);
	var fees_collected = Check_Fee_Collection(wAmount, storeBalances0, storeBalances1, fees);
	var total_fees = fees_collected.burn + fees_collected.rewards + fees_collected.liquidity;

	var amountLessAmountReceived = BigInt(wAmount) - ( (BigInt(balance1_Alice) - BigInt(balance0_Alice)) );
	expect(amountLessAmountReceived).to.equal(total_fees);
	console.log("\tThe amount sent - the amount received = total fees: %s", weiToEthEn(total_fees));
	console.log("\tCash flow on owner-to-user transfer is correct and precise.".cyan);
}

function Check_Fee_Collection(wAmount, storeBalances0, storeBalances1, fees) {
	var fees_collected  = { burn: 0, rewards: 0, liquidity: 0 };

	real = BigInt(storeBalances1.burn) - BigInt(storeBalances0.burn);
	expected = BigInt(wAmount) * BigInt(fees.burn) / BigInt(FEE_MAGNIFIER);
	expect(real).to.equal(expected);
	console.log("\tBurn fee is paid correctly. Burn fee collection was increased by: %s XO.", weiToEthEn(real));
	fees_collected.burn = real;

	real = BigInt(storeBalances1.rewards) - BigInt(storeBalances0.rewards);
	expected = BigInt(wAmount) * BigInt(fees.rewards) / BigInt(FEE_MAGNIFIER);
	expect(real).to.equal(expected);
	console.log("\tRewards fee is paid correctly. Rewards fee collection was increased by: %s XO.", weiToEthEn(real));
	fees_collected.rewards = real;

	real = BigInt(storeBalances1.liquidity) - BigInt(storeBalances0.liquidity);
	expected = BigInt(wAmount) * BigInt(fees.liquidity) / BigInt(FEE_MAGNIFIER);
	expect(real).to.equal(expected);
	console.log("\tLiquidity fee is paid correctly. Liquidity fee collection was increased by: %s XO.", weiToEthEn(real));
	fees_collected.liquidity = real;

	return fees_collected;
}

async function Check_User_to_User_Transfer(contract, wAmount) {

	XDAOWithAliceSigner = contract.connect(Alice);
	expect(Alice.address).equal(XDAOWithAliceSigner.signer.address);
	var ownerAddress = XDAOWithAliceSigner.owner();
	expect(ownerAddress).not.equal(XDAOWithAliceSigner.signer.address);
	console.log("\tTesting with the siginer Alice, who is not the current owner.");

	expect(ownerAddress).not.equal(Bob.address);
	console.log("\tBob is not the current owner, either.");

	var totalSupply0 = await XDAOWithAliceSigner.totalSupply();
	var balance0_Alice = await XDAOWithAliceSigner.balanceOf(Alice.address);
	var balance0_Bob = await XDAOWithAliceSigner.balanceOf(Bob.address);
	var storeBalances0 = await XDAOWithAliceSigner.storeBalances();
	var tx = await XDAOWithAliceSigner.transfer(Bob.address, wAmount);
	await tx.wait();
	var totalSupply1 = await XDAOWithAliceSigner.totalSupply();
	var balance1_Alice = await XDAOWithAliceSigner.balanceOf(Alice.address);
	var balance1_Bob = await XDAOWithAliceSigner.balanceOf(Bob.address);
	var storeBalances1 = await XDAOWithAliceSigner.storeBalances();
	console.log("\tAlice, a non-owner, transferred %s XO to Bob.", weiToEthEn(wAmount));

	expect(BigInt(totalSupply1)).to.equal(BigInt(totalSupply0));
	console.log("\tThe total supply is preserved to be: %s XO", weiToEthEn(totalSupply1));
	expect(BigInt(balance0_Alice)-BigInt(balance1_Alice)).to.equal(BigInt(wAmount));
	console.log("\tThe sender's balance was reduced by the transfer amount: %s XO.",  weiToEthEn(wAmount));

	fees = await XDAOWithAliceSigner.fees();
	var fees_collected = Check_Fee_Collection(wAmount, storeBalances0, storeBalances1, fees);
	var total_fees = fees_collected.burn + fees_collected.rewards + fees_collected.liquidity;

	var amountLessAmountReceived = BigInt(wAmount) - (BigInt(balance1_Bob) - BigInt(balance0_Bob));
	expect(amountLessAmountReceived).to.equal(total_fees);
	console.log("\tThe amount sent - the amount received = total fees: %s", weiToEthEn(total_fees));
	console.log("\tCash flow on owner-to-user transfer is correct and precise.".cyan);

}

async function Check_Quanized_Fee_Management(contract, wAmount) {
	XDAOWithAliceSigner = contract.connect(Alice);
	expect(XDAOWithAliceSigner.signer.address).to.equal(Alice.address);
	expect(XDAOWithAliceSigner.address).not.to.equal(await XDAOWithAliceSigner.owner());
	console.log("\tAlice is not the current owner of the contract.");
	expect(Bob.address).not.to.equal(await XDAOWithAliceSigner.owner());
	console.log("\tBob is not the current owner of the contract.");
	expect(Bob.address).not.to.equal(Alice.address);
	console.log("\tAlice and Bob are not of the same address.");

	var hertzRewardsAddress = await XDAOWithAliceSigner.hertzRewardsAddress();

	var totalSupply0 = await XDAOWithAliceSigner.totalSupply();
	var storeBalances0 = await XDAOWithAliceSigner.storeBalances();
	var hertzRewards0 = await hertzContract.balanceOf(hertzRewardsAddress);
	var liquidity0 = await XFPairContract.balanceOf(await XDAOWithAliceSigner.owner()); // XFPairContract.totalSupply();

	console.log("\n\tAlice is transfering Bob all her balance %s XO.\n", weiToEthEn(wAmount));

	var tx = await XDAOWithAliceSigner.transfer(Bob.address, wAmount);
	var receipt = await tx.wait();
	console.log("\n\tWe have an innovative implementation of token liquefying.".blue);
	console.log("\tProblem: When we add a sum of Utility tokens to liquidity pool".blue);
	console.log("\t(Utility token, Buddy token), we first assemble a new chunk of liquidity ".blue);
	console.log("\t(Utility amount, Buddy amount) using the sum, before forwarding the liquidity chunk".blue);
	console.log("\tto the liquidity pool. A typical solution is to let the new chunk equal to".blue);
	console.log("\t(1st half of the sum, BuddyTokensSwappedWith(2nd half of the sum))".blue);
	console.log("\tThe flaw is they ignore that the ratio of reserves in the pool changes by the swap.".blue);
	console.log("\tThis leads to the Buddy side of the chunk not fully accepted to the pool.".blue);
	console.log("\tThe remainder is significant if the chunk is significant compared to the total liquidity.".blue);
	console.log("\tSolution: Instead of a half-half split, We calculate the best split.");
	console.log("\tAchievement: The remainder is reduced to a few hundredths.");
	console.log("\tA smaller remainder is impossible due to numerical errors in integer calculation.");
	console.log("\tThe cost of calculation is justified by our quantized liquefying.");

	var totalSupply1 = await XDAOWithAliceSigner.totalSupply();
	var storeBalances1 = await XDAOWithAliceSigner.storeBalances();
	var hertzRewards1 = await hertzContract.balanceOf(hertzRewardsAddress);
	var liquidity1 = await XFPairContract.balanceOf(await XDAOWithAliceSigner.owner()); // XFPairContract.totalSupply();

	fees = await XDAOWithAliceSigner.fees();

	var fees_collected  = { burn: 0, rewards: 0, liquidity: 0 };

	fees_collected.burn = BigInt(wAmount) * BigInt(fees.burn) / BigInt(FEE_MAGNIFIER);
	fees_collected.rewards = BigInt(wAmount) * BigInt(fees.rewards) / BigInt(FEE_MAGNIFIER);
	fees_collected.liquidity = BigInt(wAmount) * BigInt(fees.liquidity) / BigInt(FEE_MAGNIFIER);

	console.log("\n\tThis transfer was hooked to burning XDAO tokens.");
	console.log("\t%s XO were in the burn store waiting to be burnt.", weiToEthEn(storeBalances0.burn));
	console.log("\tThey ought to have come from previous transfers, pulses or whatever.");
	console.log("\t%s XO newly came from the transfer as a burn fee, adding to the store.", weiToEthEn(fees_collected.burn));
	console.log("\tThe consistency of burn fee was/is checked somewhere else.")
	console.log("\tThis huge amount of fee was incurred by the huge transfer amount.");
	console.log("\t%s XO, the whole burn store, were subject to the burning.", weiToEthEn(BigInt(storeBalances0.burn) + BigInt(fees_collected.burn)));
	console.log("\t%s XO of them were found left in the burn store after the burning.", weiToEthEn(storeBalances1.burn));
	console.log("\t%s XO, therefore, were actually burnt by the burning.", weiToEthEn(BigInt(storeBalances0.burn) + BigInt(fees_collected.burn) - BigInt(storeBalances1.burn)));
	expect(BigInt(totalSupply0) - BigInt(totalSupply1)).to.equal(BigInt(storeBalances0.burn) + fees_collected.burn);
	console.log("\t%s XO, the change in XDAO Total Supply, equals that amount.", weiToEthEn(BigInt(totalSupply1) - BigInt(totalSupply0)));

	console.log("\n\tThis transfer was hooked to selling XDAO tokens for Rewards Hertz.");
	console.log("\t%s XO were in the rewards store waiting to be sold.", weiToEthEn(storeBalances0.rewards));
	console.log("\tThey ought to have come from previous transfers, pulses or whatever.");
	console.log("\t%s XO newly came from the transfer as a rewards fee, adding to the store.", weiToEthEn(fees_collected.rewards));
	console.log("\tThe consistency of rewards fee was/is checked somewhere else.")
	console.log("\tThis huge amount of fee was incurred by the huge transfer amount.");
	console.log("\t%s XO, the whole rewards store, were subject to the sale.", weiToEthEn(BigInt(storeBalances0.rewards) + BigInt(fees_collected.rewards)));
	console.log("\t%s XO of them were found left in the burn store after the sale.", weiToEthEn(storeBalances1.rewards));
	console.log("\t%s XO, therefore, were actually sold by the sale.", weiToEthEn(BigInt(storeBalances0.rewards) + BigInt(fees_collected.rewards) - BigInt(storeBalances1.rewards)));
	console.log("\t%s HTZ, the change in Rewards reserve, were bought with that amount.", weiToEthEn(BigInt(hertzRewards1) - BigInt(hertzRewards0)));
	console.log("\tVerifying this amount's relation belongs to checking the Dex, which we trust.");

	console.log("\n\tThis transfer was hooked to liquefying XDAO tokens into (XDAO, FTM) pool.");
	console.log("\t%s XO were in the liquidity store waiting to be liquified.", weiToEthEn(storeBalances0.liquidity));
	console.log("\tThey ought to have come from previous transfers, pulses or whatever.");
	console.log("\t%s XO newly came from the transfer as a liquidity fee, adding to the store.", weiToEthEn(fees_collected.liquidity));
	console.log("\tThe consistency of liquidity fee was/is checked somewhere else.")
	console.log("\tThis huge amount of fee was incurred by the huge transfer amount.");
	console.log("\t%s XO, the whole liquidity store, were subject to the liquifying.", weiToEthEn(BigInt(storeBalances0.liquidity) + BigInt(fees_collected.liquidity)));
	console.log("\t%s XO of them were found left in the liquidity store after the liquifying.", weiToEthEn(storeBalances1.liquidity));
	console.log("\t%s XO, therefore, were actually liquified by the liquifying.", weiToEthEn(BigInt(storeBalances0.liquidity) + BigInt(fees_collected.liquidity) - BigInt(storeBalances1.liquidity)));
	console.log("\t%s LP tokens, the change in (XDAO, FTM) pool, were minted with that amount.", weiToEthEn(BigInt(liquidity1) - BigInt(liquidity0)));
	console.log("\tVerifying this amount's relation belongs to checking the Dex, which we trust.");

	var eventArgs = retrieveEvent(receipt, "TransferEther");
	expect(eventArgs != undefined).to.equal(true);
	expect(eventArgs.sender).to.equal(XDAOWithOwnerSigner.address);
	expect(eventArgs.recipient).to.equal(Alice.address);
	console.log("\n\t%s FTM wei, or %s FTM, were transferred \n\tfrom %s, the XDAO contract, to %s, Alice the transaction sender.",
	eventArgs.amount, weiToEthEn(eventArgs.amount), uiAddr(eventArgs.sender), uiAddr(eventArgs.recipient));
	console.log("\tThis is the compensation for Alice hooked to perform a round of fee management task.".yellow);
}


describe("\t\t\t Test Report generated by automated testing.\n".yellow, function () {
	it("The purpose was stated.".green, async function () {
		console.log("\tThis is an automated testing of the smart contract of the crypto token XDAO.");
		console.log("\tA test script will be running with multiple predefined test cases.");
		console.log("\tWhile this testing can not provide a rigorous proof of the system,");
		console.log("\tit covers the majority of use cases, when supplemented with code logic.");
	});

	it("The scope was stated.".green, async function () {
		console.log("\tThe test cases were carefully selected to be independent yet typical.");
		console.log("\tWhen combined, the test cases are multiplied / convoluted with each other,");
		console.log("\timplicitly covering a majority range of use cases.");
		console.log("\tImportant events emitted by the token contract were checked.");
	});

	it("The strategy was stated.".green, async function () {
		console.log("\tThere are three phases of testing: test-bed, initial contract, and upgrading contract.");
		console.log("\tTest-bed phase will build atesting environment for the remaining two phases.");
		console.log("\tInitial phase will test the initial contract with a set of test cases.");
		console.log("\tUpgraded phase will test the upgrading contract with the same set of test cases.");
		console.log("\tNote: The initial contract is later upgraded by the upgrading contract, which");
		console.log("\tinherits the state of initial contracts at the same address of deployment.");
	});

});

describe("======= Phase 1. The test-bed for the whole testing is constructed. =====\n".yellow, async function () {
	it("", async function () {
		console.log("\tA predefined set of test cases will be running on the initial contract.");
	});
});


describe("1. Connect to Provider-Wallet-Network.\n".yellow, function () {

	it("Test signers, defined in your hardhat.config.js, are ready.".green, async function () {
		[theOwner, Alice, Bob, Charlie] = await ethers.getSigners();
		console.log("\ttheOwner's address = %s, balance = %s FTM.", uiAddr(addr = await theOwner.getAddress()), weiToEthEn(await ethers.provider.getBalance(addr)) );
		console.log("\tAlice's address = %s, balance = %s FTM.", uiAddr(addr = await Alice.getAddress()), weiToEthEn(await ethers.provider.getBalance(addr)) );
		console.log("\tBob's address = %s, balance = %s FTM.", uiAddr(addr = await Bob.getAddress()), weiToEthEn(await ethers.provider.getBalance(addr)) );
		console.log("\tCharlie's address = %s, balance = %s FTM.", uiAddr(addr = await Charlie.getAddress()), weiToEthEn(await ethers.provider.getBalance(addr)) );
	});
});

describe("2. Build a main Dex environment for the contract of the XDAO token.\n".yellow, function () {
	async function deploy_Hertz(amount) {
		try {
			//const Hertz = await ethers.getContractFactory("HertzToken", theOwner);
			//const Hertz = await ethers.getContractFactory("BEP20", theOwner);
			const Hertz = await ethers.getContractFactory("HertzSubstitute", theOwner);
			//hertzContract = await Hertz.deploy("Hertz substitute Token", "HTZ", 1e33, theOwner.address);
			hertzContract = await Hertz.deploy();
			await hertzContract.deployed();
			console.log("\tA clone Hertz deployed to: %s", uiAddr(hertzContract.address));
		} catch(err) {
			assert.fail("The clone Hertz contract is not created.");
		}

		var decimals = await hertzContract.decimals();
		//var tx = await hertzContract.mint(theOwner.address,  ethers.utils.parseUnits(amount.toString(), decimals) );
		//var tx = await hertzContract.mint(theOwner.address, 1 );  // TypeError: hertzContract.mint is not a function

		// await tx.wait();
	};

	if (network.name == 'bscmainnet') { // This is NOT tested.
		it("A handle to the PancakeFactory contract deployed on the BSC mainnet is now ready.".green, async function () {
			factoryContract = new ethers.Contract(addr_factory_original_bscmainnet,  abi_factory_original, theOwner);
		});

		it("A handle to the PancakeRouter contract deployed on the BSC mainnet is now ready.".green, async function () {
			routerContract = new ethers.Contract(addr_router_original_bscmainnet,  abi_router_original, theOwner);
		});

	} else if (network.name == 'bsctestnet') {
		it("A handle to PancakeFactory contract deployed on the BSC testnet is now ready.".green, async function () {
			factoryContract = new ethers.Contract(addr_factory_original_bsctestnet,  abi_factory_original, theOwner);
		});

		it("A handle to the PancakeRouter contract deployed on the BSC testnet is ready.".green, async function () {
			routerContract = new ethers.Contract(addr_router_original_bsctestnet,  abi_router_original, theOwner);
		});

		it("A clone of Hertz token contract was deployed and is ready for use.".green, async function () {
			await deploy_Hertz(1e15);
		});


	} else if ( ['fantomtestnet', 'localnet', 'localhost', 'hardhat'].includes(network.name) ) {
		it("A clone of Hertz token contract was deployed and is ready for use.".green, async function () {
			await deploy_Hertz(1e15);
		});

		it("A clone of PancakeFactory contract was deployed and is ready for use.".green, async function () {
			try {
				const Factory = await ethers.getContractFactory("PancakeFactory", theOwner);
				factoryContract = await Factory.deploy(theOwner.address);
				await factoryContract.deployed();
				console.log("\t!!! Source code signature = \n\t", (await factoryContract.INIT_CODE_PAIR_HASH()).substring(2) ); 
				console.log("\t!!! Please make sure the pairFor(...) function of PancakeRouter.sol file has the same code.");
			} catch(err) {
				assert.fail('Clone PancakFactory contract is not created');
			}
		});

		it("A WETH token contract was deployed and is ready for use.".green, async function () {
			try {
				const WETH = await ethers.getContractFactory("WETH9", theOwner);
				wETHContract = await WETH.deploy();
				await wETHContract.deployed();
			} catch(err) {
				assert.fail("WETH9 contract is not created.");
			}
		});

		it("A clone of PancakeRouter was deployed with the PancakeFactory and WETH.".green, async function () {
			try {
				const Router = await ethers.getContractFactory("PancakeRouter", theOwner);
				routerContract = await Router.deploy(factoryContract.address, wETHContract.address);
				await routerContract.deployed();
				console.log("\tA clone PancakeRouter deployed to: %s", uiAddr(routerContract.address));
			} catch(err) {
				assert.fail("The clone PancakeRouter contract is not created.");
			}
		});

	} else {
		console.log("Network should be one of hardhat, localnet, localhost, fantomtestnet, bsctestnet, and bscmainnet, not ", network.name);
		throw 'network unacceptable.'
	}

	it("The PancakeFactory and PancakeRouter are checked for matching.".green, async function () {
		expect(await routerContract.factory()).to.equal(factoryContract.address);
	});
});

//============================= The age of the first upgradeable contract of XDAO ========================================

describe("3. Deploy the initial upgradeable contract of XDAO token.\n".yellow, function () {

	it("The initial contract of XDAO token was deployed.".green, async function () {
		var Analytic = await ethers.getContractFactory("AnalyticMath", theOwner);
		analytic = await Analytic.deploy();
		await analytic.deployed();


		const factory = await ethers.getContractFactory("XDAO03Up", theOwner);
		XDAOWithOwnerSigner = await upgrades.deployProxy(factory, [routerContract.address, hertzContract.address, analytic.address], {initializer: 'initialize(address, address, address)'});
		await XDAOWithOwnerSigner.deployed();
		console.log("\tUpgradeable initial contract of XDAO token deployed to: ", uiAddr(XDAOWithOwnerSigner.address));
		var ownerAddress = await XDAOWithOwnerSigner.owner();
		expect(ownerAddress).to.equal(theOwner.address);
	});

	it("The basic existence of the contract was checked for.".green, async function () {
		await Check_For_Basic_Existence(XDAOWithOwnerSigner);
	});

	it("The parameters of the contract were checked.".green, async function () {
		await Check_Contract_Parameters(XDAOWithOwnerSigner);
	})
});


describe("======= Phase 2. The initial contract is tested. =====\n".yellow, async function () {
	it("", async function () {
		console.log("\tA predefined set of test cases will be run on the initial contract.");
	});
});

describe("4. Complete the test bed of the contract, with liquidity pools.\n".yellow, function () {

	it("The (XDAO, FTM) pool contract's off-chain handle was built.".green, async function () {
		XFPair_addr = await factoryContract.getPair(XDAOWithOwnerSigner.address, routerContract.WETH());
		expect(XFPair_addr).to.equal(await XDAOWithOwnerSigner.pairWithWETH());
		console.log("\tThe (XDAO, FTM) pool contract is located at: %s", uiAddr(XFPair_addr));
		XFPairContract = new ethers.Contract(XFPair_addr,  abi_pair_original, theOwner);
		if( _this_is_initial_contract == true ) {
			var totalSupply = await XFPairContract.totalSupply();
			expect(BigInt(totalSupply)).to.equal(BigInt(0));
			var reserves = await XFPairContract.getReserves();
			expect(BigInt(reserves._reserve0)).to.equal(BigInt(0));
			expect(BigInt(reserves._reserve1)).to.equal(BigInt(0));
		}
		console.log("\tThe (XDAO, FTM) pool contract's off-chain handle was built and checked.");
	});

	it("The (XDAO, FTM) pool was added with liquidity.".green, async function () {
		var totalSupply = await XFPairContract.totalSupply();
		expect(BigInt(totalSupply)).to.equal(BigInt(0));
		var reserves = await XFPairContract.getReserves();
		expect(BigInt(reserves._reserve0)).to.equal(BigInt(0));
		expect(BigInt(reserves._reserve1)).to.equal(BigInt(0));
		console.log("\tThe (XDAO, FTM) pool, now, has neither reserves nor LP tokens.");
		console.log("\tThe pool should accept any ratio of tokens as the 1s liquidity.");

		var percents = 20;
		var ethAmount = BigInt( (await ethers.provider.getBalance(theOwner.address)) * percents / 100);
		var xAmount = BigInt ((await XDAOWithOwnerSigner.balanceOf(theOwner.address)) * percents / 100);

		var tx = await XDAOWithOwnerSigner.approve(routerContract.address, xAmount);
		await tx.wait();

		//Assert xAmount * wETh >= 10**6 // uint public constant MINIMUM_LIQUIDITY = 10**3 in PancakePair.

		tx = await routerContract.addLiquidityETH(
			XDAOWithOwnerSigner.address,
			xAmount,
			0,
			0,
			theOwner.address,
			"111111111111111111111", // deadline of 'infinity'
			{ value : ethAmount } // You can't quote wETHContract here. :)
			);
		await tx.wait();

		console.log("\t(%s XO, %s FTM) added to the (XDAO, FTM) pool.", weiToEthEn(xAmount), weiToEthEn(ethAmount));
		console.log("\tIt's %s% of the theOwner's initial balance.", percents);

	});

	it("The (XDAO, HTZ) pool contract's off-chain handle was built.".green, async function () {
		XHPair_addr = await factoryContract.getPair(XDAOWithOwnerSigner.address, hertzContract.address);
		expect(XHPair_addr).to.equal(await XDAOWithOwnerSigner.pairWithHertz());
		console.log("\tThe (XDAO, HTZ) pool contract is located at: %s", uiAddr(XHPair_addr));
		XHPairContract = new ethers.Contract(XHPair_addr,  abi_pair_original, theOwner);
		if( _this_is_initial_contract == true ) {
			var totalSupply = await dexPair2.totalSupply();
			expect(BigInt(totalSupply)).to.equal(BigInt(0));
			var reserves = await dexPair2.getReserves();
			expect(BigInt(reserves._reserve0)).to.equal(BigInt(0));
			expect(BigInt(reserves._reserve1)).to.equal(BigInt(0));
		}
		console.log("\tThe (XDAO, HTZ) pool contract's off-chain handle was built and checked.");
	});

	it("The (XDAO, HTZ) pool was added with liquidity.".green, async function () {
		var totalSupply = await XHPairContract.totalSupply();
		expect(BigInt(totalSupply)).to.equal(BigInt(0));
		var reserves = await XHPairContract.getReserves();
		expect(BigInt(reserves._reserve0)).to.equal(BigInt(0));
		expect(BigInt(reserves._reserve1)).to.equal(BigInt(0));
		console.log("\tThe (XDAO, HTZ) pool, now, has neither reserves nor LP tokens.");
		console.log("\tThe pool should accept any ratio of tokens as the 1s liquidity.");

		var percents = 20;
		var xAmount = BigInt ((await XDAOWithOwnerSigner.balanceOf(theOwner.address)) * percents / 100);
		var htzAmount = BigInt ((await hertzContract.balanceOf(theOwner.address)) * percents / 100);

		var tx = await XDAOWithOwnerSigner.approve(routerContract.address, xAmount);
		await tx.wait();
		var tx = await hertzContract.approve(routerContract.address, htzAmount);
		await tx.wait();

		tx = await routerContract.addLiquidity(
			XDAOWithOwnerSigner.address,
			hertzContract.address,
			xAmount,
			htzAmount,
			0,
			0,
			theOwner.address,
			"111111111111111111111", // deadline of 'infinity'
		);
		await tx.wait();

		console.log("\t(%s XO, %s HTZ) added to the (XDAO, HTZ) pool.", weiToEthEn(xAmount), weiToEthEn(htzAmount) );
		console.log("\tIt's %s% of the theOwner's initial balance.", percents);

	});
});


function test_XDAO_token_contract_with_full_list_of_test_cases(is_initial_contract) {
	describe("5. Check administrative functions for parameter control.\n".yellow, async function () {

		it("The administrative functions for parameter control were checked.".green, async function () {
			XDAOWithAliceSigner = XDAOWithOwnerSigner.connect(Alice);
			await Check_Administrative_Funcitons_For_Parameters(XDAOWithOwnerSigner, XDAOWithAliceSigner);
		})

		it("The parameters were correctly reverted back to their initial values.".green, async function () {
			await Check_Contract_Parameters(XDAOWithOwnerSigner);
		})
	});

	describe("6. Check owner-to-user transfers and fees collection.\n".yellow, async function () {

		it("Test design was described.".green, async function () {
			console.log("\tAssumption: the state variable 'totalSupply' is always the real total supply.");
		})

		it("An owner-to-user transfer is called.".green, async function () {
			var store = await XDAOWithOwnerSigner.storeBalances();
			var eAmount = Math.min(
				weiToEth(await XDAOWithOwnerSigner.balanceOf(theOwner.address)),
				MAX_TRANSFER_AMOUNT,
				QUANTUM_BURN - weiToEth(BigInt(store.burn)),
				QUANTUM_REWARDS - weiToEth(BigInt(store.rewards)),
				QUANTUM_LIQUIDITY - weiToEth(BigInt(store.liquidity)),
			);
			console.log("\tThe maximum amount that will NOT trigger the MaxTransferAmount \n\tand quantized fee management, is %s XO", eAmount.toLocaleString('En'));
			console.log("\tOnly fee collections should be triggered, if the owner transfers this amount to a user.");
			await Check_Owner_to_User_Transfer(XDAOWithOwnerSigner, ethToWei(eAmount));
		})
	});

	describe("7. Check user-to-user transfers and fees collection.\n".yellow, async function () {

		it("Test design was described.".green, async function () {
			console.log("\tAssumption: the state variable 'totalSupply' is always the real total supply.");
		})
			
		it("An user-to-user transfer was called and the fees were correctly collected.".green, async function () {
			var store = await XDAOWithOwnerSigner.storeBalances();
			var eAmount = Math.min(
				weiToEth(await XDAOWithOwnerSigner.balanceOf(Alice.address)),
				MAX_TRANSFER_AMOUNT,
				QUANTUM_BURN - weiToEth(BigInt(store.burn)),
				QUANTUM_REWARDS - weiToEth(BigInt(store.rewards)),
				QUANTUM_LIQUIDITY - weiToEth(BigInt(store.liquidity)),
			);
			console.log("\tThe maximum amount that will NOT trigger the MaxTransferAmount \n\tand quantized fee management is %s XO", eAmount.toLocaleString('En'));
			console.log("\tOnly fee collection should be triggered, if a user transfers this amount to another user.");
			await Check_User_to_User_Transfer(XDAOWithAliceSigner, ethToWei(eAmount));
		})
	});

	describe("8. Check quantized management of fees.\n".yellow, async function () {

		it("Test design was described.".green, async function () {
			console.log("\tTokens collected in the 'storeAddresses.rewards' should be spent \n\ton a quantum basis (to buy Rewards Hertz),");
			console.log("\tto avoid frequent small transfers and to save gas fees. \n\tYou can't spend 23000M wei to buy 5 wei of Hertz.");
		})

		it("A transfer was hooked to do a round of management work, and got compensated.".green, async function () {
			var store = await XDAOWithOwnerSigner.storeBalances();
			var eAmount = Math.max(
				MAX_TRANSFER_AMOUNT,
				QUANTUM_BURN - weiToEth(BigInt(store.burn)),
				QUANTUM_REWARDS - weiToEth(BigInt(store.rewards)),
				QUANTUM_LIQUIDITY - weiToEth(BigInt(store.liquidity)),
			);
			eAmount += 1; // This is required to trigger all the quantized manamgement sub-functions.
			console.log("\tThe minimum amount that WILL trigger all the quantized management sub-functions is \n\t%s XO.", eAmount.toLocaleString('En'));
			console.log("\tAll quantized management sub-functions should be triggered, \n\tif a user transfers this amount to another user.");

			var AliceBalance = await XDAOWithOwnerSigner.balanceOf(Alice.address);
			if (weiToEth(AliceBalance) < eAmount ) {
				var tx = await XDAOWithOwnerSigner.transfer(Alice.address, ethToWei(eAmount - weiToEth(AliceBalance)));
				await tx.wait();
			}
			var AliceBalance = await XDAOWithOwnerSigner.balanceOf(Alice.address);
			expect(AliceBalance).to.equal(ethToWei(eAmount));
			console.log("\tAlice's balance was supplemented to be %s XO, \n\tto trigger the quantized fees management.", weiToEthEn(AliceBalance));

			var maxTransferAmount_org = await XDAOWithOwnerSigner.maxTransferAmount();
			var tx = await XDAOWithOwnerSigner.setMaxTransferAmount(AliceBalance);
			await tx.wait();
			expect(await XDAOWithOwnerSigner.maxTransferAmount()).to.equal(AliceBalance);
			console.log("\tMaxTransferAmount is set to Alice's balance: %s XO, for this test.", weiToEthEn(AliceBalance));

			var ethBalance0 = await XDAOWithOwnerSigner.provider.getBalance(XDAOWithOwnerSigner.address);
			if( weiToEth(ethBalance0) < 0.1 ) {
				var eAmount = 0.05; // ethers.
				var tx = await theOwner.sendTransaction( {to: XDAOWithOwnerSigner.address, value: ethers.utils.parseUnits(eAmount.toString(), 18) }); // This 18 is not DECIMALS
				await tx.wait();
				var ethBalance1 = await XDAOWithOwnerSigner.provider.getBalance(XDAOWithOwnerSigner.address);
				expect(BigInt(ethBalance1)-BigInt(ethBalance0)).to.equal(BigInt(eAmount*10**18));
				console.log("\t%s FTM was transferred to the XDAO contract to fund the future management work.", eAmount);
			}

			await Check_Quanized_Fee_Management(XDAOWithAliceSigner, AliceBalance );

			var tx = await XDAOWithOwnerSigner.setMaxTransferAmount(maxTransferAmount_org);
			await tx.wait();
			console.log("\n\tMaxTransferAmount is restored to: %s XO.", weiToEthEn(maxTransferAmount_org));
		})

	});

	describe("9. Check auto-periodic pulses management. Under construction.\n".yellow, async function () {

		it("Test design was described.".green, async function () {
			console.log("\tA portion of tokens used to vote is automatically burnt,");
			console.log("\tand a portion of liquidity is periodically converted to Rewards Hertz.");
			console.log("\tThe gas payer hooked to do the pulse tasks, are compensated for the extra gas.");
		})
	});

};

var _this_is_initial_contract = true; //===================== Declares the era of the initial contract.

test_XDAO_token_contract_with_full_list_of_test_cases(_this_is_initial_contract);

describe("10. Upgrade the current contract to a new contract at the same address.\n".yellow, async function () {

	it("deployed the new upgradeable contract, replacing/upgrading the existing contract.".green, async function () {
		const factory = await ethers.getContractFactory("XDAO04Up", theOwner);
		XDAOWithOwnerSigner = await upgrades.upgradeProxy(XDAOWithOwnerSigner.address, factory);
		await XDAOWithOwnerSigner.deployed();
		console.log("\tThe new upgradeable XDAO token was deployed to: ", uiAddr(XDAOWithOwnerSigner.address));
		console.log("\tEverything that was interacting with the existing contract, is not affected.");
	});
});

describe("======= Phase 3. The upgrading contract that inherited the initial contract is tested. =====\n".yellow, async function () {
	it("", async function () {
		console.log("\tExactly the same test cases will be repeated on the new contract.");
	});
});


_this_is_initial_contract = false; //================================= Declare the era of upgraded 

test_XDAO_token_contract_with_full_list_of_test_cases(_this_is_initial_contract);


describe("\n   Contact me with feedback:\n".yellow, async function () {

	it("\n\tfleetpro@gmail.com".yellow, async function () {
	});

	it("\n\thttps://github.com/MachineLearningMike/XDAO".green, async function () {
	});

});
