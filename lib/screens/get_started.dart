import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneforall/components/animations/fade_in_transition.dart';
import 'package:oneforall/main.dart';
import 'package:oneforall/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../data/user_data.dart';
import '../models/quizzes_models.dart';
import '../service/auth_service.dart';
import 'package:email_validator/email_validator.dart';
import '../service/community_service.dart';
import 'package:animations/animations.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  String emailQuery = "";
  String passwordQuery = "";
  String error = "";
  int currentStep = 0;
  //0 = welcome
  //1 = account creation
  //2 = join a school or a community
  //3 = settings configuration

  void changeCurrentStep(int value) {
    setState(() {
      currentStep = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/logbg.png'), fit: BoxFit.cover)),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: PageTransitionSwitcher(
                transitionBuilder: (child, animation, secondaryAnimation) {
                  return SharedAxisTransition(
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Colors.transparent,
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                child: currentStep == 0
                    ? WelcomeScreen(
                        textTheme: textTheme,
                        changeCurrentStep: changeCurrentStep,
                      )
                    : currentStep == 1
                        ? AccountCreationScreen(
                            theme: theme,
                            textTheme: textTheme,
                            changeStep: changeCurrentStep,
                          )
                        : currentStep == 2
                            ? JoinCommunityScreen(
                                changeStep: changeCurrentStep,
                              )
                            : const SettingsConfigurationScreen(),
              ),
            ),
          ),
        ));
  }
}

class SettingsConfigurationScreen extends StatefulWidget {
  const SettingsConfigurationScreen({super.key});

  @override
  State<SettingsConfigurationScreen> createState() => _SettingsConfigurationScreenState();
}

class _SettingsConfigurationScreenState extends State<SettingsConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return SafeArea(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Row(children: [
              Text("3. Configure your settings.", style: textTheme.displayMedium)
            ]),
            const SizedBox(height: 50),
            Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.tertiary, width: 1), color: theme.primary),
                child: Center(
                  child: Text("Currently unavailable cuz im too lazy to code it in rn :P You can configure settings later in the settings after setup is complete.", style: textTheme.displaySmall),
                )),
          ],
        ),
        //* Done button
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(gradient: defaultBluePrimaryGradient, borderRadius: BorderRadius.all(Radius.circular(100))),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, padding: const EdgeInsets.all(0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Text("Done", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        )
      ],
    ));
  }
}

class JoinCommunityScreen extends StatefulWidget {
  const JoinCommunityScreen({super.key, required this.changeStep});
  final Function changeStep;

  @override
  State<JoinCommunityScreen> createState() => _JoinCommunityScreenState();
}

class _JoinCommunityScreenState extends State<JoinCommunityScreen> {
  String error = "";
  bool isLoading = false;
  bool success = false;
  bool isSearchingCommunity = false;
  bool isSearchingCommunitySuccess = false;
  String getCommunityError = "";
  String communityIDQuery = "";
  String passwordQuery = "";
  var communityData;

  Future<void> getCommunityWithValidation() async {
    //* Anti spam protection
    if (isSearchingCommunity) {
      return;
    }
    //* Reset error and loading
    setState(() {
      getCommunityError = "";
      isSearchingCommunity = true;
      isSearchingCommunitySuccess = false;
    });
    //* Form validation
    if (communityIDQuery == "") {
      setState(() {
        getCommunityError = "Please fill in all fields.";
        isSearchingCommunity = false;
      });
      return;
    }
    //* Get community
    await getCommunity(communityIDQuery)
        .then((value) => setState(
              () {
                communityData = value;
                debugPrint(value.toString());
              },
            ))
        .catchError((error, stackTrace) => {
              setState(() {
                getCommunityError = error.toString();
                isSearchingCommunity = false;
              }),
              debugPrint("Community not found"),
            });

    if (getCommunityError != "") {
      return;
    }

    debugPrint(communityData.toString());

    setState(() {
      isSearchingCommunitySuccess = true;
      isSearchingCommunity = false;
    });
    return;
  }

