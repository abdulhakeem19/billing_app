import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/core/usecase/usecase.dart';
import 'package:billing_app/features/invoice/domain/entities/invoice.dart';
import 'package:billing_app/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:billing_app/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockGetInvoicesUseCase extends Mock implements GetInvoicesUseCase {}

class MockDeleteInvoiceUseCase extends Mock implements DeleteInvoiceUseCase {}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

Invoice _invoice(int number, DateTime timestamp) => Invoice(
      id: 'inv-$number',
      invoiceNumber: number,
      timestamp: timestamp,
      items: const [],
      subtotal: 100.0,
      taxRate: 0.0,
      taxAmount: 0.0,
      discountAmount: 0.0,
      total: 100.0,
      paymentMode: 'Cash',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  // -------------------------------------------------------------------------
  // LoadReportsEvent
  // -------------------------------------------------------------------------
  group('LoadReportsEvent', () {
    blocTest<ReportsBloc, ReportsState>(
      'emits loading then loaded with invoices',
      build: () {
        final uc = MockGetInvoicesUseCase();
        final inv = _invoice(1, DateTime(2024, 1, 15));
        when(() => uc(any())).thenAnswer((_) async => Right([inv]));
        return ReportsBloc(
            getInvoicesUseCase: uc,
            deleteInvoiceUseCase: MockDeleteInvoiceUseCase());
      },
      act: (bloc) => bloc.add(LoadReportsEvent()),
      expect: () => [
        isA<ReportsState>().having((s) => s.isLoading, 'loading', true),
        isA<ReportsState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.allInvoices.length, 'count', 1),
      ],
    );

    blocTest<ReportsBloc, ReportsState>(
      'emits error on failure',
      build: () {
        final uc = MockGetInvoicesUseCase();
        when(() => uc(any())).thenAnswer(
            (_) async => const Left(CacheFailure('DB error')));
        return ReportsBloc(
            getInvoicesUseCase: uc,
            deleteInvoiceUseCase: MockDeleteInvoiceUseCase());
      },
      act: (bloc) => bloc.add(LoadReportsEvent()),
      expect: () => [
        isA<ReportsState>().having((s) => s.isLoading, 'loading', true),
        isA<ReportsState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.error, 'error', 'DB error'),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // SetReportFilterEvent
  // -------------------------------------------------------------------------
  group('SetReportFilterEvent', () {
    blocTest<ReportsBloc, ReportsState>(
      'updates filter to today',
      build: () => ReportsBloc(
        getInvoicesUseCase: MockGetInvoicesUseCase(),
        deleteInvoiceUseCase: MockDeleteInvoiceUseCase(),
      ),
      act: (bloc) => bloc.add(const SetReportFilterEvent('today')),
      expect: () => [
        isA<ReportsState>()
            .having((s) => s.filter, 'filter', 'today'),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // ReportsState.filteredInvoices
  // -------------------------------------------------------------------------
  group('ReportsState.filteredInvoices', () {
    final now = DateTime.now();
    final todayInv = _invoice(1, now);
    final oldInv = _invoice(2, now.subtract(const Duration(days: 30)));

    test('filter=today returns only today\'s invoices', () {
      final state = ReportsState(
        allInvoices: [todayInv, oldInv],
        filter: 'today',
      );
      expect(state.filteredInvoices, [todayInv]);
    });

    test('filter=week returns invoices within last 7 days', () {
      final recentInv = _invoice(3, now.subtract(const Duration(days: 5)));
      final state = ReportsState(
        allInvoices: [todayInv, recentInv, oldInv],
        filter: 'week',
      );
      expect(state.filteredInvoices.length, 2);
      expect(state.filteredInvoices, containsAll([todayInv, recentInv]));
    });

    test('filter=month returns invoices in current month', () {
      final thisMonthInv = _invoice(
          4, DateTime(now.year, now.month, 1));
      final lastMonthInv =
          _invoice(5, DateTime(now.year, now.month - 1, 15));
      final state = ReportsState(
        allInvoices: [thisMonthInv, lastMonthInv],
        filter: 'month',
      );
      expect(state.filteredInvoices, [thisMonthInv]);
    });

    test('filter=all returns all invoices', () {
      final state = ReportsState(
        allInvoices: [todayInv, oldInv],
        filter: 'all',
      );
      expect(state.filteredInvoices.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // ReportsState computed properties
  // -------------------------------------------------------------------------
  group('ReportsState computed properties', () {
    final now = DateTime.now();

    test('totalRevenue sums filtered invoice totals', () {
      final inv1 = _invoice(1, now); // total = 100
      final inv2 = _invoice(2, now); // total = 100
      final state = ReportsState(
          allInvoices: [inv1, inv2], filter: 'today');
      expect(state.totalRevenue, 200.0);
    });

    test('averageOrderValue is zero when no transactions', () {
      const state = ReportsState(allInvoices: [], filter: 'today');
      expect(state.averageOrderValue, 0.0);
    });

    test('topProducts returns top 5 by quantity', () {
      final invWithItems = Invoice(
        id: 'inv-1',
        invoiceNumber: 1,
        timestamp: now,
        items: const [
          InvoiceItem(
              productId: 'p1',
              productName: 'Rice',
              quantity: 5,
              price: 50),
          InvoiceItem(
              productId: 'p2',
              productName: 'Sugar',
              quantity: 3,
              price: 40),
        ],
        subtotal: 370,
        taxRate: 0,
        taxAmount: 0,
        discountAmount: 0,
        total: 370,
        paymentMode: 'Cash',
      );
      final state =
          ReportsState(allInvoices: [invWithItems], filter: 'all');
      expect(state.topProducts.first.key, 'Rice');
      expect(state.topProducts.first.value, 5);
    });
  });

  // -------------------------------------------------------------------------
  // DeleteInvoiceFromReportsEvent
  // -------------------------------------------------------------------------
  group('DeleteInvoiceFromReportsEvent', () {
    blocTest<ReportsBloc, ReportsState>(
      'deletes invoice and reloads',
      build: () {
        final deleteUC = MockDeleteInvoiceUseCase();
        final getUC = MockGetInvoicesUseCase();
        when(() => deleteUC(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getUC(any()))
            .thenAnswer((_) async => const Right([]));
        return ReportsBloc(
            getInvoicesUseCase: getUC, deleteInvoiceUseCase: deleteUC);
      },
      act: (bloc) =>
          bloc.add(const DeleteInvoiceFromReportsEvent('inv-1')),
      expect: () => [
        // Reload emitted after delete
        isA<ReportsState>().having((s) => s.isLoading, 'loading', true),
        isA<ReportsState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.allInvoices, 'invoices', isEmpty),
      ],
    );
  });
}
