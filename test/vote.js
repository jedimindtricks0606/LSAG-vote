const { Web3 } = require('web3');

const web3 = new Web3('HTTP://127.0.0.1:7545');
web3.eth.defaultAccount = '0x81D8098028A85F5641479934D7011D551E307D0D'; // Set the default account

const voteABI = require('./vote.json');
const voteAddress = '0x576F3C99235BBBbFe944b12F4fEC9d34251152DE'; //vote
const vote = new web3.eth.Contract(voteABI, voteAddress);

const lsagABI = require('./LSAG.json');
const lsagAddress = '0x4dAfA38aEc65c9d2e9785Fb0672a92F8D43BA9F5'; //LSAG
const lsag = new web3.eth.Contract(lsagABI, lsagAddress);

async function callVoteFunction() {
    try {
        // const accounts = await web3.eth.getAccounts();
        // const message = 2;
        // const c0 = '0x2a289d64bbee194d2d534f7047a01fde7daa1c68deee018efbebd7d3e5b22389';
        // const keyImage = ["0x573ee3fa981e1d1a06cd61447872202e94df3710de5758c4c16e98e3af1c1fdc", "0x5f7ed3e0b1040aa907918642c22596f2d10e4be31d8ddabc32d9de4e8dc4bc7a"];
        // const s = ["0xec9933b5397f7f7afb2030465d8364a347b395a19e9f8fe97b45437a3bdbd1fa", "0x1ce876112c3f088f8e39c77f22f598740609ac02e5dd96307e7666dd52f3865e", "0x6c6fac6a63b03840b7fe9b44b3d34c2fad65ff142f398a373de64a2ceb7012ff", "0x4d44522cbffc97779a2a033bb716adc864b4e46d8702322ba2c33b9f33dc6ca9", "0xc9cc0f0bc3492fb684c0f0df241d31520d0d0b72a8e809408d1f5db39783294c"];

        // Call the 'vote' function
        // const result = await contract.methods.vote(message, c0, keyImage, s).send({ from: accounts[0] });
        const result = await vote.methods.test().send({ from: web3.eth.defaultAccount });
        console.log('Vote result:', result);
    } catch (error) {
        console.error('Error:', error);
    }
}

async function callLSAGFunction() {
    try {
        const result = await lsag.methods.test().send({ from: web3.eth.defaultAccount });
        console.log('Result:', result);
    } catch (error) {
        console.error('Error:', error);
    }
}

// Call the example function
callLSAGFunction();