  Future<void> joinCommunityWithValidation() async {
    //* Anti spam protection
    if (isLoading) {
      return;
    }
    //* Reset error and loading
    setState(() {
      error = "";
      isLoading = true;
    });
    //* Form validation
    if (communityIDQuery == "" || passwordQuery == "") {
      setState(() {
        error = "Please fill in all fields.";
        isLoading = false;
      });
      return;
    }
    //* Join community
    joinCommunity(communityIDQuery, passwordQuery).then((value) => debugPrint("Joined community")).catchError((error, stackTrace) => setState(() {
          this.error = error.toString();
          isLoading = false;
        }));

    if (error != "") {
      return;
    }

    //TODO go to page 3
    //* Success
    setState(() {
      success = true;
      isLoading = false;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(children: [
        Row(
          children: [
            Text("2. Join a school or a community", style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w400)),
          ],
        ),
        const SizedBox(height: 50),
        //* Search bar
        LayoutBuilder(builder: (context, c) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 40,
                width: c.maxWidth * 0.65,
                child: TextField(
                  onChanged: (value) => setState(() {
                    communityIDQuery = value;
                  }),
                  style: textTheme.displaySmall,
                  cursorColor: theme.onBackground,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0),
                    filled: true,
                    fillColor: theme.primary.withOpacity(0.125),
                    hintText: "Community ID",
                    hintStyle: textTheme.displaySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.transparent, width: 0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.onBackground, width: 1),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.transparent, width: 0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.transparent, width: 0),
                    ),
                  ),
                ),
              ),
              //* Search button
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(side: BorderSide(color: theme.tertiary, width: 1), backgroundColor: theme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => {
                          getCommunityWithValidation(),
                        },
                    icon: Icon(Icons.search, size: 20, color: theme.onBackground),
                    label: Text("Search", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold))),
              ),
            ],
          );
        }),
        const SizedBox(height: 5),
        Row(
          children: [
            !isSearchingCommunity && !isSearchingCommunitySuccess && getCommunityError == ""
                ? Text("Community ID's are currently private", style: textTheme.displaySmall!.copyWith(color: Colors.yellow))
                : isSearchingCommunity
                    ? Text("Searching for community...", style: textTheme.displaySmall)
                    : isSearchingCommunitySuccess
                        ? Text("Community found!", style: textTheme.displaySmall)
                        : getCommunityError != ""
                            ? Text(getCommunityError, style: textTheme.displaySmall!.copyWith(color: theme.error))
                            : Container(),
          ],
        ),
        const SizedBox(height: 15),
        //*Community card
        //* Stack, left is image, right is gradient and text
        communityData != null
            ? Container(
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.tertiary, width: 1)),
                child: Stack(
                  children: [
                    //* Left Bottom image
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                              image: NetworkImage(
                                communityData["image"],
                              ),
                              fit: BoxFit.cover)),
                    ),
                    //* Right Side covering bottom image
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [
                            theme.background.withOpacity(0),
                            theme.background.withOpacity(1),
                            theme.background.withOpacity(1)
                          ])),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(communityData["name"], style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold)),
                            Text(communityData["subName"], style: textTheme.displaySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ))
            : Container(),
        const SizedBox(height: 15),
        //* Password field
        SizedBox(
          height: 40,
          child: TextField(
            onChanged: (value) => setState(() {
              passwordQuery = value;
            }),
            style: textTheme.displaySmall,
            cursorColor: theme.onBackground,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(left: 10),
              filled: true,
              fillColor: theme.primary.withOpacity(0.125),
              hintText: "Password",
              hintStyle: textTheme.displaySmall,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent, width: 0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.onBackground, width: 1),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent, width: 0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.transparent, width: 0),
              ),
            ),
          ),
        ),
        //* Error text
        Row(
          children: [
            error != ""
                ? Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(error, style: textTheme.displaySmall!.copyWith(color: theme.error)),
                  )
                : Container(),
          ],
        ),
        //* Join Button
        const SizedBox(height: 15),
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(gradient: defaultBluePrimaryGradient, borderRadius: BorderRadius.all(Radius.circular(100))),
          child: ElevatedButton(
            onPressed: () => {
              joinCommunityWithValidation(),
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, padding: const EdgeInsets.all(0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: theme.onBackground,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Text("Join", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold)),
                  ),
          ),
        ),
        //* I can do this later button
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              showDialog(context: context, builder: (c) => const UnavalaibleItemDialog());
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.secondary, shadowColor: Colors.transparent, elevation: 0, side: BorderSide(color: theme.tertiary, width: 1), padding: const EdgeInsets.all(0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
            child: Text("I can do this later", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.normal)),
          ),
        ),
      ]),
    );
  }
}

class AccountCreationScreen extends StatefulWidget {
  const AccountCreationScreen({super.key, required this.theme, required this.textTheme, required this.changeStep});
  final ColorScheme theme;
  final TextTheme textTheme;
  final Function changeStep;

