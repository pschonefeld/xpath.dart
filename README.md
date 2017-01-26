# xpath_dart

Early days ... nothing working yet

XPath 3.1 Implementation in Dart
Targeting https://www.w3.org/TR/2016/CR-xpath-31-20161213/  (candidate rec)

*from the spec:* XPath 3.1 is an expression language that allows the processing of values conforming to the data model defined in [XQuery and XPath Data Model (XDM) 3.1]. The name of the language derives from its most distinctive feature, the path expression, which provides a means of hierarchic addressing of the nodes in an XML tree. As well as modeling the tree structure of XML, the data model also includes atomic values, function items, and sequences. This version of XPath supports JSON as well as XML, adding maps and arrays to the data model and supporting them with new expressions in the language and new functions in [XQuery and XPath Functions and Operators 3.1].


## Usage

Testing impletmetation requires inclusion of test driver ... in pubspec.yaml include:

    dev_dependencies:
      test: '>=0.12.0 <0.13.0'
      xml_query_test_driver:
          git: https://github.com/pschonefeld/XMLQueryTestDriver.git

setting up for tests:

      XPath xpath = new XPath();
      //TODO: following line to be set to reference test driver package
      //will only work if the catalog is in a sibling folder to project
      //with the path as specified in the argument
      var testDriver = new TestDriver.resources('../xml-query-test-driver/lib/res/qt3_1_0/');
      testDriver.setup('test/testlist.xml');
      await testDriver.buildTestCases();
      print('in test project:${testDriver.testQueue.length}');
      testDriver.testQueue.forEach((k,v)=> print(testDriver.executeTest(v,xpath.exec)));

inlcude selected catalog tests in test/testlist.xml (eg):

    <tests>
        <set>prod-AxisStep</set>
        <set>prod-AxisStep.ancestor</set>
        <set>prod-AxisStep.following</set>
    </tests>

## Features and bugs

Please file feature requests and bugs at TBA.


==========






