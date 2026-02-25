import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for formatters
import 'package:shared_preferences/shared_preferences.dart'; // The Package
import 'dart:convert'; // REQUIRED for jsonEncode

import 'session_record.dart'; // Your local import

// 1. The Entry Point (Like main() in C++)
void main()
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SessionForm(),
    );
  }
}

// 2. The StatefulWidget Configuration
class SessionForm extends StatefulWidget {
  const SessionForm({super.key});

  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  // Variables (State) - Similar to private members in a C++ class
  final TextEditingController _indexController = TextEditingController();

  SessionType? _selectedType;
  TyreState? _selectedTyreState; 

  static const _childrenIndent = EdgeInsets.only(left: 32.0, right: 16.0);

  final PressureSet _coldPressures = PressureSet();
  final PressureSet _hotPressures = PressureSet();

  final GeometryPill _leftPill = GeometryPill();
  final GeometryPill _rightPill = GeometryPill();

  final TextEditingController _alignmentController = TextEditingController();
  AxleStiffness? _selectedAxleOption;

  final TextEditingController _axleLengthController = TextEditingController();

  final TextEditingController _frontSprocketController = TextEditingController();
  final TextEditingController _rearSprocketController = TextEditingController();

  int? _rating;
  double? _balanceValue; //-1.0 to 1.0

