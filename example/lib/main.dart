import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<String>_productLists = Platform.isAndroid
      ? [
    'android.test.purchased',
    'point_1000',
    '5000_point',
    'android.test.canceled',
  ]
      : ['com.cooni.point1000','com.cooni.point5000'];

  String _platformVersion = 'Unknown';
  List<IAPItem> _items = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterInappPurchase.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // prepare
    var result = await FlutterInappPurchase.prepare;
    print ('result: $result');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    // refresh items for android
    String msg = await FlutterInappPurchase.consumeAllItems;
    print('consumeAllItems: $msg');
  }

  Future<Null> _buyProduct(IAPItem item) async {
    try {
      PurchasedItem purchased= await FlutterInappPurchase.buyProduct(item.productId);
      print('purchased: ${purchased.toString()}');
    } catch (error) {
      print('$error');
    }
  }

  Future<Null> _getProduct() async {
    List<IAPItem> items = await FlutterInappPurchase.getProducts(_productLists);
    for (var item in items) {
      print('${item.toString()}');
      this._items.add(item);
    }

    setState(() {
      this._items = items;
    });
  }

  List<Widget> _renderInapps() {
    List<Widget> widgets = this._items.map((item) => Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 5.0),
              child: Text(
                item.toString(),
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
              ),
            ),
            FlatButton(
              color: Colors.orange,
              onPressed: () {
                this._buyProduct(item);
              },
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 48.0,
                      alignment: Alignment(-1.0, 0.0),
                      child: Text('Buy Item'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )).toList();
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Inapp Plugin by dooboolab'),
        ),
        body:
        Container(
          padding: EdgeInsets.all(10.0),
          child: ListView(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Text(
                      'Running on: $_platformVersion\n',
                      style: TextStyle(
                          fontSize: 18.0
                      ),
                    ),
                  ),
                  Container(
                    height: 60.0,
                    margin: EdgeInsets.only(bottom: 10.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 15.0),
                              child: FlatButton(
                                color: Colors.green,
                                padding: EdgeInsets.all(0.0),
                                onPressed: () async {
                                  await FlutterInappPurchase.prepare;
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                                  alignment: Alignment(0.0, 0.0),
                                  child: Text(
                                    'Connect Billing',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FlatButton(
                              color: Colors.green,
                              padding: EdgeInsets.all(0.0),
                              onPressed: () {
                                this._getProduct();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                alignment: Alignment(0.0, 0.0),
                                child: Text(
                                  'Get Items',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 15.0),
                              child: FlatButton(
                                color: Colors.green,
                                padding: EdgeInsets.all(0.0),
                                onPressed: () async {
                                  await FlutterInappPurchase.endConnection;
                                  setState(() {
                                    this._items = [];
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                                  alignment: Alignment(0.0, 0.0),
                                  child: Text(
                                    'End Connection',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: this._renderInapps(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
