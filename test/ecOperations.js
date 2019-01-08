const rp = require('request-promise-native')
const EcOperations = artifacts.require('EcOperations');
let instance;

contract('EcOperations', (accounts) => {
  before(async () => {
    console.log("Deploying contract and performing pre-computations...")
    instance = await EcOperations.new({from: accounts[0]});
    // create a persistent generator point
    value = await instance.addPersistentGenerator();
    console.log("Gas used:", value.receipt.gasUsed)
    // create a persistent generator point
    value = await instance.addPersistentGenerator();
    console.log("Gas used:", value.receipt.gasUsed)
    // create a persistent generator point
    value = await instance.addPersistentGenerator();
    console.log("Gas used:", value.receipt.gasUsed)
    // add 255 additional precomputed generator values
    value = await instance.addPersistentGeneratorValues("0x00", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x00", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x00", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x00", "0x3F");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x01", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x01", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x01", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x01", "0x3F");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x02", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x02", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x02", "0x40");
    console.log("Gas used:", value.receipt.gasUsed)
    value = await instance.addPersistentGeneratorValues("0x02", "0x3F");
    console.log("Gas used:", value.receipt.gasUsed)
    console.log("Done!")
    console.log()
  });

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
    assert.strictEqual(value[0].toString(16), "20fbff5e5067c7b313cd8f3b37f7f977e8356c31443c723e288e64ac091056d");
    assert.strictEqual(value[1].toString(16), "1448861734fd860c22d8398c9a0b1aa8e9a0d4e7d3589b68cb9a328d6869ce08");
    assert.strictEqual(value[2].toString(16), "2ff59673844a73e70ddc19cd81583ab5b21eeeefdd919b7395cca27f5397dc01");
  });

  it('ecDbl: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "0x01"
    value = await instance.ecDbl(ax, ay, az);
    assert.strictEqual(value[0].toString(16), "c696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9");
    assert.strictEqual(value[1].toString(16), "1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6");
    assert.strictEqual(value[2].toString(16), "2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588");
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

  it('hashToPoint: should return correct result', async () => {
    input = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47"
    value = await instance.hashToPoint(input);
    //console.log(value)
    assert.strictEqual(value[0].toString(16), "2d8ded62f522b61488ae8afcc734331d12a576a5f5cb7738b892d4fbb2f20dad");
    assert.strictEqual(value[1].toString(16), "1e8e0e2a692dde8f8fd440aa0a5c1e84e2cf84cf8c367983eb6d36a2fca274f0");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('addPersistentGenerator: should add a generator', async () => {
    value = await instance.getPersistentGeneratorValue("0x00", "0x01");
    assert.strictEqual(value[0].toString(16), "2d8ded62f522b61488ae8afcc734331d12a576a5f5cb7738b892d4fbb2f20dad");
    assert.strictEqual(value[1].toString(16), "1e8e0e2a692dde8f8fd440aa0a5c1e84e2cf84cf8c367983eb6d36a2fca274f0");
    assert.strictEqual(value[2].toString(16), "1");
    value = await instance.getPersistentGeneratorValue("0x02", "0x01");
    assert.strictEqual(value[0].toString(16), "2c507b58a906531ceca4eb36c967a99dc9a42c8b08ea37f82a1db56d8e9d4cbe");
    assert.strictEqual(value[1].toString(16), "e10e92ea6680e5777f34b53a5b9bd5f436e881ab72ecc92d8e278494b2beb78");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('addPersistentGeneratorValues: should add generator values', async () => {
    value = await instance.getPersistentGeneratorValue("0x00", "0x02");
    assert.strictEqual(value[0].toString(16), "12c210556f4130883ea9101b518fa2bbf6ad9dedd5f65fcdb4af5795db000cab");
    assert.strictEqual(value[1].toString(16), "1e6d3a57a1c7fe65624def605ab811ad6c53f3d599d75cf64c446248f6b7597");
    assert.strictEqual(value[2].toString(16), "1");
    value = await instance.getPersistentGeneratorValue("0x00", "0x100");
    assert.strictEqual(value[0].toString(16), "1a2385c109ff3cebcff7d146d2d1e179f4e84b3f41e06b224f556ff1c90af128");
    assert.strictEqual(value[1].toString(16), "1c5923643325271e25172dbb7b8864df98ec6cff9bf518edb00a883c811a8cc");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('ecMultiScalarMult: should return correct result', async () => {
    input = ["0x12c210556f4130883ea9101b518fa2bbf6ad9dedd5f65fcdb4af5795db000cab", "0x1a2385c109ff3cebcff7d146d2d1e179f4e84b3f41e06b224f556ff1c90af128", "0x2d8ded62f522b61488ae8afcc734331d12a576a5f5cb7738b892d4fbb2f20dad"]
    //input = ["0x12c210556f4130883ea9101b518fa2bbf6ad9dedd5f65fcdb4af5795db000cab", "0x1a2385c109ff3cebcff7d146d2d1e179f4e84b3f41e06b224f556ff1c90af128"]
    //input = ["0x01", "0x01"]
    //input = ["0x01", "0x01", "0x01"]
    value = await instance.ecMultiScalarMult(input);
    assert.strictEqual(value[0].toString(16), "1cd54b86572de61e3fcd70174358dd63acfd6b85231b294dac794d3d87021a4d");
    assert.strictEqual(value[1].toString(16), "199bad177e21d93e341c5392dfc29e56cf4f888ee56f8eb3e84cad226840a700");
    assert.strictEqual(value[2].toString(16), "bcb6546280a369910d9a18ebd8422c7f18cd018c04351a6b3d85212986c77db");
  });
});