  final TextEditingController _notesController = TextEditingController();
  final String jsonKeyword = "karting_notebook_v0";
  /*final*/ List<SessionRecord> _notebook = []; // Our in-memory database
  @override
  void dispose() {
    _indexController.dispose(); // Manual memory management for controllers
    _alignmentController.dispose();
    _axleLengthController.dispose();
    _frontSprocketController.dispose();
    _rearSprocketController.dispose();
    _coldPressures.dispose();
    _hotPressures.dispose();
    _leftPill.dispose();
    _rightPill.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // We fire this off immediately. It runs in the background
    // while the first frame of the UI is being drawn.
    _loadFromDisk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSessionSection(),
            const SizedBox(height: 20), // Spacing (like a spacer widget)
            _buildTyreSection(),
            const SizedBox(height: 20), 
            _buildFrontGeometrySection(),
            const SizedBox(height: 20),
            _buildRearGeometrySection(),
            const SizedBox(height: 20),
            _buildGearingSection(),
            const SizedBox(height: 20),
            _buildFeedbackSection(),
            const SizedBox(height: 10),

            ElevatedButton.icon(
            onPressed: () {
              _saveRecord();
              _saveToDisk();
              },
            icon: const Icon(Icons.save),
            label: const Text('Save to Notebook'),
          ),

          const Divider(height: 40),


            ListView.builder(
              itemCount: _notebook.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = _notebook[index];
                return ListTile(
                  leading: Text('#${item.sessionIndex}'),
                  title: Text(getSessionTypeLabel(item.sessionType)),
                  subtitle: Text(item.timestamp.toLocal().toString()), // View in local time
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSection() {
    return ExpansionTile(
      title: const Text("Session details"),
      childrenPadding: _childrenIndent,
      children: [
                    // Integer Input Field
            TextField(
              controller: _indexController,
              decoration: const InputDecoration(labelText: 'Index'),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
             ],
              keyboardType: TextInputType.number, // Limits keyboard to numbers
            ),
            
            const SizedBox(height: 20), // Spacing (like a spacer widget)

            // Dropdown Menu
            DropdownButton<SessionType>(
              value: _selectedType,
              hint: const Text('Select Type'),
              isExpanded: true,
              items: SessionType.values.map((SessionType value) {
                return DropdownMenuItem<SessionType>(
                  value: value,
                  child: Text(getSessionTypeLabel(value)),
                );
              }).toList(),
              onChanged: (newValue) {
                // IMPORTANT: setState triggers the build() method to run again
                setState(() {
                  _selectedType = newValue;
                });
              },
            ),
      ],
    );
  }

  Widget _buildTyreSection() {
    return ExpansionTile(
      title: const Text("Tyres"),
      childrenPadding: _childrenIndent,
      //leading: const Icon(Icons.tire_repair),
      children: [
            // Dropdown Menu
            DropdownButton<TyreState>(
              value: _selectedTyreState,
              hint: const Text('Tyre state'),
              isExpanded: true,
              items: TyreState.values.map((TyreState value) {
                return DropdownMenuItem<TyreState>(
                  value: value,
                  child: Text(getTyreConditionLabel(value)),
                );
              }).toList(),
              onChanged: (newValue) {
                // IMPORTANT: setState triggers the build() method to run again
                setState(() {
                  _selectedTyreState = newValue;
                });
              },
            ),
            const Divider(),           // Visual separator
            const Text("Cold Pressures", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildPressureGrid(_coldPressures), // First instance
            const SizedBox(height: 10),
            const Text("Hot Pressures", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildPressureGrid(_hotPressures),  // Second instance
            const Divider(),
            const Text("Pressure Delta (Δ)", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            _buildDeltaGrid(), // The non-editable table
          ],
        );
  }

Widget _buildPressureGrid(PressureSet set) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: _buildPressureField('LF', set.lf)),
          Expanded(child: _buildPressureField('RF', set.rf)),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildPressureField('LR', set.lr)),
          Expanded(child: _buildPressureField('RR', set.rr)),
        ],
      ),
    ],
  );
}

  Widget _buildPressureField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        // numberWithOptions(decimal: true) tells mobile to show the ,/. button
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          DecimalInputFormatter(), // Our custom "C++ style" utility
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDeltaCell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200], // Visual hint that it's read-only
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDeltaCell('LF Delta', _calculateDelta('LF'))),
            Expanded(child: _buildDeltaCell('RF Delta', _calculateDelta('RF'))),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildDeltaCell('LR Delta', _calculateDelta('LR'))),
            Expanded(child: _buildDeltaCell('RR Delta', _calculateDelta('RR'))),
          ],
        ),
      ],
    );
  }

  double _getVal(PressureSet set, String tyre) {
    String text = "";
    if (tyre == 'LF') text = set.lf.text;
    if (tyre == 'RF') text = set.rf.text;
    if (tyre == 'LR') text = set.lr.text;
    if (tyre == 'RR') text = set.rr.text;
    
    return double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
  }

  String _calculateDelta(String tyre) {
    double cold = _getVal(_coldPressures, tyre);
    double hot = _getVal(_hotPressures, tyre);
    double delta = hot - cold;
    
    // Return formatted string, e.g., "+1.5" or "-0.2"
    return delta == 0 ? "0.0" : (delta > 0 ? "+${delta.toStringAsFixed(1)}" : delta.toStringAsFixed(1));
  }


  Widget _buildFrontGeometrySection() {
    return ExpansionTile(
      title: const Text("Front"),
      childrenPadding: _childrenIndent,
      children: [
        Row(
          children: [
// Expanded forces the pill to take exactly 50% (minus the spacer)
          Expanded(child: _buildPill("Left", _leftPill)),
          
          const SizedBox(width: 20), 
          
          Expanded(child: _buildPill("Right", _rightPill)),

          ],
        ),

        TextField(
          controller: _alignmentController,
          decoration: const InputDecoration(labelText: 'Toe [mm]'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [DecimalInputFormatter()],
        ),

        const SizedBox(height: 10), 
      ],
    );
  }
  
  Widget _buildPill(String label, GeometryPill pill)
  {
        return Column(
      children: [
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                    // Integer Input Field
            TextField(
              controller: pill._top,
              decoration: const InputDecoration(labelText: 'Top pill [1-12]'),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
             ],
              keyboardType: TextInputType.number, // Limits keyboard to numbers
            ),

            TextField(
              controller: pill._bottom,
              decoration: const InputDecoration(labelText: 'Bottom pill [1-12]'),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
             ],
              keyboardType: TextInputType.number, // Limits keyboard to numbers
            ),
            const SizedBox(height: 10)
      ]
    );
  }

  Widget _buildRearGeometrySection() {
    return ExpansionTile(
      title: const Text("Rear"),
      childrenPadding: _childrenIndent,
      children: [
            DropdownButton<AxleStiffness>(
              value: _selectedAxleOption,
              hint: const Text('Axle stiffness'),
              isExpanded: true,
              items: AxleStiffness.values.map((AxleStiffness value) {
                return DropdownMenuItem<AxleStiffness>(
                  value: value,
                  child: Text(getAxleStiffnessLabel(value)),
                );
              }).toList(),
              onChanged: (newValue) {
                // IMPORTANT: setState triggers the build() method to run again
                setState(() {
                  _selectedAxleOption = newValue;
                });
              },
            ),
            TextField(
              controller: _axleLengthController,
              decoration: const InputDecoration(labelText: 'Axle length [cm]'),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
             ],
              keyboardType: TextInputType.number, // Limits keyboard to numbers
            ),
        // TextField(
        //   controller: _alignmentController,
        //   decoration: const InputDecoration(labelText: 'Toe [mm]'),
        //   inputFormatters: [DecimalInputFormatter()],
        // ),

        const SizedBox(height: 10), 
      ],
    );
  }

  Widget _buildGearingSection() {
    return ExpansionTile(
      title: const Text("Gearing"),
      childrenPadding: _childrenIndent,
      children: [
            TextField(
              controller: _frontSprocketController,
              decoration: const InputDecoration(labelText: 'Front sprocket'),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
              ],
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _rearSprocketController,
              decoration: const InputDecoration(labelText: 'Rear sprocket'),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10), 
            Text("Gear ratio: ${_calculateRatio(_frontSprocketController.text, _rearSprocketController.text)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10), 
      ],
    );
  }

  String _calculateRatio(String front, String rear) {
    final int frontInt = int.tryParse(front) ?? 0;
    final int rearInt = int.tryParse(rear) ?? 0;

    double ratio = (frontInt != 0) ? rearInt / frontInt : 0.0;
    
    // Return formatted string, e.g., "+1.5" or "-0.2"
    return ratio.toStringAsFixed(2);
  }

  Widget _buildFeedbackSection() {
    return ExpansionTile(
      title: const Text("Feedback"),
      childrenPadding: _childrenIndent,
      children: [
            _buildStarRating(),
            const SizedBox(height: 10),
            Column(
            children: [
              Text("Balance: "),
              Row(children: [
              
                Text("Understeer"),
                Expanded(child: 
                  Slider(
                  value: _balanceValue ?? 0, // -1.0 to 1.0
                  min: -1.0,
                  max: 1.0,
                  divisions: 10, // Creates discrete steps
                  onChanged: (val) => setState(() => _balanceValue = val),
                  )
                ),
                Text("Oversteer"),
              ])
              ]
            ),
            TextFormField(
              controller: _notesController,
              maxLines: null, // Makes it expand
              minLines: 4,    // Keeps it at a decent starting size
              decoration: const InputDecoration(
                labelText: 'Session Notes',
                alignLabelWithHint: true, // Puts the label at the top
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10), 
          ]
        );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < (_rating ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => setState(() => _rating = index + 1),
        );
      }),
    );
  }


  void _saveRecord() {
    // 1. Validation: Try to parse the index
    final int? indexValue = int.tryParse(_indexController.text);
    
    if (indexValue == null || _selectedType == null) {
      // Show a quick error (Snackbars are the standard way)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid index and select a type')),
      );
      return;
    }

    // 2. Create the Record
    final newRecord = SessionRecord.fromUI(
      index: int.tryParse(_indexController.text) ?? -1,
      type: _selectedType,
      tyreState: _selectedTyreState,
      coldUI: _coldPressures,
      hotUI: _hotPressures,
      leftPillUI: _leftPill,
      rightPillUI: _rightPill,
      axleStiffness: _selectedAxleOption,
      axleLength: int.tryParse(_axleLengthController.text),
      sprocketFront: _frontSprocketController,
      sprocketRear: _rearSprocketController,
      rating: _rating,
      balance: _balanceValue,
      lapTime: "",
      notes: _notesController.text,
    );

    // 3. Update State
    setState(() {
      _notebook.add(newRecord);
      // Reset index (Clear the controller)
      _indexController.clear(); 
      // Note: We don't reset _selectedType because you asked to keep it as is.
    });
  }
  
  Future<void> _saveToDisk() async 
  {
    final prefs = await SharedPreferences.getInstance();

    // 1. Convert each SessionRecord into a JSON String
    // item.toJson() -> returns a Map
    // jsonEncode(...) -> returns a String
    final List<String> jsonStrings = _notebook.map((item) 
    {
      return jsonEncode(item.toJson()); 
    }).toList();
    await prefs.setStringList(jsonKeyword, jsonStrings);
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonStrings = prefs.getStringList(jsonKeyword);

    if (jsonStrings != null) {
      setState(() {
        _notebook = jsonStrings.map((str) {
          final Map<String, dynamic> map = jsonDecode(str);
          return SessionRecord.fromJson(map);
        }).toList();
      });
    }
  }

  String getTyreConditionLabel(TyreState condition) 
  {
    switch (condition) 
    {
      case TyreState.newTyre: return 'New';
      case TyreState.scraped: return 'Scraped';
      case TyreState.used: return 'Used';
    }
  }

  String getSessionTypeLabel(SessionType? type) 
  {
    switch (type) 
    {
      case SessionType.practice: return 'Practice';
      case SessionType.quali: return 'Qualifying';
      case SessionType.heat: return 'Heat';
      case null: return "undefined";
    }
  }

  String getAxleStiffnessLabel(AxleStiffness axle) 
  {
    switch (axle) 
    {
      case AxleStiffness.soft: return 'Soft - U';
      case AxleStiffness.medSoft: return 'Medium-soft - Q';
      case AxleStiffness.medium: return 'Medium - N';
      case AxleStiffness.hard: return 'Hard - H';
      case AxleStiffness.hardPlus: return 'Hard+ - HD';
      case AxleStiffness.hardest: return 'Hardest - HH';
    }
  }
}


