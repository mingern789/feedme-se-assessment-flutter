import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Mcdonalds Bot Kitchen Simulator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

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

  void addCompletedOrder(order) {
    setState(() {
      completedOrdersList.add(order);
      checkForPending();
      updateUI();
    });
  }

  void completeOrder(order) {
    setState(() {
      addCompletedOrder(order);
      pendingOrdersList.removeWhere((item) => item['name'] == order);
      updateUI();
    });
  }

  markAsComplete(id, order) {
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
            }
          }
          return;
        }
      }

      return;
    });
  }

  void getToWork(order) {
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
  }

  void checkForPending() {
    for (var i in pendingOrdersList) {
      //checks for any order on waiting and also whether there are any bots available to handle the order
      if (i['status'] == "waiting" && botsAvailable()) {
        getToWork(i);
      }
    }
  }

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
        updateUI();
      });
      checkForPending();
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
          updateUI();
        });
      } else {
        setState(() {
          pendingOrdersList.add({
            'name': 'VIP $vipOrderId',
            'status': "waiting",
            'assignedTo': null
          });
          vipOrderId++;
          updateUI();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            pendingOrders(),
            completedOrders(),
            botKitchen(),
            orderPanel(),
          ],
        ),
      ),
    );
  }
}
