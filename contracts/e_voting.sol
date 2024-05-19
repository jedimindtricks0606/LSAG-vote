pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;
import "./LSAG.sol";

contract EVoting {

    event LogBoolValue(bool value);

    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        address delegate;
    }

    struct Proposal {
        uint voteCount;
    }

    struct keyImages {
        uint256 x;
        uint256 y;
    }

    address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;
    uint256[2][] pub_keys;
    keyImages[] I_array;
    address common;

    constructor(uint256[2][] memory _pubkeys) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        proposals.length = 3;
        pub_keys = _pubkeys;
    }

    function setCommon(address _common) public {
        require(msg.sender == chairperson, "sender is not the chairperson. cant set the common address");
        common = _common;
    }

    function bytesToUint(bytes memory b) internal returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function LSAG_verify(bytes memory message, uint256 c0, uint256[2] memory keyImage, uint256[] memory s, uint256[2][] memory publicKeys) internal returns (bool) {
        bool status = LSAG.verify(message, c0, keyImage, s, publicKeys);
        return status;

        if (!status) return false;
        for(uint i=0; i<I_array.length; i++) {
            if (keyImage[0] == I_array[i].x && keyImage[1] == I_array[i].y) return false;
        }
        keyImages memory new_keyimage;
        new_keyimage.x = keyImage[0];
        new_keyimage.y = keyImage[1];
        I_array.push(new_keyimage);
        return true;

    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint _message, uint256 c0, uint256[2] memory keyImage, uint256[] memory s) public returns (bool){
        bytes memory message = toBytes(_message);
        // require(msg.sender == common, "sender is not the common address");
        // require(LSAG_verify(message, c0, keyImage, s, pub_keys), "LSAG verification didn't work");

        // if ((msg.sender == common) && LSAG_verify(message, c0, keyImage, s, pub_keys)) {
        if ( LSAG_verify(message, c0, keyImage, s, pub_keys)) {
            // proposals[bytesToUint(message)-1].voteCount++;
            // emit LogBoolValue(true);
            return true;
        }

        return false;

        // return proposals[bytesToUint(message)-1].voteCount;
    }

    function winningProposal() public view returns (uint8 _winningProposal, uint256 winningVoteCount) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }
    }


    // function to convert uint to bytes
    function toBytes(uint256 value) internal pure returns (bytes memory) {
        return abi.encodePacked (value);
    }

    function toBytes1(uint256 x) public returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function ToBytes2(uint256 value) internal pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), value)
        }
        return result;
    }




    function test() public returns (bool) {
        uint256 _message = 2;
        // bytes memory _message1 = hex"0000000000000000000000000000000000000000000000000000000000000002";
        uint256 _c0 = 0x2a289d64bbee194d2d534f7047a01fde7daa1c68deee018efbebd7d3e5b22389;
        uint256[2] memory _keyImage = [0x573ee3fa981e1d1a06cd61447872202e94df3710de5758c4c16e98e3af1c1fdc,0x5f7ed3e0b1040aa907918642c22596f2d10e4be31d8ddabc32d9de4e8dc4bc7a];
        uint256[] memory _s = new uint256[](5);
        // uint256[2][] memory _publicKeys = new uint256[2][](5);

        _s[0] = 0xec9933b5397f7f7afb2030465d8364a347b395a19e9f8fe97b45437a3bdbd1fa;
        _s[1] = 0x1ce876112c3f088f8e39c77f22f598740609ac02e5dd96307e7666dd52f3865e;
        _s[2] = 0x6c6fac6a63b03840b7fe9b44b3d34c2fad65ff142f398a373de64a2ceb7012ff;
        _s[3] = 0x4d44522cbffc97779a2a033bb716adc864b4e46d8702322ba2c33b9f33dc6ca9;
        _s[4] = 0xc9cc0f0bc3492fb684c0f0df241d31520d0d0b72a8e809408d1f5db39783294c;

        // _publicKeys[0] = [42590531793497166628675028504179635324399256857914437964935353302914148351568, 70258465579541072633675745945063730848340228275334547582353094321566766441378];
        // _publicKeys[1] = [60513388830880094996730554983980138069854757315251102263155115679417548335711, 32355694484654553192302999522212060151412579940815018302926997831378376731361];
        // _publicKeys[2] = [82063651073125245392661557491700795580630394335542071037371659985228773067807, 41907949531061274289048481070997646377728047353101778990100613629391341188194];
        // _publicKeys[3] = [74676233269489733243890256545638083721514278356752931791012161293367886031123, 115337805785800369503682918354032851259849520768470083724462034320348662186709];
        // _publicKeys[4] = [72043771932791372809265531473147240182298347594767811673713431858361481622778, 106080253987756479864851315802389757709136351804234230761944237646230324978631];

        bool result = vote(_message, _c0, _keyImage, _s);
        // bool result = LSAG_verify(_message1, _c0, _keyImage, _s, pub_keys);
        // bool result = LSAG.verify(_message1, _c0, _keyImage, _s, pub_keys);
        emit LogBoolValue(result);
        return result;
    }
}
