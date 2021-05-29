// import "@nomiclabs/hardhat-web3";
import hre from 'hardhat';
import {buildBalanceTransformer} from './helper/tokens.helper';
import BigNumber from 'bignumber.js';

async function main() {
    await hre.run('compile');

    //@ts-ignore
    const [deployer] = await hre.ethers.getSigners();

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    //@ts-ignore
    const rawContract = await hre.ethers.getContractFactory("PriceAggregator");
    const deployedContract = await rawContract.deploy();
    await deployedContract.deployed();

    const pairAddress = await deployedContract.getCurrentPrice('0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c', '0xe9e7cea3dedca5984780bafc599bd69add087d56');
    console.log('Result', buildBalanceTransformer(new BigNumber(pairAddress[0].toString()), pairAddress[2]).toString(), pairAddress[1], pairAddress[2]);
    const pairAddressesArr = await deployedContract.getCurrentPriceArr(['0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c', '0xe9e7cea3dedca5984780bafc599bd69add087d56'], ['0xe9e7cea3dedca5984780bafc599bd69add087d56', '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c']);

    for (let i = 0; i < pairAddressesArr[0].length; i++ ) {
        console.log('Result', i, buildBalanceTransformer(new BigNumber(pairAddressesArr[0][i].toString()), pairAddressesArr[2][i]).toString(), pairAddressesArr[1][i], pairAddressesArr[2][i]);
    }

    console.log("Token address:", deployedContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
