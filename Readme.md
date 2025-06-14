Reproduction Steps:

Clone the target repo: 

    git clone https://github.com/Rikkaav/permanent-eth-loss-imx-bridge
    cd permanent-eth-loss-imx-bridge

Place PoC files: Make sure InfiniteWithdrawal.t.sol is in test/ and MockChildToken.sol is in test/mocks/child/. (You might need to create these subdirectories if they don't exist.)
Install dependencies: This typically fetches OpenZeppelin contracts and other project dependencies.

    npm install # or yarn install

Build the contracts:

    forge build

Run the PoC test:

    forge test --match-path test/InfiniteWithdrawal.t.sol -vvvv

Expected Output:

You'll see console logs showing the Bridge ETH balance unexpectedly increasing with each withdrawal. This clearly proves the permanent accumulation of user ETH. The test will actually FAIL because the final balance is way off from what it should be.

    [FAIL: Bridge ETH balance did not decrease as expected (for total withdrawals): 13000000000000000000 !~= 6700000000000000000 (max delta: 10000000000000000, real delta: 6300000000000000000)]       testInfiniteIMXWithdrawal() (gas: 183689)
