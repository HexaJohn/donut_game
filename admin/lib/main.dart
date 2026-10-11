import 'package:flutter/material.dart';

import 'src/aws.dart';
import 'src/live_screen.dart';
import 'src/model.dart';
import 'src/stats_screen.dart';
import 'src/tables_screen.dart';
import 'src/widgets.dart';

void main() => runApp(const AdminApp());

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE9B949), brightness: brightness),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Donut Admin',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const AdminHome(),
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  AdminModel? _model;
  String? _startError;
  int _tab = 0;
  String? _selected;

  @override
  void initState() {
    super.initState();
    try {
      _model = AdminModel(AdminAws.fromEnvironment())..start();
    } catch (e) {
      _startError = '$e';
    }
  }

  @override
  void dispose() {
    _model?.dispose();
    super.dispose();
  }

  void _openTable(String code) => setState(() {
    _tab = 1;
    _selected = code;
  });

  @override
  Widget build(BuildContext context) {
    final model = _model;
    if (model == null) {
      return Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(32), child: Text(_startError ?? '')),
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _tab,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (tab) => setState(() => _tab = tab),
            leading: const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Icon(Icons.donut_large_rounded, size: 32, color: Color(0xFFE9B949)),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.sensors_rounded), label: Text('Live')),
              NavigationRailDestination(icon: Icon(Icons.table_restaurant_rounded), label: Text('Tables')),
              NavigationRailDestination(icon: Icon(Icons.insights_rounded), label: Text('Stats')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: model,
              builder: (context, _) => Column(
                children: [
                  StatusBar(model: model, title: const ['Who\'s online', 'Server browser', 'Usage'][_tab]),
                  Expanded(
                    child: switch (_tab) {
                      0 => LiveScreen(model: model, onOpenTable: _openTable),
                      1 => TablesScreen(
                        model: model,
                        selected: _selected,
                        onSelect: (code) => setState(() => _selected = code),
                      ),
                      _ => StatsScreen(model: model),
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
