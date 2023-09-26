import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:oneforall/banner_ad.dart';
import 'package:oneforall/constants.dart';
import 'package:oneforall/main.dart';
import 'package:provider/provider.dart';
import '../data/user_data.dart';
import 'flashcardsPlay_screen.dart';
import 'flashcards_edit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  String searchQuery = "";
  bool isItemValid(String title) {
    if (title.toLowerCase().contains(searchQuery.toLowerCase())) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    var appState = Provider.of<AppState>(context);
    return Container(
        decoration: appState.currentUserSelectedTheme == defaultBlueTheme ? const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/purpwallpaper 2.png'), fit: BoxFit.cover)) : BoxDecoration(color: appState.currentUserSelectedTheme.colorScheme.background),
        child: SafeArea(
            child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    showDialog(context: context, builder: (context) => const NewSetOptions());
                  },
                  backgroundColor: theme.secondary,
                  child: const Icon(Icons.add),
                ),
                resizeToAvoidBottomInset: false,
                backgroundColor: Colors.transparent,
                body: Column(
                  children: [
                    //App Bar
                    Container(
                      color: theme.secondary,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(
                                Icons.arrow_back,
                                color: theme.onPrimary,
                              ),
                            ),
                            Text(appState.getCurrentUser.username, style: textTheme.displaySmall),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: theme.onPrimary,
                                borderRadius: BorderRadius.circular(20),
                                gradient: getPrimaryGradient,
                              ),
                              child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(15)), child: Image.network(appState.getCurrentUser.profilePicture, fit: BoxFit.cover)),
                            )
                          ],
                        ),
                      ),
                    ),
                    //End of App Bar
                    //Body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Flexible(
                              flex: 3,
                              child: TextField(
                                onChanged: (value) => setState(() {
                                  searchQuery = value;
                                }),
                                keyboardAppearance: Brightness.dark,
                                cursorColor: theme.onPrimary,
                                style: textTheme.displayMedium!.copyWith(color: theme.onPrimary, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: theme.primary,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        width: 0,
                                        style: BorderStyle.none,
                                      ),
                                    ),
                                    hintText: 'Search',
                                    suffixIcon: Icon(Icons.search, color: theme.onPrimary, size: 50),
                                    hintStyle: textTheme.displayMedium!.copyWith(color: theme.onPrimary.withOpacity(0.25), fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Flexible(
                              flex: 10,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text("Library", style: textTheme.displayLarge),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: ListView.builder(
                                        scrollDirection: Axis.vertical,
                                        itemCount: appState.getCurrentUser.flashCardSets.length,
                                        itemBuilder: (context, index) {
                                          return isItemValid(appState.getCurrentUser.flashCardSets[index].title)
                                              ? Padding(
                                                  padding: const EdgeInsets.only(bottom: 8),
                                                  child: Container(
                                                    height: MediaQuery.of(context).size.height * 0.1,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: theme.secondary,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: theme.tertiary,
                                                      ),
                                                    ),
                                                    child: ElevatedButton(
                                                        onPressed: () {
                                                          showDialog(
                                                              context: context,
                                                              builder: (context) => SelectedSetModal(
                                                                    flashcardSet: appState.getCurrentUser.flashCardSets[index],
                                                                    index: index,
                                                                  ));
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          elevation: 0,
                                                          backgroundColor: Colors.transparent,
                                                          shadowColor: Colors.transparent,
                                                          foregroundColor: theme.onPrimary,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                        child: Center(
                                                            child: Text(
                                                          appState.getCurrentUser.flashCardSets[index].title,
                                                          style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold),
                                                        ))),
                                                  ),
                                                )
                                              : Container();
                                        }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ))));
  }
}

class ImportSetModal extends StatefulWidget {
  const ImportSetModal({super.key});

  @override
  State<ImportSetModal> createState() => _ImportSetModalState();
}

class _ImportSetModalState extends State<ImportSetModal> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    // var appState = Provider.of<AppState>(context);
    return Dialog(
      backgroundColor: theme.background,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Import from JSON string", style: textTheme.displayMedium),
            const SizedBox(height: 10),
            //Text Field
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: (value) => setState(() {
                  // titleQuery = value;
                }),
                keyboardAppearance: Brightness.dark,
                cursorColor: theme.onPrimary,
                style: textTheme.displaySmall!.copyWith(color: theme.onPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    filled: true,
                    fillColor: theme.primary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        width: 0,
                        style: BorderStyle.none,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        width: 2,
                        color: theme.onBackground,
                      ),
                    ),
                    hintText: 'JSON String',
                    hintStyle: textTheme.displaySmall!.copyWith(color: theme.onPrimary.withOpacity(0.25), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            //Buttons: Create and Cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary,
                      foregroundColor: theme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Import")),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary,
                      foregroundColor: theme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
              ],
            )
          ])),
    );
  }
}

