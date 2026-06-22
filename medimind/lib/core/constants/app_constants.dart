class AppConstants {
  // API
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String claudeModel = 'claude-sonnet-4-6';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String schedulesCollection = 'schedules';
  static const String remindersCollection = 'reminders';

  // Storage paths
  static const String symptomsImagesPath = 'symptom_images';

  // Notification channels
  static const String medicineChannelId = 'medicine_reminders';
  static const String medicineChannelName = 'Medicine Reminders';
  static const String medicineChannelDesc = 'Reminders for taking your medicines';

  // Duration options
  static const List<int> durationOptions = [1, 2, 3, 5, 7, 10, 14, 30];

  // Timing options
  static const Map<String, String> timingDefaults = {
    'Morning': '08:00 AM',
    'Afternoon': '02:00 PM',
    'Night': '08:00 PM',
  };

  // Session status
  static const String statusCompleted = 'Completed';
  static const String statusActive = 'Active';
  static const String statusPending = 'Pending';

  // Reminder status
  static const String reminderUpcoming = 'Upcoming';
  static const String reminderTaken = 'Taken';
  static const String reminderMissed = 'Missed';
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String symptomInput = '/symptom-input';
  static const String analysisResult = '/analysis-result';
  static const String setSchedule = '/set-schedule';
  static const String reminders = '/reminders';
  static const String history = '/history';
  static const String historyDetail = '/history-detail';
  static const String profile = '/profile';
}

class AppStrings {
  static const String appName = 'MediMind';
  static const String tagline = 'Your AI Health Companion';
  static const String analyzeBtn = 'Analyze Symptoms';
  static const String saveScheduleBtn = 'Save Schedule';
  static const String setScheduleBtn = 'Set Schedule';
  static const String saveToHistory = 'Save to History';
  static const String viewAll = 'View all';
  static const String viewAllSchedules = 'View All Schedules';
  static const String describeSymptoms = 'Describe your symptoms';
  static const String recentHistory = 'Recent History';
  static const String likelyCondition = 'Likely Condition';
  static const String recommendedMedicines = 'Recommended Medicines';
  static const String generalAdvice = 'General Advice';
  static const String selectTime = 'Select Time';
  static const String duration = 'Duration';
  static const String todaysReminders = "Today's Reminders";
}