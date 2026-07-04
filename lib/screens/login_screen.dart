import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isRegister = false;
  bool _loading = false;
  String _selectedRole = 'worker';
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await AuthService.registerUser(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text, role: _selectedRole);
        await AuthService.loginUser(_emailCtrl.text.trim(), _passCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome to Tree Tracker, ${_nameCtrl.text.trim()}! 🌳')));
        }
      } else {
        final user = await AuthService.loginUser(_emailCtrl.text.trim(), _passCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back, ${user.name}! 🌿')));
        }
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.2,
            colors: [Color(0x26059669), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradientPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 24)],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => AppTheme.gradientPrimary.createShader(bounds),
                      child: Text('Tree Tracker', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    Text('Tree Tracking Platform', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          // Tabs
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppTheme.bgSecondary, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                _buildTab('Sign In', !_isRegister, () => setState(() => _isRegister = false)),
                                _buildTab('Register', _isRegister, () => setState(() => _isRegister = true)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_isRegister) ...[
                                  _buildField('Full Name', _nameCtrl, Icons.person_outline),
                                  const SizedBox(height: 16),
                                  _buildRoleToggle(),
                                  const SizedBox(height: 16),
                                ],
                                _buildField('Email', _emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
                                const SizedBox(height: 16),
                                _buildField('Password', _passCtrl, Icons.lock_outline, obscure: true),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.gradientPrimary,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 16)],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _handleSubmit,
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                      child: _loading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Text(_isRegister ? '🚀  Create Account' : '🔓  Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Track every tree you plant & grow 🌳', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? AppTheme.gradientPrimary : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 12)] : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.textMuted)),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (type == TextInputType.emailAddress) {
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email address';
        }
        if (obscure && v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },    );
  }

  Widget _buildRoleToggle() {
    return Row(
      children: [
        Expanded(child: _buildRoleCard('Worker', 'worker', Icons.handyman)),
        const SizedBox(width: 12),
        Expanded(child: _buildRoleCard('Admin', 'admin', Icons.admin_panel_settings)),
      ],
    );
  }

  Widget _buildRoleCard(String label, String value, IconData icon) {
    final active = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.primarySubtle : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? AppTheme.primary : AppTheme.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? AppTheme.primary : AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
