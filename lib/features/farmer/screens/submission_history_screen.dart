import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/collection_provider.dart';
import '../widgets/submission_card.dart';

class SubmissionHistoryScreen extends StatelessWidget {
  const SubmissionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final collectionProvider = context.watch<CollectionProvider>();

    final allEvents = collectionProvider.events;
    final syncedEvents = collectionProvider.syncedEvents;
    final unsyncedEvents = collectionProvider.unsyncedEvents;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localeProvider.translate('submissions')),
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(
                  text: localeProvider.isHindi
                      ? 'सभी'
                      : 'All (${allEvents.length})'),
              Tab(
                  text: localeProvider.isHindi
                      ? 'सिंक किया गया'
                      : 'Synced (${syncedEvents.length})'),
              Tab(
                  text: localeProvider.isHindi
                      ? 'लंबित'
                      : 'Pending (${unsyncedEvents.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEventList(allEvents, localeProvider),
            _buildEventList(syncedEvents, localeProvider),
            _buildEventList(unsyncedEvents, localeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List events, LocaleProvider localeProvider) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              localeProvider.isHindi ? 'कोई सबमिशन नहीं' : 'No submissions',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic here
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return SubmissionCard(
            event: events[index],
            localeProvider: localeProvider,
          );
        },
      ),
    );
  }
}
