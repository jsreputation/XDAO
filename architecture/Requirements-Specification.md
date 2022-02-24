Hello,
We have developed a two token system where the governance token is either decaying, used for reputation, or used to convert to our farming token so that everyone has an option. 

### R0010: Governance token is either
- Decaying
- Used for reputation
- Used to convert to our farming token
 
We also need to create a dapp like k3pr on the Fantom Blockchain which will reward users with this token when they complete jobs if that job when it is verified by the "agents"/keepers to be a job which benefits the X DAO (our DAO).
### R0020: The dapp is like k3pr.
### R0030: The dapp will be on the Fantom Blockchain.
### R0040: Agent/keepers can verify a job.
### R0050: A user can claim they completed a job.
### R0060: The dapp rewards a user, if the user completes a job and agents/keepers verify the job.
The Dapp will also need to have voting tiers depending on how much XDAO is staked a user will have access to verify or complete a higher security clearance of jobs and also unlock other features. Here are the more specific specifications of the token and a link to iteration syndicate (most of these functions are just changing the numbers of that token). 
### R0070: The dapp has a voting tier.
### R0080: The more XDAO a user staked, the higher security clearance of jobs the user will have access to verify or complete and also unlock other features.
Providing XDAO/FTM Liquidity and then Staking your LP token will allow you to gain 10x increased farming rewards compared to an equivalent amount of HTZ Liquidity at the cost of burning your XDAO at a high rate.
### R0090: There is a XDAO/FTM liquidity pool.
### R0100: A user can provide XDAO/FTM liquidity, in exchange for XDAO/FTM LP tokens.
### R0110: A user can stake their XDAO/FTM LP token in the dapp.

### R0120: A transfer of XDAO is a transaction where one account of XDAO is debited with an amount and one or more accounts of XDAO is credited, collectively, with the same amount. A transfer has the following attributes:
- Sender: is the debited account.
- Recipient: is one of the credited accounts.
- Amount: is the amount that is debited from the Sender.
- MsgSender: is the actor who directly invoked the transfer.
- Fee accounts: is the credited accounts other than the Recipient.
### R0130: Transfers of XDAO are classified into the following categories:
- Sell transfer: [read Identifying-Transfers.md](/architecture/Identifying-Transfers.md)
- Buy transfer: [read Identifying-Transfers.md](/architecture/Identifying-Transfers.md)
- Swap transfer: [read Identifying-Transfers.md](/architecture/Identifying-Transfers.md)
- Shift transfer: [read Identifying-Transfers.md](/architecture/Identifying-Transfers.md)

**(R0160-0162)** 31.4159265359%, the **Fees_Trade_Burn %**, Fee burned on buys and sells. The fee on buys is to discourage purchasing rather than earning your tokens. The fee on sells is to encourage people to use their tokens for governance or as liquidity to farm hertz at an extremely high APR.
### *R0160*: On a sell transfer, the Fees_Trade_Burn % shall be collected from the Seller and burnt.
### *R0161*: On a buy transfer, the Fees_Trade_Burn % shall be collected from the Buyer and burnt.
### *R0162*: On a swap transfer, R0160 and R0161 shall be applied.
### R0165: The the Fees_Trade_Burn % can only be changed by the owner.

**(R0190-0192)** 1–55%, the **Fees_Trade_Rewards %** Fee sold to HTZ and added to XDAO lps airdrop rewards depending on how much you are purchasing or selling. This is to punish large buyers/sellers but add large rewards for our dedicated DAO members.
### *R0190*: On a sell transfer, the Fees_Trade_Rewards % shall be collected from the Seller and converted to HTZ tokens and added to the HTZ rewards reserve.
### *R0191*: On a buy transfer, the Fees_Trade_Rewards % shall be collected from the Buyer and converted to HTZ tokens and added to the HTZ rewards reserve.
### *R0192*: On a swap transfer, R0190 and R0191 shall be applied.
### R0195: The particular value of the Fees_Trade_Rewards % is a function of Amount. The formula will be defined by the client.
### R0196: The Fees_Trade_Rewards % can only be changed by the owner.

