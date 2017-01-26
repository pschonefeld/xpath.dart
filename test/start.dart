// Copyright (c) 2016, Peter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:test/test.dart';
import 'package:xml_query_test_driver/xml_query_test_driver.dart';
import 'package:xpath/xpath.dart';
void main() {

  var isTrue = true;

   group('A group of tests', () {

    setUp(() async {
      XPath xpath = new XPath();
      var testDriver = new TestDriver.resources('../xml-query-test-driver/lib/res/qt3_1_0/');
      testDriver.setup('test/testlist.xml');
      await testDriver.buildTestCases();
      print('in test project:${testDriver.testQueue.length}');
      testDriver.testQueue.forEach((k,v)=> print(testDriver.executeTest(v,xpath.exec)));
    });

    test('First Test', () {


       expect(true, isTrue);


    });

  });

}