class PressureSet {
  final lf = TextEditingController();
  final rf = TextEditingController();
  final lr = TextEditingController();
  final rr = TextEditingController();

  // A helper to get all values as doubles at once

  // New: Convert UI state into our Data Object
  Corners<double> getValues() 
  {
    return Corners<double>(
      lf: double.tryParse(lf.text.replaceAll(',', '.')),
      rf: double.tryParse(rf.text.replaceAll(',', '.')),
      lr: double.tryParse(lr.text.replaceAll(',', '.')),
      rr: double.tryParse(rr.text.replaceAll(',', '.')),
    );
  }

  void dispose() {
    lf.dispose(); rf.dispose(); lr.dispose(); rr.dispose();
  }
}

class GeometryPill
{
  final _top = TextEditingController();
  final _bottom = TextEditingController();

  PillSet getValues()
  {
    return PillSet(
      top: int.tryParse(_top.text),
      bottom: int.tryParse(_bottom.text),
    );
  }


  void dispose() {
    _top.dispose(); _bottom.dispose();
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, 
    TextEditingValue newValue
  ) {
    // If the user tries to type something that isn't a digit, a dot, or a comma, 
    // we return the oldValue (rejecting the change).
    final regExp = RegExp(r'^[0-9.,]*$');
    if (!regExp.hasMatch(newValue.text)) {
      return oldValue;
    }
    
    // Check if they tried to enter more than one separator
    if ((newValue.text.contains('.') && newValue.text.indexOf('.') != newValue.text.lastIndexOf('.')) ||
        (newValue.text.contains(',') && newValue.text.indexOf(',') != newValue.text.lastIndexOf(','))) {
      return oldValue;
    }

    return newValue;
  }

  double? _parseDecimal(String value) {
  // Replace comma with dot so double.tryParse can handle it
  String normalized = value.replaceAll(',', '.');
  return double.tryParse(normalized);
  }
}