import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for RawKeyboardListener
import 'package:provider/provider.dart';
import '../providers/password_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
    bool success = false;

    try {
      if (passwordProvider.isFirstTime) {
        // إنشاء كلمة مرور جديدة
        success = await passwordProvider.setPassword(_passwordController.text);
        if (success) {
          _showSuccessMessage('تم إنشاء كلمة المرور بنجاح');
        } else {
          _showErrorMessage('فشل في إنشاء كلمة المرور');
        }
      } else {
        // التحقق من كلمة المرور
        success = await passwordProvider.verifyPassword(_passwordController.text);
        if (!success) {
          _showErrorMessage('كلمة المرور غير صحيحة');
        }
      }
    } catch (e) {
      _showErrorMessage('حدث خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _handleSubmit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        body: Center(
          child: SingleChildScrollView(
            child: Consumer<PasswordProvider>(
              builder: (context, passwordProvider, child) {
                return Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  margin: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // أيقونة التطبيق
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock,
                                size: 48,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // العنوان
                            Text(
                              passwordProvider.isFirstTime
                                  ? 'إنشاء كلمة مرور جديدة'
                                  : 'تسجيل الدخول',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // النص التوضيحي
                            Text(
                              passwordProvider.isFirstTime
                                  ? 'قم بإنشاء كلمة مرور لحماية بياناتك'
                                  : 'أدخل كلمة المرور للدخول إلى التطبيق',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            // حقل كلمة المرور
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscurePassword,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscurePassword = !_isObscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال كلمة المرور';
                                }
                                if (passwordProvider.isFirstTime && value.length < 4) {
                                  return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
                                }
                                return null;
                              },
                            ),
                            
                            // حقل تأكيد كلمة المرور (للمرة الأولى فقط)
                            if (passwordProvider.isFirstTime) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _isObscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'تأكيد كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isObscureConfirmPassword = !_isObscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى تأكيد كلمة المرور';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'كلمة المرور غير متطابقة';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 32),
                            
                            // زر تسجيل الدخول
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        passwordProvider.isFirstTime
                                            ? 'إنشاء كلمة المرور'
                                            : 'تسجيل الدخول',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
