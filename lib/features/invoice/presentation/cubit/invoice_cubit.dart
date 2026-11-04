import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/network/api_exception.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoice/domain/usecases/delete_invoice_use_case.dart';
import 'package:invoflow/features/invoice/domain/usecases/get_invoices_use_case.dart';
import 'package:invoflow/features/invoice/presentation/cubit/invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  InvoiceCubit({
    required GetInvoicesUseCase getInvoices,
    required DeleteInvoiceUseCase deleteInvoice,
  }) : _getInvoices = getInvoices,
       _deleteInvoice = deleteInvoice,
       super(const InvoiceState());

  final GetInvoicesUseCase _getInvoices;
  final DeleteInvoiceUseCase _deleteInvoice;
  final Map<String, String> _pendingDeletionKeys = {};

  Future<void> loadInvoices() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      final invoices = await _getInvoices();
      if (isClosed) return;
      emit(state.copyWith(invoices: invoices, isLoading: false));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    if (state.deletingInvoiceIds.contains(invoiceId)) return;
    final invoice = state.invoices.where((item) => item.id == invoiceId);
    if (invoice.isEmpty || invoice.first.status != InvoiceStatus.approved) {
      return;
    }

    final requestKey = _pendingDeletionKeys.putIfAbsent(invoiceId, _newUuid);
    final deletingIds = {...state.deletingInvoiceIds, invoiceId};
    final deleteErrors = {...state.deleteErrors}..remove(invoiceId);
    emit(
      state.copyWith(
        deletingInvoiceIds: deletingIds,
        deleteErrors: deleteErrors,
      ),
    );

    try {
      final deletedInvoice = await _deleteInvoice(
        invoiceId: invoiceId,
        idempotencyKey: requestKey,
      );
      if (isClosed) return;
      _pendingDeletionKeys.remove(invoiceId);
      final invoices = state.invoices
          .map((item) => item.id == invoiceId ? deletedInvoice : item)
          .toList(growable: false);
      emit(
        state.copyWith(
          invoices: invoices,
          deletingInvoiceIds: {...state.deletingInvoiceIds}..remove(invoiceId),
          deleteErrors: {...state.deleteErrors}..remove(invoiceId),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          deletingInvoiceIds: {...state.deletingInvoiceIds}..remove(invoiceId),
          deleteErrors: {
            ...state.deleteErrors,
            invoiceId: _deleteErrorMessage(error),
          },
        ),
      );
    }
  }

  String _deleteErrorMessage(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Your session has expired. Please sign in again.';
        case 404:
          return 'Invoice not found. Refresh the invoice list and try again.';
        case 409:
          return 'This invoice can no longer be deleted because its status changed.';
        default:
          return error.message;
      }
    }
    return 'Could not delete the invoice. Please try again.';
  }

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
