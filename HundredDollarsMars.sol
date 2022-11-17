// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HundredDollarsMars is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    IERC20 ERC20;

    string public baseURI;
    string public constant baseExtension = ".json";
    uint256 constant ONE_ETHER = 10 ** 18;

    constructor() ERC721("Hundred Dollars Mars", "HDM") {}

    function setERC20(address _ERC20) public onlyOwner {
        ERC20 = IERC20(_ERC20);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeMintTen(address to) public onlyOwner {
        for(uint i; i < 10; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }
    function random(uint seed) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
        (seed + block.difficulty)%50,block.timestamp))) % 30;
    }
    function distributeERC20(uint tokenAmount,uint nemberAmount) external onlyOwner{
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            ERC20.transfer(luckAddress, tokenAmountPerNember);
        }
    }

    function withdrawToken(address _ERC20) external onlyOwner{
        IERC20 ERC20W = IERC20(_ERC20);
        ERC20W.transfer(msg.sender,ERC20W.balanceOf(address(this)));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return  string(abi.encodePacked(baseURI,tokenId.toString(),baseExtension));

    }
}
