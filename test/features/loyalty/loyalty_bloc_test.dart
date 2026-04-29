import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/core/usecase/usecase.dart';
import 'package:billing_app/features/loyalty/domain/entities/customer.dart';
import 'package:billing_app/features/loyalty/domain/usecases/loyalty_usecases.dart';
import 'package:billing_app/features/loyalty/presentation/bloc/loyalty_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockGetCustomerByPhoneUseCase extends Mock
    implements GetCustomerByPhoneUseCase {}

class MockCreateCustomerUseCase extends Mock
    implements CreateCustomerUseCase {}

class MockUpdateCustomerUseCase extends Mock
    implements UpdateCustomerUseCase {}

class MockGetAllCustomersUseCase extends Mock
    implements GetAllCustomersUseCase {}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _customer = Customer(
  id: 'cust-1',
  name: 'Alice',
  phone: '9876543210',
  points: 100,
);

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

LoyaltyBloc _buildBloc({
  MockGetCustomerByPhoneUseCase? lookupUC,
  MockCreateCustomerUseCase? createUC,
  MockUpdateCustomerUseCase? updateUC,
  MockGetAllCustomersUseCase? allUC,
}) {
  return LoyaltyBloc(
    getCustomerByPhoneUseCase: lookupUC ?? MockGetCustomerByPhoneUseCase(),
    createCustomerUseCase: createUC ?? MockCreateCustomerUseCase(),
    updateCustomerUseCase: updateUC ?? MockUpdateCustomerUseCase(),
    getAllCustomersUseCase: allUC ?? MockGetAllCustomersUseCase(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Customer(id: '', name: '', phone: ''));
    registerFallbackValue(NoParams());
  });

  // -------------------------------------------------------------------------
  // LookupCustomerEvent
  // -------------------------------------------------------------------------
  group('LookupCustomerEvent', () {
    blocTest<LoyaltyBloc, LoyaltyState>(
      'emits loading then selectedCustomer on found',
      build: () {
        final uc = MockGetCustomerByPhoneUseCase();
        when(() => uc(any()))
            .thenAnswer((_) async => const Right(_customer));
        return _buildBloc(lookupUC: uc);
      },
      act: (bloc) =>
          bloc.add(const LookupCustomerEvent('9876543210')),
      expect: () => [
        isA<LoyaltyState>()
            .having((s) => s.isLoading, 'loading', true),
        isA<LoyaltyState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.selectedCustomer, 'customer', _customer)
            .having((s) => s.lookupDone, 'lookupDone', true),
      ],
    );

    blocTest<LoyaltyBloc, LoyaltyState>(
      'emits loading then no customer when phone not found',
      build: () {
        final uc = MockGetCustomerByPhoneUseCase();
        when(() => uc(any()))
            .thenAnswer((_) async => const Right(null));
        return _buildBloc(lookupUC: uc);
      },
      act: (bloc) =>
          bloc.add(const LookupCustomerEvent('0000000000')),
      expect: () => [
        isA<LoyaltyState>()
            .having((s) => s.isLoading, 'loading', true),
        isA<LoyaltyState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.selectedCustomer, 'customer', isNull)
            .having((s) => s.lookupDone, 'lookupDone', true),
      ],
    );

    blocTest<LoyaltyBloc, LoyaltyState>(
      'emits error on lookup failure',
      build: () {
        final uc = MockGetCustomerByPhoneUseCase();
        when(() => uc(any())).thenAnswer(
            (_) async => const Left(CacheFailure('DB error')));
        return _buildBloc(lookupUC: uc);
      },
      act: (bloc) =>
          bloc.add(const LookupCustomerEvent('9876543210')),
      expect: () => [
        isA<LoyaltyState>().having((s) => s.isLoading, 'loading', true),
        isA<LoyaltyState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.error, 'error', 'DB error'),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // CreateCustomerEvent
  // -------------------------------------------------------------------------
  group('CreateCustomerEvent', () {
    blocTest<LoyaltyBloc, LoyaltyState>(
      'emits loading then selectedCustomer on success',
      build: () {
        final uc = MockCreateCustomerUseCase();
        when(() => uc(any()))
            .thenAnswer((_) async => const Right(_customer));
        return _buildBloc(createUC: uc);
      },
      act: (bloc) => bloc.add(
          const CreateCustomerEvent(name: 'Alice', phone: '9876543210')),
      expect: () => [
        isA<LoyaltyState>().having((s) => s.isLoading, 'loading', true),
        isA<LoyaltyState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.selectedCustomer, 'customer', _customer),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // SelectCustomerEvent
  // -------------------------------------------------------------------------
  blocTest<LoyaltyBloc, LoyaltyState>(
    'SelectCustomerEvent sets selectedCustomer',
    build: _buildBloc,
    act: (bloc) => bloc.add(const SelectCustomerEvent(_customer)),
    expect: () => [
      isA<LoyaltyState>()
          .having((s) => s.selectedCustomer, 'customer', _customer)
          .having((s) => s.lookupDone, 'lookupDone', true),
    ],
  );

  // -------------------------------------------------------------------------
  // ClearSelectedCustomerEvent
  // -------------------------------------------------------------------------
  blocTest<LoyaltyBloc, LoyaltyState>(
    'ClearSelectedCustomerEvent clears customer and resets flags',
    build: _buildBloc,
    seed: () => const LoyaltyState(
        selectedCustomer: _customer, lookupDone: true, pointsToRedeem: 50),
    act: (bloc) => bloc.add(ClearSelectedCustomerEvent()),
    expect: () => [
      isA<LoyaltyState>()
          .having((s) => s.selectedCustomer, 'customer', isNull)
          .having((s) => s.lookupDone, 'lookupDone', false)
          .having((s) => s.pointsToRedeem, 'pointsToRedeem', 0),
    ],
  );

  // -------------------------------------------------------------------------
  // AwardPointsEvent
  // -------------------------------------------------------------------------
  group('AwardPointsEvent', () {
    blocTest<LoyaltyBloc, LoyaltyState>(
      'awards points and updates customer',
      build: () {
        final uc = MockUpdateCustomerUseCase();
        when(() => uc(any()))
            .thenAnswer((_) async => const Right(null));
        return _buildBloc(updateUC: uc);
      },
      seed: () => const LoyaltyState(selectedCustomer: _customer), // 100pts
      act: (bloc) => bloc.add(const AwardPointsEvent(50)),
      expect: () => [
        isA<LoyaltyState>().having(
            (s) => s.selectedCustomer?.points, 'points', 150),
      ],
    );

    blocTest<LoyaltyBloc, LoyaltyState>(
      'clamps points at kMaxLoyaltyPoints',
      build: () {
        final uc = MockUpdateCustomerUseCase();
        when(() => uc(any()))
            .thenAnswer((_) async => const Right(null));
        return _buildBloc(updateUC: uc);
      },
      seed: () => const LoyaltyState(
          selectedCustomer: Customer(
              id: 'c', name: 'A', phone: '1', points: kMaxLoyaltyPoints - 5)),
      act: (bloc) => bloc.add(const AwardPointsEvent(1000)),
      expect: () => [
        isA<LoyaltyState>().having(
            (s) => s.selectedCustomer?.points, 'points', kMaxLoyaltyPoints),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // RedeemPointsEvent
  // -------------------------------------------------------------------------
  blocTest<LoyaltyBloc, LoyaltyState>(
    'RedeemPointsEvent sets pointsToRedeem clamped to maxPoints',
    build: _buildBloc,
    seed: () => const LoyaltyState(selectedCustomer: _customer), // 100pts
    act: (bloc) => bloc.add(const RedeemPointsEvent(60)), // max=60, clamped
    expect: () => [
      isA<LoyaltyState>()
          .having((s) => s.pointsToRedeem, 'pointsToRedeem', 60),
    ],
  );

  // -------------------------------------------------------------------------
  // LoadAllCustomersEvent
  // -------------------------------------------------------------------------
  blocTest<LoyaltyBloc, LoyaltyState>(
    'LoadAllCustomersEvent populates allCustomers',
    build: () {
      final uc = MockGetAllCustomersUseCase();
      when(() => uc(any()))
          .thenAnswer((_) async => const Right([_customer]));
      return _buildBloc(allUC: uc);
    },
    act: (bloc) => bloc.add(LoadAllCustomersEvent()),
    expect: () => [
      isA<LoyaltyState>()
          .having((s) => s.allCustomers, 'allCustomers', [_customer]),
    ],
  );
}
