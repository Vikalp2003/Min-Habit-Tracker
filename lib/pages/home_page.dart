import 'package:flutter/material.dart';
import 'package:min_habit_tracker/components/my_drawer.dart';
import 'package:min_habit_tracker/components/my_habit_tile.dart';
import 'package:min_habit_tracker/components/my_heat_map.dart';
import 'package:min_habit_tracker/database/habit_database.dart';
import 'package:min_habit_tracker/models/habit.dart';
import 'package:min_habit_tracker/util/habit_util.dart';
import 'package:provider/provider.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    Provider.of<HabitDatabase>(context, listen: false).readHabits();
    super.initState();
  }

  //text controller
  final TextEditingController textController = TextEditingController();

  void createNewHabit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: "Create a new habit"),
        ),
        actions: [
          //save button
          MaterialButton(
            onPressed: () {
              //get the nenw habit name
              String newHabitName = textController.text;
              //save to db
              context.read<HabitDatabase>().addhabit(newHabitName);
              //pop box
              Navigator.pop(context);

              //clear controller
              textController.clear();
            },
            child: const Text("Save"),
          ),
          MaterialButton(onPressed: () {
            //pop box
            Navigator.pop(context);
            //clear controller
            textController.clear();
          })
        ],
      ),
    );
  }

  void checkHabitOnOff(bool? value, Habit habit) {
    //update habit copletion status
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  //edit habit box
  void editHabitBox(Habit habit) {
    //set the controller's text to the habits's current name
    textController.text = habit.name;
    showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              content: TextField(
                controller: textController,
              ),
              actions: [
                //save button
                MaterialButton(
                  onPressed: () {
                    //get the nenw habit name
                    String newHabitName = textController.text;
                    //save to db
                    context
                        .read<HabitDatabase>()
                        .updateHabitName(habit.id, newHabitName);
                    //pop box
                    Navigator.pop(context);

                    //clear controller
                    textController.clear();
                  },
                  child: const Text("Save"),
                ),
                MaterialButton(onPressed: () {
                  //pop box
                  Navigator.pop(context);
                  //clear controller
                  textController.clear();
                })
                //cancel button
              ],
            )));
  }

  // delete habit box
  void deleteHabitbox(Habit habit) {
    showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              title: const Text("Are you sure ou want to delete?"),
              actions: [
                //delete button
                MaterialButton(
                  onPressed: () {
                    //save to db
                    context.read<HabitDatabase>().deleteHabit(habit.id);
                    //pop box
                    Navigator.pop(context);
                  },
                  child: const Text("Delete"),
                ),
                MaterialButton(onPressed: () {
                  //pop box
                  Navigator.pop(context);
                })
                //cancel button
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          //H E A T M A P
          _buildHeatMap(),

          //H A B B I T L I S T
          _buildHabitList(),
        ],
      ),
    );
  }

  //build heat map

  Widget _buildHeatMap() {
    //habit database
    final habitDatabase = context.watch<HabitDatabase>();

    //current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;

    //return heat map UI
    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (contex, snapshot) {
        //once data is available -> build heatmap
        if (snapshot.hasData) {
          return MyHeatMap(datasets: prepHeatMapDataset(currentHabits), startDate: snapshot.data!);
        }
        //handle case where no data is return
        else {
          return Container();
        }
      },
    );
  }

  Widget _buildHabitList() {
    final habitDatabase = context.watch<HabitDatabase>();

    //current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;

    //return list of habit UI
    return ListView.builder(
      itemCount: currentHabits.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        //get each individual habit
        final habit = currentHabits[index];

        //checl if habit is completed today
        bool isCompletedToday = isHabitCompletedToday(habit.completedDays);

        //return habit title ui
        return MyHabitTile(
          text: habit.name,
          isCompleted: isCompletedToday,
          onChanged: (value) => checkHabitOnOff(value, habit),
          editHabit: (context) => editHabitBox(habit),
          deleteHabit: (context) => deleteHabitbox(habit),
        );
      },
    );
  }
}
