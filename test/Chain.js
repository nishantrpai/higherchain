const { ethers } = require("hardhat");

function getRandomColor() {
  const letters = '0123456789ABCDEF';
  let color = '#';
  for (let i = 0; i < 6; i++) {
    color += letters[Math.floor(Math.random() * 16)];
  }
  return color;
}

async function main() {
  const colorContractAddress = "0x84a5413b6d840C75Dc8e5F6Eb56E0D1C3eD3337C";
  const isTestnet = true; // Set this according to your environment

  const Chain = await ethers.getContractFactory("Chain");
  const chain = await Chain.deploy(colorContractAddress, isTestnet);

  await chain.waitForDeployment();

  console.log('Chain Contract Deployed at ' + chain.target);

  // Mint 10-20 random colors to the specified address
  const recipientAddress = "0x5A8064F8249D079f02bfb688f4AA86B6b2C65359";
  const numMints = Math.floor(Math.random() * 11) + 10; // Random number between 10 and 20
  const mintedColors = new Set();

  for (let i = 0; i < numMints; i++) {
    let color;
    do {
      color = getRandomColor();
    } while (mintedColors.has(color));
    mintedColors.add(color);

    const mintTx = await chain.mint(recipientAddress, color);
    await mintTx.wait();
    console.log(`Minted NFT to ${recipientAddress} with color ${color}`);
  }

  // Get the token ID of the last minted NFT
  const tokenId = await chain.nextTokenId() - 1n;
  console.log(`Token ID of the last minted NFT: ${tokenId}`);

  // Get the token URI (which includes the SVG) for the last minted token
  const tokenURI = await chain.tokenURI(tokenId);
  console.log(`Token URI for token ${tokenId}:`);
  console.log(tokenURI);
  
  // base64 json to json
  const json = JSON.parse(atob(tokenURI.split(',')[1]));
  // copy to clipboard
  var proc = require('child_process').spawn('pbcopy'); 
  proc.stdin.write(json.image); proc.stdin.end();

  console.log('https://base-sepolia.blockscout.com/address/' + chain.target + '/transactions');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