class NewSetOptions extends StatefulWidget {
  const NewSetOptions({super.key});

  @override
  State<NewSetOptions> createState() => _NewSetOptionsState();
}

class _NewSetOptionsState extends State<NewSetOptions> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    // var appState = Provider.of<AppState>(context);
    return Dialog(
      backgroundColor: theme.background,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            //* Create New
            //Button style: Basically a square with an icon inside, and a text below it
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: theme.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (context) => const NewSetModal());
                    },
                    icon: Icon(Icons.add, color: theme.onBackground),
                    label: Text("Create New", style: textTheme.displaySmall!.copyWith(color: theme.onBackground))),
              ],
            ),
            const SizedBox(height: 16),
            //* Import
            //Button style: Basically a square with an icon inside, and a text below it
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: theme.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {},
                    icon: Icon(Icons.file_copy, color: theme.onBackground),
                    label: Text("Import", style: textTheme.displaySmall!.copyWith(color: theme.onBackground))),
              ],
            ),
            const SizedBox(height: 16),
            //* Generate
            //Button style: Basically a square with an icon inside, and a text below it
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: theme.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (context) => const GenerateFlashcardsModal());
                    },
                    icon: Icon(Icons.smart_toy, color: theme.onBackground),
                    label: Text("Generate", style: textTheme.displaySmall!.copyWith(color: theme.onBackground))),
              ],
            ),
          ])),
    );
  }
}

class GenerateFlashcardsModal extends StatefulWidget {
  const GenerateFlashcardsModal({super.key});

  @override
  State<GenerateFlashcardsModal> createState() => _GenerateFlashcardsModalState();
}

class _GenerateFlashcardsModalState extends State<GenerateFlashcardsModal> {
  int? selectedQuiz = null;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: Container(
        decoration: BoxDecoration(color: theme.background, borderRadius: const BorderRadius.all(Radius.circular(20.0))),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Generate Flashcards", style: textTheme.displayMedium),
            const SizedBox(height: 5),
            Text(
              "Generate from quiz: ",
              style: textTheme.displaySmall,
            ),
            Row(
              children: [
                Text("Select quiz : ", style: textTheme.displaySmall),
                const SizedBox(width: 5),
                DropdownButton<int>(
                    value: selectedQuiz,
                    hint: Text(
                      "Select Quiz",
                      style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    items: [
                      for (int i = 0; i < appState.getQuizzes.length; i++) ...[
                        DropdownMenuItem(value: i, child: Text(appState.getQuizzes[i].title, style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold)))
                      ]
                    ],
                    onChanged: (value) => setState(() {
                          selectedQuiz = value;
                        })),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              height: 40,
              decoration: BoxDecoration(gradient: getPrimaryGradient, borderRadius: const BorderRadius.all(Radius.circular(10))),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0, shadowColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                  onPressed: () {
                    if (selectedQuiz == null) return;
                    //TODO support all question types
                    appState.getCurrentUser.flashCardSets.add(FlashcardSet(id: appState.getCurrentUser.flashCardSets.length + 1, title: appState.getQuizzes[selectedQuiz!].title, description: appState.getQuizzes[selectedQuiz!].description, flashcards: [
                      for (int i = 0; i < appState.getQuizzes[selectedQuiz!].questions.length; i++) ...[
                        Flashcard(id: i, question: appState.getQuizzes[selectedQuiz!].questions[i].type == quizTypes.multipleChoice ? appState.getQuizzes[selectedQuiz!].questions[i].question : "not supported", answer: appState.getQuizzes[selectedQuiz!].questions[i].type == quizTypes.multipleChoice ? List<String>.generate(appState.getQuizzes[selectedQuiz!].questions[i].correctAnswer.length, (index) => appState.getQuizzes[selectedQuiz!].questions[i].answers[index]).join(", ") : "not supported")
                      ]
                    ]));
                  },
                  child: Text("Generate", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold))),
            )
          ],
        ),
      ),
    );
  }
}

class NewSetModal extends StatefulWidget {
  const NewSetModal({super.key});

  @override
  State<NewSetModal> createState() => _NewSetModalState();
}

class _NewSetModalState extends State<NewSetModal> {
  String titleQuery = "";
  bool isLoading = false;
  bool success = false;

