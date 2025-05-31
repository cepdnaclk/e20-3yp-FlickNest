import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../../../lib/features/rooms/presentation/pages/rooms.page.dart';
import '../../../../../lib/Firebase/switchModel.dart';
import '../../../../../lib/Firebase/deviceService.dart';
import 'rooms_page_test.mocks.dart';

@GenerateMocks([SwitchService, DeviceService])
void main() {
  late MockSwitchService mockSwitchService;
  late MockDeviceService mockDeviceService;

  setUp(() {
    mockSwitchService = MockSwitchService();
    mockDeviceService = MockDeviceService();
  });

  testWidgets('RoomsPage shows loading state initially', (WidgetTester tester) async {
    // Arrange
    when(mockSwitchService.getDevicesByRoomStream()).thenAnswer(
      (_) => Stream.value({
        "unassigned": {
          "name": "Unassigned",
          "devices": {},
        }
      }),
    );

    when(mockDeviceService.getAvailableSymbols()).thenAnswer(
      (_) => Future.value([]),
    );

    when(mockDeviceService.getSymbolsStream()).thenAnswer(
      (_) => Stream.value({}),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: RoomsPage(
          switchService: mockSwitchService,
          deviceService: mockDeviceService,
        ),
      ),
    );

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('RoomsPage displays devices correctly', (WidgetTester tester) async {
    // Arrange
    final mockDevicesData = {
      "room1": {
        "name": "Living Room",
        "devices": {
          "device1": {
            "name": "Light 1",
            "state": false,
            "assignedSymbol": "symbol1"
          }
        }
      },
      "unassigned": {
        "name": "Unassigned",
        "devices": {}
      }
    };

    when(mockSwitchService.getDevicesByRoomStream()).thenAnswer(
      (_) => Stream.value(mockDevicesData),
    );

    when(mockDeviceService.getAvailableSymbols()).thenAnswer(
      (_) => Future.value([
        {"id": "symbol1", "name": "Light Symbol"}
      ]),
    );

    when(mockDeviceService.getSymbolsStream()).thenAnswer(
      (_) => Stream.value({
        "symbol1": {"state": false}
      }),
    );

    when(mockDeviceService.getSymbolName("symbol1")).thenAnswer(
      (_) => Future.value("Light Symbol"),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: RoomsPage(
          switchService: mockSwitchService,
          deviceService: mockDeviceService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text("Living Room"), findsOneWidget);
    expect(find.text("Light 1"), findsOneWidget);
  });

  testWidgets('Device state toggle works correctly', (WidgetTester tester) async {
    // Arrange
    final mockDevicesData = {
      "room1": {
        "name": "Living Room",
        "devices": {
          "device1": {
            "name": "Light 1",
            "state": false,
            "assignedSymbol": "symbol1"
          }
        }
      }
    };

    when(mockSwitchService.getDevicesByRoomStream()).thenAnswer(
      (_) => Stream.value(mockDevicesData),
    );

    when(mockDeviceService.getAvailableSymbols()).thenAnswer(
      (_) => Future.value([
        {"id": "symbol1", "name": "Light Symbol"}
      ]),
    );

    when(mockDeviceService.getSymbolsStream()).thenAnswer(
      (_) => Stream.value({
        "symbol1": {"state": false}
      }),
    );

    when(mockDeviceService.getSymbolName("symbol1")).thenAnswer(
      (_) => Future.value("Light Symbol"),
    );

    when(mockSwitchService.updateDeviceState("device1", true)).thenAnswer(
      (_) => Future.value(),
    );

    when(mockDeviceService.updateSymbolState("symbol1", true)).thenAnswer(
      (_) => Future.value(),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: RoomsPage(
          switchService: mockSwitchService,
          deviceService: mockDeviceService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap the switch
    final switchFinder = find.byType(Switch);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify
    verify(mockSwitchService.updateDeviceState("device1", true)).called(1);
    verify(mockDeviceService.updateSymbolState("symbol1", true)).called(1);
  });

  testWidgets('Device room assignment works correctly', (WidgetTester tester) async {
    // Arrange
    final mockDevicesData = {
      "unassigned": {
        "name": "Unassigned",
        "devices": {
          "device1": {
            "name": "Light 1",
            "state": false,
            "assignedSymbol": "symbol1"
          }
        }
      },
      "room1": {
        "name": "Living Room",
        "devices": {}
      }
    };

    when(mockSwitchService.getDevicesByRoomStream()).thenAnswer(
      (_) => Stream.value(mockDevicesData),
    );

    when(mockDeviceService.getAvailableSymbols()).thenAnswer(
      (_) => Future.value([
        {"id": "symbol1", "name": "Light Symbol"}
      ]),
    );

    when(mockDeviceService.getSymbolsStream()).thenAnswer(
      (_) => Stream.value({
        "symbol1": {"state": false}
      }),
    );

    when(mockDeviceService.getSymbolName("symbol1")).thenAnswer(
      (_) => Future.value("Light Symbol"),
    );

    when(mockSwitchService.assignDeviceToRoom("device1", "room1")).thenAnswer(
      (_) => Future.value(),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: RoomsPage(
          switchService: mockSwitchService,
          deviceService: mockDeviceService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open assign dialog
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Select room from dropdown
    await tester.tap(find.text("Select Room"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Living Room").last);
    await tester.pumpAndSettle();

    // Tap assign button
    await tester.tap(find.text("Assign"));
    await tester.pumpAndSettle();

    // Verify
    verify(mockSwitchService.assignDeviceToRoom("device1", "room1")).called(1);
  });
} 