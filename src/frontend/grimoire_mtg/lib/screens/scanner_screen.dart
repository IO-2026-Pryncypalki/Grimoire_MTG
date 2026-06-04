import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
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

    _startingCamera = true;
    try {
      final cameras = await availableCameras();
      if (!mounted || cameras.isEmpty) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = controller.initialize();
      await _initializeControllerFuture;

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    } finally {
      _startingCamera = false;
    }
  }

  Future<void> _stopCamera() async {
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
    if (_processing || _controller == null) return;

    setState(() => _processing = true);

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      await _stopCamera();

      final plaintext = await _scanner.scanText(image.path);

      if (!mounted) return;

      if (plaintext.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie wykryto tekstu na karcie')),
        );
        await _startCamera();
        return;
      }

      final scanResult =
          await context.read<AuthService>().api.scanCard(plaintext);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        await _startCamera();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd skanowania: $e')),
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
