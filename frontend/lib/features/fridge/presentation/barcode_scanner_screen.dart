import 'package:flutter/material.dart';
import 'package:keepmydiet/shared/widgets/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> scanBarcode(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Utiliser la caméra ?'),
      content: const Text(
        'La caméra sert uniquement à lire le code-barres. Aucune image '
        "n'est enregistrée ni envoyée, et la caméra s'éteint dès que le "
        'scan est terminé.',
      ),
      actions: [
        DialogActionButtons(
          cancelLabel: 'Refuser',
          onCancel: () => Navigator.of(dialogContext).pop(false),
          confirmLabel: 'Autoriser',
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted) return null;

  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
  );
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController();

  // onDetect peut se déclencher plusieurs fois avant la fermeture de l'écran.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (_handled || code == null) return;
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
            onPressed: _controller.toggleTorch,
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, state, _) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (_, error) => Center(
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
