import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/navigation/app_route_observer.dart';
import 'features/admin/screens/admin_slot_capacity_by_package_screen.dart';
import 'features/ai/screens/ai_triage_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/booking/screens/appointment_history_screen.dart';
import 'features/booking/screens/booking_flow_screen.dart';
import 'features/booking/screens/doctor_detail_screen.dart';
import 'features/booking/screens/doctor_explore_screen.dart';
import 'features/booking/screens/doctor_search_screen.dart';
import 'features/booking/screens/doctor_hub_models.dart';
import 'features/booking/screens/home_screen.dart';
import 'features/booking/screens/my_doctors_screen.dart';
import 'features/booking/screens/featured_doctors_screen.dart';
import 'features/medical_history/screens/medical_history_detail_screen.dart';
import 'features/medical_history/screens/medical_history_models.dart';
import 'features/medical_history/screens/medical_history_screen.dart';
import 'features/profile/screens/medical_profiles_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/vaccination_booking/screens/vaccination_booking_models.dart';
import 'features/vaccination_booking/screens/vaccination_booking_screen.dart';

GoRouter createAppRouter({
  required AuthService authService,
}) {
  return GoRouter(
    observers: [appRouteObserver],
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          final requestedTab = int.tryParse(qp['tab'] ?? '') ?? 0;
          final initialTab = requestedTab.clamp(0, 3);
          final specialty = qp['specialty'];

          return HomeScreen(
            authService: authService,
            initialTab: initialTab,
            prefilledSpecialty: specialty,
          );
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(authService: authService),
      ),
      GoRoute(
        path: '/home',
        name: 'home-root',
        builder: (context, state) => HomeScreen(
          authService: authService,
          initialTab: 0,
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterScreen(authService: authService),
      ),
      GoRoute(
        path: '/ai-triage',
        name: 'ai-triage',
        builder: (context, state) => AiTriageScreen(authService: authService),
      ),
      GoRoute(
        path: '/doctor/:id',
        name: 'doctor-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final doctor = DoctorCatalog.instance.findById(id);

          if (doctor == null) {
            return const Scaffold(
              body: Center(child: Text('Doctor not found')),
            );
          }

          return DoctorDetailScreen(
            doctor: doctor,
            authService: authService,
          );
        },
      ),
      GoRoute(
        path: '/doctors/explore',
        name: 'doctor-explore',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          return DoctorExploreScreen(
            authService: authService,
            initialSearch: qp['search'],
            initialSpecialty: qp['specialty'],
          );
        },
      ),
      GoRoute(
        path: '/doctor-search',
        name: 'doctor-search',
        builder: (context, state) => const DoctorSearchScreen(),
      ),
      GoRoute(
        path: '/featured-doctors',
        name: 'featured-doctors',
        builder: (context, state) => FeaturedDoctorsScreen(
          onOpenDoctor: (doctor) => context.push('/doctor/${doctor.id}'),
          initialKeyword: state.uri.queryParameters['search'],
        ),
      ),
      GoRoute(
        path: '/my-doctors',
        name: 'my-doctors',
        builder: (context, state) => MyDoctorsScreen(
          onOpenDoctor: (doctor) => context.push('/doctor/${doctor.id}'),
        ),
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) {
          final doctorId =
              int.tryParse(state.uri.queryParameters['doctorId'] ?? '');
          return BookingFlowScreen(
            authService: authService,
            initialDoctorId: doctorId,
          );
        },
      ),
      GoRoute(
        path: '/medical-history',
        name: 'medical-history',
        builder: (context, state) => const MedicalHistoryScreen(),
      ),
      GoRoute(
        path: '/medical-history/:id',
        name: 'medical-history-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final item = MedicalHistoryCatalog.findById(id);

          if (item == null) {
            return const Scaffold(
              body: Center(child: Text('Medical history not found')),
            );
          }

          final doctor = MedicalHistoryCatalog.doctorOf(item.doctorId) ?? MedicalHistoryCatalog.fallbackDoctorForItem(item);

          if (doctor == null) {
            return const Scaffold(
              body: Center(child: Text('Doctor not found')),
            );
          }

          return MedicalHistoryDetailScreen(item: item, doctor: doctor);
        },
      ),
      GoRoute(
        path: '/vaccination-booking',
        name: 'vaccination-booking',
        builder: (context, state) => const VaccinationBookingScreen(),
      ),
      GoRoute(
        path: '/vaccination-booking/facilities',
        name: 'vaccination-booking-facilities',
        builder: (context, state) => const VaccinationFacilityScreen(),
      ),
      GoRoute(
        path: '/vaccination-booking/visit-info',
        name: 'vaccination-booking-visit-info',
        builder: (context, state) {
          final draft = state.extra is VaccinationBookingDraft
              ? state.extra as VaccinationBookingDraft
              : const VaccinationBookingDraft();
          return VaccinationVisitInfoScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/vaccination-booking/profile',
        name: 'vaccination-booking-profile',
        builder: (context, state) {
          final draft = state.extra is VaccinationBookingDraft
              ? state.extra as VaccinationBookingDraft
              : const VaccinationBookingDraft();
          return VaccinationProfileScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/vaccination-booking/confirm',
        name: 'vaccination-booking-confirm',
        builder: (context, state) {
          final draft = state.extra is VaccinationBookingDraft
              ? state.extra as VaccinationBookingDraft
              : const VaccinationBookingDraft();
          return VaccinationConfirmScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/vaccination-booking/payment',
        name: 'vaccination-booking-payment',
        builder: (context, state) {
          final draft = state.extra is VaccinationBookingDraft
              ? state.extra as VaccinationBookingDraft
              : const VaccinationBookingDraft();
          return VaccinationPaymentScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/vaccination-booking/filter',
        name: 'vaccination-booking-filter',
        builder: (context, state) => const VaccinationFilterScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/medical-profiles',
        name: 'medical-profiles',
        builder: (context, state) => const MedicalProfilesScreen(),
      ),
      GoRoute(
        path: '/medical-profiles/editor',
        name: 'medical-profiles-editor',
        builder: (context, state) {
          final args = state.extra is MedicalProfileEditorArgs
              ? state.extra as MedicalProfileEditorArgs
              : const MedicalProfileEditorArgs();
          return MedicalProfileEditorScreen(args: args);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'profile-edit',
        builder: (context, state) => const EditPersonalInfoScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const MedicalHistoryScreen(),
      ),
      GoRoute(
        path: '/appointments',
        name: 'appointments',
        builder: (context, state) => AppointmentHistoryScreen(
          dioClient: authService.dioClient,
        ),
      ),
      GoRoute(
        path: '/admin/slots-capacity',
        name: 'admin-slots-capacity',
        builder: (context, state) => const AdminSlotCapacityByPackageScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}

