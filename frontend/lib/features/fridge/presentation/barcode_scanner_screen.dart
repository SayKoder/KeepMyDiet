import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Écran plein écran avec la caméra, qui se ferme tout seul (`Navigator.pop`
/// avec le code lu) dès qu'un code-barres est détecté.
///
/// `mobile_scanner` gère lui-même la demande de permission caméra au premier
/// lancement (popup système) ; si elle est refusée, `MobileScanner` affiche
/// son propre état d'erreur dans `errorBuilder` plutôt que de planter.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController();

  // `onDetect` peut se déclencher plusieurs fois pour le même code pendant
  // qu'on ferme l'écran (plusieurs frames analysées avant que le pop ne
  // prenne effet) : ce flag évite de faire un double pop.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) {
      return;
    }
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner un code-barres'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off);
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Impossible d'accéder à la caméra : ${error.errorCode.name}",
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: Text(
                'Visez le code-barres du produit',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
