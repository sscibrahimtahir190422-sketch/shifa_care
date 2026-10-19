import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/app_config.dart';
import '../utils/fmt.dart';
import '../../data/models/appointment.dart';

class ReceiptService {
  ReceiptService._();

  static const _brandPrimary = PdfColor.fromInt(0xFF008FD7);
  static const _brandDark = PdfColor.fromInt(0xFF005F99);
  static const _brandLight = PdfColor.fromInt(0xFFE5F4FC);
  static const _textSecondary = PdfColor.fromInt(0xFF6B7A86);

  static Future<Uint8List> build(Appointment appointment) async {
    final doc = pw.Document();
    final doctor = appointment.doctor;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ---- Header -------------------------------------------------
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: _brandPrimary,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppConfig.appName,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Appointment token slip',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ---- Token --------------------------------------------------
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'YOUR TOKEN',
                      style: pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '#${appointment.token}',
                      style: pw.TextStyle(
                        color: _brandDark,
                        fontSize: 48,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: _brandLight, thickness: 1.4),
              pw.SizedBox(height: 12),

              _row('Patient', appointment.patientName),
              _row('Doctor', doctor?.fullName ?? '—'),
              _row('Department', doctor?.department ?? '—'),
              _row('Room', doctor?.room ?? '—'),
              _row('Date', Fmt.longDate(appointment.date)),
              _row('Status', appointment.status.label),
              if ((appointment.reason ?? '').isNotEmpty)
                _row('Reason', appointment.reason!),

              pw.Spacer(),
              pw.Divider(color: _brandLight, thickness: 1),
              pw.SizedBox(height: 6),
              pw.Text(
                'Please arrive a few minutes early and keep this slip handy. '
                    'Follow your live queue position in the app.',
                style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}