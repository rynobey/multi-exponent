const rp = require('request-promise-native')
const EcOperations = artifacts.require('EcOperations');
let instance;

contract('EcOperations', (accounts) => {
  beforeEach(async () => {
    instance = await EcOperations.new({from: accounts[0]});
  });

  //it('ecadd: should return correct result', async () => {
  //  ax = "1"
  //  ay = "2"
  //  bx = "1"
  //  by = "2"
  //  value = await instance.ecAddp.call(ax, ay, bx, by);
  //  assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
  //  assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  //});

  //it('ecmul: should return correct result', async () => {
  //  ax = "1"
  //  ay = "2"
  //  b = "0x03"
  //  value = await instance.ecMulp.call(ax, ay, b);
  //  console.log(value[0].toString(16))
  //  console.log(value[1].toString(16))
  ////  assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
  ////  assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  //});

  it('ecAdd: should return correct result if a is inf', async () => {
    ax = "0"
    ay = "1"
    az = "0"
    bx = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    by = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    bz = "1"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('ecAdd: should return correct result if b is inf', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    bx = "0"
    by = "1"
    bz = "0"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('ecAdd: should return correct result if a = b', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    bx = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    by = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    bz = "1"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
    assert.strictEqual(value[0].toString(16), "c696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9");
    assert.strictEqual(value[1].toString(16), "1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6");
    assert.strictEqual(value[2].toString(16), "2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588");
  });

  it('ecAdd: should return correct result if a != b, b affine', async () => {
    ax = "0xc696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9"
    ay = "0x1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6"
    az = "0x2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588"
    bx = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    by = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    bz = "1"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
  //console.log(value)
    assert.strictEqual(value[0].toString(16), "20fbff5e5067c7b313cd8f3b37f7f977e8356c31443c723e288e64ac091056d");
    assert.strictEqual(value[1].toString(16), "1448861734fd860c22d8398c9a0b1aa8e9a0d4e7d3589b68cb9a328d6869ce08");
    assert.strictEqual(value[2].toString(16), "2ff59673844a73e70ddc19cd81583ab5b21eeeefdd919b7395cca27f5397dc01");
  });

  it('ecAdd: should return correct result if a != b, b not affine', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    bx = "0xc696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9"
    by = "0x1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6"
    bz = "0x2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
  //console.log(value)
    assert.strictEqual(value[0].toString(16), "20fbff5e5067c7b313cd8f3b37f7f977e8356c31443c723e288e64ac091056d");
    assert.strictEqual(value[1].toString(16), "1448861734fd860c22d8398c9a0b1aa8e9a0d4e7d3589b68cb9a328d6869ce08");
    assert.strictEqual(value[2].toString(16), "2ff59673844a73e70ddc19cd81583ab5b21eeeefdd919b7395cca27f5397dc01");
  });

  it('ecDbl: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "0x01"
    value = await instance.ecDbl(ax, ay, az);
  //console.log(value)
    assert.strictEqual(value[0].toString(16), "c696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9");
    assert.strictEqual(value[1].toString(16), "1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6");
    assert.strictEqual(value[2].toString(16), "2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588");
  });

  it('ecQuad: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    value = await instance.ecQuad(ax, ay, az);
  //console.log(value)
    assert.strictEqual(value[0].toString(16), "3371ba31a2de2d7a795a9b65042c075fec07b1b65c417dc2d0b2647b67bf11e");
    assert.strictEqual(value[1].toString(16), "2791774d4e7f246fa2c9de1a7c94e465e229940eafc1cef3a5b80c3eb3fb23c1");
    assert.strictEqual(value[2].toString(16), "17e5d3aae5f64c5dedac86648d34dcacdc79e23bef3676b0b7f0da965147abf5");
  });

  it('ecOct: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    value = await instance.ecOct(ax, ay, az);
 // console.log(value)
    assert.strictEqual(value[0].toString(16), "c0289e1738c07ac3dd7ebbfb13a11bbe4d0c3501abcdead57d51fc6de4b4dc6");
    assert.strictEqual(value[1].toString(16), "21c0fc64929859b87e4a70a888f37835b1c0642116c142cdb802e28180931a6b");
    assert.strictEqual(value[2].toString(16), "2ba4488b6309cb25fe727d59c5353525479b2dd39dd3ad7861c71aee066e90ab");
  });

  it('ecSixteen: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    value = await instance.ecSixteen(ax, ay, az);
  //console.log(value)
    assert.strictEqual(value[0].toString(16), "d3538d82a4dac34721e42cccbb6fd19b5ac3e956097044202cc69e10df5c8d0");
    assert.strictEqual(value[1].toString(16), "1a78a971295368fde56f82502cc953b2894fd3732d626ee0e314515ded1b727");
    assert.strictEqual(value[2].toString(16), "2d87dbf131f922a89af05a48663eddd49486538e014cd034d8056109be3a07b3");
  });

  it('ecNeg: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    value = await instance.ecNeg(ax, ay, az);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "1a76dae6d3272396d0cbe61fced2bc532edac647851e3ac53ce1cc9c7e645a83");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('isOnCurve: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    value = await instance.isOnCurve(ax, ay, az);
    assert.strictEqual(value, true);
  });

  it('makeAffine: should return correct result', async () => {
    ax = "0xc696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9"
    ay = "0x1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6"
    az = "0x2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588"
    value = await instance.makeAffine(ax, ay, az);
    assert.strictEqual(value[0].toString(16), "6a7b64af8f414bcbeef455b1da5208c9b592b83ee6599824caa6d2ee9141a76");
    assert.strictEqual(value[1].toString(16), "8e74e438cee31ac104ce59b94e45fe98a97d8f8a6e75664ce88ef5a41e72fbc");
    assert.strictEqual(value[2].toString(16), "1");
  });
});
