import 'package:starter_architecture_flutter_firebase/src/features/entries/application/entries_service.dart';

class EntriesListTileModel {
  const EntriesListTileModel({
    required this.leadingText,
    required this.trailingText,
    this.middleText,
    this.isHeader = false,
    this.paymentSummary, // NEW: Optional payment summary for the "All Entries" row
  });
  final String leadingText;
  final String trailingText;
  final String? middleText;
  final bool isHeader;
  final PaymentSummary? paymentSummary; // NEW
}