/// 企业注册页（两步）
///
/// 对齐 qifuwang RegisterPage.tsx 逻辑：
/// Step1：选择企业（搜索输入框 + 下拉候选列表）
/// Step2：管理员信息（手机号 + 昵称 + 密码）
/// 注册成功自动登录并直接进入主界面
import 'package:flutter/material.dart';
import '../../contracts/agent_service.dart';
import '../../contracts/chat_service.dart';
import '../agent/agent_service_impl.dart';
import '../chat/chat_service_impl.dart';
import '../shell/shell_page.dart';
import 'enterprise_auth_service.dart';
import 'enterprise_model.dart';
import 'enterprise_search_service.dart';

class EnterpriseRegisterPage extends StatefulWidget {
  final ChatService? chatService;
  final AgentService? agentService;

  const EnterpriseRegisterPage({super.key, this.chatService, this.agentService});

  @override
  State<EnterpriseRegisterPage> createState() => _EnterpriseRegisterPageState();
}

class _EnterpriseRegisterPageState extends State<EnterpriseRegisterPage> {
  int _step = 1; // 1: 选择企业, 2: 管理员信息
  Enterprise? _selectedEnterprise;
  late final ChatService _chatService;
  late final AgentService _agentService;

  // Step1 搜索
  final TextEditingController _searchController = TextEditingController();
  List<Enterprise> _searchResults = [];
  bool _isSearching = false;

  // Step2 表单
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? HttpChatService();
    _agentService = widget.agentService ?? HttpAgentService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (value.trim().length >= 3) {
      setState(() {
        _isSearching = true;
        _searchResults = EnterpriseSearchService.search(value);
      });
    } else {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _selectEnterprise(Enterprise ent) {
    setState(() {
      _selectedEnterprise = ent;
      _searchController.text = ent.name;
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _goToStep2() {
    if (_selectedEnterprise == null) {
      setState(() => _error = '请先选择企业');
      return;
    }
    setState(() {
      _step = 2;
      _error = '';
    });
  }

  Future<void> _doRegister() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || name.isEmpty || password.isEmpty) {
      setState(() => _error = '请填写完整信息');
      return;
    }
    if (phone.length != 11) {
      setState(() => _error = '请输入正确的手机号');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = '密码至少6位');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final user = EnterpriseUser(
        phone: phone,
        password: password,
        enterpriseName: _selectedEnterprise!.name,
        enterpriseId: _selectedEnterprise!.id,
        userName: name,
        createdAt: DateTime.now().toIso8601String(),
      );

      final result = await EnterpriseAuthService.registerUser(user);
      if (!result['ok']) {
        setState(() {
          _error = result['error'] ?? '注册失败';
          _loading = false;
        });
        return;
      }

      // 注册成功，自动登录
      await EnterpriseAuthService.setAuth(EnterpriseAuth(
        token: 'mock-token',
        enterpriseName: _selectedEnterprise!.name,
        enterpriseId: _selectedEnterprise!.id,
        phone: phone,
        userName: name,
      ));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ShellPage(
              chatService: _chatService,
              agentService: _agentService,
            ),
          ),
          (route) => false,
        );
      }
    } catch (_) {
      setState(() {
        _error = '注册失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 1 ? '选择企业' : '管理员信息'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1B1C),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _step == 1 ? _buildStep1() : _buildStep2(),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '请输入企业名称或统一社会信用代码',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '输入至少3个字开始搜索',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E3DD)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 16),
        if (_isSearching && _searchResults.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('未找到匹配的企业', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
          )
        else if (_searchResults.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE4E3DD)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _searchResults.map((ent) {
                return ListTile(
                  title: Text(ent.name, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '${ent.legalPerson} · ${ent.region}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  onTap: () => _selectEnterprise(ent),
                );
              }).toList(),
            ),
          ),
        if (_selectedEnterprise != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedEnterprise!.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('统一社会信用代码：${_selectedEnterprise!.creditCode}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                Text('法定代表人：${_selectedEnterprise!.legalPerson}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _selectedEnterprise == null ? null : _goToStep2,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('下一步', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_error, style: const TextStyle(color: Color(0xFFEA6668), fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('已选企业：${_selectedEnterprise!.name}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF))),
        ),
        const SizedBox(height: 20),
        const Text('手机号', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          decoration: InputDecoration(
            hintText: '请输入手机号',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text('管理员昵称', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: '请输入管理员昵称',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text('密码', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '请输入密码（至少6位）',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _loading ? null : _doRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_loading ? '注册中…' : '注册并登录',
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('返回上一步', style: TextStyle(color: Color(0xFF6B7280))),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_error, style: const TextStyle(color: Color(0xFFEA6668), fontSize: 13)),
        ],
      ],
    );
  }
}
