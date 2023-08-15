import 'dart:math';

import 'package:data_sheet/data_sheet.dart';
import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

int nextId = 0;

class Friend {
  Friend(this.name, this.food, this.gender, this.dobEpoch, this.country,
      this.weight, this.height) {
    id = ++nextId;
  }
  late int id;
  String name;
  String food;
  String gender;
  String country;
  int dobEpoch;
  double weight;
  double height;
}

List<String> gender = ['M', 'F', 'O'];
List<String> food = ['Indian', 'South Asian', 'Italian', 'Chinese', 'Vegan'];
List<String> country = [
  'India',
  'USA',
  'France',
  'Denmark',
  'Nepal',
  'Shri Lanka'
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

//////////////// START main.dart ////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<List<String>> _dataPage1, _dataPage2, _dataPage3, _bodyPage3;
  late int _tabIndex;
  late ScrollPhysics outerPhysics;
  late ScrollController outerController1, outerController2;
  late int _curRow, _curCol, _pinnedRows, _pinnedCols;
  late List<String> _suggestGender,
      _suggestCountry,
      _suggestFood,
      _header1,
      _header2;
  final int _totalTabs = 2;
  late List<Friend> _friends;
  late List<bool?> _selected;
  late List<double> _columnWidths;

  /// Initialize our working data
  _initFriends() {
    int baseDOB = DateTime(2002, 5, 1, 6).millisecondsSinceEpoch;
    Random rand = Random();
    _friends = [];
    for (int i = 1; i < 10; i++) {
      _friends.add(Friend(
        'Friend ${nextId + 1}',
        food[rand.nextInt(food.length - 1)],
        gender[rand.nextInt(gender.length - 1)],
        baseDOB + rand.nextInt(12 * 5) * (30 * 24 * 3600 * 1000),
        country[rand.nextInt(country.length - 1)],
        60.5 + rand.nextInt(20) * 5 / 3,
        160.0 + rand.nextInt(30).toDouble(),
      ));
    }
  }

  /// Initialize the [_tabController], set listener
  _initTabController(int length) {
    _tabIndex = 0;
    _tabController = TabController(length: length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _tabIndex = _tabController.index;
      });
    });
  }

  /// Initialize all relevant variables
  _initialize() async {
    _suggestGender = ['M', 'F', 'O'];
    _suggestCountry = [
      'India',
      'USA',
      'France',
      'Nepal',
      'Shri Lanka',
    ];
    _suggestFood = ['Indian', 'Asian', 'Chinese', 'Burmese'];
    _header1 = [
      'SlNo',
      'Name',
      'Gender',
      'Country',
      'Food',
      'DOB',
      'Wt. (kg)',
      'Ht (cm)',
    ];
    _header2 = [
      'Suggest ->',
      'None',
      'Restrict',
      'Add',
      'Keep',
      'None',
      'None',
      'None'
    ];
    _dataPage1 =
        List.generate(10, (row) => List.generate(7, (col) => 'R$row:C$col'));
    _dataPage2 = List.generate(
        9,
        (row) => List.generate(
            7,
            (col) =>
                '${String.fromCharCode(65 + row)}${String.fromCharCode(49 + col)}'));

    _dataPage3 = [];
    _dataPage3.add(_header1);
    _dataPage3.add(_header2);
    _initFriends();
    _bodyPage3 = _friends.map((e) {
      return [
        '${e.id}',
        e.name,
        e.gender,
        e.country,
        e.food,
        DateFormat('dd-MMM-yyyy')
            .format(DateTime.fromMillisecondsSinceEpoch(e.dobEpoch)),
        e.weight.toStringAsFixed(1),
        e.height.toStringAsFixed(1)
      ];
    }).toList();
    _dataPage3.addAll(_bodyPage3);
    _initTabController(_totalTabs);
    _selected = List.generate(_dataPage3.length, (index) => false);
    _columnWidths = [0.15, 0.3, 0.2, 0.25, 0.25, 0.3, 0.2, 0.2];
  }

  /// CALLBACK: Passes the cell position which is selected
  /// [refresh] is planned for some future features, may be ignored.
  _onSelectCell(int row, int col, {bool refresh = true}) {
    if (refresh) {
      setState(() {
        _curRow = row;
        _curCol = col;
      });
    }
  }

  /// CALLBACK: Process information received from DataSheet
  /// Returns [true] if info processed correctly, returns [false] on error
  bool _onUpdate(int row, int col, dynamic value, EditAction action) {
    late String str, newValue;
    double? val;
    int count = 0;

    str = '';
    switch (action) {
      case EditAction.add:
        List<String> nl = List.generate(_header1.length, (index) {
          return index == 0 ? '${_dataPage3.length - _pinnedRows + 1}.' : '';
        });
        setState(() {
          _bodyPage3.add(nl);
        });
        _selected.add(false);
        break;
      case EditAction.delete:
        int rowNo = _curRow - _pinnedRows;
        setState(() {
          _bodyPage3.removeAt(rowNo);
          _selected.removeAt(rowNo);
          if (_curRow >= _bodyPage3.length + _pinnedRows) _curRow--;
          for (int i = rowNo; i < _bodyPage3.length; i++) {
            _bodyPage3[i][0] = '${i - _pinnedRows + 1}.';
          }
        });
        break;
      case EditAction.sortNone:
        _bodyPage3.sort((a, b) => a[0].compareTo(b[0]));
        break;
      case EditAction.sortA2Z:
        _bodyPage3.sort((a, b) => a[col].compareTo(b[col]));
        break;
      case EditAction.sortZ2A:
        _bodyPage3.sort((b, a) => a[col].compareTo(b[col]));
        break;
      case EditAction.select:
        _selected[row] = value;
        for (int i = _pinnedRows; i < _selected.length; i++) {
          if (_selected[i] == true) count++;
        }
        _selected[0] = count == (_dataPage3.length - _pinnedRows)
            ? true
            : count == 0
                ? false
                : null;
        break;
      case EditAction.selectAll:
        for (int i = 0; i < _selected.length; i++) {
          _selected[i] = value != true ? false : true;
        }
        break;
      default:
        break;
    }

    setState(() {
      _dataPage3 = [];
      _dataPage3.add(_header1);
      _dataPage3.add(_header2);
      _dataPage3.addAll(_bodyPage3);
    });

    if (action != EditAction.update) return true;

    switch (col) {
      case 1: // Name
      case 3: // Country
      case 4: // Food
        newValue = value;
        break;
      case 2: // Gender
        newValue = value.substring(0, 1).toUpperCase();
        break;
      case 5: // DOB
        try {
          DateFormat df = DateFormat('dd-MMM-yyyy');
          newValue = df.format(value);
        } catch (fe) {
          str = fe.toString();
        }
        break;
      case 6: // Weight
      case 7: // Height
        val = double.tryParse(value);
        if (val != null) {
          newValue = val.toStringAsFixed(1);
        } else {
          str = "Input must be a number";
        }
        break;

      default:
        assert(false);
        break;
    }
    if (str.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          str,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));
    } else {
      setState(() {
        _dataPage3[row][col] = newValue;
      });
    }

    return str.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _curRow = _pinnedRows = 2;
    _curCol = _pinnedCols = 1;
    outerPhysics = const ClampingScrollPhysics();
    outerController1 = ScrollController();
    outerController2 = ScrollController();
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    outerController1.dispose();
    outerController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _totalTabs,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Data Table Demo'),
          actions: _tabIndex < 1
              ? null
              : [
                  IconButton(
                    tooltip: 'Delete row',

                    /// The data table must have at least one editable row
                    onPressed: _dataPage3.length <= _pinnedRows + 1
                        ? null
                        : () {
                            _onUpdate(_curRow, _curCol, '', EditAction.delete);
                          },
                    icon: const Icon(Icons.delete),
                  ),
                  IconButton(
                    tooltip: 'Add Row',
                    onPressed: () {
                      _onUpdate(0, 0, 0, EditAction.add);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
          bottom: TabBar(
            isScrollable: true,
            controller: _tabController,
            automaticIndicatorColorAdjustment: true,
            tabs: [
              'ReadOnly / \nColumnWidthOptions',
              'Editable',
            ]
                .map(
                  (String e) => Tab(
                    child: Text(
                      e,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _getPage1(),
            _getPage2(),
          ],
        ),
      ),
    );
  }

  /// Page 1 of the Demo App
  Widget _getPage1() {
    // return Icon(Icons.add);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            controller: outerController1,
            children: [
              const Text('Fixed Column Width (Default)',
                  style: TextStyle(fontSize: 24)),
              SizedBox(
                width: constraints.maxWidth,
                height: 6 * kToolbarHeight,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 0.5)),
                  child: DataSheet(
                    data: _dataPage1,
                    pinnedRows: 1,
                    pinnedCols: 1,
                    cellSize: const Size(120, kToolbarHeight),
                    outerController: outerController1,
                    outerPhysics: outerPhysics,
                    decoPinnedRow: [
                      BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.4),
                        border: Border.all(width: 0.5, color: Colors.black38),
                      ),
                    ],
                    decoPinnedCol: [
                      BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        border: Border.all(width: 0.5, color: Colors.black38),
                      ),
                    ],
                    stylePinnedRowText: const TextStyle(
                        color: Colors.brown, fontWeight: FontWeight.w400),
                    stylePinnedColText: const TextStyle(
                        color: Colors.brown, fontWeight: FontWeight.w400),
                    styleNormalCellText: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w300),
                  ),
                ),
              ),
              const Divider(height: 16),
              const Text('Column Width in Pixels',
                  style: TextStyle(fontSize: 24)),
              SizedBox(
                width: constraints.maxWidth,
                height: 6 * kToolbarHeight,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 0.5)),
                  child: DataSheet(
                    data: _dataPage2,
                    pinnedRows: 1,
                    pinnedCols: 1,
                    cellSize: const Size(100, kToolbarHeight * 0.75),
                    columnWidths: const [40, 120, 80, 150, 60, 100, 60],
                    columnWidthOption: ColumnWidthOption.pixel,
                    outerController: outerController1,
                    outerPhysics: outerPhysics,
                    decoPinnedRow: [
                      BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.4),
                        border: Border.all(width: 0.5, color: Colors.black38),
                      ),
                    ],
                    decoPinnedCol: [
                      BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(width: 0.5, color: Colors.black38),
                      ),
                    ],
                    stylePinnedRowText: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w400),
                    stylePinnedColText: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w400),
                    styleNormalCellText: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w300),
                  ),
                ),
              ),
              const Divider(height: 16),
              const Text(
                  'Column Width Proportionate to Widget Width\n'
                  'When sum of values is kept 1.0, it always fits into given width',
                  style: TextStyle(fontSize: 16)),
              SizedBox(
                width: constraints.maxWidth,
                height: 6 * kToolbarHeight,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 0.5)),
                  child: DataSheet(
                    data: _dataPage2,
                    pinnedRows: 1,
                    pinnedCols: 0,
                    outerController: outerController1,
                    outerPhysics: outerPhysics,
                    cellSize: const Size(100, kToolbarHeight * 0.75),
                    columnWidths: const [
                      0.075,
                      0.25,
                      0.1,
                      0.2,
                      0.15,
                      0.125,
                      0.1
                    ],
                    columnWidthOption: ColumnWidthOption.ratio,
                    decoPinnedRow: [
                      BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.6),
                        border: Border.all(width: 0.5, color: Colors.black38),
                      ),
                      BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.3),
                        border: Border.all(width: 0.5, color: Colors.black38),
                      ),
                    ],
                    // decoPinnedCol: [BoxDecoration(
                    //   color: Colors.purple.withOpacity(0.1),
                    //   border: Border.all(width: 0.5, color: Colors.black38),
                    // )],
                    stylePinnedRowText: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w400),
                    styleNormalCellText: const TextStyle(
                        color: Colors.purple, fontWeight: FontWeight.w300),
                  ),
                ),
              ),
              const Divider(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Page 2 of the Demo App
  Widget _getPage2() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            controller: outerController2,
            children: [
              const Text('SuggestionsOption\n'
                  '\n   [Restrict] -> Entry restricted to suggestions in list'
                  '\n   [Add]      -> Entry added to suggestions list, if not existing'
                  '\n   [Keep]     -> Allows to keep entry, not added to list'
                  '\n   [None]     -> Free editing, No suggestions'),
              Text('\nSelected Cell - R$_curRow:C$_curCol'),
              const Divider(height: 10),
              SizedBox(
                width: constraints.maxWidth,
                height: 6 * kToolbarHeight,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 0.5)),
                  child: DataSheet(
                    data: _dataPage3,
                    onUpdate: _onUpdate,
                    onSelectCell: _onSelectCell,
                    isEditing: true,
                    outerController: outerController2,
                    outerPhysics: outerPhysics,
                    cellSetups: [
                      CellSetup(selected: _selected),
                      CellSetup(
                          textInputType: TextInputType.name,
                          defaultSort: EditAction.sortA2Z,
                          selected: _selected),
                      CellSetup(
                          suggestions: _suggestGender,
                          action: SuggestionsAction.restrict,
                          defaultSort: EditAction.sortNone),
                      CellSetup(
                          suggestions: _suggestCountry,
                          textInputType: TextInputType.name,
                          defaultSort: EditAction.sortZ2A,
                          triStateSort: false),
                      CellSetup(
                          suggestions: _suggestFood,
                          action: SuggestionsAction.keep,
                          textInputType: TextInputType.name),
                      CellSetup(
                          textInputType: TextInputType.text,
                          defaultSort: EditAction.sortZ2A,
                          triStateSort: false,
                          dateFormat: 'dd-MMM-yyyy',
                          pickerMode: DateTimeFieldPickerMode.date),
                      CellSetup(textInputType: TextInputType.number),
                      CellSetup(textInputType: TextInputType.number),
                    ],
                    pinnedRows: _pinnedRows,
                    pinnedCols: _pinnedCols,
                    cellSize: const Size(100, kToolbarHeight * 0.7),
                    columnWidths: _columnWidths,
                    columnWidthOption: ColumnWidthOption.ratio,
                    decoPinnedRow: [
                      BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.4),
                        border: const Border(
                          bottom: BorderSide(width: 0.5, color: Colors.black38),
                        ),
                      ),
                      BoxDecoration(
                        color: Colors.limeAccent.withOpacity(0.4),
                        border: const Border(
                          bottom: BorderSide(width: 0.5, color: Colors.black38),
                        ),
                      ),
                    ],
                    decoPinnedCol: [
                      BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        border: const Border(
                          bottom: BorderSide(width: 0.5, color: Colors.black38),
                          right: BorderSide(width: 0.5, color: Colors.black38),
                        ),
                      )
                    ],
                    decoNormal: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(width: 0.5, color: Colors.black38),
                      ),
                    ),
                    stylePinnedRowText: const TextStyle(
                        color: Colors.brown, fontWeight: FontWeight.w400),
                    stylePinnedColText: const TextStyle(
                        color: Colors.brown, fontWeight: FontWeight.w400),
                    styleNormalCellText: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w300),
                  ),
                ),
              ),
              const Divider(height: 5),
              const Text('\n- Tap on cell to edit.'
                  '\n- Completing edit automatically selects next cell.'
                  '\n- Tap outside of Edit Dialog to End Edit'),
              SizedBox(height: constraints.maxHeight),
            ],
          ),
        );
      },
    );
  }
}
