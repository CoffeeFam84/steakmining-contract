// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SteakDAO is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 2 ether;
    uint256 public Wlcost = 1 ether;
    uint256 constant public maxSupply = 200;
    uint256 public maxMintAmount = 5;
    mapping(address => uint256) public mintPerWallet;
    bool public paused = false;
    mapping(address => bool) public whitelisted;
    
    address public daoWallet = 0x7A0b8D56DDBAa1B4b2B51B634714348897108792;

    constructor(string memory _initBaseURI) ERC721("La Brigade De Cuisine", "LBDC") {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 amount) public payable {
        require(!paused, "paused");
       
        require(amount > 0, "amount shouldn't be zero");
        require(mintPerWallet[msg.sender] + amount <= maxMintAmount, "Can't mint more than max Mint");
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply, "Max supply exceeded");
        uint256 price = cost;
        if ( whitelisted[msg.sender] ) {
            price = Wlcost;
        }
        require(msg.value >= price * amount, "insufficient funds");
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply+i);
        }
        mintPerWallet[msg.sender] += amount;
  
        payable(daoWallet).transfer(address(this).balance);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWlcost(uint256 _newWlcost) public onlyOwner {
        Wlcost = _newWlcost;
    }

    function setWhitelisted(address _address, bool _whitelisted)
        public
        onlyOwner
    {
        whitelisted[_address] = _whitelisted;
    }

    function setWhitelistAddresses(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    //
    function mintCost(address _minter)
        external
        view
        returns (uint256)
    {
        if (whitelisted[_minter]) return Wlcost;
        return cost;
    }
}
