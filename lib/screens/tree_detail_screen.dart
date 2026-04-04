import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/pdf_certificate_service.dart';
import '../models/tree_model.dart';
import '../widgets/photo_comparison_slider.dart';
import 'update_entry_screen.dart';

class TreeDetailScreen extends StatefulWidget {
  final String treeId;
  const TreeDetailScreen({super.key, required this.treeId});
  @override
  State<TreeDetailScreen> createState() => _TreeDetailScreenState();
}

class _TreeDetailScreenState extends State<TreeDetailScreen> {
  TreeRecord? _tree;
  bool _showComparison = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await DatabaseService.getTreeById(widget.treeId);
    if (mounted) setState(() => _tree = t);
  }

  @override
  Widget build(BuildContext context) {
    if (_tree == null) {
      return Scaffold(appBar: AppBar(title: const Text('Tree Detail')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    final tree = _tree!;
    return Scaffold(
      appBar: AppBar(
        title: Text(tree.treeId),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, size: 22),
            onPressed: () => PdfCertificateService.generateAndPreviewCertificate(tree),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, size: 22),
            onPressed: () => _showQRCode(tree),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UpdateEntryScreen(preSelectedTree: tree),
              ),
            ).then((_) => _load()), // Reload tree data after update
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Update'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: tree.imagePath.isNotEmpty
                      ? Image.file(File(tree.imagePath), width: 90, height: 90, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _badge(tree.treeId, AppTheme.primarySubtle, AppTheme.primary),
                    const SizedBox(width: 6),
                    _badge('${tree.updates.length} updates', const Color(0x26FBBF24), AppTheme.accent),
                  ]),
                  const SizedBox(height: 8),
                  Text(tree.plantName, style: Theme.of(context).textTheme.headlineLarge),
                ])),
              ]),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.divider),
              const SizedBox(height: 12),
              _infoGrid(tree),
            ]),
          ),
          const SizedBox(height: 20),

          // Map
          _sectionTitle(Icons.location_on, 'Location'),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
            clipBehavior: Clip.antiAlias,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(tree.latitude, tree.longitude),
                    zoom: 15,
                  ),
                  mapType: MapType.normal,
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: {
                    Marker(
                      markerId: MarkerId(tree.treeId),
                      position: LatLng(tree.latitude, tree.longitude),
                      infoWindow: InfoWindow(title: tree.plantName  ),
                    ),
                  },
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
                ),
          ),
          const SizedBox(height: 24),

          // Photo Comparison Slider (if there are updates)
          if (tree.updates.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle(Icons.compare, 'Growth Comparison'),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showComparison = !_showComparison);
                  },
                  icon: Icon(
                    _showComparison ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(_showComparison ? 'Hide' : 'Show'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showComparison) ...[
              PhotoComparisonSlider(
                beforeImagePath: tree.imagePath,
                afterImagePath: tree.updates.last.imagePath,
                beforeLabel: 'Initial',
                afterLabel: 'Latest',
              ),
              const SizedBox(height: 24),
            ],
          ],

          // Timeline
          _sectionTitle(Icons.history, 'Photo Timeline'),
          const SizedBox(height: 12),
          _timelineItem('Initial Planting', tree.dateTime, tree.imagePath, 'New', null, null),
          ...tree.updates.asMap().entries.map((e) {
            final u = e.value;
            return _timelineItem('Update #${e.key + 1}', u.dateTime, u.imagePath, u.condition, u.height, u.remarks);
          }),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _infoGrid(TreeRecord tree) {
    final items = [
      ['🧑‍🤝‍🧑 Donor', tree.donorName],
      ['📅 Planted', _fmt(tree.dateTime)],
      if (tree.areaName != null && tree.areaName!.isNotEmpty) ['🏙️ Area', tree.areaName!],
      if (tree.remarks != null && tree.remarks!.isNotEmpty) ['📝 Remarks', tree.remarks!],
      ['👤 By', tree.createdBy],
      ['📍 Location', '${tree.latitude.toStringAsFixed(4)}, ${tree.longitude.toStringAsFixed(4)}'],
    ];
    return Column(children: items.map((i) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 90, child: Text(i[0], style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Text(i[1], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    )).toList());
  }

  Widget _timelineItem(String label, String dateTime, String imagePath, String condition, String? height, String? remarks) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary,
          border: Border.all(color: AppTheme.bgPrimary, width: 2))),
        Container(width: 2, height: 180, color: AppTheme.border),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(_fmt(dateTime), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(children: [
          _badge(condition, AppTheme.primarySubtle, AppTheme.primary),
          if (height != null && height.isNotEmpty) ...[const SizedBox(width: 6), _badge('📏 $height', const Color(0x26FBBF24), AppTheme.accent)],
        ]),
        if (remarks != null && remarks.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
          child: Text(remarks, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        const SizedBox(height: 6),
        if (imagePath.isNotEmpty)
          GestureDetector(
            onTap: () => _showFullScreenPhoto(imagePath),
            child: Hero(
              tag: imagePath.hashCode,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  width: double.infinity, height: 180, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 80, color: AppTheme.bgElevated),
                ),
              ),
            ),
          )
        else
          Container(height: 80, color: AppTheme.bgElevated, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 16),
      ])),
    ]);
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: AppTheme.primary, size: 18),
      const SizedBox(width: 6),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
    ]);
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  Widget _placeholder() => Container(width: 90, height: 90, decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(16)),
    child: const Icon(Icons.park, color: AppTheme.primary, size: 32));

  void _showFullScreenPhoto(String imagePath) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: imagePath.hashCode,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Image.file(File(imagePath), fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  String _fmt(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd MMM yyyy, hh:mm a').format(d);
  }

  void _showQRCode(TreeRecord tree) {
    HapticFeedback.mediumImpact();
    final GlobalKey qrKey = GlobalKey();
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Code',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                tree.plantName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: 'geocamera://tree/${tree.treeId}',
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to view tree details',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(dialogContext);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradientPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await _saveAndShareQR(qrKey, tree, dialogContext);
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndShareQR(GlobalKey qrKey, TreeRecord tree, BuildContext dialogContext) async {
    try {
      // Capture QR code as image
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_${tree.treeId}.png');
      await file.writeAsBytes(pngBytes);

      // Share the QR code
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code for ${tree.plantName}\nTree ID: ${tree.treeId}',
      );

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code shared successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share QR code: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}
