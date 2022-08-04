// Copyright (C) 2020-2022 Jason C.H
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:convert';

import 'package:convert/convert.dart';

final jsonEncoder = JsonEncoder.withIndent('    ');

extension IntToHexString on int {
  String toHexString([int? width]) {
    final hexStr = toRadixString(16);
    return width == null ? hexStr : hexStr.padLeft(width, '0');
  }
}

extension BytesToHexString on List<int> {
  String get hexString => hex.encode(this);

  String get prettyString {
    final list = map((e) => e.toRadixString(16).padLeft(2, '0'));
    var str = StringBuffer();
    var lineBytes = 0;
    for (var i in list) {
      str.write(i);
      str.write(' ');
      lineBytes++;
      if (lineBytes == 16) {
        str.writeln();
        lineBytes = 0;
      }
    }
    return str.toString();
  }
}
