import 'dart:async';

import 'package:animations/animations.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneforall/banner_ad.dart';
import 'package:oneforall/components/main_container.dart';
import 'package:oneforall/constants.dart';
import 'package:oneforall/functions/quizzes_functions.dart';
import 'package:oneforall/main.dart';
import 'package:oneforall/models/quizzes_models.dart';
import 'package:oneforall/screens/interstitial_screen.dart';
import 'package:provider/provider.dart';
import './flashcardsPlay_screen.dart';
import 'package:just_audio/just_audio.dart';

class QuizzesPlayScreen extends StatefulWidget {
  const QuizzesPlayScreen({super.key, required this.quizSet});
  final QuizSet quizSet;

  @override
  State<QuizzesPlayScreen> createState() => _QuizzesPlayScreenState();
}

class _QuizzesPlayScreenState extends State<QuizzesPlayScreen> {
  bool reversed = false;
  int currentScreen = 0;

  final playScreenKey = GlobalKey<_PlayScreenState>();

  void changeScreen(int screen) {
    setState(() {
      if (screen > currentScreen) {
        reversed = false;
      } else {
        reversed = true;
      }
      currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => currentScreen == 0 ? true : false,
      child: Scaffold(
        body: MainContainer(
            onClose: () {
              if (currentScreen == 0) {
                Navigator.of(context).pop();
              }
              if (currentScreen == 1) {
                showDialog(
                    context: context,
                    builder: (context) => OnCloseDialog(onCloseFunction: () {
                          QuizzesFunctions().refreshQuizzesFromLocal(context.read<AppState>(), true);
                          playScreenKey.currentState!.audioPlayer.stop();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }));
              }
            },
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PageTransitionSwitcher(
                  reverse: reversed,
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation, secondaryAnimation) => SharedAxisTransition(
                    fillColor: Colors.transparent,
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  ),
                  child: currentScreen == 0
                      ? PlayScreenConfirmation(changeScreenFunction: changeScreen)
                      : currentScreen == 1
                          ? PlayScreen(key: playScreenKey, quizSet: widget.quizSet)
                          : const Placeholder(),
                ))),
      ),
    );
  }
}

//* Play screen confirmation screen
class PlayScreenConfirmation extends StatelessWidget {
  const PlayScreenConfirmation({super.key, required this.changeScreenFunction});
  final Function changeScreenFunction;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(builder: (context, c) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Quizzes", style: textTheme.displayLarge!.copyWith(fontStyle: FontStyle.italic)),
          Text("Let's get started.", style: textTheme.displaySmall),
          const SizedBox(height: 100),
          Container(
            width: c.maxWidth * 0.7,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: primaryGradient,
            ),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                onPressed: () {
                  changeScreenFunction(1);
                },
                child: Text(
                  "Start Quiz",
                  style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold),
                )),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: c.maxWidth * 0.7,
            height: 50,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.primaryContainer,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Nevermind",
                  style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold),
                )),
          )
        ],
      );
    });
  }
}

