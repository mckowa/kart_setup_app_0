import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'session_record.dart'; // Adjust path as needed
import 'main.dart'; // To access PressureSet, GeometryPill, and Label functions

class SetupMasterLayout extends StatelessWidget {
  final bool isReadOnly;
  final SessionRecord? record;

  // Controllers for Input Mode
  final TextEditingController? indexController;
  final SessionType? selectedType;
  final ValueChanged<SessionType?>? onTypeChanged;
  
  final TyreState? selectedTyreState;
  final ValueChanged<TyreState?>? onTyreStateChanged;

  final PressureSet? coldUI;
  final PressureSet? hotUI;
  final GeometryPill? leftPillUI;
  final GeometryPill? rightPillUI;
  final TextEditingController? alignmentUI;
  
  final AxleStiffness? selectedAxle;
  final ValueChanged<AxleStiffness?>? onAxleChanged;
  final TextEditingController? axleLengthUI;

  final TextEditingController? frontSprocketUI;
  final TextEditingController? rearSprocketUI;

  final int? rating;
  final ValueChanged<int>? onRatingChanged;
  final double? balance;
  final ValueChanged<double>? onBalanceChanged;
  final TextEditingController? notesUI;

  static const _indent = EdgeInsets.only(left: 32.0, right: 16.0);

  const SetupMasterLayout({
    super.key,
    required this.isReadOnly,
    this.record,
    this.indexController,
    this.selectedType,
    this.onTypeChanged,
    this.selectedTyreState,
    this.onTyreStateChanged,
    this.coldUI,
    this.hotUI,
    this.leftPillUI,
    this.rightPillUI,
    this.alignmentUI,
    this.selectedAxle,
    this.onAxleChanged,
    this.axleLengthUI,
    this.frontSprocketUI,
    this.rearSprocketUI,
    this.rating,
    this.onRatingChanged,
    this.balance,
    this.onBalanceChanged,
    this.notesUI,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSessionSection(),
        const SizedBox(height: 20),
        _buildTyreSection(),
        const SizedBox(height: 20),
        _buildFrontGeometrySection(),
        const SizedBox(height: 20),
        //_buildRearGeometrySection(),
        const SizedBox(height: 20),
        _buildGearingSection(),
        const SizedBox(height: 20),
        _buildFeedbackSection(),
      ],
    );
  }

  // --- REUSABLE FIELD ENGINE ---
  Widget _field(String label, String? value, TextEditingController? controller, {bool isDigits = false}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          isReadOnly
              ? Text(value ?? "-", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
              : TextField(
                  controller: controller,
                  keyboardType: isDigits ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [isDigits ? FilteringTextInputFormatter.digitsOnly : DecimalInputFormatter()],
                  decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
                ),
        ],
      ),
    );
  }

  // --- SECTIONS ---

  Widget _buildSessionSection() {
    return ExpansionTile(
      title: const Text("Session Details"),
      initiallyExpanded: !isReadOnly,
      childrenPadding: _indent,
      children: [
        Row(
          children: [
            Expanded(child: _field("Index", record?.sessionIndex.toString(), indexController, isDigits: true)),
            const SizedBox(width: 20),
            Expanded(
              child: isReadOnly 
                ? Text(record?.sessionType.toString().split('.').last ?? "-")
                : DropdownButton<SessionType>(
                    value: selectedType,
                    isExpanded: true,
                    items: SessionType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                    onChanged: onTypeChanged,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTyreSection() {
    return ExpansionTile(
      title: const Text("Tyres"),
      childrenPadding: _indent,
      children: [
        if (!isReadOnly) ...[
           DropdownButton<TyreState>(
             value: selectedTyreState,
             isExpanded: true,
             onChanged: onTyreStateChanged,
             items: TyreState.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
           ),
           const Divider(),
        ],
        const Text("Cold Pressures", style: TextStyle(fontSize: 12, color: Colors.grey)),
        _buildPressureGrid(record?.coldPressures, coldUI),
        const SizedBox(height: 10),
        const Text("Hot Pressures", style: TextStyle(fontSize: 12, color: Colors.grey)),
        _buildPressureGrid(record?.hotPressures, hotUI),
      ],
    );
  }

  Widget _buildPressureGrid(Corners<double>? data, PressureSet? ui) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _field("LF", data?.lf?.toString(), ui?.lf)),
          Expanded(child: _field("RF", data?.rf?.toString(), ui?.rf)),
        ]),
        Row(children: [
          Expanded(child: _field("LR", data?.lr?.toString(), ui?.lr)),
          Expanded(child: _field("RR", data?.rr?.toString(), ui?.rr)),
        ]),
      ],
    );
  }

  Widget _buildFrontGeometrySection() {
    return ExpansionTile(
      title: const Text("Front Geometry"),
      childrenPadding: _indent,
      children: [
        Row(children: [
          Expanded(child: _buildPillColumn("Left", record?.leftPills, leftPillUI)),
          const SizedBox(width: 20),
          Expanded(child: _buildPillColumn("Right", record?.rightPills, rightPillUI)),
        ]),
        _field("Toe [mm]", record?.toe?.toString(), alignmentUI),
      ],
    );
  }

  Widget _buildPillColumn(String side, PillSet? data, GeometryPill? ui) {
    return Column(
      children: [
        Text(side, style: const TextStyle(fontWeight: FontWeight.bold)),
        _field("Top", data?.top?.toString(), ui?.top, isDigits: true),
        _field("Bottom", data?.bottom?.toString(), ui?.bottom, isDigits: true),
      ],
    );
  }

  Widget _buildGearingSection() {
    return ExpansionTile(
      title: const Text("Gearing"),
      childrenPadding: _indent,
      children: [
        Row(children: [
          Expanded(child: _field("Front", record?.gearing.front?.toString(), frontSprocketUI, isDigits: true)),
          Expanded(child: _field("Rear", record?.gearing.rear?.toString(), rearSprocketUI, isDigits: true)),
        ]),
      ],
    );
  }

  Widget _buildFeedbackSection() {
     return ExpansionTile(
      title: const Text("Feedback & Notes"),
      childrenPadding: _indent,
      children: [
        if (isReadOnly) ...[
          Text("Rating: ${record?.rating ?? 0} Stars"),
          Text("Balance: ${record?.balance ?? 0.0}"),
          const Divider(),
          Text(record?.notes ?? ""),
        ] else ...[
          // Here you'd place your StarRating and Slider widgets
          // using the callbacks (onRatingChanged, etc.)
          TextField(controller: notesUI, maxLines: 3, decoration: const InputDecoration(labelText: "Notes")),
        ]
      ],
    );
  }
}