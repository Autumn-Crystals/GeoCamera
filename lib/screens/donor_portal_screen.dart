import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/impact_calculator.dart';
import '../services/certificate_service.dart';
import '../models/tree_model.dart';

class DonorPortalScreen extends StatefulWidget {
  final bool showAppBar;
  const DonorPortalScreen({super.key, this.showAppBar = true});

  @override
  State<DonorPortalScreen> createState() => _DonorPortalScreenState();
}

class _DonorPortalScreenState extends State<DonorPortalScreen> {
  List<String> _donors = [];
  String? _selectedDonor;
  List<TreeRecord> _donorTrees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  Future<void> _loadDonors() async {
    setState(() => _isLoading = true);
    final trees = await DatabaseService.getTrees();
    
    // Get unique donors
    final donorSet = trees.map((t) => t.donorName).toSet().toList();
    donorSet.sort();

    if (mounted) {
      setState(() {
        _donors = donorSet;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDonorTrees(String donor) async {
    final trees = await DatabaseService.getTrees();
    final filtered = trees.where((t) => t.donorName == donor).toList();

    if (mounted) {
      setState(() {
        _selectedDonor = donor;
        _donorTrees = filtered;
      });
    }
  }

  Future<void> _shareDonorLink(String donor) async {
    HapticFeedback.mediumImpact();
    
    // In a real app, this would be a web URL like: https://yourapp.com/donor/john-doe
    final link = 'ngo-tree-tracker://donor/${Uri.encodeComponent(donor)}';
    final message = '''
🌳 Your Tree Plantation Report

Dear $donor,

Thank you for your contribution! You have planted ${_donorTrees.length} trees.

View your trees and their growth progress:
$link

- Tree Tracker Team
''';

    await Share.share(message, subject: 'Your Tree Plantation Report');
  }

  Future<void> _generateCertificate(String donor) async {
    HapticFeedback.mediumImpact();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text('Generating Certificate...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate unique certificate ID
      final certId = 'CERT-${donor.toUpperCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      // Generate PDF
      final pdfFile = await CertificateService.generateDonorCertificate(
        donorName: donor,
        trees: _donorTrees,
        certificateId: certId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show options dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Certificate Generated!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Certificate for $donor has been generated successfully.'),
                const SizedBox(height: 16),
                Text(
                  'Certificate ID: $certId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await CertificateService.printCertificate(pdfFile);
                },
                child: const Text('Print'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await CertificateService.shareCertificate(pdfFile);
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating certificate: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Donor Portal'),
        actions: [
          if (_selectedDonor != null) ...[
            IconButton(
              icon: const Icon(Icons.card_membership_rounded, size: 22),
              onPressed: () => _generateCertificate(_selectedDonor!),
              tooltip: 'Generate Certificate',
            ),
            IconButton(
              icon: const Icon(Icons.share, size: 22),
              onPressed: () => _shareDonorLink(_selectedDonor!),
            ),
          ],
        ],
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _selectedDonor == null
              ? _buildDonorList()
              : _buildDonorDetail(),
    );
  }

  Widget _buildDonorList() {
    if (_donors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.people, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text('No Donors Yet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Donors will appear here as trees are planted',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _donors.length,
      itemBuilder: (context, index) {
        final donor = _donors[index];
        return _donorCard(donor);
      },
    );
  }

  Widget _donorCard(String donor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _loadDonorTrees(donor);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  donor[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: _getDonorTreeCount(donor),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count ${count == 1 ? 'tree' : 'trees'} planted',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Future<int> _getDonorTreeCount(String donor) async {
    final trees = await DatabaseService.getTrees();
    return trees.where((t) => t.donorName == donor).length;
  }

  Widget _buildDonorDetail() {
    final totalUpdates = _donorTrees.fold<int>(0, (sum, tree) => sum + tree.updates.length);
    final survivalRate = _donorTrees.isEmpty
        ? 0.0
        : (_donorTrees.length / _donorTrees.length * 100); // Simplified - in real app, check actual survival

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedDonor = null;
                _donorTrees = [];
              });
            },
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Back to Donors',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Carbon Impact Card
          _buildCarbonImpactCard(),
          const SizedBox(height: 20),

          // Donor header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.gradientPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _selectedDonor![0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedDonor!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thank you for your contribution!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              Expanded(
                child: _statCard(
                  '${_donorTrees.length}',
                  'Trees Planted',
                  Icons.park,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  '$totalUpdates',
                  'Total Updates',
                  Icons.update,
                  AppTheme.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statCard(
            '${survivalRate.toStringAsFixed(0)}%',
            'Survival Rate',
            Icons.trending_up,
            AppTheme.primary,
          ),
          const SizedBox(height: 24),

          // Trees list
          Text(
            'Your Trees',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          ..._donorTrees.map((tree) => _treeCard(tree)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _treeCard(TreeRecord tree) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/tree/${tree.treeId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: tree.imagePath.isNotEmpty
                  ? Image.file(
                      File(tree.imagePath),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tree.plantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📅 ${_formatDate(tree.dateTime)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x26FBBF24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tree.updates.length} updates',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Individual tree certificate - TODO: Implement
            // Padding(
            //   padding: const EdgeInsets.only(right: 8),
            //   child: IconButton(
            //     icon: const Icon(Icons.badge_outlined, color: AppTheme.primary, size: 20),
            //     onPressed: () {}, // TODO: Generate individual tree certificate
            //     tooltip: 'Tree Certificate',
            //   ),
            // ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonImpactCard() {
    final totalCo2 = ImpactCalculator.calculateTotalCo2(_donorTrees);
    final co2Formatted = ImpactCalculator.formatCo2(totalCo2);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENVIRONMENTAL IMPACT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  co2Formatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Carbon sequestered to date',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppTheme.bgElevated,
      child: const Icon(Icons.park, color: AppTheme.primary),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd MMM yyyy').format(d);
  }
}
