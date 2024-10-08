// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IColorContract {
    function getColorData(
        string memory color
    ) external view returns (uint256, bool, uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Chain is ERC721, Ownable {
    using Strings for uint256;

    uint256 public nextTokenId;
    string[] public colors;
    string private constant BASE_SVG =
        '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 625 625" fill="#fff" style="background:#fff"><g transform="translate(395, 395)"><path id="arrow" d="M 0 -149.75 L -140 0 L -98.125 41.375 L -29.625 -27.375 L -29.58 159.5 H 31.125 V -27.375 L 100 41.375 L 141 0 L 1.25 -149.75 H 0 Z" fill="CURRENT_COLOR"/></g></svg>';
    IColorContract private colorContract;
    bool public isTestnet;

    constructor(
        address _colorContractAddress,
        bool _isTestnet
    ) ERC721("ChainNFT", "CHN") Ownable(msg.sender) {
        nextTokenId = 0;
        colorContract = IColorContract(_colorContractAddress);
        isTestnet = _isTestnet;
    }

    function mint(address to, string memory color) external {
        require(bytes(color).length == 7, "Color must be in #RRGGBB format");
        if (!isTestnet) {
            (uint256 colorId, bool exists, ) = colorContract.getColorData(
                color
            );
            require(exists, "Color does not exist in the color contract");
            require(
                colorContract.ownerOf(colorId) == msg.sender,
                "You don't own this color"
            );
        }
        require(!colorExists(color), "Color already minted");

        _safeMint(to, nextTokenId);
        colors.push(color);
        nextTokenId++;
    }

    function colorExists(string memory color) internal view returns (bool) {
        for (uint256 i = 0; i < colors.length; i++) {
            if (keccak256(abi.encodePacked(colors[i])) == keccak256(abi.encodePacked(color))) {
                return true;
            }
        }
        return false;
    }

    function generateSVG(uint256 tokenId) internal view returns (string memory) {
        string memory svg = BASE_SVG;
        svg = string(abi.encodePacked('<g transform="translate(395, 395)"><path id="arrow" d="M 0 -149.75 L -140 0 L -98.125 41.375 L -29.625 -27.375 L -29.58 159.5 H 31.125 V -27.375 L 100 41.375 L 141 0 L 1.25 -149.75 H 0 Z" fill="', colors[tokenId], '"/>'));
        uint256 viewBoxWidth = 800;
        uint256 viewBoxHeight = 800 + (tokenId * 50);
        uint256 centerOffsetX = tokenId * 5;
        string memory viewBox = string(
            abi.encodePacked(
                "-",
                centerOffsetX.toString(),
                " 0 ",
                viewBoxWidth.toString(),
                " ",
                viewBoxHeight.toString()
            )
        );

        for (uint256 i = 0; i < tokenId; i++) {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<rect x="-29.5" y="',
                    (158 + (i * 60)).toString(),
                    '" width="60.5" height="60.5" fill="',
                    colors[i],
                    '" />'
                )
            );
        }

        svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="',
                viewBox,
                '" fill="#000" style="background:#fff;">',
                svg,
                '</g></svg>'
            )
        );

        return svg;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(tokenId < nextTokenId, "ERC721: invalid token ID");
        string memory svg = generateSVG(tokenId);
        string memory encodedSvg = Base64.encode(bytes(svg));
        
        string memory json = string(
            abi.encodePacked(
                '{"name": "ChainNFT #',
                Strings.toString(tokenId),
                '", "description": "A dynamic NFT with colors", "image": "data:image/svg+xml;base64,',
                encodedSvg,
                '"}'
            )
        );
        
        string memory encodedJson = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", encodedJson));
    }
}
