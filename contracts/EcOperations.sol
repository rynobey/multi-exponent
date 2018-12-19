pragma solidity ^0.4.24;

contract EcOperations {

  uint256 constant GROUP_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
  uint256 constant PP = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
  uint256 constant a = 0;
  uint256 constant b = 3;

  function makeAffine(uint256 ax, uint256 ay, uint256 az) public view returns(uint256[3] p) {
    if (az == 1) {
      return;
    }
    if (az == 0) {
      assembly {
        mstore(p, 0)
        mstore(add(p, 0x20), 1)
        mstore(add(p, 0x40), 0)
      }
      return;
    }
    uint256 z_inv = expMod(az, PP-2, PP); // find inverse using Fermat's little theorem, since PP is prime
    // recovers x and y from Jacobian form (X, Y, Z) given that x = X/Z^3 and y = Y/Z^2
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      let zz_inv := mulmod(z_inv, z_inv, P)
      let zzz_inv := mulmod(z_inv, zz_inv, P)
      mstore(p, mulmod(ax, zz_inv, P))
      mstore(add(p, 0x20), mulmod(ay, zzz_inv, P))
      mstore(add(p, 0x40), 0x01)
    }
  }

  function isOnCurve(uint256 ax, uint256 ay, uint256 az) public pure returns(bool output) {
    if (az == 0) {
      return true;
    }
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      let b := 3
      let z2 := mulmod(az, az, P)
      let z6 := mulmod(z2, mulmod(z2, z2, P), P)
      let x3 := mulmod(ax, mulmod(ax, ax, P), P)
      x3 := addmod(x3, mulmod(b, z6, P), P) // scale b with z6 in order to avoid an inversion
      let y2 := mulmod(ay, ay, P)
      output := eq(y2, x3)
    }
  }

  function ecNeg(uint256 ax, uint256 ay, uint256 az) public pure returns(uint256[3] p) {
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      mstore(p, ax)
      mstore(add(p, 0x20), sub(P, ay))
      mstore(add(p, 0x40), az)
    }
  }

  function ecDbl(uint256 ax, uint256 ay, uint256 az) public pure returns(uint256[3] p) {
    /*
      Static memory map:
      0x0200: ax
      0x0220: ay
      0x0240: az
      0x02C0: px
      0x02E0: py
      0x0300: pz
    */
    assembly {
      mstore(0x0200, ax)
      mstore(0x0220, ay)
      mstore(0x0240, az)

      if iszero(mload(0x0240)) { // if point a is inf
        setInf()
      }
      if gt(mload(0x0240), 0) {
        dbl()
      }
      mstore(p, mload(0x02C0))
      mstore(add(p, 0x20), mload(0x02E0))
      mstore(add(p, 0x40), mload(0x0300))

      function setInf() {
        mstore(0x02C0, 0)
        mstore(0x02E0, 1)
        mstore(0x0300, 0)
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
      function dbl() {
        let Pd := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        let axd := mload(0x0200)
        let ayd := mload(0x0220)
        //A = X1^2
        let tmp1d := mulmod(axd, axd, Pd)
        //B = Y1^2
        let tmp2d := mulmod(ayd, ayd, Pd)
        //C = B^2
        let tmp3d := mulmod(tmp2d, tmp2d, Pd)
        //t0 = X1+B
        let tmp4d := addmod(axd, tmp2d, Pd)
        //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
        tmp2d := mulmod(
          0x02,
          addmod(mulmod(tmp4d, tmp4d, Pd), sub(Pd, addmod(tmp1d, tmp3d, Pd)), Pd),
          Pd
        )
        //E = 3*A
        tmp1d := mulmod(0x03, tmp1d, Pd)
        //F = E^2
        tmp4d := mulmod(tmp1d, tmp1d, Pd)
        //X3 = F-2*D, X3 -> p + 0x00
        mstore(
          0x02C0,
          addmod(
            tmp4d,
            sub(Pd, mulmod(0x02, tmp2d, Pd)),
            Pd
          )
        )
        //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
        mstore(
          0x02E0,
          addmod(
            mulmod(tmp1d, addmod(tmp2d, sub(Pd, mload(0x02C0)), Pd), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)), Pd
          )
        )
        //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
        mstore(
          0x0300,
          mulmod(
            0x02,
            mulmod(ayd, mload(0x0240), Pd),
            Pd
          )
        )
      }
    }
    //p = makeAffine(p[0], p[1], p[2]);
  }

  function ecAdd(uint256 ax, uint256 ay, uint256 az, uint256 bx, uint256 by, uint256 bz) public pure returns(uint256[3] p) {
    /*
      Static memory map:
      0x0200: ax
      0x0220: ay
      0x0240: az
      0x0260: bx
      0x0280: by
      0x02A0: bz
      0x02C0: px
      0x02E0: py
      0x0300: pz
    */
    assembly {
      mstore(0x0200, ax)
      mstore(0x0220, ay)
      mstore(0x0240, az)
      mstore(0x0260, bx)
      mstore(0x0280, by)
      mstore(0x02A0, bz)

      if iszero(mload(0x0240)) { // if point a is inf
        setB()
      }
      if gt(mload(0x0240), 0) {
        switch mload(0x02A0)
        case 0 {// if point b is inf
          setA()
        }
        case 1 {// if point b is affine, use faster algorithm
          addSpcl()
        }
        default {
          addNrml()
        }
      }
      mstore(p, mload(0x02C0))
      mstore(add(p, 0x20), mload(0x02E0))
      mstore(add(p, 0x40), mload(0x0300))

      function setA() {
        mstore(0x02C0, mload(0x0200))
        mstore(0x02E0, mload(0x0220))
        mstore(0x0300, mload(0x0240))
      }

      function setB() {
        mstore(0x02C0, mload(0x0260))
        mstore(0x02E0, mload(0x0280))
        mstore(0x0300, mload(0x02A0))
      }

      function setInf() {
        mstore(0x02C0, 0)
        mstore(0x02E0, 1)
        mstore(0x0300, 0)
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian/addition/madd-2008-g.op3
      function addSpcl() {
        let azs := mload(0x0240)
        let Ps := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        //T1 = Z1^2
        let tmp1s := mulmod(azs, azs, Ps)
        //T2 = T1*Z1
        let tmp2s := mulmod(tmp1s, azs, Ps)
        //T1 = T1*X2
        tmp1s := mulmod(tmp1s, mload(0x0260), Ps)
        //T2 = T2*Y2
        tmp2s := mulmod(tmp2s, mload(0x0280), Ps)
        //T1 = X1-T1
        tmp1s := addmod(mload(0x0200), sub(Ps, tmp1s), Ps)
        //T2 = T2-Y1
        tmp2s := addmod(tmp2s, sub(Ps, mload(0x0220)), Ps)
        if iszero(tmp1s) {
          if iszero(tmp2s) { // if points are co-located, do double instead
            dbl()
          }
          if gt(tmp2s, 0) {//return inf
            setInf()
          }
        }
        if gt(tmp1s, 0) {
          //Z3 = Z1*T1
          mstore(0x0300, mulmod(azs, tmp1s, Ps))
          //T4 = T1^2
          let tmp4s := mulmod(tmp1s, tmp1s, Ps)
          //T1 = T1*T4
          tmp1s := mulmod(tmp1s, tmp4s, Ps)
          //T4 = T4*X1
          tmp4s := mulmod(tmp4s, mload(0x0200), Ps)
          //X3 = T2^2
          let pxs := mulmod(tmp2s, tmp2s, Ps)
          //X3 = X3+T1
          pxs := addmod(pxs, tmp1s, Ps)
          //Y3 = T1*Y1
          mstore(0x02E0, mulmod(tmp1s, mload(0x0220), Ps))
          //T1 = 2*T4
          tmp1s := mulmod(0x02, tmp4s, Ps)
          //X3 = X3-T1
          mstore(0x02C0, addmod(pxs, sub(Ps, tmp1s), Ps))
          //T4 = X3-T4
          tmp4s := addmod(mload(0x02C0), sub(Ps, tmp4s), Ps)
          //T4 = T4*T2
          tmp4s := mulmod(tmp4s, tmp2s, Ps)
          //Y3 = T4-Y3
          mstore(0x02E0, addmod(tmp4s, sub(Ps, mload(0x02E0)), Ps))
        }
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian/addition/add-1998-cmo-2.op3
      function addNrml() {
        let Pn := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        let azn := mload(0x02A0)
        //Z2Z2 = Z2^2
        let tmp1n := mulmod(azn, azn, Pn)
        //U1 = X1*Z2Z2
        let tmp2n := mulmod(mload(0x0200), tmp1n, Pn)
        //S1 = Y1*t0 = Y1*Z2*Z2Z2
        let tmp3n := mulmod(mload(0x0220), mulmod(azn, tmp1n, Pn), Pn)
        //Z1Z1 = Z1^2
        tmp1n := mulmod(mload(0x0240), mload(0x0240), Pn)
        //r = S2-S1 = Y2*t1 - S1 = Y2*Z1*Z1Z1 - S1
        let tmp4n := addmod(
          mulmod(mload(0x0280), mulmod(mload(0x0240), tmp1n, Pn), Pn),
          sub(Pn, tmp3n),
          Pn
        )
        //H = U2-U1 = X2*Z1Z1 - U1
        let tmp5n := addmod(
          mulmod(mload(0x0260), tmp1n, Pn),
          sub(Pn, tmp2n),
          Pn
        )
        if and(iszero(tmp4n), iszero(tmp5n)) {// if the points are co-located, do double instead
          dbl()
        }
        if or(gt(tmp4n, 0), gt(tmp5n, 0)) {
          //HH = H^2, hh offset = 0x0100
          tmp1n := mulmod(tmp5n, tmp5n, Pn)
          //V = U1*HH, v offset = 0x0160
          tmp2n := mulmod(tmp2n, tmp1n, Pn)
          //HHH = H*HH, hhh offset = 0x0120
          tmp1n := mulmod(tmp5n, tmp1n, Pn)
          //Z3 = Z1*t8 = Z1*Z2*H, Z3 -> p + 0x40
          mstore(
            0x02C0,
            mulmod(mload(0x0240), mulmod(azn, tmp5n, Pn), Pn)
          )
          //X3 = t4-t3 = r^2 - (hhh + 2*V), X3 -> p + 0x00
          mstore(
            0x02E0,
            addmod(
              mulmod(tmp4n, tmp4n, Pn),
              sub(Pn, addmod(tmp1n, mulmod(0x02, tmp2n, Pn), Pn)),
              Pn
            )
          )
          //Y3 = t7-t6 = r*(V-X3) - S1*HHH, Y3 -> p + 0x20
          mstore(
            0x0300,
            addmod(
              mulmod(tmp4n, addmod(tmp2n, sub(Pn, mload(0x02C0)), Pn), Pn),
              sub(Pn, mulmod(tmp3n, tmp1n, Pn)),
              Pn
            )
          )
        }
      }

      // Implementation of http://hyperelliptic.org/EFD/g1p/auto-code/shortw/jacobian-0/doubling/dbl-2009-l.op3
      function dbl() {
        let Pd := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        let axd := mload(0x0200)
        let ayd := mload(0x0220)
        //A = X1^2
        let tmp1d := mulmod(axd, axd, Pd)
        //B = Y1^2
        let tmp2d := mulmod(ayd, ayd, Pd)
        //C = B^2
        let tmp3d := mulmod(tmp2d, tmp2d, Pd)
        //t0 = X1+B
        let tmp4d := addmod(axd, tmp2d, Pd)
        //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
        tmp2d := mulmod(
          0x02,
          addmod(mulmod(tmp4d, tmp4d, Pd), sub(Pd, addmod(tmp1d, tmp3d, Pd)), Pd),
          Pd
        )
        //E = 3*A
        tmp1d := mulmod(0x03, tmp1d, Pd)
        //F = E^2
        tmp4d := mulmod(tmp1d, tmp1d, Pd)
        //X3 = F-2*D, X3 -> p + 0x00
        mstore(
          0x02C0,
          addmod(
            tmp4d,
            sub(Pd, mulmod(0x02, tmp2d, Pd)),
            Pd
          )
        )
        //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
        mstore(
          0x02E0,
          addmod(
            mulmod(tmp1d, addmod(tmp2d, sub(Pd, mload(0x02C0)), Pd), Pd),
            sub(Pd, mulmod(0x08, tmp3d, Pd)), Pd
          )
        )
        //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
        mstore(
          0x0300,
          mulmod(
            0x02,
            mulmod(ayd, mload(0x0240), Pd),
            Pd
          )
        )
      }
    }
    //p = makeAffine(p[0], p[1], p[2]);
  }

  function ecDbli(uint256 ax, uint256 ay, uint256 az) public pure returns(uint256[3] p) {
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      //A = X1^2
      let tmp1 := mulmod(ax, ax, P)
      //B = Y1^2
      let tmp2 := mulmod(ay, ay, P)
      //C = B^2
      let tmp3 := mulmod(tmp2, tmp2, P)
      //t0 = X1+B
      let tmp4 := addmod(ax, tmp2, P)
      //D = 2*t3 = 2*(t2-C) = 2*(t1-A-C) = 2*((X1+B)^2-(A+C))
      tmp2 := mulmod(
        0x02,
        addmod(mulmod(tmp4, tmp4, P), sub(P, addmod(tmp1, tmp3, P)), P),
        P
      )
      //E = 3*A
      tmp1 := mulmod(0x03, tmp1, P)
      //F = E^2
      tmp4 := mulmod(tmp1, tmp1, P)
      //X3 = F-2*D, X3 -> p + 0x00
      mstore(
        p,
        addmod(
          tmp4,
          sub(P, mulmod(0x02, tmp2, P)),
          P
        )
      )
      //Y3 = t7-t6 = E*(D-X3) - 8*C, r -> p + 0x20
      mstore(
        add(p, 0x20),
        addmod(
          mulmod(tmp1, addmod(tmp2, sub(P, mload(p)), P), P),
          sub(P, mulmod(0x08, tmp3, P)), P
        )
      )
      //Z3 = 2*t8 = 2*Y1*Z1, Z3 -> p + 0x40
      mstore(
        add(p, 0x40),
        mulmod(
          0x02,
          mulmod(ay, az, P),
          P
        )
      )
    }
    //p = makeAffine(p[0], p[1], p[2]);
  }

  function expMod(uint256 base, uint256 e, uint256 m) public view returns (uint256 o) {
    assembly {
      let p := mload(0x40)
      mstore(p, 0x20)             // Length of Base
      mstore(add(p, 0x20), 0x20)  // Length of Exponent
      mstore(add(p, 0x40), 0x20)  // Length of Modulus
      mstore(add(p, 0x60), base)  // Base
      mstore(add(p, 0x80), e)     // Exponent
      mstore(add(p, 0xa0), m)     // Modulus
      if iszero(staticcall(sub(gas, 2000), 0x05, p, 0xc0, p, 0x20)) {
        revert(0, 0)
      }
      o := mload(p)
    }
  }

  function ecAddp(uint256 ax, uint256 ay, uint256 bx, uint256 by) public view returns(uint256[2] p) {
    uint256[4] memory input;
    input[0] = ax;
    input[1] = ay;
    input[2] = bx;
    input[3] = by;
    assembly {
      if iszero(staticcall(sub(gas, 2000), 0x06, input, 0x80, p, 0x40)) {
        revert(0, 0)
      }
    }
  }

  function ecMulp(uint256 x, uint256 y, uint256 scalar) public view returns(uint256[2] p) {
    uint256[3] memory input;
    input[0] = x;
    input[1] = y;
    input[2] = scalar;
    assembly {
      // call ecmul precompile
      if iszero(staticcall(sub(gas, 2000), 0x07, input, 0x60, p, 0x40)) {
        revert(0, 0)
      }
    }
  }
}
