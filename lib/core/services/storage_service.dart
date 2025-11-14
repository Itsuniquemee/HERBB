import 'package:hive_flutter/hive_flutter.dart';
import '../models/collection_event.dart';

class StorageService {
  static const String collectionEventsBox = 'collection_events';
  static const String userDataBox = 'user_data';
  static const String cacheBox = 'cache';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    // Register adapters
    Hive.registerAdapter(CollectionEventAdapter());

    // Open boxes
    await Hive.openBox(collectionEventsBox);
    await Hive.openBox(userDataBox);
    await Hive.openBox(cacheBox);
    await Hive.openBox(settingsBox);
  }

  // Collection Events
  static Future<void> saveCollectionEvent(CollectionEvent event) async {
    final box = Hive.box(collectionEventsBox);
    await box.put(event.id, event);
  }

  static List<CollectionEvent> getAllCollectionEvents() {
    final box = Hive.box(collectionEventsBox);
    return box.values.cast<CollectionEvent>().toList();
  }

  static List<CollectionEvent> getUnsyncedEvents() {
    final box = Hive.box(collectionEventsBox);
    return box.values
        .cast<CollectionEvent>()
        .where((event) => !event.isSynced)
        .toList();
  }

  static Future<void> markEventAsSynced(
      String eventId, String blockchainHash) async {
    final box = Hive.box(collectionEventsBox);
    final event = box.get(eventId) as CollectionEvent?;
    if (event != null) {
      event.isSynced = true;
      event.blockchainHash = blockchainHash;
      await event.save();
    }
  }

  static Future<void> deleteCollectionEvent(String eventId) async {
    final box = Hive.box(collectionEventsBox);
    await box.delete(eventId);
  }

  // User Data
  static Future<void> saveUserData(String key, dynamic value) async {
    final box = Hive.box(userDataBox);
    await box.put(key, value);
  }

  static dynamic getUserData(String key) {
    final box = Hive.box(userDataBox);
    return box.get(key);
  }

  // Cache
  static Future<void> cacheData(String key, dynamic value) async {
    final box = Hive.box(cacheBox);
    await box.put(key, {
      'data': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static dynamic getCachedData(String key, {Duration? maxAge}) {
    final box = Hive.box(cacheBox);
    final cached = box.get(key);

    if (cached == null) return null;

    if (maxAge != null) {
      final timestamp = DateTime.parse(cached['timestamp']);
      if (DateTime.now().difference(timestamp) > maxAge) {
        return null;
      }
    }

    return cached['data'];
  }

  // Settings
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBox);
    await box.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await Hive.box(collectionEventsBox).clear();
    await Hive.box(userDataBox).clear();
    await Hive.box(cacheBox).clear();
  }
}