**(R0220)** 0.69%, the **Pulses_LP_Rewards %**, of XDAO/FTM LP has the XDAO side sold for FTM, then the FTM is used to buy HTZ which is added to XDAO lps airdrop rewards every 12 hours.
### *R0220*: The Pulses_LP_Rewards % of the total supply of the XDAO/FTM liquidity token will be converted to FTM on the XDAO/FTM pool, and the resulting FTM will be converted to HTZ on the existing HTZ/FTM liquidity pool, and the resulting HTZ will be added to the HTZ rewards reserve, every 12 hours.
### R0221: The Pulses_LP_Rewards % can only be changed by the owner.
### R0225: The periodic pulse required by R0220 shall be implemented completely on-chain.

**(R0250)** 13.37420%, **Fees_Shift_Burn %**, fee on transfers burned. This is to dissuade transferring of reputation to others temporarily.
### *R0250*: 13.37420%, the Fees_Shift_Burn %, of the Amount of a shift transfer shall be collected and burnt.
### R0251: The Fees_Shift_Burn % can only be changed by the owner.

**(R0260)** 0.777%, the **Pulses_All_Burn %**, of tokens(not in Cyberswap/Agency dapp) burned each 24 hours from users wallets. This is to make sure people who do not actively participate or provide liquidity cannot just sit on their reputation.‌ This will not be active until the Agency dapp goes live.
### *R0260*: The Pulses_All_Burn %, of all balances will be burnt, every 24 hours. (We may need checkpoints to avoid having to enumerate all holders.)
### R0261: The Pulses_All_Burn % can only be changed by the owner.
### R0265: Alternative to R0250: Instead of burning part of all holders' balances every 24 hours, a holder's balance shall be checked and debited with the amount equal to the accumulated Pulses_All_Burn % that would have incurred since the last checkpoint, whenever before the balance is referred to by all functions or the transfer hub function. (This is equivalent to R0250 if only we overlook the total supply lately binding. This technique will save us the possible huge cost of enumerating all holders at one call.)
### R0266: R0260 shall be implemented completely on-chain.

**(R0280)** 0.07%, the **Pulses_Vote_Burn %**, of tokens in the Agency dapp actively being used for voting burned every 12 hours. This is to make sure even our actively voting members still need to complete some tasks to maintain their rank within the DAO after it has been reached.
### *R0280*: The Pulses_Vote_Burn %, of the amount of XDAO that was used to vote will be burnt, every 12 hours.
### R0281: The Pulses_Vote_Burn % can only be changed by the owner.
### R0282: R0280 shall be implemented completely on-chain.


### R0300: WHO will add XDAO/FTM liquidity HOW?


[login to view URL]
The Agency is the dapp that makes reputation in the X DAO function. It is a fork of KP3R, designed specifically to serve as a jobs marketplace for work that benefits the X DAO. 
### R0600: The dapp, called the Agency, is a fork of KP3R.
### R0610: The dapp is a job marketplace for work that benefits the XDAO.
In return for completing this work onchain or offchain users are rewarded with X DAO membership tokens similar to during the ITO. Once they reach certain ranks by staking their XDAO tokens, Agents will be able to verify whether a task is eligible for the X DAO bonus, verify if a task has been completed, create governance proposals, fund joint X DAO work with the treasury, and resolve any disputes.
### R0620: A user can stake their XDOA tokens. The more they stake, the higher they rank.
### R0630: If they reach certain ranks, they can
verify whether a task is eligible for the X DAO bonus, 
verify if a task has been completed, 
create governance proposals, 
fund joint X DAO work with the treasury, 
and resolve any disputes.
By combining jobs on this dapp with upgradeable smart contracts that can be edited directly by voting, the X DAO will be truly decentralized. It will need no intermediaries in order to keep creating and building products.
### R0640: Agents can vote to upgrade some smart contracts. The smart contracts are upgradeable.
You will also be able to use the jobs board for non-X DAO related work, but it will not earn you any X DAO Membership tokens. All work posted in the Agency can be paid for in any cryptocurrency token, however you will receive a discount on fees if you pay with Hertz.
### R0650: Non-XDAO related work can be posted on the job board. It will not earn you any XDAO membership tokens.
### R0660: All work posted in the Agency can be paid for in any cryptocurrency token.
### R0670: If you accept payment in Hertz, you will receive a discount on fees.

<p align="center">
  <img src=".\Usecases Toplevel.PNG" width="1280" title="hover text">
</p>