//* Play screen
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.quizSet});
  final QuizSet quizSet;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  @override
  void initState() {
    super.initState();
    initializeVariables();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        elapsedTime++;
      });
    });
    audioPlayer.setAsset("assets/audio/quizAudio.mp3");
    audioPlayer.setLoopMode(LoopMode.one);
    audioPlayer.play();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(context: context, builder: (context) => const ThreeTwoOneGoRibbon(), barrierDismissible: false);
    });
  }

  //* Variables
  late QuizQuestion currentQuestion;
  late QuizSet quizSet;

  int score = 0;
  int correctAnswers = 0;
  int correctStreak = 0;
  int highestStreak = 0;
  int questionsDone = 0;
  int redemptionAmount = 0;
  DateTime startTime = DateTime.now();
  int elapsedTime = 0;
  late Timer timer;

  //* Audio
  final AudioPlayer audioPlayer = AudioPlayer();

  //* Animation
  Tween<double> scoreStatTween = Tween<double>(begin: 0, end: 0);
  Tween<double> scoreStatAddTween = Tween<double>(begin: 1, end: 1);
  int scoreBeingAdded = 0;

  //* Redemption
  QuizSet redemptionSet = QuizSet(title: "Redemption", description: "Redemption", questions: [], settings: {});

  //* Functions
  void initializeVariables() {
    quizSet = widget.quizSet;
    currentQuestion = quizSet.questions[0];
    redemptionSet = QuizSet(title: "Redemption", description: "Redemption", questions: [], settings: quizSet.settings);
  }

  void initializeRedemption() {
    quizSet = redemptionSet;
    currentQuestion = quizSet.questions[0];
    redemptionSet = QuizSet(title: "Redemption", description: "Redemption", questions: [], settings: quizSet.settings);
    redemptionAmount++;
    if (currentQuestion.type == quizTypes.reorder) {
      if (reorderKey.currentState == null) return;
      reorderKey.currentState!.selectedAnswers = List.generate(currentQuestion.answers.length, (index) => -1);
    }

    if (currentQuestion.type == quizTypes.dropdown) {
      if (dropdownKey.currentState == null) return;
      dropdownKey.currentState!.sentence = currentQuestion.question.split("<seperator />");
      dropdownKey.currentState!.selectedAnswers = List.generate(currentQuestion.correctAnswer.length, (index) => 0);
    }
    setState(() {});
    // currentQuestion = quizSet.questions[quizSet.questions.indexOf(currentQuestion) + 1];
  }

  String formatSeconds(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds - (minutes * 60);
    String formattedMinutes = minutes.toString().padLeft(2, "0");
    String formattedSeconds = remainingSeconds.toString().padLeft(2, "0");
    return "$formattedMinutes:$formattedSeconds";
  }

  void doNextQuestionAnimations(int scoreBeingAdded) async {
    if (!mounted) return;
    setState(() {
      this.scoreBeingAdded = scoreBeingAdded;
    });
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      scoreStatAddTween = Tween<double>(begin: 1, end: 0);
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      scoreStatTween = Tween<double>(begin: score.toDouble(), end: score.toDouble() + scoreBeingAdded);
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      scoreStatAddTween = Tween<double>(begin: 0, end: 1);
    });
  }

  final reorderKey = GlobalKey<_ReorderQuestionState>();
  final dropdownKey = GlobalKey<_DropdownQuestionState>();

  void nextQuestion(bool correct, int score, QuizQuestion question) {
    if (!mounted) return;
    //* Check if quiz is finished
    if (quizSet.questions.indexOf(currentQuestion) + 1 > quizSet.questions.length - 1) {
      questionsDone++;
      if (correct) {
        correctAnswers++;
        correctStreak++;
        if (correctStreak > highestStreak) {
          highestStreak = correctStreak;
        }
        //TODO: Have streak affect the score
        this.score += score;
      } else {
        correctStreak = 0;
        redemptionSet.questions.add(question);
      }
      if (redemptionSet.questions.isNotEmpty && redemptionAmount < (int.parse(quizSet.settings["redemptionAmounts"] ?? "0"))) {
        redemptionSequence();

        initializeRedemption();
        return;
      }
      endSequence();
      return;
    }
    questionsDone++;
    if (correct) {
      correctAnswers++;
      correctStreak++;
      this.score += score;
    } else {
      correctStreak = 0;
      this.score += score * (correctStreak / 10.round() + 1).round();
      redemptionSet.questions.add(question);
    }

    currentQuestion = quizSet.questions[quizSet.questions.indexOf(currentQuestion) + 1];
    if (currentQuestion.type == quizTypes.reorder) {
      if (reorderKey.currentState == null) return;
      reorderKey.currentState!.selectedAnswers = List.generate(currentQuestion.answers.length, (index) => -1);
    }
    if (currentQuestion.type == quizTypes.dropdown) {
      if (dropdownKey.currentState == null) return;
      dropdownKey.currentState!.sentence = currentQuestion.question.split("<seperator />");
      dropdownKey.currentState!.selectedAnswers = List.generate(currentQuestion.correctAnswer.length, (index) => 0);
    }
    setState(() {});
  }

  Future<void> redemptionSequence() async {
    showDialog(
        context: context,
        builder: (c) => Container(
              color: Colors.black,
              width: double.infinity,
              child: Center(child: Text("Redemption #$redemptionAmount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 50))),
            ),
        barrierDismissible: false);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pop();
    return;
  }

  Future<void> endSequence() async {
    timer.cancel();
    audioPlayer.stop();
    showDialog(
        context: context,
        builder: (c) => Container(
              color: Colors.black,
              width: double.infinity,
              child: const Center(child: Text("All Done!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 50))),
            ),
        barrierDismissible: false);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => EndScreen(score: this.score, correctAnswers: correctAnswers, totalQuestions: questionsDone, redemptionAmount: redemptionAmount, timeSpent: DateTime.now().difference(startTime), highestStreak: highestStreak)));
  }

  @override
  Widget build(BuildContext context) {
    // var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        //* Statistics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //* Score
            Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder(
                  tween: scoreStatTween,
                  duration: const Duration(milliseconds: 250),
                  builder: (context, double value, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.yellow),
                        const SizedBox(width: 5),
                        Text(value.toInt().toString(), style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 2.5),
                        //* + <score add amount> Score animation. Shows when the score increases, goes from being faded from above, to being faded out to the bottom
                        TweenAnimationBuilder(
                          tween: scoreStatAddTween,
                          duration: const Duration(milliseconds: 250),
                          builder: (context, value, child) {
                            return Opacity(opacity: 1 - value, child: Transform.translate(offset: Offset(0, -value), child: child));
                          },
                          child: Text("+${scoreBeingAdded.toString()}", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                        )
                      ],
                    );
                  }),
            ),
            //* Time Elapsed
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_rounded, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(formatSeconds(elapsedTime), style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            //* Streak
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 5),
                AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: Text(correctStreak.toString(), style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold))),
              ]),
            )
          ],
        ),
        Expanded(
          child: currentQuestion.type == quizTypes.multipleChoice || currentQuestion.type == null
              ? MultipleChoice(
                  question: currentQuestion,
                  nextQuestionFunction: nextQuestion,
                  doAnimationFunction: doNextQuestionAnimations,
                )
              : currentQuestion.type == quizTypes.dropdown
                  ? DropdownQuestion(key: dropdownKey, question: currentQuestion, nextQuestionFunction: nextQuestion, doAnimationFunction: doNextQuestionAnimations)
                  : currentQuestion.type == quizTypes.reorder
                      ? ReorderQuestion(key: reorderKey, question: currentQuestion, nextQuestionFunction: nextQuestion, doAnimationFunction: doNextQuestionAnimations)
                      : const Placeholder(),
        ),
      ],
    );
  }
}

