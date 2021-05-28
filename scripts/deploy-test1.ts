// import "@nomiclabs/hardhat-web3";
import hre from 'hardhat';

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
    const Token = await hre.ethers.getContractFactory("Greeter");
    const token = await Token.deploy("Hello, Hardhat!");

    console.log("Token address:", token.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
