import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Mcdonalds Bot Kitchen Simulator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List pendingOrdersList = [];
  List completedOrdersList = [];
  List botList = [];
  int regOrderId = 1; //ID to keep track of regular orders
  int vipOrderId = 1; //ID to keep track of vip orders
  int botId = 0;

  late var stringPendingList = pendingOrdersList.isNotEmpty
      ? pendingOrdersList.join(', ')
      : 'No pending orders';
  late var stringCompletedList = completedOrdersList.isNotEmpty
      ? completedOrdersList.join(', ')
      : 'No completed orders';
  late var stringBotList =
      botList.isNotEmpty ? botList.join(', ') : 'No bots added';

  void updateUI() {
    stringPendingList = pendingOrdersList.isNotEmpty
        ? pendingOrdersList.join(', ')
        : 'No pending orders';
    stringCompletedList = completedOrdersList.isNotEmpty
        ? completedOrdersList.join(', ')
        : 'No completed orders';
    stringBotList = botList.isNotEmpty ? botList.join(', ') : 'No bots added';
  }

  bool botsAvailable() {
    for (var map in botList) {
      if (map?['botStatus'] == 'AFK') {
        return true;
      }
    }
    return false;
  }

  addCompletedOrder(order) {
    setState(() {
      completedOrdersList.add(order);
      checkForPending();
      updateUI();
    });
  }

  completeOrder(order) {
    // const completeStore = useCompleteOrdersStore();
    setState(() {
      addCompletedOrder(order);
      pendingOrdersList.removeWhere((item) => item['name'] == order);
      updateUI();
    });
  }

  markAsComplete(id, order) {
    // const orderStore = usePendingOrdersStore();
    setState(() {
      for (var i in botList) {
        /** Matches available bots to assigned bot order id for completion, will only run when found,
         *  therefore timeout will not execute if bot with that id doesnt exist.
         **/
        if (i['id'] == id) {
          //Put the bot to rest after job is completed
          i['botStatus'] = "AFK";
          updateUI();
          //Move the newly completed order to completed orders
          for (var e in pendingOrdersList) {
            if (e['name'] == order['name']) {
              completeOrder(e['name']);
              // orderStore.completeOrder(e.name);
            }
          }
          return;
        }
      }

      return;
    });
  }

  void getToWork(order) {
    // const orderStore = usePendingOrdersStore();
    var botId;
    setState(() {
      if (botsAvailable()) {
        for (var i in botList) {
          if (i['botStatus'] == "AFK") {
            botId = i['id'];
            break;
          }
        }

        //Will mark the ongoing order as completed once 10s mark is passed
        var timer = Timer(
            const Duration(seconds: 10), () => markAsComplete(botId, order));
        // const timeout = setTimeout(this.markAsComplete, 10000, botId, order);

        //Put the bot in working mode
        for (var i in botList) {
          if (i['id'] == botId) {
            i['botStatus'] = 'Preparing ${order["name"]}';
          }
        }

        //Set the order as being prepared
        for (var i in pendingOrdersList) {
          if (i['name'] == order['name']) {
            i['status'] = "preparing";
            i['assignedTo'] = botId.toString();
          }
        }
        updateUI();
      }
    });
    //searches for any afk bots to get them to do any orders on waiting
  }

  checkForPending() {
    // const orderStore = usePendingOrdersStore();
    for (var i in pendingOrdersList) {
      //checks for any order on waiting and also whether there are any bots available to handle the order
      if (i['status'] == "waiting" && botsAvailable()) {
        getToWork(i);
      }
    }
  }

  // void _incrementCounter() {
  //   setState(() {
  //     return;
  //   });
  // }

  Widget pendingOrders() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          child: const Text(
            'Pending orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            softWrap: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(stringPendingList, softWrap: true),
        )
      ],
    );
  }

  Widget completedOrders() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          child: const Text(
            'Completed orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            softWrap: true,
          ),
        ),
        Text(stringCompletedList, softWrap: true)
      ],
    );
  }

  Widget botKitchen() {
    void addBot() {
      setState(() {
        botList.add({'botStatus': "AFK", 'id': botId});
        botId++;
        stringBotList =
            botList.isNotEmpty ? botList.join(', ') : 'No bots added';
      });
      checkForPending();
      //checkForPending(); //makes newly added bot to check for any orders on wait
    }

    bool botDeleted(botId) {
      for (var map in botList) {
        if (map?['id'] == botId) {
          return true;
        }
      }
      return false;
    }

    void removeBot() {
      //Will only run when bot list isn't empty
      if (botList.isNotEmpty) {
        setState(() {
          botList.removeLast();
          
          //Below is the handler for any abandoned orders to be put back in the waiting queue
          for (var i in pendingOrdersList) {
            if (i['status'] == "preparing" && !botDeleted(i['assignedTo'])) {
              i['status'] = "waiting";
              i['assignedTo'] = 'abandoned by bot ${i["assignedTo"]}';
            }
          }
          updateUI();
        });
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Bot Kitchen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            softWrap: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () => addBot(),
                child: const Text('+ Bot'),
              ),
              TextButton(
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () => removeBot(),
                child: const Text('- Bot'),
              )
            ],
          ),
        ),
        Text(stringBotList, softWrap: true)
      ],
    );
  }

  Widget orderPanel() {
    void addOrder() {
      setState(() {
        pendingOrdersList.add({
          'name': 'Regular $regOrderId',
          'status': "waiting",
          'assignedTo': null
        });
        regOrderId++;
        stringPendingList = pendingOrdersList.isNotEmpty
            ? pendingOrdersList.join(', ')
            : 'No pending orders';
      });
      checkForPending();
    }

    checkForRegular() {
      for (var map in pendingOrdersList) {
        if (map?['name'].contains("Regular") ?? false) {
          return map;
        }
      }
      return false;
    }

    void addVipOrder() {
      if (checkForRegular() != false) {
        setState(() {
          pendingOrdersList
              .insert(pendingOrdersList.indexOf(checkForRegular()), {
            'name': 'VIP $vipOrderId',
            'status': "waiting",
            'assignedTo': null
          });
          vipOrderId++;
          stringPendingList = pendingOrdersList.isNotEmpty
              ? pendingOrdersList.join(', ')
              : 'No pending orders';
        });
      } else {
        setState(() {
          pendingOrdersList.add({
            'name': 'VIP $vipOrderId',
            'status': "waiting",
            'assignedTo': null
          });
          vipOrderId++;
          stringPendingList = pendingOrdersList.isNotEmpty
              ? pendingOrdersList.join(', ')
              : 'No pending orders';
        });
      }
      checkForPending();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          child: const Text(
            'Order Here',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            softWrap: true,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: () => addOrder(),
              child: const Text('New Normal Order'),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: () => addVipOrder(),
              child: const Text('New VIP Order'),
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            pendingOrders(),
            completedOrders(),
            botKitchen(),
            orderPanel(),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
