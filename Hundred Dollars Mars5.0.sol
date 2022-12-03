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

    IERC20 USDT;
    uint public totalSupply;
    string public baseURI;
    string public constant baseExtension = ".json";
    uint256 constant ONE_ETHER = 10 ** 18;

    //round
    bool roundOne;
    bool roundTwo;
    bool roundThree;
    //fund
    uint256 public cost;
    mapping(address => uint) public ETHBalance;
    mapping(address => uint) public usdtBalance;
    mapping(address => mapping(address => uint256)) public erc20Balance;
    mapping(address => uint)public role;
    //address [] public whiteList;

    //team
    mapping(uint => uint []) nemberList;
    mapping(uint => mapping(uint => bool)) public isNemberOf;
    mapping(uint => string) internal specialTokenURI;
    mapping(uint => bool) internal isChampion;

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

    }

    receive() external payable {}
//setting

    function setNFTPrice(uint256 price) public onlyRole(DATA_ADMIN) {
        cost = price;
    }

    function setBaseURI (string memory _baseURI) public onlyRole(DATA_ADMIN) {
        baseURI = _baseURI;
    }

    function setRoundOneStar() public onlyRole(DATA_ADMIN){
        roundOne = true;
    }

    function setRoundTwoStar() public onlyRole(DATA_ADMIN){
        roundTwo = true;
    }

    function setRoundThreeStar() public onlyRole(DATA_ADMIN){
        roundThree = true;
    }

    function setSpecialTokenURI(uint tokenId, string memory _tokenURI) public onlyRole(DATA_ADMIN) {
        isChampion[tokenId] = true;
        specialTokenURI[tokenId] = _tokenURI;
    }
//mint function
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

    function publicMintRoundOne(address to) public {
        require(totalSupply <= 150,"Maximum roundOne supply exceeded");
        require(balanceOf(to) <= 3,"every address only mint 3 max");
        require(roundOne,"not start or ended");
        safeMint(to);
    }

    function publicMintRoundTwo(address to, uint amount) public payable {
        require(msg.value >= amount * cost,"invalid eth value");
        require(totalSupply + amount <= 300,"Maximum roundOne supply exceeded");
        require(balanceOf(to) + amount <= 5,"every address can only mint 5 max");
        require(roundTwo,"not start or ended");
        safeMintByAmount(to,amount);
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        totalSupply++;
    }

    function safeMintByAmount(address to, uint amount) internal {
        for(uint i; i < amount; i++) {
            safeMint(to);
        }
    }

    function MintByRole(address to,uint amount) public {
        require(role[msg.sender] > 0,"already minted");
        require(totalSupply + amount <= 3000,"Maximum supply exceeded");
        safeMintByAmount(to,amount);
        role[msg.sender] --;
    }
//fund

    function depositETH(uint amount) public payable {
        address user = msg.sender;
        uint amountIn = amount * ONE_ETHER;
        require(msg.value == amountIn,"invalid number");
        ETHBalance[user] += amountIn;
    }

    function depositUSDT(uint amount) public {
        address user = msg.sender;
        uint amountIn = amount * ONE_ETHER;
        USDT.transferFrom(user,address(this),amountIn);
        usdtBalance[user] += amountIn;
    }

    function depositERC20(address _ERC20, uint amount) public {
        IERC20 ERC20 = IERC20(_ERC20);
        address user = msg.sender;
        uint amountIn = amount * ONE_ETHER;
        ERC20.transferFrom(user,address(this),amountIn);
        erc20Balance[_ERC20][user] += amountIn;
    }

    function depositERC20AndDisbute(address _ERC20 ,uint tokenAmount,uint nemberAmount) public {
        depositERC20(_ERC20,tokenAmount);
        distributeERC20Token(_ERC20,tokenAmount,nemberAmount);
    }

    function depositUSDTAndDisbute(uint tokenAmount,uint nemberAmount) public {
        depositUSDT(tokenAmount);
        distributeUSDT(tokenAmount,nemberAmount);
    }


    function random(uint seed) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
        (seed + block.difficulty)%50,block.timestamp))) % (totalSupply) + 1;
    }


    function distributeERC20Token(address _ERC20, uint tokenAmount,uint nemberAmount) public{
        IERC20 ERC20 = IERC20(_ERC20);
        require(erc20Balance[_ERC20][msg.sender] >= tokenAmount * ONE_ETHER,"not enought ERC20");
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        erc20Balance[_ERC20][msg.sender] -= tokenAmount * ONE_ETHER;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            ERC20.transfer(luckAddress, tokenAmountPerNember);
        }   
    }

    function distributeETH(uint tokenAmount,uint nemberAmount) external{
        require(ETHBalance[msg.sender] >= tokenAmount * ONE_ETHER,"not enought ETH");
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            payable (luckAddress).transfer(tokenAmountPerNember);
        }
    }

    function distributeUSDT(uint tokenAmount,uint nemberAmount) public onlyRole(MARS_ADMIN){
        require(usdtBalance[msg.sender] >= tokenAmount * ONE_ETHER,"not enought USDT");
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        usdtBalance[msg.sender] -= tokenAmount * ONE_ETHER;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            USDT.transfer(luckAddress, tokenAmountPerNember);
        }
    }



    function distributeETHByRole(uint tokenAmount,uint nemberAmount) external onlyRole(FUND_ADMIN){
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        for(uint i; i <nemberAmount; i ++ ){
            address luckAddress = ownerOf(random(i));
            payable (luckAddress).transfer(tokenAmountPerNember);
        }
    }
