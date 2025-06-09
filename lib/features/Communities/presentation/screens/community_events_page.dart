import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:talkifyapp/features/Communities/data/models/community_event_model.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community_event.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';
import 'package:talkifyapp/features/auth/Presentation/Cubits/auth_cubit.dart';

class CommunityEventsPage extends StatefulWidget {
  final String communityId;
  final String communityName;
  
  const CommunityEventsPage({
    Key? key,
    required this.communityId,
    required this.communityName,
  }) : super(key: key);

  @override
  State<CommunityEventsPage> createState() => _CommunityEventsPageState();
}

class _CommunityEventsPageState extends State<CommunityEventsPage> {
  final CommunityRepositoryImpl _repository = CommunityRepositoryImpl();
  List<CommunityEvent> _events = [];
  bool _isLoading = true;
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
    _currentUserId = context.read<AuthCubit>().GetCurrentUser()?.id;
  }
  
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final events = await _repository.getCommunityEvents(widget.communityId);
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }
  
  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final meetingLinkController = TextEditingController();
    
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    startDate = DateTime(startDate.year, startDate.month, startDate.day, 10, 0);
    
    DateTime endDate = startDate.add(const Duration(hours: 2));
    bool isOnline = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    const Text('Is Online: '),
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
                ListTile(
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
                const SizedBox(height: 8),
                const Text('End Date & Time'),
                ListTile(
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }
                
                if (_currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be logged in to create events')),
                  );
                  return;
                }
                
                try {
                  // Create new event
                  final event = CommunityEventModel(
                    id: '',
                    communityId: widget.communityId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                    createdBy: _currentUserId!,
                    createdAt: DateTime.now(),
                    location: isOnline ? '' : locationController.text.trim(),
                    isOnline: isOnline,
                    meetingLink: isOnline ? meetingLinkController.text.trim() : '',
                    attendees: [_currentUserId!],
                  );
                  
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
                  
                  // Create event in database
                  await _repository.createEvent(event);
                  
                  // Close loading dialog
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Close create dialog
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Reload events
                  if (mounted) {
                    _loadEvents();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event created successfully')),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create event: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _deleteEvent(CommunityEvent event) async {
    if (_currentUserId == null || _currentUserId != event.createdBy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the creator can delete this event')),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Show loading dialog that can't be dismissed
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button dismissal
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting event...'),
            ],
          ),
        ),
      ),
    );
    
    // Use a retry mechanism
    int maxRetries = 3;
    int currentRetry = 0;
    bool success = false;
    
    while (currentRetry < maxRetries && !success) {
      try {
        // Attempt to delete the event
        await _repository.deleteEvent(event.id);
        success = true;
      } catch (e) {
        print("Delete attempt ${currentRetry + 1} failed: $e");
        currentRetry++;
        
        // Only continue retrying if we haven't reached max retries
        if (currentRetry < maxRetries) {
          // Wait a bit before retrying
          await Future.delayed(Duration(milliseconds: 500 * currentRetry));
        } else {
          if (mounted) {
            // Dismiss the loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            // Show error with retry button
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to delete event after multiple attempts'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _deleteEvent(event),
                  textColor: Colors.white,
                ),
              ),
            );
          }
          return;
        }
      }
    }
    
    // If we got here, the operation was successful
    if (mounted) {
      // Dismiss the loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
      
      // Reload the events to reflect the change
      await _loadEvents();
    }
  }
  
  Future<void> _toggleAttendance(CommunityEvent event) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to join events')),
      );
      return;
    }
    
    final isAttending = event.attendees.contains(_currentUserId);
    final String actionLabel = isAttending ? 'Leaving' : 'Joining';
    final String completeLabel = isAttending ? 'left' : 'joined';
    
    // Show a loading dialog that can't be dismissed
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button dismissal
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('$actionLabel event...'),
            ],
          ),
        ),
      ),
    );
    
    // Use a retry mechanism
    int maxRetries = 3;
    int currentRetry = 0;
    bool success = false;
    
    while (currentRetry < maxRetries && !success) {
      try {
        // Attempt to join/leave the event
        if (isAttending) {
          await _repository.leaveEvent(event.id, _currentUserId!);
        } else {
          await _repository.joinEvent(event.id, _currentUserId!);
        }
        
        success = true;
      } catch (e) {
        print("Attempt ${currentRetry + 1} failed: $e");
        currentRetry++;
        
        // Only continue retrying if we haven't reached max retries
        if (currentRetry < maxRetries) {
          // Wait a bit before retrying
          await Future.delayed(Duration(milliseconds: 500 * currentRetry));
        } else {
          if (mounted) {
            // Dismiss the loading dialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            // Show error with retry button
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to ${isAttending ? 'leave' : 'join'} event after multiple attempts'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _toggleAttendance(event),
                  textColor: Colors.white,
                ),
              ),
            );
          }
          return;
        }
      }
    }
    
    // If we got here, the operation was successful
    if (mounted) {
      // Dismiss the loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have $completeLabel the event')),
      );
      
      // Reload the events to reflect the change
      await _loadEvents();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.communityName} Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 80,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No upcoming events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new event to get started',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final isAttending = event.attendees.contains(_currentUserId);
                    final isCreator = _currentUserId == event.createdBy;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (event.isOnline)
                                  const Chip(
                                    label: Text('Online'),
                                    backgroundColor: Colors.green,
                                    labelStyle: TextStyle(color: Colors.white),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(event.startDate),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat('HH:mm').format(event.startDate)} - ${DateFormat('HH:mm').format(event.endDate)}',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            if (!event.isOnline && event.location.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (event.isOnline && event.meetingLink.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.link, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.meetingLink,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${event.attendees.length} attending',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (isCreator) ...[
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Remove'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => _deleteEvent(event),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isAttending 
                                            ? Colors.red 
                                            : Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _toggleAttendance(event),
                                      child: Text(isAttending ? 'Leave' : 'Join'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createEventFAB',
        onPressed: _showCreateEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 