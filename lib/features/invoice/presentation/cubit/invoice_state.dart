part of 'invoice_cubit.dart';

class InvoiceState {
  const InvoiceState({
    this.invoices = const [],
    this.deletingInvoiceIds = const {},
    this.deleteErrors = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Invoice> invoices;
  final Set<String> deletingInvoiceIds;
  final Map<String, String> deleteErrors;
  final bool isLoading;
  final String? errorMessage;

  InvoiceState copyWith({
    List<Invoice>? invoices,
    Set<String>? deletingInvoiceIds,
    Map<String, String>? deleteErrors,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return InvoiceState(
      invoices: invoices ?? this.invoices,
      deletingInvoiceIds: deletingInvoiceIds ?? this.deletingInvoiceIds,
      deleteErrors: deleteErrors ?? this.deleteErrors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
