// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library BitmapLib {
    struct Bitmap {
        mapping(uint256 => uint256) map;
    }

    function get(Bitmap storage bitmap, uint256 index) internal view returns (bool) {
        return bitmap.map[index >> 8] & (1 << (index & 0xff)) != 0;
    }

    function setTo(
        Bitmap storage bitmap,
        uint256 index,
        bool shouldSet
    ) internal {
        shouldSet ? set(bitmap, index) : unset(bitmap, index);
    }

    function set(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] |= (1 << (index & 0xff));
    }

    function unset(Bitmap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] &= ~(1 << (index & 0xff));
    }
}
