import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/local_file_service.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';
import '../services/image_stamp_service.dart';
import '../services/species_database.dart';
import '../services/image_quality_checker.dart';
import '../models/tree_model.dart';

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});
  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  int _step = 1;
  final _donorCtrl = TextEditingController();
  final _plantCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedSpecies;
  PlantSpecies? _speciesInfo;
  ImageQualityResult? _imageQuality;

  CameraController? _camCtrl;
  Position? _position;
  Uint8List? _stampedImage;
  bool _loading = false;
  String _locStatus = 'Fetching GPS...';

  @override
  void initState() {
    super.initState();
    _loadUserDefaults();
  }

  Future<void> _loadUserDefaults() async {
    await AuthService.getCurrentUser();
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    _donorCtrl.dispose();
    _plantCtrl.dispose();
    _areaCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final cam = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      _camCtrl = CameraController(cam, ResolutionPreset.high);
      await _camCtrl!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera error: $e'), backgroundColor: AppTheme.danger));
    }
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      _position = await LocationService.getCurrentLocation();
      if (mounted) setState(() => _locStatus = '✅ GPS: ${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}');
    } catch (e) {
      if (mounted) setState(() => _locStatus = '❌ $e');
    }
  }

  Future<void> _capture() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    setState(() => _loading = true);
    try {
      final file = await _camCtrl!.takePicture();
      final bytes = await file.readAsBytes();
      
      // Check image quality
      _imageQuality = await ImageQualityChecker.checkQuality(file.path);
      
      _stampedImage = await ImageStampService.stampImage(
        imageBytes: bytes,
        treeId: 'NEW',
        plantName: _plantCtrl.text.trim(),
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        dateTime: DateTime.now(),
      );
      await _camCtrl?.dispose();
      _camCtrl = null;
      setState(() { _step = 3; _loading = false; });
      
      // Show quality warning if needed
      if (_imageQuality != null && !_imageQuality!.isAcceptable) {
        _showQualityWarning();
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e'), backgroundColor: AppTheme.danger));
    }
  }

  void _showQualityWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Image Quality Warning'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_imageQuality!.getSummary()),
            const SizedBox(height: 12),
            if (_imageQuality!.issues.isNotEmpty) ...[
              const Text('Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._imageQuality!.issues.map((issue) => Text('• $issue', style: const TextStyle(color: AppTheme.danger))),
            ],
            if (_imageQuality!.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._imageQuality!.warnings.map((warning) => Text('• $warning', style: const TextStyle(color: AppTheme.warning))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _step = 2;
                _stampedImage = null;
              });
              _initCamera();
            },
            child: const Text('Retake Photo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _save({bool continuePlanting = false}) async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final user = await AuthService.getCurrentUser();
      final imagePath = await LocalFileService.saveImageBytes(_stampedImage!);
      final treeId = 'TREE-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      
      final tree = TreeRecord(
        treeId: treeId, userId: user!.id,
        donorName: _donorCtrl.text.trim(),
        plantName: _plantCtrl.text.trim(),
        areaName: _areaCtrl.text.trim().isNotEmpty ? _areaCtrl.text.trim() : null,
        remarks: _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null,
        latitude: _position?.latitude ?? 0, longitude: _position?.longitude ?? 0,
        imagePath: imagePath, dateTime: DateTime.now().toIso8601String(),
        createdBy: user.name,
      );
      await DatabaseService.insertTree(tree);

      if (mounted) {
        HapticFeedback.heavyImpact(); // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tree ${tree.treeId} saved! 🌳')));
        
        if (continuePlanting) {
          // Keep donor, area, remarks - only clear plant name and image
          _plantCtrl.clear();
          _stampedImage = null;
          setState(() => _step = 1);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate(); // Error feedback
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _speciesChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { _camCtrl?.dispose(); Navigator.pop(context); }),
        title: const Text('New Plantation'),
        actions: [_stepBadge()],
      ),
      body: _step == 2 ? _buildCameraView() : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildStepper(),
          const SizedBox(height: 24),
          if (_step == 1) _buildDetailsForm(),
          if (_step == 3) _buildPreview(),
        ]),
      ),
    );
  }

  Widget _stepBadge() => Padding(
    padding: const EdgeInsets.all(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.primarySubtle, borderRadius: BorderRadius.circular(20)),
      child: Text('Step $_step of 3', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );

  Widget _buildStepper() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _stepDot('Details', 1), _stepLine(_step > 1),
      _stepDot('Capture', 2), _stepLine(_step > 2),
      _stepDot('Review', 3),
    ]);
  }

  Widget _stepDot(String label, int s) {
    final active = _step >= s;
    return Column(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active ? AppTheme.gradientPrimary : null,
          color: active ? null : AppTheme.bgElevated,
          border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
          boxShadow: active ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 10)] : null,
        ),
        child: Center(child: Text('$s', style: TextStyle(color: active ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 13))),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: active ? AppTheme.textPrimary : AppTheme.textMuted)),
    ]);
  }

  Widget _stepLine(bool active) => Container(width: 40, height: 2, margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6), color: active ? AppTheme.primary : AppTheme.border);

  Widget _buildDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.bgCard.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🌱  Plantation Details', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Enter the details about this tree plantation', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          TextFormField(controller: _donorCtrl, decoration: const InputDecoration(labelText: 'Donor Name', prefixIcon: Icon(Icons.handshake, size: 20)), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          
          // Species Dropdown
          DropdownButtonFormField<String>(
            value: _selectedSpecies,
            decoration: const InputDecoration(
              labelText: 'Plant Species',
              prefixIcon: Icon(Icons.eco, size: 20),
              helperText: 'Select from database or enter custom name below',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Select species...')),
              ...SpeciesDatabase.getSpeciesNames().map((name) => DropdownMenuItem(value: name, child: Text(name))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSpecies = value;
                if (value != null) {
                  _plantCtrl.text = value;
                  _speciesInfo = SpeciesDatabase.getByName(value);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Custom plant name (if not in database)
          TextFormField(
            controller: _plantCtrl,
            decoration: InputDecoration(
              labelText: 'Plant / Tree Name',
              prefixIcon: const Icon(Icons.park, size: 20),
              helperText: _speciesInfo != null ? 'Scientific: ${_speciesInfo!.scientificName}' : null,
            ),
            validator: (v) => v!.isEmpty ? 'Required' : null,
            onChanged: (value) {
              if (_selectedSpecies != null && value != _selectedSpecies) {
                setState(() {
                  _selectedSpecies = null;
                  _speciesInfo = null;
                });
              }
            },
          ),
          
          // Show species info if selected
          if (_speciesInfo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_speciesInfo!.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_speciesInfo!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_speciesInfo!.scientificName, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_speciesInfo!.description, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _speciesChip('☀️ ${_speciesInfo!.sunlightNeeds}'),
                      _speciesChip('💧 ${_speciesInfo!.wateringNeeds}'),
                      _speciesChip('📏 ${_speciesInfo!.avgHeightMeters}m'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          TextFormField(controller: _areaCtrl, decoration: const InputDecoration(labelText: 'Area Name (Optional)', prefixIcon: Icon(Icons.location_city, size: 20))),
          const SizedBox(height: 16),
          TextFormField(controller: _remarksCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Remarks (Optional)', prefixIcon: Icon(Icons.note, size: 20))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 54, child: Container(
            decoration: BoxDecoration(gradient: AppTheme.gradientPrimary, borderRadius: BorderRadius.circular(14)),
            child: ElevatedButton(
              onPressed: () { if (_formKey.currentState!.validate()) { setState(() => _step = 2); _initCamera(); } },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              child: const Text('Next: Capture Photo  →'),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Full-screen camera preview — properly scaled for portrait
        if (_camCtrl != null && _camCtrl!.value.isInitialized)
          Builder(builder: (context) {
            final size = MediaQuery.of(context).size;
            // Camera aspect ratio is w/h (often landscape like 1.77).
            // In portrait the screen ratio is h/w (tall like 1.77).
            // Scale so the preview fills the full screen height.
            var scale = _camCtrl!.value.aspectRatio * size.aspectRatio;
            if (scale < 1) scale = 1 / scale;
            return SizedBox(
              width: size.width,
              height: size.height,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: size.width * scale,
                  maxHeight: size.height * scale,
                  child: CameraPreview(_camCtrl!),
                ),
              ),
            );
          })
        else
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          ),
        // Location / plant info overlay at top
        Positioned(
          top: 12, left: 12, right: 12,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _infoRow('📍', _locStatus),
                _infoRow('🌱', _plantCtrl.text),
              ]),
            ),
          ),
        ),
        // Bottom controls overlay
        Positioned(
          bottom: 32, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              onPressed: () { _camCtrl?.dispose(); _camCtrl = null; setState(() => _step = 1); },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.all(14)),
            ),
            const SizedBox(width: 32),
            GestureDetector(
              onTap: _loading ? null : _capture,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 16)]),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _loading ? AppTheme.primary : Colors.white),
                  child: _loading ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))) : null,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(children: [
      Text('✅  Review & Save', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
        clipBehavior: Clip.antiAlias,
        child: _stampedImage != null ? Image.memory(_stampedImage!, fit: BoxFit.contain) : const SizedBox(),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Column(children: [
          _summaryRow('Donor', _donorCtrl.text),
          _summaryRow('Plant', _plantCtrl.text),
          if (_areaCtrl.text.isNotEmpty) _summaryRow('Area', _areaCtrl.text),
          _summaryRow('Location', _position != null ? '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}' : 'N/A'),
        ]),
      ),
      const SizedBox(height: 20),
      // Save and Continue Planting buttons
      Column(
        children: [
          // Continue Planting button (primary)
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.gradientPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : () => _save(continuePlanting: true),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(_loading ? 'Saving...' : 'Save & Plant Another'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Regular buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _step = 2);
                    _initCamera();
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : () => _save(continuePlanting: false),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save & Exit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ]);
  }

  Widget _infoRow(String emoji, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 14)), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)))]),
  );

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
    ]),
  );
}
