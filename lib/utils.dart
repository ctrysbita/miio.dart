/*
Copyright (C) 2020 Jason C.H

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

part of 'miio.dart';

extension ToBytes on BigInt {
  Uint8List toBytes([int length]) {
    if (length == null) length = bitLength ~/ 8;

    var number = this;
    final bytes = ByteData(length);

    for (var i = 1; i <= bytes.lengthInBytes; ++i, number >>= 8)
      bytes.setUint8(bytes.lengthInBytes - i, number.toUnsigned(8).toInt());

    return bytes.buffer.asUint8List();
  }
}

extension ToHexString on Uint8List {
  String get hexString =>
      this.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}