  @override
  State<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends State<AccountCreationScreen> {
  String userNameQuery = "";
  String emailQuery = "";
  String passwordQuery = "";
  String retypePasswordQuery = "";
  String error = "";
  bool isLoading = false;
  bool success = false;

  void loginAsGuest(AppState appState) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      //continue
    }
    appState.setCurrentUser(UserData(uid: 0, exp: 0, streak: 0, posts: 0, flashCardSets: [], username: "Guest", email: "guest@guest.com", profilePicture: "https://picsum.photos/200", assignedCommunity: "0", assignedSection: "0"));
    appState.setQuizzes([]);
    //* Get quizzes data from shared preferences
    await SharedPreferences.getInstance().then((value) {
      if (value.containsKey("quizData")) {
        appState.setQuizzes([]);
        dynamic decodedObject = jsonDecode(value.getString("quizData")!);

        //* Convert the decoded `dynamic` object back to your desired Dart object structure
        List<QuizSet> quizzes = [];
        for (var quiz in decodedObject['quizzes']) {
          quizzes.add(
            QuizSet(
                title: quiz['title'],
                description: quiz['description'],
                questions: [
                  for (int i = 0; i < quiz["questions"].length; i++) QuizQuestion(id: i, question: quiz["questions"][i]["question"], answers: List<String>.from(quiz["questions"][i]["answers"] as List), correctAnswer: List<int>.from(quiz["questions"][i]["correctAnswer"] as List), type: quiz["questions"][i]["type"] != null ? quizTypes.values[quiz["questions"][i]["type"]] : quizTypes.multipleChoice),
                ],
                settings: quiz["settings"] ?? {}),
          );
        }
        //* Add the quizzes to the user data
        for (QuizSet quiz in quizzes) {
          appState.getQuizzes.add(quiz);
        }
      }
      //* Push to home screen
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = widget.theme;
    var textTheme = widget.textTheme;
    var changeStep = widget.changeStep;

    void createAccountValidation() async {
      //If loading, return
      if (isLoading) {
        return;
      }
      setState(() {
        error = "";
        isLoading = true;
      });
      //Check if forms are filled
      if (userNameQuery == "" || emailQuery == "" || passwordQuery == "" || retypePasswordQuery == "") {
        debugPrint("e");
        setState(() {
          isLoading = false;
          error = "Please fill in all fields.";
        });
        return;
      }
      //Validate username
      if (userNameQuery.length < 3) {
        setState(() {
          isLoading = false;
          error = "Username must be at least 3 characters long.";
        });
        return;
      }
      if (userNameQuery.length > 20) {
        setState(() {
          isLoading = false;
          error = "Username must be less than 20 characters long.";
        });
        return;
      }
      if (userNameQuery.contains(" ")) {
        setState(() {
          isLoading = false;
          error = "Username cannot contain spaces.";
        });
        return;
      }
      //*Validate email
      if (!EmailValidator.validate(emailQuery)) {
        setState(() {
          isLoading = false;
          error = "Please enter a valid email.";
        });
        return;
      }
      //*Validate password
      if (passwordQuery != retypePasswordQuery) {
        setState(() {
          isLoading = false;
          error = "Passwords do not match.";
        });
        return;
      }
      const regex = r"^(?=.*[A-Za-z]).{6,}$";
      if (!RegExp(regex).hasMatch(passwordQuery)) {
        setState(() {
          isLoading = false;
          error = "Password must be at least 6 characters long.";
        });
        return;
      }
      //*Create account
      await createAccount(emailQuery, passwordQuery, userNameQuery, context.read<AppState>()).then((value) => debugPrint("Account created")).onError((error, stackTrace) => setState(() {
            isLoading = false;
            this.error = error.toString();
          }));
      if (error != "") {
        return;
      }
      setState(() {
        success = true;
        isLoading = false;
      });
      await Future.delayed(const Duration(seconds: 3));
      //Go to step 2
      changeStep(2);
      return;
    }

    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              Text("1. Set up your account", style: widget.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w400)),
            ],
          ),
          //Account creation form
          const SizedBox(height: 50),

          FormField(
            textTheme: textTheme,
            theme: theme,
            hintText: "Username",
            onChanged: (value) => setState(() {
              userNameQuery = value;
            }),
          ),
          const SizedBox(height: 10),
          FormField(
            textTheme: textTheme,
            theme: theme,
            hintText: "Email",
            onChanged: (value) => setState(() {
              emailQuery = value;
            }),
          ),
          const SizedBox(height: 10),
          FormField(
            textTheme: textTheme,
            theme: theme,
            hintText: "Password",
            onChanged: (value) => setState(() {
              passwordQuery = value;
            }),
          ),
          const SizedBox(height: 10),
          FormField(
            textTheme: textTheme,
            theme: theme,
            hintText: "Retype Password",
            onChanged: (value) => setState(() {
              retypePasswordQuery = value;
            }),
          ),
          const SizedBox(height: 30),
