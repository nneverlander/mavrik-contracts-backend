pragma solidity ^0.5.0;

import "./ERC1155.sol";

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items.
*/
contract ERC1155Mintable is ERC1155 {

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // id => creators
    mapping (uint256 => address) public creators;

    // A nonce to ensure we have a unique id each time we mint.
    uint256 public nonce;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    modifier creatorsOnly(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(creators[_ids[i]] == msg.sender);
        }
        _;
    }

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    // Creates a new token type and assigns _initialSupply to minter
    function create(uint256 _initialSupply, string calldata _uri) external returns(uint256 _id) {

        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
    }

    // Mint tokens of a type. Assign directly to _to[].
    function mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external creatorOnly(_id) {

        //todo: may be check for max supply this token can have? right now an infinite number can be minted

        require(_to.length == _quantities.length, "_to and _quantities array lengths must match.");

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            if (to.isContract()) {
                require(IERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0x0), _id, quantity, '') == ERC1155_RECEIVED, "Receiver contract did not accept the transfer.");
            }

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);
        }
    }

    // Batch mint tokens of different types. Assign directly to _to.
    function batchMint(address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external creatorsOnly(_ids) {
        require(_ids.length == _amounts.length, "_to and _amounts array lengths must match");
        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, address(0x0), _ids, _amounts, '') == ERC1155_BATCH_RECEIVED, "Receiver contract did not accept the transfer.");
        }

         // Executing all minting
        for (uint256 i = 0; i < _ids.length; i++) {
          // Update storage balance
          balances[_ids[i]][_to] = balances[_ids[i]][_to].add(_amounts[i]);
        }

        // Emit batch mint event
        emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);
    }

    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        emit URI(_uri, _id);
    }
}
