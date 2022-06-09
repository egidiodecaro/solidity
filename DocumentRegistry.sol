pragma solidity ^0.5.6;

/* 
 * DocumentRegistry contract by eg
 */
contract DocumentRegistry{

    address internal owner;

    struct Document{
        address signer;
        bytes32 documentHash;
        uint date;
        bytes32 previousHash;
        uint revisionNumber;
        bytes32 newHash;
        string jsonMetadata;
    }

    mapping(bytes32 => Document) internal registry;

    event Registered(address indexed _signer, bytes32 _protocol, uint _date);
    event Revisioned(address indexed _signer, bytes32 _protocol, uint _date);
    event DocumentNotPresent(address indexed _signer, bytes32 _protocol, uint _date);
    event DocumentAlreadyPresent(address indexed _signer, bytes32 _protocol, uint _date);
    event ExceptionEvent(address indexed _signer, string message , uint date);

    constructor() public{
        owner = msg.sender;
    }

     function isRegistered(bytes32 _hash)
    public view returns (bool)
    {
        return (registry[_hash].documentHash == _hash);
    }

    function registerDocument(bytes32 _hash, string calldata _metadata) external {
        uint date = now;

        if(!isRegistered(_hash)){
            registry[_hash].signer = msg.sender;
            registry[_hash].documentHash = _hash;
            registry[_hash].date = date;
            registry[_hash].previousHash = _hash;
            registry[_hash].revisionNumber = 1;
            registry[_hash].newHash = _hash;
            registry[_hash].jsonMetadata = _metadata;
            emit Registered(msg.sender , _hash , date);
        }
        else emit DocumentAlreadyPresent(msg.sender,  _hash , date);
    }

    function registerDocumentRevision(bytes32 _newHash , bytes32 _previousHash) external {
        uint date = now;

        if(_newHash == _previousHash){
            emit ExceptionEvent(msg.sender , "the revisioned document is equal to the old one" , date);
            return;
        }

        if(isRegistered(_previousHash) && !isRegistered(_newHash)){
            /*inserisco nuova versione documento*/
            registry[_newHash].signer = msg.sender;
            registry[_newHash].documentHash = _newHash;
            registry[_newHash].date = date;
            registry[_newHash].previousHash = _previousHash;
            registry[_newHash].revisionNumber = registry[_previousHash].revisionNumber + 1;
            registry[_newHash].newHash = _newHash;
            registry[_newHash].jsonMetadata = registry[_previousHash].jsonMetadata;
            emit Registered(msg.sender , _newHash , date);

            /*aggiorno riferimenti versione precedente documento*/
            registry[_previousHash].newHash = _newHash;
            emit Revisioned(msg.sender , _previousHash , date);

        }
        else emit DocumentNotPresent(msg.sender , _previousHash , date);
    }

    function isRevisioned(bytes32 _protocol)
    public view returns (bool)
    {
        return (registry[_protocol].newHash != _protocol);
    }

    function getLatestRevision(bytes32 _hash) public returns (bytes32){
        if(isRegistered(_hash)){
            bytes32 latestRev = registry[_hash].documentHash;
            while(registry[latestRev].documentHash != registry[latestRev].newHash){
                
                latestRev = registry[latestRev].newHash;
            }
        return latestRev;
        }
        else
        emit DocumentNotPresent(msg.sender , _hash , now);
        return "";
    }

    function getRevisionHistory(bytes32 _hash) external returns (bytes32[] memory){
        if(registry[_hash].documentHash == _hash){
            bytes32 latestRevision = getLatestRevision(_hash);
            uint n = registry[latestRevision].revisionNumber;
            bytes32[] memory history = new bytes32[](n);
            for(uint i = n; i >= 1 ; i--){
                history[i-1] = registry[latestRevision].documentHash;
                latestRevision = registry[latestRevision].previousHash;
                }
            return history;
        }
        else emit DocumentNotPresent(msg.sender , _hash , now);
    }
}