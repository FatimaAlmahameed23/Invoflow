import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/invoices_details/domain/usecases/get_invoice_details_use_case.dart';
import 'package:invoflow/features/invoices_details/presentation/cubit/invoice_details_state.dart';

class InvoiceDetailsCubit extends Cubit<InvoiceDetailsState> {
  InvoiceDetailsCubit(this._getInvoiceDetails)
    : super(const InvoiceDetailsState());

  final GetInvoiceDetailsUseCase _getInvoiceDetails;

  Future<void> loadInvoice(String invoiceId) async {
    emit(const InvoiceDetailsState(isLoading: true));
    try {
      final invoice = await _getInvoiceDetails(invoiceId);
      if (!isClosed) emit(InvoiceDetailsState(invoice: invoice));
    } catch (error) {
      if (!isClosed) {
        emit(InvoiceDetailsState(errorMessage: error.toString()));
      }
    }
  }
}
