# About

Smart wallets on zkSync can be the `from` address of a transaction.

1. Create a basic AA on Ethereum
2. Create a basic AA on zkSync
3. Deploy, and send a userOp / transaction through them
   1. Not going to send an AA tx to Ethereum
   2. But will send an AA tx to zkSync

## Account abstraction libraries:

`forge install eth-infinitism/account-abstraction@v0.7.0 --no-commit`

`forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit`

Install the [foundry-zksync repo](https://github.com/matter-labs/foundry-zksync) and run the following command:

`forge build --zksync`

If you're having a hard time with build, delete the `out` folder and run the command again

At the end of each command when compiling, add the `--system-mode=true` modifier
This is gonna make that every time the system sees:
call(x, y, z) -> its gonna read it as system contract calls

Run tests like this: `forge test --mt testZkValidateTransaction --zksync`

[Bootloader in documentation](https://docs.zksync.io/zk-stack/components/zksync-evm/bootloader#bootloader)
