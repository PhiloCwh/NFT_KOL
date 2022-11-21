// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HundredDollarsMars is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    bytes32 public constant DATA_ADMIN = keccak256("DATA_ADMIN");
    bytes32 public constant FUND_ADMIN = keccak256("FUND_ADMIN");
    bytes32 public constant MARS_ADMIN = keccak256("MARS_ADMIN");

    IERC20 ERC20;
    IERC20 USDT;
    uint public totalSupply;
    string public baseURI;
    string public constant baseExtension = ".json";
    uint256 constant ONE_ETHER = 10 ** 18;

    mapping(address => uint)public role;
    address [] public whiteList;

    constructor() ERC721("Hundred Dollars Mars", "HDM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DATA_ADMIN, msg.sender);
        _grantRole(FUND_ADMIN, msg.sender);
        _grantRole(MARS_ADMIN, msg.sender);

        role[0xb1Fa9D21134263Ef01e155b695CB4Dc781C14AD8] = 8;
        role[0x65BCa6e57210d8eb7f7754AC28C6725fC60fe248] = 8;
        role[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 8;
        USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        baseURI = "ipfs://QmP4Y3oUtvwgpkT6FSEaNdFVWSUb7fEmnfKVfhRGLEwQBX/";
        _tokenIdCounter.increment();
        whiteList = [0x65BCa6e57210d8eb7f7754AC28C6725fC60fe248,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2];

    }

    function setERC20(address _ERC20) public onlyRole(DATA_ADMIN){
        ERC20 = IERC20(_ERC20);

    }

    function setBaseURI (string memory _baseURI) external onlyRole(DATA_ADMIN) {
        baseURI = _baseURI;
    }

    function safeMintForThree(address to) public {

        for(uint i; i < 3; i++){
            require(totalSupply < 640,"Maximum supply exceeded");
            require(balanceOf(to) < 3,"only mint 3 max");
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            totalSupply++;
        }
    }

    function safeMint(address to) public {
        require(totalSupply < 640,"Maximum supply exceeded");
        require(balanceOf(to) < 3,"every address only mint 3 max");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        totalSupply++;
    }

    function safeMintByRole(address to) public {
        require(role[msg.sender] > 0,"already minted");
        require(totalSupply < 800,"Maximum supply exceeded");
        for(uint i; i < 100; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            totalSupply++;
        }
        role[msg.sender] --;
    }
    function random(uint seed) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
        (seed + block.difficulty)%50,block.timestamp))) % (totalSupply) + 1;
    }


    function distributeERC20Token(uint tokenAmount,uint nemberAmount) external onlyRole(FUND_ADMIN){
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            ERC20.transfer(luckAddress, tokenAmountPerNember);
        }
    }

    function distributeUSDT(uint tokenAmount,uint nemberAmount) external onlyRole(MARS_ADMIN){
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            USDT.transfer(luckAddress, tokenAmountPerNember);
        }
    }


    function distributeETH(uint tokenAmount,uint nemberAmount) external onlyRole(FUND_ADMIN){
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            payable (luckAddress).transfer(tokenAmountPerNember);
        }
    }

    function withdrawToken(address _ERC20) external onlyRole(FUND_ADMIN){
        IERC20 ERC20W = IERC20(_ERC20);
        ERC20W.transfer(msg.sender,ERC20W.balanceOf(address(this)));
    }

    function withdrawETH() external onlyRole(FUND_ADMIN){
        address payable user = payable(msg.sender);
        user.transfer((address(this)).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
