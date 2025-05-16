import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PasswordApp());
}

class PasswordApp extends StatelessWidget {
  const PasswordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '密码生成器',
      home: const PasswordHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PasswordHomePage extends StatefulWidget {
  const PasswordHomePage({super.key});

  @override
  State<PasswordHomePage> createState() => _PasswordHomePageState();
}

class _PasswordHomePageState extends State<PasswordHomePage> {
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _ruleController = TextEditingController();
  int? _selectedDays;
  String _password = '';

  // 天数 -> iOnlyDaysFlag01 映射表
  static const Map<int, int> _flagMap = {
    3: 9242,
    7: 5953,
    10: 3156,
    15: 5601,
    20: 3424,
    25: 5509,
    30: 2053,
    60: 6878,
    90: 3355,
    120: 4577,
    150: 9653,
    180: 5251,
    210: 3575,
    240: 9515,
    270: 3650,
    300: 5356,
    330: 9619,
    360: 5750,
    540: 5012,
    30000: 6435,
    300000: 7461,
  };

  final List<int> _daysOptions = _flagMap.keys.toList()..sort();

  void _generatePassword() {
    // 1. 校验并解析输入
    final serial = int.tryParse(_serialController.text);
    final status = int.tryParse(_statusController.text);
    final days = _selectedDays;
    final rule =
    _ruleController.text.isEmpty
        ? 1
        : int.tryParse(_ruleController.text) ?? -1;

    if (serial == null || status == null || days == null) {
      _showError('请输入有效的序列号、状态号和剩余天数');
      return;
    }
    if (rule < 1 || rule > 999) {
      _showError('规则符必须在 1~999 之间或留空');
      return;
    }

    // 2. 计算 a = 19 * flag * rule
    final flag = _flagMap[days]!;
    final a = 19 * flag * rule;

    // 3. 计算 c 和 d
    final idx = (status % 256) % 5; // 0..4
    const p2 = [1, 2, 4, 8, 16];
    const p7 = [1, 7, 49, 343, 2401];
    final c = p2[idx];
    final d = p7[idx];

    // 4. 计算 b = serial * (11 + c) + status * d + rule
    final b = serial * (11 + c) + status * d + rule;

    // 5. 最终密码 = a + b
    final result = a + b;

    setState(() {
      _password = result.toString();
    });
  }

  void _copyPasswordToClipboard() {
    Clipboard.setData(ClipboardData(text: _password)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('密码已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }


  void _showError(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
        title: const Text('输入错误'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _serialController.clear();
    _statusController.clear();
    _ruleController.clear();
    setState(() {
      _selectedDays = null;
      _password = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('密码生成器')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _serialController,
              decoration: const InputDecoration(
                labelText: '序列号',
                hintText: '设备返回的序列号',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: '状态号',
                hintText: '设备返回的状态号',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '剩余天数',
                border: OutlineInputBorder(),
              ),
              value: _selectedDays,
              items:
              _daysOptions
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDays = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ruleController,
              decoration: const InputDecoration(
                labelText: '规则符（可选）',
                hintText: '1~999，留空则视为1',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generatePassword,
              child: const Text('生成密码'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _clearFields, child: const Text('清空')),
            const SizedBox(height: 24),
            if (_password.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '密码：$_password',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: '复制密码',
                    onPressed: _copyPasswordToClipboard,
                  ),
                ],
              )
            else
              const Text(
                '生成的密码会显示在此',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
