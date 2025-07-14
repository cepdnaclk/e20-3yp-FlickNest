import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('FlickNest App', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('check co-admin dashboard initial state', () async {
      // Wait for dashboard to load
      await driver.waitFor(find.text('Co-Admin Dashboard'));
      
      // Verify overview section
      expect(await driver.getText(find.text('Overview')), 'Overview');
      
      // Verify quick actions
      expect(await driver.getText(find.text('Quick Actions')), 'Quick Actions');
      expect(await driver.getText(find.text('Add Device')), 'Add Device');
      expect(await driver.getText(find.text('Add Room')), 'Add Room');
      
      // Verify management section
      expect(await driver.getText(find.text('Management')), 'Management');
      expect(await driver.getText(find.text('Device\nManagement')), 'Device\nManagement');
      expect(await driver.getText(find.text('Room\nManagement')), 'Room\nManagement');
      expect(await driver.getText(find.text('System\nSettings')), 'System\nSettings');
    });

    test('navigate to device management', () async {
      await driver.tap(find.text('Device\nManagement'));
      await driver.waitFor(find.text('Device Management'));
      // Add more specific checks for device management page
    });

    test('navigate to room management', () async {
      await driver.tap(find.text('Room\nManagement'));
      await driver.waitFor(find.text('Room Management'));
      // Add more specific checks for room management page
    });

    test('navigate to system settings', () async {
      await driver.tap(find.text('System\nSettings'));
      await driver.waitFor(find.text('System Settings'));
      // Add more specific checks for settings page
    });

    test('add new device flow', () async {
      // Navigate back to dashboard
      await driver.tap(find.pageBack());
      await driver.waitFor(find.text('Co-Admin Dashboard'));
      
      // Start add device flow
      await driver.tap(find.text('Add Device'));
      await driver.waitFor(find.text('Add New Device'));
      
      // Fill device form
      await driver.tap(find.byValueKey('device_name_field'));
      await driver.enterText('Test Device');
      
      await driver.tap(find.byValueKey('device_type_dropdown'));
      await driver.tap(find.text('Sensor'));
      
      await driver.tap(find.text('Add Device'));
      
      // Verify success message
      await driver.waitFor(find.text('Device added successfully'));
    });

    test('add new room flow', () async {
      // Navigate back to dashboard
      await driver.tap(find.pageBack());
      await driver.waitFor(find.text('Co-Admin Dashboard'));
      
      // Start add room flow
      await driver.tap(find.text('Add Room'));
      await driver.waitFor(find.text('Add New Room'));
      
      // Fill room form
      await driver.tap(find.byValueKey('room_name_field'));
      await driver.enterText('Test Room');
      
      await driver.tap(find.byValueKey('room_type_dropdown'));
      await driver.tap(find.text('Bedroom'));
      
      await driver.tap(find.text('Add Room'));
      
      // Verify success message
      await driver.waitFor(find.text('Room added successfully'));
    });

    test('verify statistics update', () async {
      // Navigate back to dashboard
      await driver.tap(find.pageBack());
      await driver.waitFor(find.text('Co-Admin Dashboard'));
      
      // Wait for stats to update
      await driver.waitFor(find.text('Active Devices'));
      final devicesCount = await driver.getText(find.byValueKey('devices_count'));
      final roomsCount = await driver.getText(find.byValueKey('rooms_count'));
      
      // Verify counts increased
      expect(int.parse(devicesCount), greaterThan(0));
      expect(int.parse(roomsCount), greaterThan(0));
    });
  });
} 