pragma solidity >0.5.6;
pragma experimental ABIEncoderV2;

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

    constructor() public{
        owner = msg.sender;
    }

    modifier registered(bytes32 _hash){
        require(isRegistered(_hash) , "Document not registered;");
        _;
    }
    modifier notRegistered(bytes32 _hash){
        require(!isRegistered(_hash) , "Document already registered;");
        _;
    }
    modifier diverseInputs(bytes32 _newHash , bytes32 _previousHash){
        require(_newHash != _previousHash , "The revisioned document is equal to the old one");
        _;
    }

    modifier oldRegisteredNewUnregistered(bytes32 _newHash,bytes32 _previousHash){
        require(isRegistered(_previousHash) && !isRegistered(_newHash) , "Document is not present or the revision it's been already registered");
        _;
    }

    function isRegistered(bytes32 _hash)
        public view returns (bool)
        {
            return (registry[_hash].documentHash == _hash);
        }

    function isRevisioned(bytes32 _protocol)
        public view returns (bool){
            return (registry[_protocol].newHash != _protocol);
        }

    function registerDocument(bytes32 _hash, string calldata _metadata) external notRegistered(_hash){
            registry[_hash].signer = msg.sender;
            registry[_hash].documentHash = _hash;
            registry[_hash].date = block.timestamp;
            registry[_hash].previousHash = _hash;
            registry[_hash].revisionNumber = 1;
            registry[_hash].newHash = _hash;
            registry[_hash].jsonMetadata = _metadata;
            emit Registered(msg.sender , _hash , block.timestamp);
    }

    function registerDocumentRevision(bytes32 _newHash , bytes32 _previousHash) external
    diverseInputs(_newHash,_previousHash) oldRegisteredNewUnregistered(_newHash,_previousHash){        
            /*inserisco nuova versione documento*/
            registry[_newHash].signer = msg.sender;
            registry[_newHash].documentHash = _newHash;
            registry[_newHash].date = block.timestamp;
            registry[_newHash].previousHash = _previousHash;
            registry[_newHash].revisionNumber = registry[_previousHash].revisionNumber + 1;
            registry[_newHash].newHash = _newHash;
            registry[_newHash].jsonMetadata = registry[_previousHash].jsonMetadata;
            emit Registered(msg.sender , _newHash , block.timestamp);

            /*aggiorno riferimenti versione precedente documento*/
            registry[_previousHash].newHash = _newHash;
            emit Revisioned(msg.sender , _previousHash , block.timestamp);
    }    

    function getLatestRevision(bytes32 _hash) public view
    registered(_hash) returns (bytes32){
        bytes32 latestRev = registry[_hash].documentHash;
        while(registry[latestRev].documentHash != registry[latestRev].newHash){
            latestRev = registry[latestRev].newHash;
            }
        return latestRev;
    }

    function getFullRevisionHistory(bytes32 _hash) external view 
    registered(_hash) returns (bytes32[] memory){
        bytes32 latestRevision = getLatestRevision(_hash);
        uint n = registry[latestRevision].revisionNumber;
        bytes32[] memory history = new bytes32[](n);
        for(uint i = n; i >= 1 ; i--){
            history[i-1] = registry[latestRevision].documentHash;
            latestRevision = registry[latestRevision].previousHash;
            }
        return history;
    }

    function getPartialRevisionHistory(bytes32 _hash) external view 
    registered(_hash) returns (bytes32[] memory){
        bytes32 tmp = _hash;
        uint n = registry[tmp].revisionNumber;
        bytes32[] memory history = new bytes32[](n);
        for(uint i = n; i >= 1 ; i--){
            history[i-1] = registry[tmp].documentHash;
            tmp = registry[tmp].previousHash;
            }
        return history;
    }

    function getDocument(bytes32 _hash) registered(_hash) external view returns(OutputDocument memory outputDocument){
            return OutputDocument(registry[_hash].documentHash , registry[_hash].date , registry[_hash].jsonMetadata, registry[_hash].revisionNumber);
        }

    struct OutputDocument{
        bytes32 _hash;
        uint date;
        string jsonMetadata;
        uint revisionNumber;
    }
}
