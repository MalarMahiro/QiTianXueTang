import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _sendingCode = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      _showToast('请输入正确的手机号');
      return;
    }
    setState(() => _sendingCode = true);
    final success = await context.read<AuthProvider>().sendSmsCode(phone);
    setState(() => _sendingCode = false);
    if (success) {
      _showToast('验证码已发送');
      _startCountdown();
    } else {
      _showToast('发送失败，请重试');
    }
  }

  void _startCountdown() {
    _countdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_countdown > 0) _countdown--;
      });
      return _countdown > 0;
    });
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (phone.length != 11) {
      _showToast('请输入正确的手机号');
      return;
    }
    if (code.length < 4) {
      _showToast('请输入验证码');
      return;
    }
    final success = await context.read<AuthProvider>().login(phone, code);
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      _showToast('登录失败，请检查验证码');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.school, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              const Text(
                '欢迎使用七天学堂',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '登录后即可查看成绩与学情分析',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '验证码',
                        hintText: '请输入验证码',
                        prefixIcon: Icon(Icons.message),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _countdown > 0
                          ? null
                          : (_sendingCode ? null : _sendCode),
                      child: Text(
                        _countdown > 0
                            ? '${_countdown}s后重发'
                            : '获取验证码',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('登录', style: TextStyle(fontSize: 16)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '登录即表示同意《用户协议》和《隐私政策》',
                  style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}