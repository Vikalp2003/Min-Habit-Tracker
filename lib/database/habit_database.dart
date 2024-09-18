import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:min_habit_tracker/models/app_settings.dart';
import 'package:min_habit_tracker/models/habit.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;

  /*
  S E T U P
  */
  //INITIALIZE - DATABASE

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [HabitSchema, AppSettingsSchema],
      directory: dir.path,
    );
  }

  //Save first date of app startup(heatmap)
  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }
  //Get first date of startup(heatmap)

  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  /*
   C R U D X O P E R A T I O N S
  */

  //LIST OF HABITS
  final List<Habit> currentHabits = [];

  //C R E A T E -ADD NEW HABIT
  Future<void> addhabit(String habitName) async {
    //create a new habit
    final newHabit = Habit()..name = habitName;

    //save the habit into the db
    await isar.writeTxn(() => isar.habits.put(newHabit));

    //re-read habits from db
    readHabits();
  }

  //R E A D - READ SAVED HABIT FROM DB
  Future<void> readHabits() async {
    //fetch all habits from db
    List<Habit> fetchedHabits = await isar.habits.where().findAll();

    //give to current habits
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);

    //update UI
    notifyListeners();
  }

  //U P D A T E - CHEACK HABIT ON AND OFF
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    //find the specific habit
    final habit = await isar.habits.get(id);

    //update completion status
    if (habit != null) {
      await isar.writeTxn(() async {
        //if habit is complleted -> add the current date to the completed dats list
        if (isCompleted && !habit.completedDays.contains(DateTime.now())) {
          //today
          final today = DateTime.now();

          //add the current date if it's not already in the list
          habit.completedDays.add(
            DateTime(
              today.year,
              today.month,
              today.day,
            ),
          );
        }

        //if habit is NOT completed -> remove the current date from the list
        else {
          //remove the current date if habit is marked as not completed
          habit.completedDays.removeWhere(
            (date) =>
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day,
          );
        }
        //save the updated habits back to the db
        await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  //U P D A T E - EDIT HABIT NAME
  Future<void> updateHabitName(int id, String newName) async {
    //find the specific habit
    final habit = await isar.habits.get(id);

    //update habit name
    if (habit != null) {
      //update name
      await isar.writeTxn(() async {
        habit.name = newName;
        //save updated habit back to the db
        await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  //D E L E T E - DELETE HABIT
  Future<void> deleteHabit(int id) async {
    //perform the delete
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });
    //re-read from the db
    readHabits();
  }
}
