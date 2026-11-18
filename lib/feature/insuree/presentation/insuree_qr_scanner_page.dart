import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openimis_claim_policy_app/core/localization/app_localizations.dart';
import 'package:openimis_claim_policy_app/core/utils/insuree_number.dart';
import 'package:openimis_claim_policy_app/feature/shared/widgets/app_widgets.dart';

abstract final class InsureeQrPayload {
  static String? parse(String? rawValue) {
    if (rawValue == null) return null;
    final mpi = InsureeNumber.normalize(rawValue);
    return InsureeNumber.validate(mpi) == null ? mpi : null;
  }
}

class InsureeQrScannerPage extends StatefulWidget {
  const InsureeQrScannerPage({super.key});

  @override
  State<InsureeQrScannerPage> createState() => _InsureeQrScannerPageState();
}

class _InsureeQrScannerPageState extends State<InsureeQrScannerPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final mpi = InsureeQrPayload.parse(barcode.rawValue);
      if (mpi == null) continue;
      _handled = true;
      Navigator.pop(context, mpi);
      return;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppAppBar(
      title: Text(context.tr('Scan insuree QR code')),
      actions: [
        IconButton(
          tooltip: context.tr('Toggle torch'),
          onPressed: _controller.toggleTorch,
          icon: const Icon(Icons.flashlight_on_outlined),
        ),
        IconButton(
          tooltip: context.tr('Switch camera'),
          onPressed: _controller.switchCamera,
          icon: const Icon(Icons.cameraswitch_outlined),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
