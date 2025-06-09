import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talkifyapp/features/Communities/data/models/community_event_model.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';

class EventCreationForm extends StatefulWidget {
  final String communityId;
  final String userId;
  final Function onEventCreated;

  const EventCreationForm({
    Key? key,
    required this.communityId,
    required this.userId,
    required this.onEventCreated,
  }) : super(key: key);

  @override
  State<EventCreationForm> createState() => _EventCreationFormState();
}

class _EventCreationFormState extends State<EventCreationForm> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final meetingLinkController = TextEditingController();
  final CommunityRepositoryImpl _repository = CommunityRepositoryImpl();
  
  late DateTime startDate;
  late DateTime endDate;
  bool isOnline = false;
  bool enableReminder = false;
  String reminderTime = '15m'; // Default reminder time
  
  @override
  void initState() {
    super.initState();
    // Set default start date to tomorrow at 10 AM
    startDate = DateTime.now().add(const Duration(days: 1));
    startDate = DateTime(startDate.year, startDate.month, startDate.day, 10, 0);
    
    // Set default end date to 2 hours after start date
    endDate = startDate.add(const Duration(hours: 2));
  }
  
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    meetingLinkController.dispose();
    super.dispose();
  }
  
  Future<void> _createEvent() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating event...'),
          ],
        ),
      ),
    );
    
    try {
      // Create new event
      final event = CommunityEventModel(
        id: '',
        communityId: widget.communityId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        startDate: startDate,
        endDate: endDate,
        createdBy: widget.userId,
        createdAt: DateTime.now(),
        location: isOnline ? '' : locationController.text.trim(),
        isOnline: isOnline,
        meetingLink: isOnline ? meetingLinkController.text.trim() : '',
        attendees: [widget.userId],
      );
      
      // Create event in database
      final createdEvent = await _repository.createEvent(event);
      
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Close the form
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Call the callback
      widget.onEventCreated();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Event',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Is Online:'),
                const SizedBox(width: 8),
                Switch(
                  value: isOnline,
                  onChanged: (value) {
                    setState(() {
                      isOnline = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isOnline)
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              )
            else
              TextField(
                controller: meetingLinkController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Start Date & Time'),
            Card(
              child: ListTile(
                title: Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(startDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startDate),
                    );
                    
                    if (time != null && mounted) {
                      setState(() {
                        startDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        
                        // Ensure end date is after start date
                        if (endDate.isBefore(startDate)) {
                          endDate = startDate.add(const Duration(hours: 2));
                        }
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text('End Date & Time'),
            Card(
              child: ListTile(
                title: Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(endDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(endDate),
                    );
                    
                    if (time != null && mounted) {
                      setState(() {
                        endDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // Reminder option
            Row(
              children: [
                const Text('Set Reminder:'),
                const SizedBox(width: 8),
                Switch(
                  value: enableReminder,
                  onChanged: (value) {
                    setState(() {
                      enableReminder = value;
                    });
                  },
                ),
              ],
            ),
            if (enableReminder) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Reminder Time',
                  border: OutlineInputBorder(),
                ),
                value: reminderTime,
                items: const [
                  DropdownMenuItem(value: '15m', child: Text('15 minutes before')),
                  DropdownMenuItem(value: '1h', child: Text('1 hour before')),
                  DropdownMenuItem(value: '1d', child: Text('1 day before')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      reminderTime = value;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _createEvent,
                child: const Text('Create Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}