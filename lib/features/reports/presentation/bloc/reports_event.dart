part of 'reports_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object> get props => [];
}

class LoadReportsEvent extends ReportsEvent {}

class SetReportFilterEvent extends ReportsEvent {
  final String filter; // 'today', 'week', 'month', 'all'
  const SetReportFilterEvent(this.filter);
  @override
  List<Object> get props => [filter];
}

class DeleteInvoiceFromReportsEvent extends ReportsEvent {
  final String invoiceId;
  const DeleteInvoiceFromReportsEvent(this.invoiceId);
  @override
  List<Object> get props => [invoiceId];
}
