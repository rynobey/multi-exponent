pragma solidity ^0.4.23;

contract EcOperations {

  uint256 constant GROUP_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
  uint256 constant PP = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
  uint256 constant a = 0;
  uint256 constant b = 7;

  //function makeAffine(uint256[] a) public view returns(uint256[] p) {
  //  assembly {

  //  }
  //}

  //function _inverse(uint256 a) public view returns(uint256)
  //{
  //    uint256 t=0;
  //    uint256 newT=1;
  //    uint256 r=PP;
  //    uint256 newR=a;
  //    uint256 q;
  //    while (newR != 0) {
  //        q = r / newR;

  //        (t, newT) = (newT, addmod(t , (r - mulmod(q, newT,r)) , r));
  //        (r, newR) = (newR, r - q * newR );
  //    }

  //    return t;
  //}

  function ecAddc(uint256 ax, uint256 ay, uint256 az, uint256 bx, uint256 by, uint256 bz) public returns(uint256[3] p) {
    if (ay == by) {
      p = ecDbli(ax, ay, az);
    } else {
      p = ecAddi(ax, ay, az, bx, by, bz);
    }
  }

  function ecAddi(uint256 ax, uint256 ay, uint256 az, uint256 bx, uint256 by, uint256 bz) internal view returns(uint256[3] p) {
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      //Z1Z1 = Z1^2, z1z1 offset = 0x1020
      mstore(
        0x1020,
        mulmod(
          az,
          az,
          P
        )
      )
      //Z2Z2 = Z2^2, z2z2 offset = 0x1040
      mstore(
        0x1040,
        mulmod(
          bz,
          bz,
          P
        )
      )
      //U1 = X1*Z2Z2, u1 offset = 0x1060
      mstore(
        0x1060,
        mulmod(
          ax,
          mload(0x1040),
          P
        )
      )
      //S1 = Y1*t0, s1 offset = 0x10E0
      mstore(
        0x10E0,
        mulmod(
          ay,
          //t0 = Z2*Z2Z2
          mulmod(
            bz,
            mload(0x1040),
            P
          ),
          P
        )
      )
      //H = U2-U1, h offset = 0x1140
      mstore(
        0x1140,
        addmod(
          //U2 = X2*Z1Z1
          mulmod(
            bx,
            mload(0x1020),
            P
          ),
          // -u1
          sub(
            P,
            mload(0x1060)
          ),
          P
        )
      )
      //HH = H^2, hh offset = 0x1160
      mstore(
        0x1160,
        mulmod(
          mload(0x1140),
          mload(0x1140),
          P
        )
      )
      //HHH = H*HH, hhh offset = 0x1180
      mstore(
        0x1180,
        mulmod(
          mload(0x1140),
          mload(0x1160),
          P
        )
      )
      //r = S2-S1, r offset = 0x11C0
      mstore(
        0x11C0,
        addmod(
          //S2 = Y2*t1
          mulmod(
            by,
            //t1 = Z1*Z1Z1
            mulmod(
              az,
              mload(0x1020),
              P
            ),
            P
          ),
          // -s1
          sub(
            P,
            mload(0x10E0)
          ),
          P
        )
      )
      //V = U1*HH, v offset = 0x11E0
      mstore(
        0x11E0,
        mulmod(
          mload(0x1060),
          mload(0x1160),
          P
        )
      )
      //X3 = t4-t3, X3 -> p + 0x00
      mstore(
        p,
        addmod(
          //t4 = t2-HHH
          addmod(
            // t2 = r^2
            mulmod(
              mload(0x11C0),
              mload(0x11C0),
              P
            ),
            sub(
              P,
              mload(0x1180)
            ),
            P
          ),
          // -t3
          sub(
            P,
            //t3 = 2*V
            mulmod(
              0x02,
              mload(0x11E0),
              P
            )
          ),
          P
        )
      )
      //Y3 = t7-t6, Y3 -> p + 0x20
      mstore(
        add(p, 0x20),
        addmod(
          // t7 = r*t5
          mulmod(
            mload(0x11C0),
            //t5 = V-X3
            addmod(
              mload(0x11E0),
              // -X3
              sub(
                P,
                mload(p)
              ),
              P
            ),
            P
          ),
          // -t6
          sub(
            P,
            // t6 = s1*hhh
            mulmod(
              mload(0x10E0),
              mload(0x1180),
              P
            )
          ),
          P
        )
      )
      //Z3 = Z1*t8, Z3 -> p + 0x40
      mstore(
        add(p, 0x40),
        mulmod(
          az,
          // t8 = z2*h
          mulmod(
            bz,
            mload(0x1140),
            P
          ),
          P
        )
      )
    }
  }

  function ecDbli(uint256 ax, uint256 ay, uint256 az) public view returns(uint256[3] p) {
    assembly {
      let P := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
      //A = X1^2, A offset = 0x1020
      mstore(
        0x1020,
        mulmod(
          ax,
          ax,
          P
        )
      )
      //B = Y1^2, B offset = 0x1040
      mstore(
        0x1040,
        mulmod(
          ay,
          ay,
          P
        )
      )
      //C = B^2, u1 offset = 0x1060
      mstore(
        0x1060,
        mulmod(
          mload(0x1040),
          mload(0x1040),
          P
        )
      )
      //D = 2*t3, D offset = 0x1080
      mstore(
        0x1080,
        mulmod(
          0x02,
          //t3 = t2-C
          addmod(
            // t2 = t1-A
            addmod(
              // t1 = t0^2
              mulmod(
                // t0 = X1+B
                addmod(
                  ax,
                  mload(0x1040),
                  P
                ),
                // t0 = X1+B
                addmod(
                  ax,
                  mload(0x1040),
                  P
                ),
                P
              ),
              sub(
                P,
                mload(0x1020)
              ),
              P
            ),
            sub(
              P,
              mload(0x1060)
            ),
            P
          ),
          P
        )
      )
      //E = 3*A, E offset = 0x1140
      mstore(
        0x1140,
        mulmod(
          0x03,
          mload(0x1020),
          P
        )
      )
      //F = E^2, F offset = 0x1160
      mstore(
        0x1160,
        mulmod(
          mload(0x1140),
          mload(0x1140),
          P
        )
      )
      //X3 = F-t4, X3 -> p + 0x00
      mstore(
        p,
        addmod(
          mload(0x1160),
          sub(
            P,
            // t4 = 2*D
            mulmod(
              0x02,
              mload(0x1080),
              P
            )
          ),
          P
        )
      )
      //Y3 = t7-t6, r -> p + 0x20
      mstore(
        add(p, 0x20),
        addmod(
          //t7 = E*t5
          mulmod(
            mload(0x1140),
            //t5 = D-X3
            addmod(
              mload(0x1080),
              // -X3
              sub(
                P,
                p
              ),
              P
            ),
            P
          ),
          // -t6
          sub(
            P,
            // t6 = 8*C
            mulmod(
              0x08,
              mload(0x1060),
              P
            )
          ),
          P
        )
      )
      //Z3 = 2*t8, Z3 -> p + 0x40
      mstore(
        add(p, 0x40),
        mulmod(
          0x02,
          // t8 = Y1*Z1
          mulmod(
            ay,
            az,
            P
          ),
          P
        )
      )
    }
  }

  function ecAdd(uint256 ax, uint256 ay, uint256 bx, uint256 by) public view returns(uint256[2] p) {
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

  function ecMul(uint256 x, uint256 y, uint256 scalar) public view returns(uint256[2] p) {
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
