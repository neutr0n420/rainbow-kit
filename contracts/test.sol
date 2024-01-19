// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// This contract is an implementation of a non-fungible token (NFT) system using the ERC1155 
// standard. Users can create collections of tokens with a specified supply and price. 
// The contract owner can receive payments, and the details of each collection are stored in the idToECollection mapping.

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// This line declares the main contract named StreamSphere, which inherits from the ERC1155 
// and Ownable contracts. ERC1155 is a standard interface for multi-token contracts, and Ownable 
// provides basic authorization control functions.
contract StreamSphere is ERC1155, Ownable {
    // Declares a state variable to store the contract owner's address. The owner is set in the 
    // constructor and is of type payable to allow the owner to receive Ether.
    address payable contractOwner;
    // This is the constructor function that initializes the contract. It sets the contract 
    // owner to the address that deployed the contract (msg.sender) and calls the constructor of the ERC1155 contract with an empty string for the URI.
    constructor() ERC1155("") {
        contractOwner = payable(msg.sender);
    }
    // Defines a counter variable _tokenId of type Counters.Counter from the OpenZeppelin library. 
    // This counter will be used to assign unique IDs to tokens.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    struct ecollection {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 price;
        uint256 supply;
        uint256 supplyleft;
    }

    // Declares an event named ecollectionCreated that is emitted when a new collection is 
    // created. It logs various details such as the token ID, owner, creator, price, total supply, and remaining supply.
    event ecollectionCreated (
        uint256 indexed tokenId,
        address owner,
        address creator,
        uint256 price,
        uint256 supply,
        uint256 supplyleft
    );

    // Declares a mapping named idToECollection that associates each token ID with its corresponding ecollection struct.
    mapping (uint256 => ecollection) idToECollection;

    // Overrides the supportsInterface function from the ERC1155 contract to indicate that this contract supports the ERC1155 interface. The purpose of the supportsInterface function in this context is to provide compatibility with the ERC165 standard, which allows querying whether a contract supports a particular interface by checking its interface ID.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Defines a function createToken that allows users to create a new token with a given URI, 
    // supply, and price. It increments the token ID counter, mints the specified supply of tokens to 
    // the caller, sets the token URI, and calls createEcollection to store information about the new collection.
    function createToken(string memory tokenURI, uint256 supply, uint256 price) public payable {
        _tokenId.increment();
        uint256 currentToken = _tokenId.current();
        _mint(msg.sender, currentToken, supply, "");
        _setURI(tokenURI);
        createEcollection(currentToken, supply, price);
    }

    // Defines a private function createEcollection that updates the idToECollection mapping with information about the newly created collection. It also transfers the newly minted tokens from the creator to the contract and emits the ecollectionCreated event.
    function createEcollection(uint256 tokenId, uint256 supply, uint256 price) private {
        idToECollection[tokenId] = ecollection(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            supply,
            supply
        );

        _safeTransferFrom(msg.sender, address(this), tokenId, supply, "");

        emit ecollectionCreated(tokenId, address(this), msg.sender, price, supply, supply);
    }

    function buy(uint256 tokenId) public payable {
        uint256 price = idToECollection[tokenId].price;
        require(msg.value == price);
        require(idToECollection[tokenId].supplyleft >= idToECollection[tokenId].supply);
        idToECollection[tokenId].owner = payable(msg.sender);
        idToECollection[tokenId].supplyleft--;

        _safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        uint256 fee = price / 100;
        uint256 remaining = price - fee;

        payable(idToECollection[tokenId].creator).transfer(remaining);
        payable(contractOwner).transfer(fee);
    }

    function fetchMarketPlace() public view returns(ecollection[] memory) {
        uint counter = 0;
        uint length;

        for (uint i = 0; i < _tokenId.current(); i++) {
            if (idToECollection[i+1].supplyleft > 0) {
                length++;
            }
        }

        ecollection[] memory unsoldECollections = new ecollection[](length);
        for(uint i = 0; i < _tokenId.current(); i++){
            if (idToECollection[i+1].supplyleft > 0) {
                uint currentId = i+1;
                ecollection storage currentItem = idToECollection[currentId];
                unsoldECollections[counter] = currentItem;
                counter++;
            }
        }
        return unsoldECollections;
    }

    function fetchInventory() public view returns (ecollection[] memory){
        uint counter = 0;
        uint length;

        for (uint i = 0; i < _tokenId.current(); i++){
            if(idToECollection[i+1].owner == msg.sender){
                length++;
            }
        }

        ecollection[] memory myCollections = new ecollection[](length);
        for (uint i = 0; i < _tokenId.current(); i++) {
                if (idToECollection[i+1].owner == msg.sender) {
                    uint currentId = i+1;
                    ecollection storage currentItem = idToECollection[currentId];
                    myCollections[counter] = currentItem;
                    counter++;
                }
            }
            return myCollections;
    }

}