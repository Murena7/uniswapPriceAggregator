// import "@nomiclabs/hardhat-web3";
import hre from 'hardhat';
import {buildBalanceTransformer} from './helper/tokens.helper';
import BigNumber from 'bignumber.js';
import fs from 'fs';

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
    ///
    const artifactPath = await hre.artifacts.getArtifactPaths();

    //@ts-ignore
    const abiInfo = JSON.parse(fs.readFileSync(artifactPath[4]));
    //@ts-ignore
    const webContract = new hre.web3.eth.Contract(abiInfo.abi, deployedContract.address);

    const result1 = await webContract.methods.getCurrentPrice({ sendToken: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', getToken: '0xdac17f958d2ee523a2206206994597c13d831ec7'}).call();
    console.log(result1.getPrice, result1.getSymbol, result1.getDecimal);
    // const pairAddress = await deployedContract.getCurrentPrice('0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', '0xdac17f958d2ee523a2206206994597c13d831ec7');
    // console.log('Result', buildBalanceTransformer(new BigNumber(pairAddress[0].toString()), pairAddress[2]).toString(), pairAddress[1], pairAddress[2]);
    const pairAddressesArr = await deployedContract.getCurrentPriceArr([{ sendToken: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', getToken: '0xdac17f958d2ee523a2206206994597c13d831ec7'}]);
    console.log("Token address:", deployedContract.address);
    for (let i = 0; i < pairAddressesArr.length; i++ ) {
        console.log('Result', i, buildBalanceTransformer(new BigNumber(pairAddressesArr[i].getPrice.toString()), pairAddressesArr[i].getDecimal).toString(), pairAddressesArr[i].getSymbol, pairAddressesArr[i].getDecimal, pairAddressesArr[i].status);
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
