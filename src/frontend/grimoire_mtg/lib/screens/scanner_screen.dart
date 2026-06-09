import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../navigation/route_observer.dart';
import '../scanner/text_scanner.dart';
import '../services/auth_service.dart';
import 'scan_result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with RouteAware, WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final TextScanner _scanner = TextScanner();
  bool _processing = false;
  bool _startingCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  void didPushNext() {
    _stopCamera();
  }

  @override
  void didPopNext() {
    _startCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _startCamera();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopCamera();
    }
  }

  Future<void> _startCamera() async {
    if (_controller != null || _startingCamera || !mounted) return;

    debugPrint('[scanner] _startCamera: starting');
    _startingCamera = true;
    try {
      final cameras = await availableCameras();
      debugPrint('[scanner] _startCamera: found ${cameras.length} camera(s)');
      if (!mounted || cameras.isEmpty) {
        debugPrint('[scanner] _startCamera: no cameras or unmounted, aborting');
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = controller.initialize();
      await _initializeControllerFuture;

      if (!mounted) {
        debugPrint('[scanner] _startCamera: unmounted after init, disposing controller');
        await controller.dispose();
        return;
      }

      _controller = controller;
      debugPrint('[scanner] _startCamera: camera ready');
      setState(() {});
    } catch (e, st) {
      debugPrint('[scanner] _startCamera ERROR: $e\n$st');
      if (mounted) setState(() {});
    } finally {
      _startingCamera = false;
    }
  }

  Future<void> _stopCamera() async {
    debugPrint('[scanner] _stopCamera');
    _startingCamera = false;
    final controller = _controller;
    _controller = null;
    _initializeControllerFuture = null;
    if (controller != null) {
      await controller.dispose();
    }
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    if (_processing || _controller == null) {
      debugPrint('[scanner] _takePicture: skipped (processing=$_processing, controller=${_controller == null ? "null" : "ok"})');
      return;
    }

    debugPrint('[scanner] _takePicture: start');
    setState(() => _processing = true);

    try {
      await _initializeControllerFuture;
      debugPrint('[scanner] _takePicture: taking picture');
      final image = await _controller!.takePicture();
      debugPrint('[scanner] _takePicture: picture saved to ${image.path}');
      await _stopCamera();

      debugPrint('[scanner] _takePicture: running OCR');
      final plaintext = await _scanner.scanText(image.path);
      debugPrint('[scanner] --- OCR plaintext ---\n$plaintext');

      if (!mounted) return;

      if (plaintext.trim().isEmpty) {
        debugPrint('[scanner] _takePicture: OCR returned empty text');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.scanNoText)),
        );
        await _startCamera();
        return;
      }

      debugPrint('[scanner] _takePicture: calling API scanCard');
      final scanResult =
          await context.read<AuthService>().api.scanCard(plaintext);
      final parsed = scanResult.parsed;
      debugPrint(
        '[scanner] --- Parsed card ---\n'
        'resolution: ${scanResult.resolution}\n'
        'name: ${parsed?['name']}\n'
        'set: ${parsed?['set']}\n'
        'collectorNumber: ${parsed?['collectorNumber']}',
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(scanResult: scanResult),
        ),
      );

      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        await _startCamera();
      }
    } on ApiException catch (e) {
      debugPrint('[scanner] _takePicture ApiException: ${e.statusCode} ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        await _startCamera();
      }
    } catch (e, st) {
      debugPrint('[scanner] _takePicture ERROR: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.scanError(e.toString()))),
        );
        await _startCamera();
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          Center(
            child: Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Skanowanie...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _processing ? null : _takePicture,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _controller != null &&
            _controller!.value.isInitialized) {
          return Center(child: CameraPreview(_controller!));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
