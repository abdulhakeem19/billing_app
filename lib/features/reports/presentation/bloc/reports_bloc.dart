import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../../invoice/domain/usecases/invoice_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final DeleteInvoiceUseCase deleteInvoiceUseCase;

  ReportsBloc({
    required this.getInvoicesUseCase,
    required this.deleteInvoiceUseCase,
  }) : super(const ReportsState()) {
    on<LoadReportsEvent>(_onLoadReports);
    on<SetReportFilterEvent>(_onSetFilter);
    on<DeleteInvoiceFromReportsEvent>(_onDeleteInvoice);
  }

  Future<void> _onLoadReports(
      LoadReportsEvent event, Emitter<ReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await getInvoicesUseCase(NoParams());
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (invoices) => emit(state.copyWith(
        isLoading: false,
        allInvoices: invoices,
      )),
    );
  }

  void _onSetFilter(SetReportFilterEvent event, Emitter<ReportsState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onDeleteInvoice(
      DeleteInvoiceFromReportsEvent event, Emitter<ReportsState> emit) async {
    await deleteInvoiceUseCase(event.invoiceId);
    add(LoadReportsEvent());
  }
}
