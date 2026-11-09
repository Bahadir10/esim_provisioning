import 'package:esim_provisioning/esim_provisioning.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EsimExampleApp());
}

class EsimExampleApp extends StatelessWidget {
  const EsimExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eSIM Provisioning Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const EsimHomePage(),
    );
  }
}

class EsimHomePage extends StatefulWidget {
  const EsimHomePage({super.key});

  @override
  State<EsimHomePage> createState() => _EsimHomePageState();
}

class _EsimHomePageState extends State<EsimHomePage> {
  final EsimProvisioning _engine = EsimProvisioning.instance;
  final TextEditingController _lpaController = TextEditingController(
    text: 'LPA:1\$smdp.example.com\$1234-ABCD-5678-EFGH',
  );

  EsimCapabilities? _caps;
  String _statusMessage = 'Idle';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCapabilities();
  }

  @override
  void dispose() {
    _lpaController.dispose();
    super.dispose();
  }

  Future<void> _checkCapabilities() async {
    setState(() => _isLoading = true);
    try {
      final caps = await _engine.getCapabilities();
      setState(() {
        _caps = caps;
        _statusMessage = 'eSIM Supported: ${caps.isSupported}';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Capabilities check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _installEsim() async {
    final rawLpa = _lpaController.text.trim();
    setState(() {
      _isLoading = true;
      _statusMessage = 'Validating LPA and provisioning...';
    });

    try {
      final result = await _engine.install(rawLpaString: rawLpa);
      setState(() {
        _statusMessage = result.isSuccess
            ? 'Success: ${result.message}'
            : 'Failed (${result.errorCode.name}): ${result.message}';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Install error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = _caps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('eSIM Provisioning Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Device eUICC Capabilities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (caps == null)
                    const Text('Checking device capabilities...')
                  else ...<Widget>[
                    Text('eSIM Hardware Supported: ${caps.isSupported}'),
                    Text('eUICC Subsystem Enabled: ${caps.isEnabled}'),
                    Text('EID: ${caps.eid ?? "Hidden / Carrier Restricted"}'),
                    Text('Carrier Privileges / Entitlements: ${caps.hasCarrierPrivileges}'),
                    Text('Direct Background Download: ${caps.supportsDirectDownload}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'GSMA SGP.22 LPA Activation Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lpaController,
                    decoration: const InputDecoration(
                      labelText: 'LPA String (e.g. LPA:1\$smdp.com\$matchingId)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _installEsim,
                        icon: const Icon(Icons.sim_card_download),
                        label: const Text('Install eSIM Profile'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _engine.openCellularSettings(),
                        icon: const Icon(Icons.settings),
                        label: const Text('Open SIM Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Status Output',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_statusMessage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