//* Multiple choice question
class MultipleChoice extends StatefulWidget {
  const MultipleChoice({super.key, required this.question, required this.nextQuestionFunction, required this.doAnimationFunction});
  final QuizQuestion question;
  final Function nextQuestionFunction;
  final Function doAnimationFunction;

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  List<int> selectedAnswers = [];
  bool showAnswers = false;
  final AudioPlayer audioPlayer = AudioPlayer();
  void validateAnswer() async {
    int correctAnswers = 0;
    for (var answer in selectedAnswers) {
      if (widget.question.correctAnswer.contains(answer)) {
        correctAnswers++;
      }
    }
    if (correctAnswers == widget.question.correctAnswer.length) {
      await audioPlayer.setAsset("assets/audio/successSound.mp3");
      audioPlayer.play();
    }
    setState(() {
      showAnswers = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    int calculatedScore = calculateScore(correctAnswers, widget.question.correctAnswer.length);
    widget.doAnimationFunction(calculatedScore);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      showAnswers = false;
      selectedAnswers = [];
    });
    widget.nextQuestionFunction(
      (correctAnswers == widget.question.correctAnswer.length),
      calculatedScore,
      widget.question,
    );
  }

  int calculateScore(int correctAnswers, int answersLength) {
    int score = 0;
    if (correctAnswers == answersLength) {
      score = 100;
    } else if (correctAnswers == 0) {
      score = 0;
    } else {
      score = (correctAnswers / answersLength * 100).round();
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    // var textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        //* Question
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 50,
            ),
            Text("Multiple Choice - ${widget.question.correctAnswer.length > 1 ? "Multiple Answers" : "One Answer"}", style: Theme.of(context).textTheme.displaySmall!.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(
              height: 10,
            ),
            //* Question
            Text(
              widget.question.question,
              style: Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        //* Validate answer button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selectedAnswers.isNotEmpty && !showAnswers ? primaryGradient : null,
            border: selectedAnswers.isEmpty || showAnswers ? Border.all(color: theme.onBackground.withOpacity(0.25)) : null,
          ),
          width: double.infinity,
          child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.onBackground,
                disabledForegroundColor: theme.onBackground.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: selectedAnswers.isNotEmpty && !showAnswers ? () => validateAnswer() : null,
              icon: const Icon(Icons.check),
              label: const Text("Validate Answer")),
        ),
        const SizedBox(height: 10),
        //* Choices
        Expanded(
            child: Column(
          children: [
            for (var answer in widget.question.answers) ...[
              Flexible(
                flex: 1,
                child: SizedBox.expand(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      //* Change color based on answer
                      //* If question answer is correct, turn green
                      //* If user answers wrong, turn red
                      //* If answer is not selected, turn default color
                      backgroundColor: !showAnswers
                          ? theme.primaryContainer
                          : showAnswers && widget.question.correctAnswer.contains(widget.question.answers.indexOf(answer))
                              ? Colors.green
                              : showAnswers && !widget.question.correctAnswer.contains(widget.question.answers.indexOf(answer)) && selectedAnswers.contains(widget.question.answers.indexOf(answer))
                                  ? Colors.red
                                  : theme.primaryContainer,

                      foregroundColor: theme.onBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: selectedAnswers.contains(widget.question.answers.indexOf(answer)) ? BorderSide(color: theme.onBackground, width: 2) : const BorderSide(color: Colors.transparent, width: 2),
                    ),
                    onPressed: showAnswers
                        ? () {}
                        : () => setState(() {
                              if (widget.question.correctAnswer.length > 1) {
                                if (selectedAnswers.contains(widget.question.answers.indexOf(answer))) {
                                  selectedAnswers.remove(widget.question.answers.indexOf(answer));
                                } else {
                                  selectedAnswers.add(widget.question.answers.indexOf(answer));
                                }
                              } else {
                                selectedAnswers = [
                                  widget.question.answers.indexOf(answer)
                                ];
                              }
                            }),
                    child: Text(answer),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ],
        )),
      ],
    );
  }
}

