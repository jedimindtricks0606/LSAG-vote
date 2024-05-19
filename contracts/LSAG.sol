pragma solidity ^0.5.17;

// import "./AltBn128.sol";
import "./secp256k1.sol";

/*
Linkable Spontaneous Anonymous Groups

https://eprint.iacr.org/2004/027.pdf
*/

library LSAG {
    // abi.encodePacked is the "concat" or "serialization"
    // of all supplied arguments into one long bytes value
    // i.e. abi.encodePacked :: [a] -> bytes

    /**
    * Converts an integer to an elliptic curve point
    */
    function intToPoint(uint256 _x) public view
        returns (uint256[2] memory)
    {
        uint256 x = _x;
        uint256 y;
        uint256 beta;
        uint8 prefix = 0x0;

        if (_x%2 == 0) {
            prefix = 0x02;
        }
        if (_x%2 == 1) {
            prefix = 0x03;
        }

        while (true) {

            (beta, y) = secp256k1.map_curve(prefix, x);

            if (secp256k1.onCurve(x, y)) {
                return [x, y];
            }

            x = secp256k1.addmodn(x, 1);
        }
    }

    /**
    * Returns an integer representation of the hash
    * of the input
    */
    function H1(bytes memory b) public pure
        returns (uint256)
    {
        // uint256 a = 11631197716381341491910650601086533899062258680921704624436296724004857123675;
        return secp256k1.modn(uint256(sha256(b)));
    }

    /**
    * Returns elliptic curve point of the integer representation
    * of the hash of the input
    */
    function H2(bytes memory b) public view
        returns (uint256[2] memory)
    {

        return intToPoint(H1(b));
    }

    /**
    * Helper function to calculate Z1
    * Avoids stack too deep problem
    */
    function ringCalcZ1(
        uint256[2] memory pubKey,
        uint256 c,
        uint256 s
    ) public pure
        returns (uint256[2] memory)
    {

        // return AltBn128.ecAdd(
        //     AltBn128.ecMulG(s),
        //     AltBn128.ecMul(pubKey, c)
        // );

        uint256[2] memory output;
        uint256[2] memory p1;
        uint256[2] memory p2;
        uint256 x;
        uint256 y;

        (x, y) = secp256k1.ecMultG(s);

        p1[0] = x;
        p1[1] = y;

        (x, y) = secp256k1.ecMult(pubKey, c);

        p2[0] = x;
        p2[1] = y;

        (x, y) = secp256k1.ecAddd(
            p1,
            p2
        );

        output[0] = x;
        output[1] = y;
        return output;
    }

    /**
    * Helper function to calculate Z2
    * Avoids stack too deep problem
    */
    function ringCalcZ2(
        uint256[2] memory keyImage,
        uint256[2] memory h,
        uint256 s,
        uint256 c
    ) public pure
        returns (uint256[2] memory)
    {
        // return AltBn128.ecAdd(
        //     AltBn128.ecMul(h, s),
        //     AltBn128.ecMul(keyImage, c)
        // );

        uint256[2] memory output;
        uint256[2] memory p1;
        uint256[2] memory p2;
        uint256 x;
        uint256 y;

        (x, y) = secp256k1.ecMult(h, s);

        p1[0] = x;
        p1[1] = y;

        (x, y) = secp256k1.ecMult(keyImage, c);

        p2[0] = x;
        p2[1] = y;

        (x, y) = secp256k1.ecAddd(
            p1,
            p2
        );

        output[0] = x;
        output[1] = y;
        return output;
    }


    /**
    * Verifies the ring signature
    * Section 4.2 of the paper https://eprint.iacr.org/2004/027.pdf
    */
    function verify(
        bytes memory message,
        uint256 c0,
        uint256[2] memory keyImage,
        uint256[] memory s,
        uint256[2][] memory publicKeys
    ) public view
        returns (bool)
    {


        require(publicKeys.length >= 2, "Signature size too small");
        require(publicKeys.length == s.length, "Signature sizes do not match!");


        uint256 c = c0;
        uint256 i = 0;

        // Step 1
        // Extract out public key bytes
        bytes memory hBytes = "";

        for (i = 0; i < publicKeys.length; i++) {
            hBytes = abi.encodePacked(
                hBytes,
                publicKeys[i]
            );
        }


        uint256[2] memory h = H2(hBytes);

        // require(h[0] ==106245785169166674832827933205895298349539914377793708839139737261608903456172, "H[0] is not matching");
        // require(h[1] == 38130597350437976482118320406716909458312114499366885177464997577442444961143, "H[1] is not matching");


        // Step 2
        uint256[2] memory z_1;
        uint256[2] memory z_2;


        for (i = 0; i < publicKeys.length; i++) {

            z_1 = ringCalcZ1(publicKeys[i], c, s[i]);
            z_2 = ringCalcZ2(keyImage, h, s[i], c);
            // require(z_1[0] == 104603062327150847596075863885237206448711583172763894617559229948636949816387, "z_1[0] me problem hai");
            // require(z_1[1] == 3877022914943913174973231854694363839599317059260525512126388493689905288930, "z_1[1] me problem hai");
            // require(z_2[0] == 25157251625505657634097849792771000312472027419867594537390547422728421981871, "z_2[0] me problem hai");
            // require(z_2[1] == 69948776311331987906694682752320754045742553606829709747780937321352532856962, "z_2[1] me problem hai");

            if (i != publicKeys.length - 1) {
                c = H1(
                    abi.encodePacked(
                        hBytes,
                        keyImage,
                        message,
                        z_1,
                        z_2
                    )
                );
            }
        }

        return c0 == H1(
            abi.encodePacked(
                hBytes,
                keyImage,
                message,
                z_1,
                z_2
            )
        );
    }

    function test() public view returns (bool) {
        bytes memory _message = hex"0000000000000000000000000000000000000000000000000000000000000002";
        uint256 _c0 = 0x2a289d64bbee194d2d534f7047a01fde7daa1c68deee018efbebd7d3e5b22389;
        uint256[2] memory _keyImage = [0x573ee3fa981e1d1a06cd61447872202e94df3710de5758c4c16e98e3af1c1fdc,0x5f7ed3e0b1040aa907918642c22596f2d10e4be31d8ddabc32d9de4e8dc4bc7a];
        uint256[] memory _s = new uint256[](5);
        uint256[2][] memory _publicKeys = new uint256[2][](5);

        _s[0] = 0xec9933b5397f7f7afb2030465d8364a347b395a19e9f8fe97b45437a3bdbd1fa;
        _s[1] = 0x1ce876112c3f088f8e39c77f22f598740609ac02e5dd96307e7666dd52f3865e;
        _s[2] = 0x6c6fac6a63b03840b7fe9b44b3d34c2fad65ff142f398a373de64a2ceb7012ff;
        _s[3] = 0x4d44522cbffc97779a2a033bb716adc864b4e46d8702322ba2c33b9f33dc6ca9;
        _s[4] = 0xc9cc0f0bc3492fb684c0f0df241d31520d0d0b72a8e809408d1f5db39783294c;

        _publicKeys[0] = [42590531793497166628675028504179635324399256857914437964935353302914148351568, 70258465579541072633675745945063730848340228275334547582353094321566766441378];
        _publicKeys[1] = [60513388830880094996730554983980138069854757315251102263155115679417548335711, 32355694484654553192302999522212060151412579940815018302926997831378376731361];
        _publicKeys[2] = [82063651073125245392661557491700795580630394335542071037371659985228773067807, 41907949531061274289048481070997646377728047353101778990100613629391341188194];
        _publicKeys[3] = [74676233269489733243890256545638083721514278356752931791012161293367886031123, 115337805785800369503682918354032851259849520768470083724462034320348662186709];
        _publicKeys[4] = [72043771932791372809265531473147240182298347594767811673713431858361481622778, 106080253987756479864851315802389757709136351804234230761944237646230324978631];

        if(verify(_message, _c0, _keyImage, _s, _publicKeys)) return true;
        else return false;

    }

    function test2() public pure returns (uint256) {
        bytes memory _message = hex"0000000000000000000000000000000000000000000000000000000000000001";
        return H1(_message);
    }
}