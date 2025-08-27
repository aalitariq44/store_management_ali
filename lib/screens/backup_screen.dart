import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/backup_service.dart';
import '../utils/date_formatter.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  List<FileObject> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await BackupService.getBackupFiles();
      setState(() {
        _backupFiles = files;
        _backupFiles.sort((a, b) {
          final dateA = DateTime.parse(a.createdAt!);
          final dateB = DateTime.parse(b.createdAt!);
          return dateB.compareTo(dateA); // Sort from newest to oldest
        });
      });
    } catch (e) {
      _showSnackBar('خطأ في جلب قائمة النسخ الاحتياطية: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BackupService.uploadBackup();
      if (success) {
        _showSnackBar('تم إنشاء النسخة الاحتياطية بنجاح');
        await _loadBackupFiles();
        // تنظيف النسخ القديمة
        await BackupService.cleanupOldBackups();
      } else {
        _showSnackBar('فشل في إنشاء النسخة الاحتياطية', isError: true);
      }
    } catch (e) {
      _showSnackBar('خطأ في إنشاء النسخة الاحتياطية: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBackup(String fileName) async {
    final confirmed = await _showConfirmationDialog(
      'حذف النسخة الاحتياطية',
      'هل أنت متأكد من أنك تريد حذف هذه النسخة الاحتياطية؟',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BackupService.deleteBackup(fileName);
      if (success) {
        _showSnackBar('تم حذف النسخة الاحتياطية بنجاح');
        await _loadBackupFiles();
      } else {
        _showSnackBar('فشل في حذف النسخة الاحتياطية', isError: true);
      }
    } catch (e) {
      _showSnackBar('خطأ في حذف النسخة الاحتياطية: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatFileName(String fileName) {
    // استخراج التاريخ من اسم الملف
    final parts = fileName.split('_');
    if (parts.length >= 2) {
      final datePart = parts[1].replaceAll('.json', '');
      try {
        final date = DateTime.parse(datePart.replaceAll('-', ':'));
        return DateFormatter.formatDateTime(date);
      } catch (e) {
        return fileName;
      }
    }
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطية'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadBackupFiles,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _createBackup,
                          icon: const Icon(Icons.backup),
                          label: const Text('إنشاء نسخة احتياطية جديدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _backupFiles.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد نسخ احتياطية',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _backupFiles.length,
                          itemBuilder: (context, index) {
                            final file = _backupFiles[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.backup,
                                  color: Colors.blue,
                                ),
                                title: Text(_formatFileName(file.name)),
                                subtitle: Text(
                                  'تاريخ الإنشاء: ${DateFormatter.formatDateTime(DateTime.parse(file.createdAt!).toLocal())}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: _isLoading
                                          ? null
                                          : () => _deleteBackup(file.name),
                                      tooltip: 'حذف',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