//* Dropdown Question
class DropdownQuestion extends StatefulWidget {
  const DropdownQuestion({super.key, required this.question, required this.nextQuestionFunction, required this.doAnimationFunction});
  final QuizQuestion question;
  final Function nextQuestionFunction;
  final Function doAnimationFunction;

  @override
  State<DropdownQuestion> createState() => _DropdownQuestionState();
}

class _DropdownQuestionState extends State<DropdownQuestion> {
  //* Variables
  List<int> selectedAnswers = [];
  List<String> answers = [];
  List<String> sentence = [];
  bool showAnswers = false;
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    //* Initialize variables
    answers = widget.question.answers;
    sentence = widget.question.question.split("<seperator />");
    // ignore: unused_local_variable
    for (var i in widget.question.correctAnswer) {
      selectedAnswers.add(0);
    }
  }

  void validateAnswer() async {
    setState(() {
      showAnswers = true;
    });
    int correctAmount = 0;
    for (int i = 0; i < selectedAnswers.length; i++) {
      if (widget.question.correctAnswer[i] == selectedAnswers[i]) {
        correctAmount++;
      }
    }
    await audioPlayer.setAsset("assets/audio/successSound.mp3");
    audioPlayer.play();
    widget.doAnimationFunction(correctAmount * 100 ~/ widget.question.correctAnswer.length);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showAnswers = false;
        selectedAnswers = [
          for (int i = 0; i < widget.question.correctAnswer.length; i++) 0
        ];
      });
      widget.nextQuestionFunction((correctAmount == widget.question.correctAnswer.length), correctAmount * 100 ~/ widget.question.correctAnswer.length, widget.question);
    });
  }

  int indexOfDropDown(int pos) {
    int index = 0;
    for (int i = 0; i < sentence.length; i++) {
      if (i == pos) return index;
      if (sentence[i].contains("<dropdown answer=")) {
        index++;
      }
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Dropdown", style: textTheme.displaySmall!.copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 20),
        //* Sentence
        Wrap(
          runSpacing: 5,
          spacing: 10,
          children: [
            for (int i = 0; i < sentence.length; i++) ...[
              if (sentence[i].contains("<dropdown answer="))
                //* Dropdown
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    showAnswers ? Text(widget.question.answers[widget.question.correctAnswer[indexOfDropDown(i)]], style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.green)) : const SizedBox(),
                    const SizedBox(
                      height: 5,
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        color: showAnswers ? (widget.question.correctAnswer[indexOfDropDown(i)] == selectedAnswers[indexOfDropDown(i)] ? Colors.green : Colors.red) : theme.primaryContainer,
                      ),
                      child: DropdownButton<int>(
                        value: selectedAnswers[indexOfDropDown(i)],
                        onChanged: showAnswers
                            ? null
                            : (int? value) {
                                setState(() {
                                  selectedAnswers[indexOfDropDown(i)] = value!;
                                });
                              },
                        items: [
                          for (int i = 0; i < widget.question.answers.length; i++) ...[
                            DropdownMenuItem(
                              value: i,
                              child: Text(widget.question.answers[i], style: textTheme.displaySmall),
                            )
                          ]
                        ],
                      ),
                    ),
                  ],
                )
              else
                Text(
                  sentence[i],
                  style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
            ]
          ],
        ),
        const SizedBox(height: 20),
        //* Validate answer button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selectedAnswers.isNotEmpty && !showAnswers ? primaryGradient : null,
            border: selectedAnswers.isEmpty || showAnswers ? Border.all(color: theme.onBackground.withOpacity(0.25)) : null,
          ),
          height: 40,
          child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.onBackground,
                disabledForegroundColor: theme.onBackground.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: selectedAnswers.isNotEmpty && !showAnswers ? () => validateAnswer() : null,
              icon: const Icon(Icons.check),
              label: const Text("Validate Answer")),
        ),
      ],
    );
  }
}

