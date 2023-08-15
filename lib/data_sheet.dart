library data_sheet;

import 'dart:math';

import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Defines how the Column widths of the DataSheet must be interpreted
enum ColumnWidthOption {
  fixed, // all column widths equal to the width given by cellSize parameter.
  // Default <cellSize> is Size (80,40), cellSize MUST not be Size.zero
  pixel, // column width read from list <columnWidths>, the width is given in pixels,
  // <cellWidths.length> MUST have entries equal to number of columns in parameter <data>
  ratio, // column width is derived from the widget width x ratio,
  // given in corresponding element of the list
  // cellWidths.length MUST have entries equal to number of columns in parameter <data>
}

/// Used to pass edit event to parent widget
/// User must write code to handle <add>/<delete> and modify <data> accordingly
/// DataSheet calls back parent onUpdate when user takes any other action
enum EditAction {
  update, // User has updated a cell

  // Optional command only to be in sync with EditAction command
  // data_sheet does not handle or send add/delete action callbacks
  add,
  delete,

  // Sort actions, caller widget must handle the actions, data_sheet simply
  // calls back the parent with action
  sortA2Z, //
  sortZ2A,
  sortNone,

  // Select actions, caller widget must handle the actions, data_sheet simply
  // calls back the parent with action
  select,
  selectAll,
}

/// Set options to act on user input, when suggestions are shown
enum SuggestionsAction {
  /// Allows Selection from suggestion List only
  restrict,

  /// Add user input to the suggestion List apart from passing the new value to caller
  add,

  /// Pass the user input to caller, do not add to suggestion List
  keep,
}

///
/// CellSetup class has all the info for cells in a given column
/// e.g. the type of input expected, whether sortable etc.
///
/// textInputType - used to determine the cell content type and also the type of keyboard to use
/// triStateSort  - if true, allows asc, desc and none (unsorted) sort
///               - if false, allows asc & desc sorts only
///  defaultSort  - informs widget about the sort state of column
///  suggestions  - a List<String> suggesting possible options for the cell
///  action       - helps in deciding what to do once a suggestion is selected
///                 refer SuggestionsAction for details
///  helperText   - Same as InputDecoration, used while editing
///  labelText    - Same as InputDecoration, used while editing
///  selected     - a List<bool> with status of corresponding row selection
///               - the List length must be equal to the # of rows in data table
///  getWidget    - a callback function, in case one wants to override the default
///               - being used by the widget
///
class CellSetup {
  CellSetup({
    this.textInputType = TextInputType.text,
    this.triStateSort = true,
    this.defaultSort,
    this.suggestions,
    this.action = SuggestionsAction.add,
    this.helperText,
    this.hintText,
    this.labelText,
    this.selected,
    this.getWidget,
    this.dateFormat,
    this.pickerMode,
  });
  TextInputType textInputType;
  bool triStateSort;
  EditAction? defaultSort;
  List<String>? suggestions;
  List<bool?>? selected;
  SuggestionsAction action;
  Widget Function(int row, int col)? getWidget;
  String? labelText, helperText, hintText;
  String? dateFormat;
  DateTimeFieldPickerMode? pickerMode;
  bool get isSortable => defaultSort != null;
  bool get isSelectable => selected != null;
  bool get isDateTime => dateFormat != null && pickerMode != null;
}

///
/// DataSheet
///   Basically a Scrollable DataTable widget with facility to edit each cell
///   Parameter [data]
///       - Must be provided in List<List<String>> format
///       - Contains values of all columns & rows in String format. 
///       - data.length -> # of Rows
///       - data[0].length -> # of Columns
///       - The user shall populate this List converting all the values to String
///         and ultimately to List<List<String>>
///
///   Parameter [onUpdate]
///     - This is the main callback function the widget calls after the user performs edit, sort operation. 
///     - The functions passes a dynamic value related to the cell identified 
///       by row & column number along with action taken. 
///     - It is users responsibility to handle/check the passed value for correctness and updating the same.
///   Parameter [onSelectCell]
///     - Callback function, called by DataSheet when a select checkbox is tapped on
///   Parameter [cellSetups]
///     - A [List<CellSetup>] having Cell Setup values for columns.
///     - The length of this must equal number of columns.
///   Parameters [outerController] / [outerPhysics]
///     - Scroll controller of parent widget (if scrollable), can be null.
///     - The outerPhysics parameter is required in pair with outerController parameter, else it can be null.
///   Parameter [isEditing]
///     - Setting it true/false will make the widget editable/read-only
///   Parameter [moveNextAfterEdit]
///     - If true, moves to & selects editing for next cell, after editing of currently selected cell is complete.
///   Parameter [pinnedRows]
///     - Number of pinned (fixed) top row(s), This is like header of the sheet.
///     - Top row(s) given by this parameter will be always visible during scroll.
///   Parameter [pinnedCols]
///     - Number of pinned (fixed) left columns(s).
///     - The left column(s) given by this parameter will be always visible during scroll.
///   Parameter [cellSize]
///     - Override, default cellSize
///   Parameter [columnWidths]
///     - A List<double> parameter providing column width setup values,
///     - Parameter [columnWidthOption] decides how these given values are interpreted.
///   Parameter [columnWidthOption] : Refer comments above
///
///   Parameter [decoPinnedRow]/[decoPinnedCol]/[decoNormal]
///     - BoxDecorations for Pinned Row Cells, Pinned Column Cells and Normal Cells respectively.
///
///   Parameter [stylePinnedRowText]/[stylePinnedColText]/[styleNormalCellText]
///     - TextStyles for Pinned Row Cells, Pinned Column Cells and Normal Cells respectively.
///     
class DataSheet extends StatefulWidget {
  const DataSheet(
      {Key? key,
      required this.data,
      this.onUpdate,
      this.onSelectCell,
      this.cellSetups,
      this.outerController,
      this.outerPhysics,
      this.isEditing = false,
      this.moveNextAfterEdit = true,
      this.pinnedRows,
      this.pinnedCols,
      this.cellSize = const Size(80, kToolbarHeight),
      this.columnWidths,
      this.columnWidthOption = ColumnWidthOption.fixed,
      this.decoPinnedRow,
      this.decoPinnedCol,
      this.decoNormal,
      this.stylePinnedRowText,
      this.stylePinnedColText,
      this.styleNormalCellText})
      : super(key: key);

