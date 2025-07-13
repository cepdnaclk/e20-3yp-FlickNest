// Centralized constants for FlickNest Flutter frontend
// Add/modify values as needed for your project

class AppConstants {
  // Server URLs
  static const String apiBaseUrl = 'https://api.flicknest.com';
  static const String firebaseDbUrl = 'https://flicknest.firebaseio.com';
  // static const String localBrokerUrl = 'http://10.42.0.1:5000';
  static const String localBrokerUrl = 'localhost:5000';

  // Environment keys
  static const String defaultEnvironmentId = 'env_default';
  static const String userIdKey = 'user_001';

  // Theme
  static const String defaultTheme = 'light';

  // Notification
  static const bool notificationsEnabledDefault = true;

  // Version
  static const String appVersion = '1.0.0';

  // Other constants
  static const int timeoutSeconds = 30;
  static const String supportEmail = 'support@flicknest.com';

  // Device type icons mapping
  static const Map<String, String> deviceTypeIcons = {
    'L': 'lightbulb_outline',
    'F': 'wind_power',
    'TV': 'tv',
    'C': 'camera_outdoor',
    'MS': 'sensor_door',
    'B': 'bathroom',
    'E': 'electrical_services',
    'DB': 'doorbell',
    'K': 'kitchen',
    'R': 'router',
    'BL': 'blinds',
    'AC': 'ac_unit',
    'GL': 'garage',
    'GD': 'door_sliding',
  };

  // Device constants
  static const String defaultDeviceName = 'Unknown Device';
  static const String unassignedRoomId = 'unassigned';
  static const String defaultRoomName = 'New Room';
  static const String deviceSourceMobile = 'mobile';

  // Device states
  static const String deviceStateOn = 'On';
  static const String deviceStateOff = 'Off';

  // UI Text constants
  static const String addDeviceTitle = 'Add New Device';
  static const String noDevicesTitle = 'No Devices';
  static const String loadingMessage = 'Loading your smart home...';
  static const String noSymbolsMessage = 'No available symbols. Please add symbols first.';
  static const String noRoomsMessage = 'No rooms available. Device will be unassigned.';
  static const String unassignedDevicesTitle = 'Unassigned Devices';
  static const String deviceNameLabel = 'Device Name';
  static const String deviceTypeLabel = 'Device Type';
  static const String selectRoomLabel = 'Select Room';
  static const String addDeviceButtonLabel = 'Add Device';
  static const String cancelButtonLabel = 'Cancel';
  static const String moveToUnassignedLabel = 'Move to Unassigned';
  static const String moveToRoomPrefix = 'Move to';
  static const String appBarTitle = 'Smart Home';
  static const String deviceCountLabel = '{0} devices';
  static const String moveToRoomLabel = '${moveToRoomPrefix} {0}';
  static const String addDevicePrompt = 'Add a device to get started';
  static const String contactAdminPrompt = 'Contact your administrator to add devices';

  // Error messages
  static const String noEnvironmentError = 'Please select an environment first';
  static const String noDeviceNameError = 'Please enter a device name';
  static const String noDeviceTypeError = 'Please select a device type';
  static const String deviceAddedSuccess = 'Device "{0}" added successfully';
  static const String deviceAddError = 'Error adding device: {0}';
  static const String symbolFetchError = 'Error fetching available symbols';

  // API endpoints
  static const String healthEndpoint = '/health';
  static const String symbolsEndpoint = '/symbols';
  static const String devicesEndpoint = '/devices';
}