// authority power
    function withdrawToken(address _ERC20) public onlyRole(FUND_ADMIN){
        IERC20 ERC20W = IERC20(_ERC20);
        ERC20W.transfer(msg.sender,ERC20W.balanceOf(address(this)));
    }

    function withdrawETH() public onlyRole(FUND_ADMIN){
        address payable user = payable(msg.sender);
        user.transfer((address(this)).balance);
    }
//TEAM


    function granToTeamNember(uint256 leaderTokenId,uint256 nemberTokenId) public {
        require(
            _exists(nemberTokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        require(ownerOf(leaderTokenId) == msg.sender, "not owner of leaderNFT");
        require(isNemberOf[nemberTokenId][leaderTokenId] == false, "alredy nember of you");
        require(!(ownerOf(nemberTokenId) == msg.sender), "nft of you balance");
        nemberList[leaderTokenId].push(nemberTokenId);
        isNemberOf[nemberTokenId][leaderTokenId] = true;
    }

    function granToTeamNemberByArray(uint256 leaderTokenId,uint256 [] memory nemberTokenId) public {

        for(uint i; i < nemberTokenId.length; i ++) {
            require(
                _exists(nemberTokenId[i]),
                "ERC721Metadata: URI query for nonexistent token"
            );
            require(ownerOf(leaderTokenId) == msg.sender, "not owner of leaderNFT");
            require(isNemberOf[nemberTokenId[i]][leaderTokenId] == false, "alredy nember of you");
            require(!(ownerOf(nemberTokenId[i]) == msg.sender), "nft of you balance");
            nemberList[leaderTokenId].push(nemberTokenId[i]);
            isNemberOf[nemberTokenId[i]][leaderTokenId] = true;
        }
    }

    function revokeToTeamNember(uint256 leaderTokenId,uint256 nemberTokenId) public {
        require(ownerOf(leaderTokenId) == msg.sender, "not owner of leaderNFT");
        require(isNemberOf[nemberTokenId][leaderTokenId] == true, "not nember of you");
        for(uint i; i < nemberList[leaderTokenId].length; i ++){
            if(nemberList[leaderTokenId][i] == nemberTokenId){
                nemberList[leaderTokenId][i] = nemberList[leaderTokenId][nemberList[leaderTokenId].length - 1];
                nemberList[leaderTokenId].pop();
            }
        }
        isNemberOf[nemberTokenId][leaderTokenId] = false;
    }

    function revokeToTeamNemberByArray(uint256 leaderTokenId,uint256 [] memory nemberTokenId) public {
        for(uint j; j < nemberTokenId.length; j ++) {
            require(ownerOf(leaderTokenId) == msg.sender, "not owner of leaderNFT");
            require(isNemberOf[nemberTokenId[j]][leaderTokenId] == true, "not nember of you");
            for(uint i; i < nemberList[leaderTokenId].length; i ++){
                if(nemberList[leaderTokenId][i] == nemberTokenId[j]){
                    nemberList[leaderTokenId][i] = nemberList[leaderTokenId][nemberList[leaderTokenId].length - 1];
                    nemberList[leaderTokenId].pop();
                }
            }
            isNemberOf[nemberTokenId[j]][leaderTokenId] = false;
        }
    }

    function distributeERC20TokenForTeamNember(address _ERC20 ,uint tokenId,uint tokenAmount,uint nemberAmount) public{
        IERC20 ERC20 = IERC20(_ERC20);
        require(ownerOf(tokenId) == msg.sender,"not nft owner");
        require(erc20Balance[_ERC20][msg.sender] >= tokenAmount * ONE_ETHER,"not enought ERC20");
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        uint nemberLength = nemberList[tokenId].length - 1;
        for(uint i; i < nemberAmount; i ++ ){
            address luckAddress = ownerOf(nemberList[tokenId][(random(i) % nemberLength)]);
            ERC20.transfer(luckAddress, tokenAmountPerNember);
        }
        erc20Balance[_ERC20][msg.sender] -= tokenAmount * ONE_ETHER;
    }

    function distributeUSDTForTeamNember(uint tokenId,uint tokenAmount,uint nemberAmount) public{
        require(ownerOf(tokenId) == msg.sender,"not nft owner");
        require(usdtBalance[msg.sender] >= tokenAmount * ONE_ETHER,"not enought USDT");
        uint tokenAmountPerNember = tokenAmount * ONE_ETHER / nemberAmount;
        uint nemberLength = nemberList[tokenId].length - 1;
        for(uint i; i < nemberAmount; i ++ ){
            address luckAddress = ownerOf(nemberList[tokenId][(random(i) % nemberLength)]);
            USDT.transfer(luckAddress, tokenAmountPerNember);
        }
        usdtBalance[msg.sender] -= tokenAmount * ONE_ETHER;
    }

    

    function returnTeamNember(uint leaderTokenId) public view returns(uint [] memory) {
        return nemberList[leaderTokenId];
    }
//tokenURI

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721,AccessControl)
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
        if(isChampion[tokenId]) {
            return specialTokenURI[tokenId];
        }
        else {
            return  string(abi.encodePacked(baseURI,tokenId.toString(),baseExtension));
        }

    }
}