//* Reorder Question
class ReorderQuestion extends StatefulWidget {
  const ReorderQuestion({super.key, required this.question, required this.nextQuestionFunction, required this.doAnimationFunction});
  final QuizQuestion question;
  final Function nextQuestionFunction;
  final Function doAnimationFunction;

  @override
  State<ReorderQuestion> createState() => _ReorderQuestionState();
}

class _ReorderQuestionState extends State<ReorderQuestion> {
  List<int> selectedAnswers = [];
  bool showAnswers = false;
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    selectedAnswers = List.generate(widget.question.correctAnswer.length, (index) => -1);
  }

  void validateAnswers() async {
    setState(() {
      showAnswers = true;
    });
    int correctAnswers = 0;
    for (int i = 0; i < selectedAnswers.length; i++) {
      if (selectedAnswers.length > i && selectedAnswers[i] == widget.question.correctAnswer[i]) {
        correctAnswers++;
      }
    }
    await audioPlayer.setAsset("assets/audio/successSound.mp3");
    audioPlayer.play();
    widget.doAnimationFunction(100 * correctAnswers);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showAnswers = false;
      });
      widget.nextQuestionFunction((correctAnswers == widget.question.correctAnswer.length), 100 * correctAnswers, widget.question);
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Text("Reorder", style: textTheme.displaySmall!.copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(
          height: 10,
        ),
        Text(
          widget.question.question,
          style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 10,
        ),
        //* Validate Answer
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selectedAnswers.isNotEmpty && !showAnswers ? primaryGradient : null,
            border: selectedAnswers.isEmpty || showAnswers ? Border.all(color: theme.onBackground.withOpacity(0.25)) : null,
          ),
          child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.onBackground,
                disabledForegroundColor: theme.onBackground.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: showAnswers || selectedAnswers.contains(-1) ? null : () => validateAnswers(),
              icon: const Icon(Icons.check),
              label: const Text("Validate Answers")),
        ),
        //* Gridvew of answers
        Expanded(
          flex: 1,
          child: Center(
            child: Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                for (var answer in widget.question.answers) ...[
                  Draggable<int>(
                    data: widget.question.answers.indexOf(answer),
                    feedback: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.primaryContainer,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(answer, style: textTheme.displaySmall),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.primaryContainer,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Text(answer, style: textTheme.displaySmall),
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                for (int i = 0; i < widget.question.correctAnswer.length; i++) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      showAnswers
                          ? Text(
                              widget.question.answers[widget.question.correctAnswer[i]],
                              style: textTheme.displaySmall!.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 10),
                      DragTarget<int>(
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: !showAnswers
                                  ? theme.primaryContainer
                                  : widget.question.correctAnswer[i] == selectedAnswers[i]
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: selectedAnswers.length > i && selectedAnswers[i] != -1
                                  ? Text(
                                      widget.question.answers[selectedAnswers[i]],
                                      style: textTheme.displaySmall,
                                    )
                                  : Text("Order #${i + 1}", style: textTheme.displaySmall),
                            ),
                          );
                        },
                        onAccept: (data) {
                          for (var i = 0; i < widget.question.correctAnswer.length - selectedAnswers.length; i++) {
                            //Add missing answers
                            //fuck state
                            selectedAnswers.add(-1);
                          }

                          setState(() {
                            selectedAnswers[i] = data;
                          });
                        },
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EndScreen extends StatefulWidget {
  const EndScreen({super.key, required this.score, required this.correctAnswers, required this.totalQuestions, required this.redemptionAmount, required this.timeSpent, required this.highestStreak});
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int redemptionAmount;
  final Duration timeSpent;
  final int highestStreak;

  @override
  State<EndScreen> createState() => _EndScreenState();
}

class _EndScreenState extends State<EndScreen> with TickerProviderStateMixin {
  List<int> formatDurationToSeperateInts(Duration duration) {
    int minutes = (duration.inSeconds / 60).floor();
    int remainingSeconds = duration.inSeconds - (minutes * 60);
    return [
      minutes,
      remainingSeconds
    ];
  }

  bool continueButtonEnabled = false;

  void onAnimationFinished() async {
    await Future.delayed(const Duration(seconds: 10));
    setState(() {
      continueButtonEnabled = true;
    });
  }

  @override
  void initState() {
    super.initState();
    QuizzesFunctions().refreshQuizzesFromLocal(context.read<AppState>(), true);
    onAnimationFinished();
    //* Notify listeners after build
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: MainContainer(
          onClose: () => null,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Text("Quiz Finished", style: textTheme.displayLarge!.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(
                  height: 50,
                ),
                statisticCard(title: "Score", value: widget.score, context: context, index: 1),
                const SizedBox(
                  height: 10,
                ),
                statisticCard(title: "Total Questions", value: widget.totalQuestions, context: context, index: 2),
                const SizedBox(height: 10),
                statisticCard(title: "Correct Answers", value: widget.correctAnswers, context: context, index: 3),
                const SizedBox(height: 10),
                statisticCard(title: "Highest Streak", value: widget.highestStreak, context: context, index: 4),
                const SizedBox(height: 10),
                statisticCard(title: "Redemption Amount", value: widget.redemptionAmount, context: context, index: 5),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.primaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Time Spent", style: textTheme.displayMedium),
                        //* Score, number adding animation
                        Row(
                          children: [
                            NumberAddingAnimation(value: formatDurationToSeperateInts(widget.timeSpent)[0], context: context, index: 7),
                            Text(":", style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold)),
                            NumberAddingAnimation(value: formatDurationToSeperateInts(widget.timeSpent)[1], context: context, index: 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                    child: Center(
                        child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.primaryContainer,
                    disabledBackgroundColor: Colors.transparent,
                    foregroundColor: theme.onBackground,
                    disabledForegroundColor: theme.onBackground.withOpacity(0.5),
                    side: !continueButtonEnabled ? BorderSide(color: theme.onBackground.withOpacity(0.25)) : null,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  onPressed: continueButtonEnabled ? () => Navigator.of(context).pop() : null,
                  label: const Text("Back"),
                  icon: const Icon(Icons.arrow_back_rounded),
                ))),
              ],
            ),
          )),
    );
  }

  Widget statisticCard({required String title, required int value, required BuildContext context, required int index}) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: textTheme.displayMedium),
            //* Score, number adding animation
            NumberAddingAnimation(value: value, context: context, index: index),
          ],
        ),
      ),
    );
  }
}