//Error text
          error != "" ? Text(error, style: textTheme.displaySmall!.copyWith(color: theme.error)) : Container(),
          //Create account button. Primary gradient, rounded corners. And also "i already have an account" button, elevated button with secondary color background and tertiary borders
          Row(
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(gradient: defaultBluePrimaryGradient, borderRadius: BorderRadius.all(Radius.circular(100))),
                  child: ElevatedButton(
                    onPressed: () {
                      createAccountValidation();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, padding: const EdgeInsets.all(0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: theme.onBackground,
                                strokeWidth: 2,
                              ),
                            )
                          : success
                              ? Icon(Icons.check, color: theme.onBackground, size: 20)
                              : Text("Create Account", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 5),
              Flexible(
                flex: 1,
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.secondary, shadowColor: Colors.transparent, elevation: 0, side: BorderSide(color: theme.tertiary, width: 1), padding: const EdgeInsets.all(0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                    child: Text("I already have an account", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.normal)),
                  ),
                ),
              ),
              const SizedBox(width: 5),
// Login as Guest
              Flexible(
                flex: 1,
                child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondary,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          side: BorderSide(color: theme.tertiary),
                        ),
                        onPressed: () => loginAsGuest(context.read<AppState>()),
                        child: Text("Login as Guest", style: textTheme.displaySmall))),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class FormField extends StatelessWidget {
  const FormField({
    super.key,
    required this.textTheme,
    required this.theme,
    required this.onChanged,
    required this.hintText,
  });

  final TextTheme textTheme;
  final ColorScheme theme;
  final Function onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) => onChanged(value),
      style: textTheme.displaySmall,
      cursorColor: theme.onBackground,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(left: 10),
        filled: true,
        fillColor: theme.primary.withOpacity(0.125),
        hintText: hintText,
        hintStyle: textTheme.displaySmall,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.textTheme,
    required this.changeCurrentStep,
  });

  final TextTheme textTheme;
  final Function changeCurrentStep;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      FadeInTransition(
        child: Text(
          "Welcome!",
          style: textTheme.displayLarge!.copyWith(fontSize: 48),
          textAlign: TextAlign.center,
        ),
      ),
      FadeInTransition(delayMilliseconds: 500 * 1, child: Text("Let's get you started.", style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w400))),
      const SizedBox(height: 20),
      FadeInTransition(
        delayMilliseconds: 500 * 2,
        child: Container(
          height: 200,
          width: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover),
          ),
          // decoration: BoxDecoration(
          //     image: DecorationImage(
          //         image: AssetImage(
          //             'assets/images/getstarted.png'))),
        ),
      ),
      const SizedBox(height: 75),
      // FadeInTransition(
      //   delayMilliseconds: 150 * 3,
      //   child: Container(
      //     height: 40,
      //     decoration: BoxDecoration(gradient: defaultBluePrimaryGradient, borderRadius: BorderRadius.all(Radius.circular(100))),
      //     child: ElevatedButton(
      //       onPressed: () {
      //         changeCurrentStep(1 /*account creation*/);
      //       },
      //       style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, padding: const EdgeInsets.all(0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
      //       child: Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 80),
      //         child: Text("Get Started", style: textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold)),
      //       ),
      //     ),
      //   ),
      // ),

      TapRegion(
        onTapInside: (event) => changeCurrentStep(1),
        onTapOutside: (event) => changeCurrentStep(1),
        child: FadeInTransition(
            delayMilliseconds: 500 * 3 + 500,
            duration: 1000,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Continue", style: textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 15),
                Transform.flip(flipX: true, child: const Icon(Icons.arrow_back_rounded, color: Colors.white))
              ],
            )),
      ),

      const SizedBox(height: 100),
    ]);
  }
}

//* Unavailable item dialog
class UnavalaibleItemDialog extends StatelessWidget {
  const UnavalaibleItemDialog({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: theme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            "This item is currently unavailable",
            style: textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: textTheme.displaySmall,
                  )),
            ],
          )
        ]),
      ),
    );
  }
}
