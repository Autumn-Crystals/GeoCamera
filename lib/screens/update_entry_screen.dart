import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/local_file_service.dart';
import '../services/location_service.dart';
import '../services/image_stamp_service.dart';
import '../models/tree_model.dart';

class UpdateEntryScreen extends StatefulWidget {
  final TreeRecord? preSelectedTree;
  const UpdateEntryScreen({super.key, this.preSelectedTree});
  @override
  State<UpdateEntryScreen> createState() => _UpdateEntryScreenState();
}

class _UpdateEntryScreenState extends State<UpdateEntryScreen> {
  String _phase = 'search'; // search | capture | review
  List<TreeRecord> _allTrees = [];
  List<TreeRecord> _filteredTrees = [];
  TreeRecord? _selectedTree;
  CameraController? _camCtrl;
  Position? _position;
  Uint8List? _stampedImage;
  bool _loading = false;
  String _condition = 'Good';
  final _searchCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrees();
    
    // If a tree is pre-selected, skip search and go directly to capture
    if (widget.preSelectedTree != null) {
      _selectedTree = widget.preSelectedTree;
      _phase = 'capture';
      _initCamera();
    }
  }

  Future<void> _loadTrees() async {
    final trees = await DatabaseService.getTrees();
    setState(() { _allTrees = trees; _filteredTrees = trees; });
  }

  void _search(String q) {
    if (q.isEmpty) { setState(() => _filteredTrees = _allTrees); return; }
    final lower = q.toLowerCase();
    setState(() => _filteredTrees = _allTrees.where((t) =>
        t.treeId.toLowerCase().contains(lower) || t.plantName.toLowerCase().contains(lower)).toList());
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final cam = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      _camCtrl = CameraController(cam, ResolutionPreset.high);
      await _camCtrl!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera error: $e')));
    }
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      _position = await LocationService.getCurrentLocation();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    setState(() => _loading = true);
    try {
      final file = await _camCtrl!.takePicture();
      final bytes = await file.readAsBytes();
      _stampedImage = await ImageStampService.stampImage(
        imageBytes: bytes,
        treeId: _selectedTree!.treeId,
        plantName: _selectedTree!.plantName,
        latitude: _position?.latitude, longitude: _position?.longitude, dateTime: DateTime.now(),
      );
      await _camCtrl?.dispose(); _camCtrl = null;
      setState(() { _phase = 'review'; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Future<void> _renameTree() async {
    final ctrl = TextEditingController(text: _selectedTree!.plantName);
    final newName = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Rename Plantation'),
      content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Plant Name')),
    ));
    if (newName != null && newName.trim().isNotEmpty) {
      await DatabaseService.updateTree(_selectedTree!.treeId, {'plantName': newName.trim()});
      _selectedTree = await DatabaseService.getTreeById(_selectedTree!.treeId);
      setState(() {});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renamed to "$newName"')));
    }
  }

  Future<void> _saveUpdate() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.getCurrentUser();
      final imagePath = await LocalFileService.saveImageBytes(_stampedImage!);
      final update = TreeUpdate(
        updateId: const Uuid().v4(),
        treeId: _selectedTree!.treeId,
        userId: user!.id,
        imagePath: imagePath,
        height: _heightCtrl.text.trim(), condition: _condition,
        remarks: _remarksCtrl.text.trim(),
        latitude: _position?.latitude ?? 0, longitude: _position?.longitude ?? 0,
        dateTime: DateTime.now().toIso8601String(),
        updatedBy: user.name,
      );
      await DatabaseService.insertTreeUpdate(update);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update saved for ${_selectedTree!.treeId}! 📸')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _camCtrl?.dispose(); _searchCtrl.dispose(); _heightCtrl.dispose(); _remarksCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { _camCtrl?.dispose(); Navigator.pop(context); }),
        title: const Text('Update Plantation'),
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildPhase()),
    );
  }

  Widget _buildPhase() {
    if (_phase == 'search') return _searchPhase();
    if (_phase == 'capture') return _capturePhase();
    return _reviewPhase();
  }

  Widget _searchPhase() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🔍  Find a Tree', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      Text('Search by Tree ID or plant name', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 16),
      TextField(
        controller: _searchCtrl, onChanged: _search,
        decoration: InputDecoration(labelText: 'Search trees...', prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _search(''); }) : null),
      ),
      const SizedBox(height: 16),
      if (_filteredTrees.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
          Icon(Icons.search_off, size: 48, color: AppTheme.textMuted), const SizedBox(height: 8),
          Text('No trees found', style: Theme.of(context).textTheme.bodyMedium),
        ])))
      else
        ..._filteredTrees.map((t) => _treeResult(t)),
    ]);
  }

  Widget _treeResult(TreeRecord t) {
    return GestureDetector(
      onTap: () { _selectedTree = t; setState(() => _phase = 'capture'); _initCamera(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: t.imagePath.isNotEmpty
                ? Image.file(File(t.imagePath), width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppTheme.bgElevated, child: const Icon(Icons.park, color: AppTheme.primary)))
                : Container(width: 60, height: 60, color: AppTheme.bgElevated, child: const Icon(Icons.park, color: AppTheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _badge(t.treeId, AppTheme.primarySubtle, AppTheme.primary),
              const SizedBox(width: 6),
              _badge('${t.updates.length} updates', const Color(0x26FBBF24), AppTheme.accent),
            ]),
            const SizedBox(height: 4),
            Text(t.plantName, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (t.areaName != null && t.areaName!.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text(t.areaName!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
          ])),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
        ]),
      ),
    );
  }

  Widget _capturePhase() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primarySubtle, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('🌳', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _badge(_selectedTree!.treeId, AppTheme.primarySubtle, AppTheme.primary),
            const SizedBox(height: 2),
            Text(_selectedTree!.plantName, style: const TextStyle(fontWeight: FontWeight.w600)),
          ])),
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: _renameTree, tooltip: 'Rename'),
        ]),
      ),
      const SizedBox(height: 16),
      Text('📸  Capture Growth Photo', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          if (_camCtrl == null || !_camCtrl!.value.isInitialized) {
            return Container(height: 400, color: Colors.black, child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)));
          }
          final size = MediaQuery.of(context).size;
          var scale = _camCtrl!.value.aspectRatio * size.aspectRatio;
          if (scale < 1) scale = 1 / scale;
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxWidth / (1 / _camCtrl!.value.aspectRatio),
              child: OverflowBox(
                maxWidth: constraints.maxWidth * scale,
                maxHeight: constraints.maxWidth / (1 / _camCtrl!.value.aspectRatio) * scale,
                child: CameraPreview(_camCtrl!),
              ),
            ),
          );
        }),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: () { _camCtrl?.dispose(); _camCtrl = null; setState(() => _phase = 'search'); },
          icon: const Icon(Icons.arrow_back), style: IconButton.styleFrom(backgroundColor: AppTheme.bgElevated, padding: const EdgeInsets.all(14))),
        const SizedBox(width: 24),
        GestureDetector(onTap: _loading ? null : _capture, child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary, width: 4)),
          child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, color: _loading ? AppTheme.primary : Colors.white),
            child: _loading ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))) : null),
        )),
      ]),
    ]);
  }

  Widget _reviewPhase() {
    return Column(children: [
      Text('📋  Update Details', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      if (_stampedImage != null) Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
        clipBehavior: Clip.antiAlias, child: Image.memory(_stampedImage!, fit: BoxFit.contain)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.bgCard.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _heightCtrl, decoration: const InputDecoration(labelText: '📏  Height (optional)', hintText: 'e.g. 3 feet')),
          const SizedBox(height: 16),
          Text('🩺  Condition', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: ['Excellent', 'Good', 'Fair', 'Poor', 'Dead'].map((c) =>
            GestureDetector(onTap: () => setState(() => _condition = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _condition == c ? AppTheme.primarySubtle : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _condition == c ? AppTheme.primary : AppTheme.border)),
                child: Text(c, style: TextStyle(color: _condition == c ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 13))))).toList()),
          const SizedBox(height: 16),
          TextField(controller: _remarksCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '📝  Remarks', hintText: 'Observations...')),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () { setState(() => _phase = 'capture'); _initCamera(); },
          icon: const Icon(Icons.camera_alt), label: const Text('Retake'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: Container(
          decoration: BoxDecoration(gradient: AppTheme.gradientPrimary, borderRadius: BorderRadius.circular(14)),
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _saveUpdate,
            icon: const Icon(Icons.save), label: Text(_loading ? 'Saving...' : 'Save Update'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16))))),
      ]),
      const SizedBox(height: 40),
    ]);
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
