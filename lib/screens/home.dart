import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'dart:math';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //Database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  final dbService = DatabaseService();


  //Tiger Mood
  int hunger = 50;
  int happiness = 50;
  int energy = 50;

  //Tiger Animation

  bool isBlinking = false;
  bool isMoodChanging = false;
  bool isHungerChangning = false;

  //Loading Animation
  bool _isLoading = true;

  //TigerBlinking Image
  String currentPetImage = 'assets/images/tiger/tiger_normal.png';
  String currentBlinkImage = 'assets/images/tiger/tiger_normal_blink.png';

  //Food
  String? droppedFoodImage; // Store food image when feeding
  int selectedFoodIndex = 0;

  List<String> foodKeys = [
    'bread', 'candy', 'cheese', 'chocolate', 'eggs',
    'hotdogsandwich', 'icecream', 'meat', 'nuggetsfries',
    'pizza', 'salad', 'salmon'
  ];

  Map<String, int> foodInventory = {};

  Map<String, Map<String, int>> foodEffects = {
    'bread': {'hunger': 5, 'happiness': 2, 'experience': 3},
    'candy': {'hunger': 3, 'happiness': 8, 'experience': 4},
    'cheese': {'hunger': 8, 'happiness': 4, 'experience': 5},
    'chocolate': {'hunger': 4, 'happiness': 10, 'experience': 5},
    'eggs': {'hunger': 10, 'happiness': 3, 'experience': 5},
    'hotdogsandwich': {'hunger': 12, 'happiness': 5, 'experience': 6},
    'icecream': {'hunger': 5, 'happiness': 9, 'experience': 5},
    'meat': {'hunger': 20, 'happiness': 4, 'experience': 7},
    'nuggetsfries': {'hunger': 15, 'happiness': 6, 'experience': 6},
    'pizza': {'hunger': 18, 'happiness': 7, 'experience': 7},
    'salad': {'hunger': 7, 'happiness': 2, 'experience': 3},
    'salmon': {'hunger': 20, 'happiness': 5, 'experience': 7},
  };

  //Coins
  int coins = 100;
  //Level
  int level = 1;
  //Experience
  int experience = 0;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _loadData();
    _startBlinking();
    _startMoodChanging();
    _startHungerDecay();
  }

  Future<void> _loadData() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> petStats = data['petStats'];

        // Get the lastUpdated time
        Timestamp lastUpdatedTimestamp = petStats['lastUpdated'];
        DateTime lastUpdated = lastUpdatedTimestamp.toDate();
        DateTime now = DateTime.now();
        Duration diff = now.difference(lastUpdated);

        // Calculate decays/restores
        int hungerDecayAmount = 5 * (diff.inHours ~/ 3);
        int happinessDecayAmount = 5 * diff.inHours;
        int energyRestoreAmount = 5 * (diff.inHours ~/ 2);

        int newHunger = petStats['hunger'] - hungerDecayAmount;
        int newHappiness = petStats['happiness'] - happinessDecayAmount;
        int newEnergy = petStats['energy'] + energyRestoreAmount;

        // Clamp values and update UI state
        setState(() {
          hunger = newHunger.clamp(0, 100);
          happiness = newHappiness.clamp(0, 100);
          energy = newEnergy.clamp(0, 100);

          foodInventory = Map<String, int>.from(data['foodInventory']);
          _isLoading = false;
        });

        // Set pet image based on mood
        if (happiness > 50) {
          currentPetImage = 'assets/images/tiger/tiger_happy.png';
          currentBlinkImage = 'assets/images/tiger/tiger_blink.png';
        } else if (happiness == 50) {
          currentPetImage = 'assets/images/tiger/tiger_normal.png';
          currentBlinkImage = 'assets/images/tiger/tiger_normal_blink.png';
        } else {
          currentPetImage = 'assets/images/tiger/tiger_sad.png';
          currentBlinkImage = 'assets/images/tiger/tiger_sad_blink.png';
        }

        // Save updated values to Firestore
        await dbService.updateDatabase(
          userId: currentUser!.uid,
          hunger: hunger,
          happiness: happiness,
          energy: energy,
          currentPetImage: currentPetImage,
          currentBlinkImage: currentBlinkImage,
          coins: coins,
          level: level,
          experience: experience,
          foodInventory: foodInventory,
          lastUpdated: now,
        );
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _startBlinking() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        isBlinking = true;
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        setState(() {
          isBlinking = false;
        });
      });
    });
  }

  //Happiness Mood Change
  void _startMoodChanging() {
    Timer.periodic(const Duration(seconds: 3600), (timer) {
      _changeMood((happiness - 5).clamp(0, 100));
    });
  }

  Future<void> _changeMood(int newHappiness) async {
    setState(() {
      isMoodChanging = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () async {
      setState(() {
        happiness = newHappiness;

        if (happiness > 50) {
          currentPetImage = 'assets/images/tiger/tiger_happy.png';
          currentBlinkImage = 'assets/images/tiger/tiger_blink.png';
        } else if (happiness == 50) {
          currentPetImage = 'assets/images/tiger/tiger_normal.png';
          currentBlinkImage = 'assets/images/tiger/tiger_normal_blink.png';
        } else {
          currentPetImage = 'assets/images/tiger/tiger_sad.png';
          currentBlinkImage = 'assets/images/tiger/tiger_sad_blink.png';
        }
      });

      // Extract userId from currentUser
      String userId = _auth.currentUser!.uid;

      // Save updated stats to Firestore
      await dbService.updateDatabase(
        userId: userId,
        hunger: hunger,
        happiness: happiness,
        energy: energy,
        currentPetImage: currentPetImage,
        currentBlinkImage: currentBlinkImage,
        coins: coins,
        level: level,
        experience: experience,
        foodInventory: foodInventory,
        lastUpdated: DateTime.now(),
      );
    });

    // Reset mood change flag after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        isMoodChanging = false;
      });
    });
  }

  void _startHungerDecay() {
    Timer.periodic(const Duration(seconds: 14400), (timer) {
      _decreaseHunger((hunger - 1).clamp(0, 100)); // or decrease by any amount you want
    });
  }

  Future<void> _decreaseHunger(int newHunger) async {
    setState(() {
      hunger = newHunger;
    });

    // Update Firestore
    String userId = _auth.currentUser!.uid;
    await dbService.updateDatabase(
      userId: userId,
      hunger: hunger,
      happiness: happiness,
      energy: energy,
      currentPetImage: currentPetImage,
      currentBlinkImage: currentBlinkImage,
      coins: coins,
      level: level,
      experience: experience,
      foodInventory: foodInventory,
      lastUpdated: DateTime.now(),
    );
  }

  void feedTiger(String food) {
    if (foodInventory[food]! > 0) {
      setState(() {
        // Reduce food count
        foodInventory[food] = (foodInventory[food]! - 1).clamp(0, 99);

        // Apply food effects
        int hungerGain = foodEffects[food]?['hunger'] ?? 10;
        int happinessGain = foodEffects[food]?['happiness'] ?? 5;
        int experienceGain = foodEffects[food]?['experience'] ?? 3;

        //Increase Stats
        hunger = (hunger + hungerGain).clamp(0, 100);
        _changeMood((happiness + happinessGain).clamp(0, 100));
        addExperience(experienceGain);


        // Show food animation near tiger
        droppedFoodImage = 'assets/images/foods/${food}_food.png';
      });

      // Extract userId from currentUser
      String userId = _auth.currentUser!.uid;

      // Save updated stats to Firestore
      dbService.updateDatabase(
        userId: userId,
        hunger: hunger,
        happiness: happiness,
        energy: energy,
        currentPetImage: currentPetImage,
        currentBlinkImage: currentBlinkImage,
        coins: coins,
        level: level,
        experience: experience,
        foodInventory: foodInventory,
        lastUpdated: DateTime.now(),
      );

      // Remove food after animation
      Future.delayed(const Duration(seconds: 1), () {
        setState(() => droppedFoodImage = null);
      });
    }
  }

  void navigateFood(int direction) {
    setState(() {
      selectedFoodIndex = (selectedFoodIndex + direction) % foodKeys.length;
      if (selectedFoodIndex < 0) selectedFoodIndex = foodKeys.length - 1;
    });
  }

  //Experience Thresholds
  Map<int, int> generateExperienceThresholds({int maxLevel = 99}) {
    Map<int, int> thresholds = {};
    for (int level = 1; level <= maxLevel; level++) {
      thresholds[level] = (50 * (level * sqrt(level.toDouble()))).round();
    }
    return thresholds;
  }

  //Experience
  void addExperience(int amount) async {
    final thresholds = generateExperienceThresholds();

    setState(() {
      experience += amount;

      while (level < 99 && experience >= thresholds[level]!) {
        experience -= thresholds[level]!;
        levelUp();
      }
    });

    // Save after updating experience and level
    String userId = _auth.currentUser!.uid;
    await dbService.updateDatabase(
      userId: userId,
      hunger: hunger,
      happiness: happiness,
      energy: energy,
      currentPetImage: currentPetImage,
      currentBlinkImage: currentBlinkImage,
      coins: coins,
      level: level,
      experience: experience,
      foodInventory: foodInventory,
      lastUpdated: DateTime.now(),
    );
  }

  // Level up method
  void levelUp() {
    if (level >= 99) return;

    setState(() {
      level++;
      experience = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Level Up! You're now at Level $level"))
    );
  }

  //Open Shop
  void openShop(){
    showModalBottomSheet(
      context: context,
      builder:(context) => Container(
        height: 300,
        child:Center(child: Text('Welcome to the Shop!')),
      ),
    );
  }

  void openBag() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Builder(
          builder: (context) {
            double width = MediaQuery.of(context).size.width;
            double height = MediaQuery.of(context).size.height;
            double modalWidth = width * 0.85; // Responsive width
            double modalHeight = height * 0.6; // Responsive height

            return Container(
              width: modalWidth,
              height: modalHeight,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Bag',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: width < 600 ? 3 : 5, // 3 items on smaller devices, 5 on larger ones
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: foodKeys.length, // number of items
                      itemBuilder: (context, index) {
                        final foodName = foodKeys[index];
                        final quantity = foodInventory[foodName] ?? 0;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/foods/${foodName}_food.png',
                              height: width < 600 ? 40 : 80,
                            ),
                            const SizedBox(height: 4),
                            Text('x$quantity', style: TextStyle(fontSize: width < 600 ? 12 : 16)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String selectedFood = foodKeys[selectedFoodIndex];
    final thresholds = generateExperienceThresholds();
    if(_isLoading){
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.green[300],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green),
                        Text('$coins', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildStatBox('Hunger', hunger, Colors.yellow),
                      const SizedBox(width: 20),
                      buildStatBox('Happiness', happiness, Colors.yellow),
                      const SizedBox(width: 20),
                      buildStatBox('Energy', energy, Colors.yellow),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text('Lv. $level', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 5),
                            const Icon(Icons.star, color: Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: experience / thresholds[level]!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DragTarget<String>(
                      onAccept: (food) => feedTiger(food), // Feeding logic
                      builder: (context, candidateData, rejectedData) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(currentPetImage, height: 200),
                            AnimatedOpacity(
                              opacity: isBlinking ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Image.asset(currentBlinkImage, height: 200),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Food Navigation & Dragging
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: openBag,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Column(
                        children: [
                          Image.asset('assets/images/etc/bag_home.png', height: 60),
                          const Text('Bag', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left, size: 40),
                          onPressed: () => navigateFood(-1),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Draggable<String>(
                            data: selectedFood,
                            feedback: Image.asset('assets/images/foods/${selectedFood}_food.png', height: 80),
                            childWhenDragging: SizedBox(
                              height: 100,
                              child: Opacity(
                                opacity: 0.3,
                                child: Image.asset('assets/images/foods/${selectedFood}_food.png', height: 80),
                              ),
                            ),
                            child: Column(
                              children: [
                                Image.asset('assets/images/foods/${selectedFood}_food.png', height: 80),
                                Text('${foodInventory[selectedFood]}'),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right, size: 40),
                          onPressed: () => navigateFood(1),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: openShop,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 30),
                      child: Column(
                        children: [
                          Image.asset('assets/images/etc/shopping_cart.png', height: 60),
                          const Text('Shop', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildStatBox(String label, int value, Color fillColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 40,
                height: (value / 100) * 40,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        Text('$value%', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}