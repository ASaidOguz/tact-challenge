import { Blockchain, SandboxContract, TreasuryContract } from '@ton-community/sandbox';
import { toNano } from 'ton-core';
import { Task1 } from '../wrappers/Task1';
import '@ton-community/test-utils';
describe('Task1', () => {
    let blockchain: Blockchain;
    let task1: SandboxContract<Task1>;
    let deployer: SandboxContract<TreasuryContract>;
    const sub_value=5n;
    const add_value=10n;
    beforeEach(async () => {
        blockchain = await Blockchain.create();
        task1 = blockchain.openContract(await Task1.fromInit());
         deployer = await blockchain.treasury('deployer');
        const deployResult = await task1.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: task1.address,
            deploy: true,
            success: true,
        });
    });

    it('test-add', async () => {
        await task1.send(deployer.getSender(),{value:toNano("0.05")},{$$type:'Add',queryId:0n,number:add_value})
        console.log("Counter:",await task1.getCounter())
        expect(add_value).toEqual(await task1.getCounter());
    });
    it('test-substract', async () => {
        await task1.send(deployer.getSender(),{value:toNano("0.05")},{$$type:'Add',queryId:0n,number:add_value})
        await task1.send(deployer.getSender(),{value:toNano("0.05")},{$$type:'Subtract',queryId:0n,number:sub_value})
        expect(sub_value).toEqual(await task1.getCounter())
    });
    it('test-getter', async () => {
        expect(0n).toEqual(await task1.getCounter());
    });
});
