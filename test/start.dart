// Copyright (c) 2016, Peter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:test/test.dart';

void main() {

  var isTrue = true;

   group('A group of tests', () {


    setUp(() async {


    });

    test('First Test', () {


       expect(true, isTrue);


    });

    test('2nd Test', ()  {


      expect(true, isTrue);

    });


  });

}
