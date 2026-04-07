const bool useLocalServer = true;
const String localServerBaseUrl = 'http://localhost:3000';
const String tunnelServerBaseUrl = 'https://factually-humane-doberman.ngrok-free.app';
const String serverBaseUrl =
    useLocalServer ? localServerBaseUrl : tunnelServerBaseUrl;
const String baseUrl = '$serverBaseUrl/api';

// Feature URLs
const String authBaseUrl = '$baseUrl/auth';
const String appointmentsBaseUrl = '$baseUrl/appointments';
const String aiBaseUrl = '$baseUrl/ai';
const String notificationsBaseUrl = '$baseUrl/notifications';
const String doctorsBaseUrl = '$baseUrl/doctors';
const String specialtiesBaseUrl = '$baseUrl/specialties';
const String slotsBaseUrl = '$baseUrl/slots';
const String clinicsBaseUrl = '$baseUrl/facilities';
