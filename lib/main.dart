import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for formatters
import 'package:shared_preferences/shared_preferences.dart'; // The Package

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
  final List<String> _options = ['Practice', 'Qualifying', 'Heat'];
  String? _selectedType; // Nullable type (like std::optional)
  String? _selectedTyreState; 
  final List<String> _tyreOptions = ['New', 'Scraped', 'Used'];
  static const _childrenIndent = EdgeInsets.only(left: 32.0, right: 16.0);

  final PressureSet _coldPressures = PressureSet();
  final PressureSet _hotPressures = PressureSet();

  final GeometryPill _leftPill = GeometryPill();
  final GeometryPill _rightPill = GeometryPill();

  final TextEditingController _alignmentController = TextEditingController();

  final List<String> _axleOptions = ["Soft - U", "Medium-soft - Q", "Medium - N", "Hard - H", "Hard+ - HD", "Hardest - HH"];
  String? _selectedAxleOption;

  final TextEditingController _axleLengthController = TextEditingController();

  final String jsonKeyword = "my_notebook";
  /*final*/ List<SessionRecord> _notebook = []; // Our in-memory database
  @override
  void dispose() {
    _indexController.dispose(); // Manual memory management for controllers
    _alignmentController.dispose();
    _axleLengthController.dispose();
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
            const SizedBox(height: 20), // Spacing (like a spacer widget)
            _buildFrontGeometrySection(),
            const SizedBox(height: 20),
            _buildRearGeometrySection(),
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
                  leading: Text('#${item.index}'),
                  title: Text(item.type),
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
            DropdownButton<String>(
              value: _selectedType,
              hint: const Text('Select Type'),
              isExpanded: true,
              items: _options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
            DropdownButton<String>(
              value: _selectedTyreState,
              hint: const Text('Tyre state'),
              isExpanded: true,
              items: _tyreOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
              controller: pill.top,
              decoration: const InputDecoration(labelText: 'Top pill [1-12]'),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
             ],
              keyboardType: TextInputType.number, // Limits keyboard to numbers
            ),

            TextField(
              controller: pill.bottom,
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
            DropdownButton<String>(
              value: _selectedAxleOption,
              hint: const Text('Axle stiffness'),
              isExpanded: true,
              items: _axleOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
    final newRecord = SessionRecord(
      index: indexValue,
      type: _selectedType!, // ! tells Dart: "I know this isn't null"
      timestamp: DateTime.now().toUtc(), // Independent of timezone
      tyreState: 'new'
    );

    // 3. Update State
    setState(() {
      _notebook.add(newRecord);
      // Reset index (Clear the controller)
      _indexController.clear(); 
      // Note: We don't reset _selectedType because you asked to keep it as is.
    });
  }
  
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = _notebook.map((item) => item.toJson()).toList();
    await prefs.setStringList('jsonKeyword', strings);
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
  
    // Get the list of strings we saved yesterday
    final List<String>? jsonList = prefs.getStringList('jsonKeyword');

    if (jsonList != null) {
      // This is the critical "Re-entry" point
      setState(() {
        _notebook = jsonList
            .map((jsonStr) => SessionRecord.fromJson(jsonStr))
           .toList();
      });
    }
  }
}


class PressureSet {
  final lf = TextEditingController();
  final rf = TextEditingController();
  final lr = TextEditingController();
  final rr = TextEditingController();

  // A helper to get all values as doubles at once
  Map<String, double> getValues() {
    return {
      'LF': double.tryParse(lf.text.replaceAll(',', '.')) ?? 0.0,
      'RF': double.tryParse(rf.text.replaceAll(',', '.')) ?? 0.0,
      'LR': double.tryParse(lr.text.replaceAll(',', '.')) ?? 0.0,
      'RR': double.tryParse(rr.text.replaceAll(',', '.')) ?? 0.0,
    };
  }

  void dispose() {
    lf.dispose(); rf.dispose(); lr.dispose(); rr.dispose();
  }
}

class GeometryPill
{
  final top = TextEditingController();
  final bottom = TextEditingController();

    Map<String, int> getValues() {
    return {
      'TOP': int.tryParse(top.text) ?? 0,
      'BOTTOM': int.tryParse(bottom.text) ?? 0,
    };
  }

  void dispose() {
    top.dispose(); bottom.dispose();
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