class NumberAddingAnimation extends StatefulWidget {
  const NumberAddingAnimation({super.key, required this.value, required this.context, required this.index});
  final int value;
  final BuildContext context;
  final int index;

  @override
  State<NumberAddingAnimation> createState() => _NumberAddingAnimationState();
}

class _NumberAddingAnimationState extends State<NumberAddingAnimation> {
  Tween<double> tween = Tween<double>(begin: 0, end: 0);

  void startAnimation() async {
    await Future.delayed(Duration(milliseconds: 1200 * widget.index));
    setState(() {
      tween = Tween<double>(begin: 0, end: widget.value.toDouble());
    });
  }

  @override
  void initState() {
    super.initState();
    startAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: tween,
      duration: const Duration(milliseconds: 1000),
      builder: (context, double value, child) {
        return Text(value.toInt().toString(), style: Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold));
      },
    );
  }
}

class OnCloseDialog extends StatefulWidget {
  const OnCloseDialog({super.key, required this.onCloseFunction});
  final Function onCloseFunction;

  @override
  State<OnCloseDialog> createState() => _OnCloseDialogState();
}

class _OnCloseDialogState extends State<OnCloseDialog> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var ttheme = Theme.of(context).textTheme;
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.background,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Are you sure you want to quit?", style: ttheme.displayMedium),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.primaryContainer,
                      foregroundColor: theme.onBackground,
                      side: BorderSide(color: theme.onBackground.withOpacity(0.25)),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                    onPressed: () => widget.onCloseFunction(),
                    child: const Text("Quit")),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.primaryContainer,
                      foregroundColor: theme.onBackground,
                      side: BorderSide(color: theme.onBackground.withOpacity(0.25)),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
