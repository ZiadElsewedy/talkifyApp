import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talkifyapp/features/Communities/domain/Entites/community_event.dart';
import 'package:talkifyapp/features/Communities/data/repositories/community_repository_impl.dart';
import 'package:talkifyapp/features/Communities/presentation/screens/community_events_page.dart';

class UpcomingEventsWidget extends StatefulWidget {
  final String communityId;
  final String communityName;
  
  const UpcomingEventsWidget({
    Key? key,
    required this.communityId,
    required this.communityName,
  }) : super(key: key);

  @override
  State<UpcomingEventsWidget> createState() => _UpcomingEventsWidgetState();
}

class _UpcomingEventsWidgetState extends State<UpcomingEventsWidget> {
  final CommunityRepositoryImpl _repository = CommunityRepositoryImpl();
  List<CommunityEvent> _events = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    try {
      final events = await _repository.getCommunityEvents(widget.communityId);
      
      // Sort events by start date and filter to only show upcoming events
      final now = DateTime.now();
      final upcomingEvents = events
          .where((event) => event.startDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Show only the next 3 events
      final nextEvents = upcomingEvents.take(3).toList();
      
      if (mounted) {
        setState(() {
          _events = nextEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_events.isEmpty) {
      return const SizedBox(); // Don't show anything if no upcoming events
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityEventsPage(
                          communityId: widget.communityId,
                          communityName: widget.communityName,
                        ),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return _EventCard(event: event);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CommunityEvent event;
  
  const _EventCard({required this.event});
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = event.startDate.day == now.day && 
                    event.startDate.month == now.month && 
                    event.startDate.year == now.year;
    
    final isTomorrow = event.startDate.day == now.add(const Duration(days: 1)).day && 
                       event.startDate.month == now.add(const Duration(days: 1)).month && 
                       event.startDate.year == now.add(const Duration(days: 1)).year;
                       
    final dateText = isToday 
        ? 'Today' 
        : (isTomorrow 
            ? 'Tomorrow' 
            : DateFormat('MMM d').format(event.startDate));
            
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.isOnline ? Icons.videocam : Icons.event,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  dateText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.isOnline)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Online',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              event.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('HH:mm').format(event.startDate)} - ${DateFormat('HH:mm').format(event.endDate)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const Spacer(),
            Text(
              '${event.attendees.length} attending',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 