  /// Main data that the scroll-table shall handle, must have atlease one row & one column
  final List<List<String>> data;

  /// Callback function to inform parent widget about the changes in cell
  ///  If this parameter is null then the data-sheet will be displayed read-only else it is in editMode
  final bool Function(int row, int col, dynamic value, EditAction action)?
      onUpdate;

  /// Used to pass-on the scroll event to outer widget.
  ///  When this parameter is defined, parameter outerPhysics must also be defined
  /// This shall be defined if this sheet is child of a scrollable widget
  final ScrollController? outerController;
  final ScrollPhysics? outerPhysics;

  /// Call back function, informing parent widget about the changes in selected cell
  /// This will be ignored when onUpdate is null
  final Function(int row, int col, {bool refresh})? onSelectCell;

  /// List defining the setup of cells in a given column
  final List<CellSetup>? cellSetups;

  /// Sets Edit/read-only mode
  final bool isEditing;

  /// Selects next cell once editing of selected cell is completed
  final bool moveNextAfterEdit;

  /// # of Rows that will ALWAYS be displayed at the top of table, other rows may be scrolled
  final int? pinnedRows;

  /// # of Columns that will ALWAYS be displayed at the left of table, other columns may be scrolled
  final int? pinnedCols;

  /// Define CellSize
  final Size cellSize;

  /// All styles go here
  final TextStyle? stylePinnedColText;
  final TextStyle? stylePinnedRowText;
  final TextStyle? styleNormalCellText;

  /// List of column Widths, <columnWidths.length> must match the
  /// given number of columns
  final List<double>? columnWidths;
  /// Used to interpret content of <columnWidths>
  final ColumnWidthOption columnWidthOption;

  /// All decorations go here
  final List<BoxDecoration?>? decoPinnedRow;
  final List<BoxDecoration?>? decoPinnedCol;
  final BoxDecoration? decoNormal;

  @override
  State<DataSheet> createState() => _DataSheetState();
}

class _DataSheetState extends State<DataSheet> with TickerProviderStateMixin {
  late ScrollController _scrollControllerVert, _scrollControllerHorz;
  ScrollController? _scrollControllerTop, _scrollControllerLeft;
  late double _vertPos, _horzPos, _viewWidth, _viewHeight;
  late TextStyle _stylePinnedRow, _stylePinnedCol, _styleNormal;
  late List<BoxDecoration?>? _decoPinnedRow, _decoPinnedCol;
  late BoxDecoration _decoNormal, _decoSelected;
  late List<double> _columnWidths, _colOffsets;
  late List<double> _rowHeights, _rowOffsets;
  late TextEditingController? _editController;
  late int _pinnedColumn, _pinnedRow, _leftColumnNo, _topRowNo;
  late List<List<String>> _data;
  late List<int> _selectedCell;
  late int _sortState, _sortColumn;
  late bool _editMode, _firstTap;
  late Offset _tapPosition;
  late List<CellSetup>? _cellSetups;
  late Map<String, String> _suggestions;
  late List<String> _options;

  /// Called when the inner widget scrolls
  /// Passes scroll event to parent once lower/upper limit reached
  void _innerListener(double velocity, ScrollController outer) {
    assert(outer.hasClients);
    final Simulation? simulation = widget.outerPhysics
        ?.createBallisticSimulation(outer.position, velocity);
    if (simulation != null) {
      ScrollActivity test = BallisticScrollActivity(
          outer.position.activity!.delegate, simulation, this, false);
      outer.position.beginActivity(test);
    }
  }

  /// Initializes the column widths based on the ColumnWidthOption set by user,
  /// Also, sets the offset values of each column for quick reference
  void _setColumnWidth(double widgetWidth) {
    if (widget.columnWidthOption == ColumnWidthOption.fixed) {
      assert(widget.cellSize != Size.zero);
      _columnWidths = _data[0].map((e) {
        return widget.cellSize.width;
      }).toList();
    } else {
      assert(widget.columnWidths != null);
      assert(widget.columnWidths!.length == _data[0].length);

      _columnWidths = List<double>.from(widget.columnWidths!);

      if (widget.columnWidthOption == ColumnWidthOption.ratio) {
        assert(widget.columnWidths != null);
        assert(widget.columnWidths!.length == _data[0].length);
        for (int i = 0; i < _data[0].length; i++) {
          _columnWidths[i] *= widgetWidth;
        }
      }
    }
    double off = 0;
    _colOffsets.clear();
    for (int i = 0; i < _columnWidths.length; i++) {
      _colOffsets.add(off);
      off += _columnWidths[i];
    }
  }

