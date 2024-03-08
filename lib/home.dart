import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Event? _event;
  late final DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar> _calendars = [];
  Calendar _calendar = Calendar();
  String? eventId;
  DateTime get nowDate => DateTime.now();
  TZDateTime? _startDate;
  TimeOfDay? startTime;
  TZDateTime? _endDate;
  TimeOfDay? endTime;
  String _timezone = 'Etc/UTC';

  Future<void> getCurrentLocation() async {
    try {
      tz.initializeTimeZones();
      _timezone = await FlutterTimezone.getLocalTimezone();
      print('local time zone: $_timezone');
      //   print(' timeZoneDatabase zone: ${timeZoneDatabase.locations}');
      Location currentLocation = timeZoneDatabase.locations.entries
          .firstWhere(
              (element) => element.key.toLowerCase() == _timezone.toLowerCase())
          .value;

      print('currentLocation: $currentLocation');
      print('calendar id: ${_calendar.id}');
      setState(() {
        _event = Event(_calendar.id);
        // this is an example how to set the startDate and endDate
        _startDate = TZDateTime(
          currentLocation,
          DateTime.now()
              .year, // take year from the eventDate of eventCommunicate function
          DateTime.now()
              .month, // take month from the eventDate of eventCommunicate function
          14, // take day from the eventDate of eventCommunicate function
          10, // take hour from the startTime of eventCommunicate function
          20, // take minute from the startTime of eventCommunicate function
        );
        _endDate = TZDateTime(
            currentLocation,
            DateTime.now()
                .year, // take year from the eventDate of eventCommunicate function
            DateTime.now()
                .month, // take month from the eventDate of eventCommunicate function
            14, // // take day from the eventDate of eventCommunicate function
            11, // take hour from the endTime of eventCommunicate function
            45 // // take minute from the endTime of eventCommunicate function
            );
      });
    } catch (e) {
      debugPrint('Could not get the local timezone');
    }
    // _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  List<Calendar> get _writableCalendars =>
      _calendars.where((c) => c.isReadOnly == false).toList();

  Future<void> _retrieveCalendars() async {
    print('inside retrieve calendars');
    _deviceCalendarPlugin = DeviceCalendarPlugin();
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      print('permissionsGranted success: ${permissionsGranted.isSuccess}');
      print('permissionsGranted data: ${permissionsGranted.data}');
      if (permissionsGranted.isSuccess &&
          (permissionsGranted.data == null ||
              permissionsGranted.data == false)) {
        print('requesting permit: ');
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess ||
            permissionsGranted.data == null ||
            permissionsGranted.data == false) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      //  print('calendarsResult: $calendarsResult');
      setState(() {
        _calendars = calendarsResult.data as List<Calendar>;
        _calendar = _writableCalendars[0];
      });
      // _calendars.forEach((element) {
      //   print('calendar id: ${element.id}');
      //   print('calendar name: ${element.name}');
      // });
    } on PlatformException catch (e, s) {
      debugPrint('RETRIEVE_CALENDARS: $e, $s');
    }
  }

  @override
  void initState() {
    // getCurrentLocation();
    _retrieveCalendars().then((value) => getCurrentLocation());
    // getCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // print('calendar list: $_calendars');
    String? dateTimeToDisplay =
        DateTime(nowDate.year, nowDate.month, nowDate.day + 6).toString();
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$dateTimeToDisplay'),
          ElevatedButton(
              onPressed: () async {
                List<Reminder> _reminders = [];
                //Availability _availability = Availability.Busy;
                _reminders.add(Reminder(minutes: 50));
                // _event?.start = TZDateTime(Location(nowDate.timeZoneName), year)
                // _event?.calendarId = _calendar.id;
                _event?.title = 'this is our test title 21xx';
                _event?.description = 'this will be location';
                // _event?.eventId = '600';
                // _event?.eventId =
                //     '2050B8A4-502B-4A25-A33B-AECF4C16E2A6:4A69B204-4BB5-4050-ADCA-457829FDF138';
                //_event?.availability = _availability;
                _event?.reminders = _reminders;
                _event?.start = _startDate;
                _event?.end = _endDate;
                // _event.sta
                print('event to send calendarId: ${_event?.title}');
                print('event to send calendarId: ${_event?.calendarId}');
                print('event to send eventId: ${_event?.eventId}');
                print('event to send availability: ${_event?.availability}');
                print('event to send reminders: ${_event?.reminders}');
                print('event to send date start: ${_event?.start}');
                print('event to end date end: ${_event?.end}');
                // return;
                if (_event?.eventId != null) {
                  print('this is delete event first');
                  _deviceCalendarPlugin
                      .deleteEvent(_event?.calendarId, _event?.eventId)
                      .then((value) async {
                    if (value.isSuccess) {
                      print('this is in new event after delete event');
                      _event?.eventId = null;
                      createEvent(_event);
                    }
                  });
                } else {
                  print('this is in new event');
                  createEvent(_event);
                }
              },
              child: Text('create event'))
        ],
      ),
    );
  }

  Future<void> createEvent(Event? event) async {
    var createEventResult =
        await _deviceCalendarPlugin.createOrUpdateEvent(event);

    if (createEventResult?.isSuccess == true) {
      print('create event response: ${createEventResult?.data}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(createEventResult?.errors
              .map((err) => '[${err.errorCode}] ${err.errorMessage}')
              .join(' | ') as String)));
    }
  }

  Future<String> eventCommunicate(
      {String? eventId,
      String? title,
      String? description,
      int? reminderMinutes,
      DateTime? eventDate,
      TimeOfDay? startTime,
      TimeOfDay? endTime}) async {
    return 'add/update success';
  }
}