  Future createSet(AppState appState) async {
    //* Spam prevention
    if (isLoading || success) {
      return;
    }
    //* Check if the title is empty
    if (titleQuery == "") {
      return;
    }
    //* Set loading to true
    setState(() {
      isLoading = true;
    });
    //* Create the set and add it to shared preferences
    List<FlashcardSet> flashcardSets = [];
    //* Get the flashcard sets from shared prefs
    await SharedPreferences.getInstance().then((value) {
      if (value.containsKey("flashcardSets")) {
        dynamic decodedObject = jsonDecode(value.getString("flashcardSets")!);

        //* Convert the decoded `dynamic` object back to your desired Dart object structure
        for (var set in decodedObject['sets']) {
          flashcardSets.add(FlashcardSet(id: decodedObject['sets'].indexOf(set), title: set["title"], description: "description_unavailable", flashcards: [
            for (var flashcard in set['questions']) Flashcard(id: set['questions'].indexOf(flashcard), question: flashcard['question'], answer: flashcard['answer'])
          ]));
        }
      }
    });
    flashcardSets.add(FlashcardSet(id: flashcardSets.length, flashcards: [], title: titleQuery, description: ""));
    //* Convert flashcard sets to json
    Object flashcardSetsObject = {
      "sets": [
        for (FlashcardSet set in flashcardSets)
          {
            "title": set.title,
            "description": set.description,
            "questions": [
              for (Flashcard flashcard in set.flashcards)
                {
                  "question": flashcard.question,
                  "answer": flashcard.answer
                }
            ]
          }
      ],
    };

    //* Save the data to shared prefs by converting it to json
    await SharedPreferences.getInstance().then((value) async {
      await value.setString("flashcardSets", jsonEncode(flashcardSetsObject));
    });

    //* Add the set to the current user
    appState.addFlashcardSet(FlashcardSet(id: flashcardSets.length, flashcards: [], title: titleQuery, description: ""));

    //* Rebuild
    setState(() {});

    //* Set loading to false
    setState(() {
      isLoading = false;
      success = true;
    });
    //ignore: user_build_context_synchronously, use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Dialog(
        child: Container(
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text("New Set", style: textTheme.displayLarge),
                const Divider(),
                const SizedBox(height: 10),
                //Title Text Field
                SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (value) => setState(() {
                      titleQuery = value;
                    }),
                    keyboardAppearance: Brightness.dark,
                    cursorColor: theme.onPrimary,
                    style: textTheme.displaySmall!.copyWith(color: theme.onPrimary, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(0),
                        filled: true,
                        fillColor: theme.primary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            width: 2,
                            color: theme.onBackground,
                          ),
                        ),
                        hintText: 'Title',
                        hintStyle: textTheme.displaySmall!.copyWith(color: theme.onPrimary.withOpacity(0.25), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                //How to use
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: theme.onPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text("How to use", style: textTheme.displaySmall),
                  ],
                ),
                const SizedBox(height: 10),
                //How to use text
                Text("You may put as much question as you will, each flashcard set are stored locally (CACHED!). Each set represents one collection of cards. For each card you encounter you must think of the answer in your head, and then flip the card by tapping it, revealing the answer. You then must choose the following buttons depending on your performance on the question (The buttons mentioned are the 100% knew it, 50% some, 0% didn’t know). Each question has a weight, depending on your performance on the question, the weight can go down and up. In which if it goes up it will show more frequently per as if it goes down it will show less frequently. For more information, look at the *docs*", style: textTheme.displaySmall),
                const SizedBox(height: 10),
                //Buttons: Create and Cancel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondary,
                          foregroundColor: theme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          createSet(context.read<AppState>());
                        },
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : success
                                ? const Icon(Icons.check)
                                : const Text("Create")),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondary,
                          foregroundColor: theme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")),
                  ],
                )
              ]),
            )));
  }
}

class SelectedSetModal extends StatelessWidget {
  const SelectedSetModal({super.key, required this.flashcardSet, required this.index});
  final FlashcardSet flashcardSet;
  final int index;
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //Top
              Column(
                children: [
                  Text(flashcardSet.title, style: textTheme.displayLarge),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  //Middle
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Number of questions", style: textTheme.displaySmall),
                        Text(flashcardSet.flashcards.length.toString(), style: textTheme.displaySmall)
                      ]),
                    ),
                  ),
                ],
              ),
              //Bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        foregroundColor: theme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return FlashcardsPlayScreen(flashcardsSet: flashcardSet);
                        }));
                      },
                      child: const Text("Open")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        foregroundColor: theme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) {
                            return FlashcardsEditScreen(
                                //Index is the index of the set in the user list of sets
                                setIndex: index);
                          })),
                      child: const Text("Edit")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        foregroundColor: theme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