  /// Initializes parameters based on main widget
  /// if caller has not specified any required parameter (i.e. passed a null),
  /// then the parameters are initialized to default
  void _init() {
    // First thing first, _data is base for all calculations
    _data = widget.data;
    _cellSetups = widget.cellSetups;
    assert(_cellSetups == null || _cellSetups!.length == _data[0].length);
    _options = [];
    _suggestions = {};

    _columnWidths = [];
    _rowHeights = [];
    _rowOffsets = [];
    _colOffsets = [];
    _pinnedColumn = widget.pinnedCols ?? 0;
    _pinnedRow = widget.pinnedRows ?? 0;

    _styleNormal = widget.styleNormalCellText ??
        const TextStyle(color: Colors.black54, fontWeight: FontWeight.w300);
    _stylePinnedCol = widget.stylePinnedColText ??
        const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold);
    _stylePinnedRow = widget.stylePinnedRowText ??
        const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold);

    _decoPinnedRow = widget.decoPinnedRow ??
        [
          BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.3),
            border: Border.all(color: Colors.black54, width: 0.1),
          )
        ];
    _decoPinnedCol = widget.decoPinnedCol ??
        [
          BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.1),
            border: Border.all(color: Colors.black54, width: 0.1),
          )
        ];
    _decoNormal = widget.decoNormal ??
        BoxDecoration(
          border: Border.all(
            color: Colors.black38,
            width: 0.1,
          ),
        );
    _decoSelected = BoxDecoration(
      color: Colors.blue.shade100.withOpacity(0.5),
//       border: Border.all(color: Colors.black38, width: 0.1,),
      border: const Border(
        bottom: BorderSide(width: 1.0, color: Colors.black54),
      ),
    );
    _sortState = 0; // Sort State: 0 > None, 1 > Asc, 2 > Desc
    _sortColumn = -1;
  }

  /// Returns Column number at the given offset position
  int _getColumnAtPosition(double position) {
    int col = 0;
    double width = 0;
    int columns = _data[0].length;
    for (int i = _pinnedColumn; i < columns; i++, col++) {
      width += _columnWidths[i];
      if (width >= position || i + 1 == columns) break;
    }
    assert(col < columns);
    return col + _pinnedColumn;
  }

  /// Returns Row number at the given offset position
  int _getRowAtPosition(double position) {
    int row = 0;
    double height = 0;
    int rows = _data.length;
    for (int i = _pinnedRow; i < rows; i++, row++) {
      height += _rowHeights[i];
      if (height >= position || i + 1 == rows) break;
    }
    assert(row < rows);
    return row + _pinnedRow;
  }

  /// Calls back the parent onUpdate
  /// Note that row/col number includes pinned Rows/Columns
  bool onUpdate(int row, int col, dynamic value, EditAction action) {
    assert(widget.onUpdate != null);
    return widget.onUpdate!(row, col, value, action);
  }

  @override
  initState() {
    _init();

    /// Refer https://stackoverflow.com/questions/69952261/is-there-any-way-to-scroll-parent-listview-when-the-child-listview-reached-end-i
    assert((widget.outerController == null && widget.outerPhysics == null) ||
        (widget.outerController != null && widget.outerPhysics != null));
    _scrollControllerVert = ScrollController();
    _scrollControllerHorz = ScrollController();
    if (widget.pinnedRows != null && widget.pinnedRows! > 0) {
      _scrollControllerTop = ScrollController();
    }
    if (widget.pinnedCols != null && widget.pinnedCols! > 0) {
      _scrollControllerLeft = ScrollController();
    }
    _horzPos = _vertPos = 0;
    _leftColumnNo = widget.pinnedCols ?? 0;
    _topRowNo = widget.pinnedRows ?? 0;
    _scrollControllerVert.addListener(() {
      setState(() {
        _vertPos = _scrollControllerVert.offset;
      });
      _topRowNo = _getRowAtPosition(_vertPos); //(_vertPos/_cellHeight).floor();
      if (_scrollControllerLeft?.offset != _vertPos) {
        _scrollControllerLeft?.jumpTo(_vertPos);
      }
    });

    _scrollControllerHorz.addListener(() {
      setState(() {
        _horzPos = _scrollControllerHorz.offset;
      });
      _leftColumnNo = _getColumnAtPosition(_horzPos);
      if (_scrollControllerTop != null &&
          _scrollControllerTop!.offset != _horzPos) {
        if (_scrollControllerTop!.hasClients) {
          _scrollControllerTop!.jumpTo(_horzPos);
        }
      }
    });

    _scrollControllerLeft?.addListener(() {
      if (_scrollControllerLeft!.position.pixels !=
          _scrollControllerVert.position.pixels) {
        if (_scrollControllerVert.hasClients) {
          _scrollControllerVert.jumpTo(_scrollControllerLeft!.position.pixels);
        }
      }
    });

    _scrollControllerTop?.addListener(() {
      if (_scrollControllerTop!.position.pixels !=
          _scrollControllerHorz.position.pixels) {
        if (_scrollControllerHorz.hasClients) {
          _scrollControllerHorz.jumpTo(_scrollControllerTop!.position.pixels);
        }
      }
    });
    _selectedCell =
        widget.onUpdate == null ? [0, 0] : [_pinnedRow, _pinnedColumn];
    _firstTap = true;
    super.initState();
  }

  @override
  dispose() {
    _scrollControllerVert.dispose();
    _scrollControllerHorz.dispose();
    _scrollControllerTop?.dispose();
    _scrollControllerLeft?.dispose();
    _editController?.dispose();
    super.dispose();
  }

  /// //////////////////////////////////////////////////////////////////////////
  /// Returns the Cell widget as applicable
  /// editMode ->
  ///         Returns TextEdit if the corresponding selectedCell column in <_suggestions> is null
  ///         Returns RawAutocomplete if the corresponding selectedCell column in <_suggestions> is defined (non-null)
  /// /////////////////////////////////////////////////////////////////////////
  Future<int> getOption(
      String cellText, String headerText, CellSetup? cellSetup) async {
    late String text;
    late bool updateOK;
    // CellSetup? setup = _cellSetups?[_selectedCell[1]];
    bool hasSuggestions = (cellSetup != null && cellSetup.suggestions != null);

    /// DateFormat does not support 2 digit years, year must be in 4 digitd
    assert(cellSetup == null ||
        (!cellSetup.isDateTime || cellSetup.dateFormat!.contains('yyyy')));
    if (hasSuggestions) {
      _options.clear();
      _suggestions.clear();
      assert(cellSetup.suggestions != null);

      /// Create suggestion map, avoids case sensitive comparisons
      cellSetup.suggestions!.map((e) {
        text = e.trim();
        _suggestions[text.toUpperCase()] = text;
        _options.add(text.toUpperCase());
      }).toList();
    }
    _editController!.text = _data[_selectedCell[0]][_selectedCell[1]];

    var result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_data[0][0]}-${_data[_selectedCell[0]][0]}: ',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              Text(
                headerText,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSuggestions && !cellSetup.isDateTime)
                RawAutocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return _suggestions.keys.where((String check) {
                      return check
                          .contains(textEditingValue.text.toUpperCase());
                    });
                  },
                  onSelected: (String text) {
                    debugPrint('Selected suggestion "$text"');
                    if (text.isNotEmpty) {
                      text = text.trim();
                      updateOK = onUpdate(_selectedCell[0], _selectedCell[1],
                          text, EditAction.update);
                    }
                    if (updateOK) Navigator.of(context).pop(0);
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    textEditingController.text = cellText;
                    return TextFormField(
                      autofocus: true,
                      controller: textEditingController,
                      // decoration: const InputDecoration(
                      //   // helperText: 'Enter Recipe Name',
                      //   labelText: 'Ingredient Title',
                      //   hintText: 'Specify Ingredient',
                      //   border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      //       borderSide: BorderSide(color: Colors.blue)),
                      // ),
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w300),
                      keyboardType: _cellSetups != null
                          ? _cellSetups![_selectedCell[1]].textInputType
                          : TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      focusNode: focusNode,

                      onTap: () {
                        if (_firstTap) {
                          _firstTap = false;
                          textEditingController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset:
                                textEditingController.value.text.length,
                          );
                        }
                      },
                      onTapOutside: (value) {
                        /// Ignore edit if not submitted
                        // setState((){_data[rowNo][colNo]=_editController!.text;});
                        setState(() {
                          _firstTap = true;
                        });
                        Navigator.of(context).pop(-1);
                      },
                      onFieldSubmitted: (String text) {
                        if (text != "") {
                          if (cellSetup.action == SuggestionsAction.add) {
                            if (_suggestions[text.toUpperCase()] == null) {
                              _suggestions[text.toUpperCase()] = text;
                              cellSetup.suggestions!.add(text);
                              debugPrint(
                                  'added $text to ${cellSetup.suggestions}');
                            }
                          } else if (cellSetup.action ==
                              SuggestionsAction.restrict) {
                            if (_suggestions[text.toUpperCase()] == null) {
                              // Not found in suggestions, ignore and reset to exiting value
                              text = _data[_selectedCell[0]][_selectedCell[1]];
                            }
                          } else {
                            assert(cellSetup.action == SuggestionsAction.keep);
                            // do nothing, simply pass on the <text>
                          }
                        }

                        updateOK = onUpdate(_selectedCell[0], _selectedCell[1],
                            text, EditAction.update);
                        if (updateOK) {
                          setState(() {
                            _firstTap = true;
                            if (widget.moveNextAfterEdit) {
                              _nextCell();
                            }
                          });
                          Navigator.of(context).pop(0);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: Colors.grey.shade200,
                        child: SizedBox(
                          height: 200.0,
                          width: 200.0,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(_suggestions[option]!),
                                onTap: () {
                                  onSelected(_suggestions[option]!);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (!hasSuggestions && !cellSetup!.isDateTime)
                TextField(
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.center,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w300),
                  controller: _editController!,
                  onTapOutside: (value) {
                    /// Ignore edit if not submitted
                    setState(() {
                      _firstTap = true;
                    });
                    Navigator.of(context).pop(-1);
                  },
                  keyboardType: _cellSetups != null
                      ? _cellSetups![_selectedCell[1]].textInputType
                      : TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (newText) {
                    updateOK = onUpdate(_selectedCell[0], _selectedCell[1],
                        newText, EditAction.update);
                    if (updateOK) {
                      setState(() {
                        _firstTap = true;
                        if (widget.moveNextAfterEdit) {
                          _nextCell();
                        }
                      });
                      Navigator.of(context).pop(0);
                    }
                  },
                ),
              if (cellSetup.isDateTime)
                DateTimeFormField(
                  decoration: InputDecoration(
                    hintStyle: const TextStyle(color: Colors.black45),
                    errorStyle: const TextStyle(color: Colors.redAccent),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.event_note),
                    labelText: cellSetup.labelText,
                  ),
                  initialValue:
                      DateFormat(cellSetup.dateFormat).parse(cellText),
                  mode: cellSetup.pickerMode!,
                  autovalidateMode: AutovalidateMode.always,
                  dateFormat: DateFormat(cellSetup.dateFormat),
                  dateTextStyle: const TextStyle(color: Colors.black54),
                  validator: (e) =>
                      (e?.day ?? 0) == 1 ? 'Please not the first day' : null,
                  onDateSelected: (DateTime value) {
                    updateOK = onUpdate(_selectedCell[0], _selectedCell[1],
                        value, EditAction.update);
                    if (updateOK) {
                      setState(() {
                        _firstTap = true;
                        if (widget.moveNextAfterEdit) {
                          _nextCell();
                        }
                      });
                      Navigator.of(context).pop(0);
                    }
                  },
                ),
              const SizedBox(
                height: 10,
              ),
              if (cellSetup.helperText != null)
                Text(
                  cellSetup.helperText!,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
            ],
          ),
          // actions:[
          //   TextButton(
          //     onPressed:(){
          //       Navigator.of(context).pop(-1);
          //     },
          //     child:const Text('DONE'),
          //   ),
          // ],
        );
      },
    );
    return result ?? -1;
  }

  /// Returns Left/Top cell(s), which is the overlap of pinnedRows & pinnedColumns
  Widget _getFixedCell(
      String text, double width, double height, int row, int col) {
    return Flexible(
      child: Container(
        width: width,
        height: height,
        decoration: ((row < _decoPinnedRow!.length)
            ? _decoPinnedRow![row] ?? _decoPinnedRow![0]
            : _decoPinnedRow![0]),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: widget.stylePinnedRowText != null
                ? _stylePinnedRow
                : const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// Returns top fixed rows
  Widget _getPinnedRowCell(
      String text, double width, double height, int row, int col) {
    bool showCheckbox =
        row == 0 && _cellSetups != null && _cellSetups![col].isSelectable;
    return Container(
      width: width,
      height: height,
      decoration: (row < _decoPinnedRow!.length)
          ? _decoPinnedRow![row] ?? _decoPinnedRow![0]
          : _decoPinnedRow![0],
      // child: Center(
      child: Wrap(
        alignment: showCheckbox ? WrapAlignment.start : WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showCheckbox)
            Checkbox(
              tristate: true,
              onChanged: (value) {
                setState(() {
                  onUpdate(row, col, value, EditAction.selectAll);
                });
              },
              value: _cellSetups![col].selected![row],
            ),
          Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: widget.stylePinnedRowText != null
                ? _stylePinnedRow
                : const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 3),
          if (row == 0 && _sortColumn == col && _sortState != 0)
            Icon(_sortState == 1 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14),
        ],
      ),
    );
  }

  /// Returns left fixed columns
  Widget _getPinnedColCell(String text, double width, double height, int col) {
    return Flexible(
      child: Container(
        width: width,
        height: height,
        decoration: (col < _decoPinnedCol!.length)
            ? _decoPinnedCol![col] ?? _decoPinnedCol![0]
            : _decoPinnedCol![0],
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: widget.stylePinnedColText != null
                ? _stylePinnedCol
                : const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// Selects & Edits next cell on reciept of onEditCompleted event of existing edit
  void _nextCell() {
    int rowCount = _data.length;
    int colCount = _data[0].length;
    if (_selectedCell[1] + 1 < colCount) {
      _selectedCell[1]++;
    } else {
      _selectedCell[1] = _pinnedColumn;
      if (_selectedCell[0] + 1 < rowCount) {
        _selectedCell[0]++;
      }
    }
    _scrollTo(_selectedCell[0], col: _selectedCell[1]);
  }

  /// returns a decorated cell widget based on select/deselect state
  Widget _getCell(String text, double width, double height, int row, int col,
      {bool editing = false, bool selected = false}) {
    bool showCheckbox = _cellSetups != null && _cellSetups![col].isSelectable;
    CellSetup? setup = widget.cellSetups?[col];
    return Container(
      width: width,
      height: height,
      decoration: selected ? _decoSelected : _decoNormal,
      child: Center(
//          child: _getTextWidget(text, editing),
        child: (setup != null && setup.getWidget != null)
            ? setup.getWidget!(row, col)
            : Wrap(
                alignment:
                    showCheckbox ? WrapAlignment.start : WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (showCheckbox)
                    Checkbox(
                      tristate: false,
                      onChanged: (value) {
                        onUpdate(row, col, value, EditAction.select);
                      },
                      value: _cellSetups![col].selected![row],
                    ),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    style: _styleNormal,
                  ),
                ],
              ),
      ),
    );
  }

  /// Returns sum of column widths for given column range
  double _getColumnWidthSum(int fromCol, int upToCol) {
    double width = 0;
    for (int i = fromCol; i < upToCol; i++) {
      width += _columnWidths[i];
    }
    return width;
  }

  /// Returns sum of row heights for given row range
  double _getRowHeightSum(int fromRow, int upToRow) {
    double height = 0;
    for (int i = fromRow; i < upToRow; i++) {
      height += _rowHeights[i];
    }
    return height;
  }

  ///
  ///   =============   TABLE-1 =====================================
  ///
  //   +---------+-------------------------------------------------+
  //   |  Rect1  |  Rect2 - Pinned Row(s)                          |
  //   | (fixed) |  (Fixed Vertically, may scroll horizontlly)     |
  //   +---------+-------------------------------------------------+
  //   |  Rect3  |                                                 |
  //   |         |                       Rect4                     |
  //   |  Pinned |          Active/editable cells                  |
  //   |  Col(s) |                                                 |
  //   |         |    May Scroll vert/horz                         |
  //   | fixed   |     Rect2 scrolls when Rect4 scrolls horz       |
  //   | horzly  |     Rect3 scrolls when Rect4 scrolls vert       |
  //   | may     |                                                 |
  //   | scroll  |                                                 |
  //   | vertcly |                                                 |
  //   +---------+-------------------------------------------------+
  ///
  ///   Following 4 functions return the rectangles as per settings

  ///   Returns Rect1, as shown above
  Widget _getRect1Widgets() {
    assert(_pinnedColumn != 0);
    return SizedBox(
//       width: _pinnedColumn*_cellWidth,
      width: _getColumnWidthSum(0, _pinnedColumn),
//      height: _pinnedRow*_cellHeight,
      height: _getRowHeightSum(0, _pinnedRow),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinnedRow, (rowNo) {
          return Row(
            children: List.generate(_pinnedColumn, (colNo) {
              return _getFixedCell(
                  _data[rowNo][colNo], //_cellWidth,
                  _columnWidths[colNo],
                  _rowHeights[rowNo],
                  rowNo,
                  colNo);
              // SizedBox(
              //   width:cellWidth,
              //   height:cellHeight,
              //   child: Text(data[rowNo][colNo], style:const TextStyle(color:Colors.orange),),
              // );
            }),
          );
        }),
      ),
    );
  }

  /// Checks if the tap is on header (1st Fixed row)
  int _checkCellSortOnTap(Offset tap, double width, double height) {
    late double l, t, w, h;
    late Rect rcCell;
    int offsetCol = _leftColumnNo;
    int rightCol = _getColumnAtPosition(width) + 1;
    bool tapFound = false;
    late int colNo;

    if (_pinnedRow <= 0 || _cellSetups == null) return -1;

    for (colNo = offsetCol;
        !tapFound && colNo < min(rightCol + offsetCol, _data[0].length);
        colNo++) {
      l = _getColumnWidthSum(_pinnedColumn, colNo);
      t = 0; // _getRowHeightSum(0, rowNo);
      w = _columnWidths[colNo];
      h = _rowHeights[0];
      rcCell = Rect.fromLTWH(l, t, w, h);
      if (rcCell.contains(tap)) {
        debugPrint('Sorted on Cell C$colNo');

        if (!_cellSetups![colNo].isSortable) {
          _sortColumn = colNo;
          _sortState = -1;
          return -1;
        }

        bool isTriStateSort = _cellSetups![colNo].triStateSort;

        if (_sortColumn != colNo) {
          _sortState = 1;
        } else {
          _sortState++;
          _sortState %= 3;
          if (!isTriStateSort && _sortState == 0) _sortState++;
        }
        _sortColumn = colNo;
        debugPrint('Sort $_sortState, $colNo');
        // Clear any selection before sorting
        onUpdate(0, colNo, false, EditAction.selectAll);

        //
        onUpdate(
            0,
            colNo,
            '',
            _sortState == 1
                ? EditAction.sortA2Z
                : _sortState == 2
                    ? EditAction.sortZ2A
                    : EditAction.sortNone);
        return colNo;
      }
    }
    return -1;
  }

  ///   Returns Rect2
  Widget _getRect2Widgets() {
    double width = _getColumnWidthSum(_pinnedColumn, _data[0].length);
    double height = _getRowHeightSum(0, _pinnedRow);
    late Offset tapPosition;
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTapDown: (value) {
          tapPosition = value.localPosition;
        },
        onTap: () {
          _checkCellSortOnTap(tapPosition, width, height);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pinnedRow, (rowNo) {
            return Row(
              children: List.generate(_data[0].length - _pinnedColumn, (colNo) {
                colNo += _pinnedColumn;
                return _getPinnedRowCell(
                    _data[rowNo][colNo], //_cellWidth,
                    _columnWidths[colNo],
                    _rowHeights[rowNo],
                    rowNo,
                    colNo);
              }),
            );
          }),
        ),
      ),
    );
  }

  ///   Returns Rect3
  Widget _getRect3Widgets() {
    return SizedBox(
      width: _getColumnWidthSum(0, _pinnedColumn),
      height: _getRowHeightSum(_pinnedRow, _data.length),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(_data.length - _pinnedRow, (rowNo) {
          return Row(
            children: List.generate(_pinnedColumn, (colNo) {
              return _getPinnedColCell(
                  _data[rowNo + _pinnedRow][colNo], //_cellWidth,
                  _columnWidths[colNo],
                  _rowHeights[rowNo + _pinnedRow],
                  colNo);
              // return SizedBox(
              //   width:cellWidth,
              //   height:cellHeight,
              //   child: Text(data[rowNo+pinnedRow][colNo], style:const TextStyle(color:Colors.blue),),
              // );
            }),
          );
        }),
      ),
    );
  }

  ///   Returns Rect4
  Widget _getRect4Widgets(double widthView, double heightView) {
    return SizedBox(
      width: _getColumnWidthSum(_pinnedColumn, _data[0].length),
      height: _getRowHeightSum(_pinnedRow, _data.length),
      child: GestureDetector(
        onTapDown: (value) {
          _tapPosition = value.localPosition;
        },
        onTap: () async {
          int result = 0;
          _findCellOnTap(_tapPosition, widthView, heightView);
          _scrollTo(_selectedCell[0], col: _selectedCell[1]);
          CellSetup? setup = widget.cellSetups?[_selectedCell[1]];
          if (_editMode && setup?.getWidget == null) {
            while (!result.isNegative) {
              result = await getOption(
                  _data[_selectedCell[0]][_selectedCell[1]],
                  _pinnedRow > 0 ? _data[0][_selectedCell[1]] : 'Edit Item',
                  setup);
              setup = widget.cellSetups?[_selectedCell[1]];
            }
          }
          setState(() {});
        },
        child: Stack(children: _getVisibleCells(widthView, heightView)),
      ),
    );
  }

  /// Finds the cell at position gicen by user Tap
  /// Sets _selectedCell accordingly with row & col of tapped cell
  void _findCellOnTap(Offset tap, double width, double height) {
    late double l, t, w, h;
    late Rect rcCell;
    int offsetCol = _leftColumnNo;
    int offsetRow = _topRowNo;
    int rightCol = _getColumnAtPosition(width) + 1;
    int bottomRow = _getRowAtPosition(height) + 1;
    bool tapFound = false;
    late int rowNo, colNo;

    for (rowNo = offsetRow;
        !tapFound && rowNo < min(bottomRow + offsetRow, _data.length);
        rowNo++) {
      for (colNo = offsetCol;
          !tapFound && colNo < min(rightCol + offsetCol, _data[0].length);
          colNo++) {
        l = _getColumnWidthSum(_pinnedColumn, colNo);
        t = _getRowHeightSum(_pinnedRow, rowNo);
        w = _columnWidths[colNo];
        h = _rowHeights[rowNo];
        rcCell = Rect.fromLTWH(l, t, w, h);
        if (rcCell.contains(tap)) {
          debugPrint('Tapped on Cell R$rowNo:C$colNo');
          setState(() {
            _selectedCell = [rowNo, colNo];
            tapFound = true;
          });
        }
      }
    }
  }

  /// Recalculates height of visible cells and adjusts the row height to make
  /// the cell value fully visible
  void _recalculateRowHeights(double width, double height) {
    late double w, h;
    late String cellText;

    int offsetCol = _leftColumnNo;
    int offsetRow = _topRowNo;
    int rightCol = _getColumnAtPosition(width) + 1; // _data[0].length;
    int bottomRow = _getRowAtPosition(height) +
        1; //_data.length;//(height/_cellHeight).floor()+1;
    late int rowNo;

    double lastOffset = offsetRow > 0 ? _rowOffsets[offsetRow - 1] : 0;
    double tmpH = 0, rowH = 0, defH = widget.cellSize.height;
    for (rowNo = offsetRow;
        rowNo <= min(bottomRow, _data.length - 1);
        rowNo++) {
      h = 0;
      for (int colNo = offsetCol;
          colNo <= min(rightCol, _data[0].length - 1);
          colNo++) {
        w = _cellSetups != null && _cellSetups![colNo].isSelectable && _columnWidths[colNo] > 50
                ? _columnWidths[colNo] - 40 :  _columnWidths[colNo];
        cellText = _data[rowNo][colNo].trim();
        tmpH = _textHeight(cellText, _styleNormal, w);
        h = max(tmpH, h);
      }
      rowH = _rowHeights[rowNo];
      rowH = h > rowH
          ? h
          : (h < defH && rowH > defH)
              ? defH
              : rowH;
      _rowHeights[rowNo] = rowH;
      _rowOffsets[rowNo] = (lastOffset += rowH);
    }
  }

  /// Returns List of visible cells
  List<Positioned> _getVisibleCells(double width, double height) {
    List<Positioned> list = [];
    late Positioned cell;
    late double l, t, w, h;
    late String cellText;
    late bool editing, selected;

    int offsetCol = _leftColumnNo;
    int offsetRow = _topRowNo;
    int rightCol = _getColumnAtPosition(width) + 1;
    int bottomRow = _getRowAtPosition(height) + 1;
    for (int rowNo = offsetRow;
        rowNo < min(bottomRow + offsetRow, _data.length);
        rowNo++) {
      for (int colNo = offsetCol;
          colNo <= min(rightCol + offsetCol, _data[0].length - 1);
          colNo++) {
        l = _getColumnWidthSum(_pinnedColumn, colNo);
        t = _getRowHeightSum(_pinnedRow, rowNo);
        w = _columnWidths[colNo];
        selected =
            _selectedCell[0] == rowNo && _selectedCell[1] == colNo && _editMode;
        editing = selected && _selectedCell[1] == colNo;
        cellText = _data[rowNo][colNo].trim();
        h = _rowHeights[rowNo];
        if (editing) {
          _editController!.text = cellText;
          t += 2;
          l += 2;
          w -= 4;
          h -= 4;
        }
        cell = Positioned(
          left: l,
          top: t,
          child: _getCell(cellText, w, h, rowNo, colNo,
              editing: editing, selected: selected),
        );
        list.add(cell);
      }
    }
    return list;
  }

  /// Scrolls the view to given row (and column)
  _scrollTo(int row, {int col = 0}) {
    double h = 0, h1 = 0;
    late int i;
    for (i = _pinnedRow; i < row; i++) {
      h += _rowHeights[i];
    }

    h1 = h + _rowHeights[row];
    if (!(h > _vertPos && h1 <= (_vertPos + _viewHeight))) {
      _scrollControllerVert.animateTo(h,
          duration: const Duration(milliseconds: 250), curve: Curves.bounceIn);
    } else if (h1 > (_vertPos + _viewHeight)) {
      _scrollControllerVert.animateTo(
          _vertPos - (h1 - (_vertPos + _viewHeight)),
          duration: const Duration(milliseconds: 250),
          curve: Curves.bounceIn);
    }

    h = 0;
    for (i = _pinnedColumn; i < col; i++) {
      h += _columnWidths[i];
    }

    h1 = h + _columnWidths[col];
    if (!(h > _horzPos && h1 <= (_horzPos + _viewWidth))) {
      _scrollControllerHorz.animateTo(h,
          duration: const Duration(milliseconds: 250), curve: Curves.bounceIn);
    } else if (h1 > (_horzPos + _viewWidth)) {
      _scrollControllerHorz.animateTo(_horzPos - (h1 - (_horzPos + _viewWidth)),
          duration: const Duration(milliseconds: 250), curve: Curves.bounceIn);
    }
    setState(() {
      _selectedCell = [row, col > 0 ? col : _selectedCell[1]];

      /// If Parent widget callback is set, inform about cell selection
      if (widget.onSelectCell != null) {
        widget.onSelectCell!(
          _selectedCell[0],
          _selectedCell[1],
        );
      }
    });
  }

  /// Returns height in pixel for a given <text> & TextStyle <style> that can be
  /// made visible in the cell with given <width>
  /// We use this to workout the height of the row that contains the given cell
  double _textHeight(String text, TextStyle style, double width) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 100,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: width - 4);
    return textPainter.height;
  }

  /// Called to update parameter every <build> call
  /// This is to reflect changes done to the cell by parent widget
  void _updateDynamicParameters(BoxConstraints constraints) {
    _editMode = widget.isEditing;
    _editController = _editMode ? TextEditingController(text: '') : null;

    _data = widget.data;

    /// Last row might have been deleted, need to adjust selected row
    if (_selectedCell[0] >= _data.length) {
      _selectedCell[0] = _data.length - 1;

      /// Inform Parent about selection change
      if (widget.onSelectCell != null) {
        widget.onSelectCell!(_selectedCell[0], _selectedCell[1],
            refresh: false);
      }
    }
    if (_selectedCell[1] >= _data[0].length) {
      _selectedCell[1] = _data[0].length - 1;

      /// Inform Parent about selection change
      if (widget.onSelectCell != null) {
        widget.onSelectCell!(_selectedCell[0], _selectedCell[1],
            refresh: false);
      }
    }
    if (_rowHeights.isEmpty || _rowHeights.length != _data.length) {
      _rowHeights = List.generate(_data.length, (e) => widget.cellSize.height);
      _rowOffsets =
          List.generate(_data.length, (e) => e * widget.cellSize.height);
    }
    _recalculateRowHeights(
        constraints.maxWidth - _getColumnWidthSum(0, _pinnedColumn),
        constraints.maxHeight - _getRowHeightSum(0, _pinnedRow));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxHeight <= widget.cellSize.height) {
          /// Not enough height, return
          return const Center(
              child: Icon(
            Icons.cancel_outlined,
          ));
        }
        if (_columnWidths.isEmpty) _setColumnWidth(constraints.maxWidth);

        /// Build is called every time after setState is called
        /// Some parameters initialized during initState() will not be updated in such case
        /// We force update them to absorb any changes done by the parent
        _updateDynamicParameters(constraints);
        return Row(children: [
          /// Top Left Corner
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_pinnedColumn > 0)
                SizedBox(
                  width: _getColumnWidthSum(0, _pinnedColumn),
                  height: _getRowHeightSum(0, _pinnedRow),
                  child: _getRect1Widgets(),
                ),

              /// Pinned Top Row(s)
              if (_pinnedColumn > 0)
                SizedBox(
                  width: _getColumnWidthSum(0, _pinnedColumn),
                  height:
                      constraints.maxHeight - _getRowHeightSum(0, _pinnedRow),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _scrollControllerLeft,
                      scrollDirection: Axis.vertical,
                      child: _getRect3Widgets(),
                    ),
                  ),
                ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width:
                    constraints.maxWidth - _getColumnWidthSum(0, _pinnedColumn),
                height: _getRowHeightSum(0, _pinnedRow),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    controller: _scrollControllerTop,
                    scrollDirection: Axis.horizontal,
                    child: _getRect2Widgets(),
                  ),
                ),
              ),

              /// Main Cells
              SizedBox(
                width:
                    constraints.maxWidth - _getColumnWidthSum(0, _pinnedColumn),
                height: constraints.maxHeight - _getRowHeightSum(0, _pinnedRow),
                child: SingleChildScrollView(
                  controller: _scrollControllerVert,
                  scrollDirection: Axis.vertical,
                  physics: widget.outerController == null
                      ? null
                      : CustomScrollPhysics(
                          outerController: (velocity, isMin) => _innerListener(
                              velocity, widget.outerController!)),
                  child: SingleChildScrollView(
                    controller: _scrollControllerHorz,
                    scrollDirection: Axis.horizontal,
                    child: _getRect4Widgets(
                      _viewWidth = constraints.maxWidth -
                          _getColumnWidthSum(0, _pinnedColumn),
                      _viewHeight = constraints.maxHeight -
                          _getRowHeightSum(0, _pinnedRow),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]);
      }),
    );
  }
}

/// Class to handle scroll events
/// Refer https://stackoverflow.com/questions/69952261/is-there-any-way-to-scroll-parent-listview-when-the-child-listview-reached-end-i
/// for details
class CustomScrollPhysics extends ClampingScrollPhysics {
  final Function outerController;
  CustomScrollPhysics(
      {required this.outerController, ScrollPhysics? parent})
      : super(parent: parent);
  bool isMinCheck = false;

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(
        outerController: outerController, parent: buildParent(ancestor)!);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (position.pixels >= position.maxScrollExtent && velocity >= 0.0) {
      outerController(velocity, false);
    } else if (position.pixels == position.minScrollExtent && isMinCheck) {
      outerController(velocity, true);
    } else {
      isMinCheck = true;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
