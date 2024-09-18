// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IColorContract {
    function getColorData(string memory color) external view returns (uint256, bool, uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Chain is ERC721, Ownable {
    using Strings for uint256;

    uint256 public nextTokenId;
    uint256[] public colors;
    string private constant BASE_SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 625 625" fill="#fff" style="background:#fff"><path d="M 312 162.75 L 172 302.5 L 213.875 343.875 L 282.375 275.125 L 282.42 462.5 H 343.125 V 275.125 L 412 343.875 L 453 302.5 L 313.25 162.75 H 312 Z" fill="#333"/></svg>';
    IColorContract private colorContract;

    constructor(address _colorContractAddress) ERC721("ChainNFT", "CHN") {
        nextTokenId = 1;
        colorContract = IColorContract(_colorContractAddress);
    }

    function mint(address to, string memory color) external {
        require(bytes(color).length == 7, "Color must be in #RRGGBB format");
        (uint256 colorId, bool exists, ) = colorContract.getColorData(color);
        require(exists, "Color does not exist in the color contract");
        require(colorContract.ownerOf(colorId) == msg.sender, "You don't own this color");
        require(!colorExists(color), "Color already minted");

        _safeMint(to, nextTokenId);
        colors.push(uint256(keccak256(abi.encodePacked(color))));
        nextTokenId++;
    }

    function colorExists(string memory color) internal view returns (bool) {
        uint256 colorHash = uint256(keccak256(abi.encodePacked(color)));
        for (uint256 i = 0; i < colors.length; i++) {
            if (colors[i] == colorHash) {
                return true;
            }
        }
        return false;
    }

    function generateSVG() internal view returns (string memory) {
        string memory svg = BASE_SVG;
        uint256 viewBoxSize = 625 - (colors.length * 2);
        string memory viewBox = string(abi.encodePacked("0 0 ", viewBoxSize.toString(), " ", viewBoxSize.toString()));

        for (uint256 i = 0; i < colors.length; i++) {
            string memory color = string(abi.encodePacked("#", uint256(colors[i]).toHexString(6)));
            svg = string(abi.encodePacked(svg, '<rect x="', (283 + i * 60).toString(), '" y="', (462 + i * 60).toString(), '" width="60" height="60" fill="', color, '" />'));
        }

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="',
            viewBox,
            '" fill="#fff" style="background:#fff">',
            svg,
            '</svg>'
        ));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory svg = generateSVG();
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked(
                '{"name": "ChainNFT #', tokenId.toString(),
                '", "description": "A dynamic NFT with colors", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )))
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}