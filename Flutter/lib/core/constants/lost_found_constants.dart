/// Labels and enums mirrored from biu-lost-found `constants.ts`.
abstract final class LostFoundConstants {
  static const Map<String, String> typeLabel = {
    'LOST': 'Lost',
    'FOUND': 'Found',
  };

  static const Map<String, String> statusLabel = {
    'OPEN': 'Open',
    'RESOLVED': 'Resolved',
    'CLOSED': 'Closed',
  };

  static const Map<String, String> categoryLabel = {
    'ELECTRONICS': 'Electronics & tech',
    'DOCUMENTS': 'Documents & ID',
    'KEYS': 'Keys & access cards',
    'CLOTHING': 'Clothing & wearables',
    'BOOKS': 'Books & notes',
    'ACCESSORIES': 'Accessories & jewelry',
    'SPORTS': 'Sports & recreation',
    'STATIONERY': 'Stationery & supplies',
    'BAGS': 'Bags & luggage',
    'OTHER': 'Other',
  };

  static const List<String> categories = [
    'ELECTRONICS',
    'DOCUMENTS',
    'KEYS',
    'CLOTHING',
    'BOOKS',
    'ACCESSORIES',
    'SPORTS',
    'STATIONERY',
    'BAGS',
    'OTHER',
  ];

  static const List<String> campusBuildings = [
    'Main Block A (Administration & Classes)',
    'Main Block B (Faculty of Business)',
    'Library & Learning Center',
    'IT & Innovation Lab',
    'Engineering & Tech Building',
    'Science & Language Block',
    'Student Center & Cafeteria',
    'Dormitory East (Student Housing)',
    'Dormitory West (Student Housing)',
    'Sports Complex & Gymnasium',
  ];

  static const Map<String, String> foundDispositionLabel = {
    'STILL_HAVE': 'I still have it',
    'SUBMITTED_SECURITY': 'Submitted to security',
    'LEFT_WHERE_FOUND': 'Left where found',
  };

  static const List<String> foundDispositions = [
    'STILL_HAVE',
    'SUBMITTED_SECURITY',
    'LEFT_WHERE_FOUND',
  ];
}
