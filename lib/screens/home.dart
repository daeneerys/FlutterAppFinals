import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'dart:math';
import '../ui/pages/startup_page.dart';
import 'splash_screen.dart';
import 'package:tomas_tigerpet/minigame_runner/lib/main.dart';

import 'package:tomas_tigerpet/ui/pages/startup_page.dart';


class Home extends StatefulWidget {
  final int rewardCoins;
  final int energyCost;
  const Home({super.key, this.rewardCoins = 0, this.energyCost = 0});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {

  Color _backgroundColor = Colors.green[300]!;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isGamesVisible = false;
  //Database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  final dbService = DatabaseService();


  //Tiger Mood
  int hunger = 50;
  int happiness = 50;
  int energy = 50;
  int coins = 100;
  int level = 1;
  int experience = 0;
  //Tiger Animation

  bool isBlinking = false;
  bool isMoodChanging = false;
  bool isHungerChangning = false;
  bool isLampOn = false;
  Timer? sleepTimer;

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

  final Map<String, int> foodPrices = {
    'bread': 10,
    'candy': 15,
    'cheese': 20,
    'chocolate': 25,
    'eggs': 15,
    'hotdogsandwich': 30,
    'icecream': 20,
    'meat': 35,
    'nuggetsfries': 25,
    'pizza': 30,
    'salad': 15,
    'salmon': 35,
  };

  // Helper method to get food price
  int _getFoodPrice(String food) {
    // Define your pricing logic here
    final prices = {
      'bread': 10,
      'candy': 15,
      'cheese': 20,
      'chocolate': 25,
      'eggs': 15,
      'hotdogsandwich': 30,
      'icecream': 20,
      'meat': 35,
      'nuggetsfries': 25,
      'pizza': 30,
      'salad': 15,
      'salmon': 35,
    };
    return prices[food] ?? 20; // Default price
  }

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    print("Current user ID: ${currentUser?.uid}");
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
        String? colorName = await dbService.getBackgroundPreference(currentUser!.uid);
        if (colorName != null) {
          setState(() {
            _backgroundColor = _colorFromString(colorName);
          });
        }
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


        experience = petStats['experience'];
        level = petStats['level'];
        coins = petStats['coins'];

        // ✅ REWARD COINS if high score was 100 or more
        if (widget.rewardCoins > 0) {
          coins += widget.rewardCoins;

          // Optional: Show a snackbar reward message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You earned ${widget.rewardCoins} coins for your high score! 🎉'),
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Apply energy cost if coming from the game
        if (widget.energyCost > 0) {
          energy = (energy - widget.energyCost).clamp(0, 100); // Ensure it's between 0 and 100

          // Optional: Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Energy reduced by ${widget.energyCost} from playing the game. ⚡'),
              duration: Duration(seconds: 3),
            ),
          );
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

  Color _colorFromString(String name) {
    switch (name.toLowerCase()) {
      case 'blue': return Colors.blue[200]!;
      case 'purple': return Colors.purple[200]!;
      case 'orange': return Colors.orange[200]!;
      case 'pink': return Colors.pink[200]!;
      default: return Colors.green[300]!;
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

  void feedTiger(String food) async {
    if (foodInventory[food]! <= 0) return;

    try {
      setState(() {
        foodInventory[food] = foodInventory[food]! - 1;

        int hungerGain = foodEffects[food]?['hunger'] ?? 10;
        int happinessGain = foodEffects[food]?['happiness'] ?? 5;
        int experienceGain = foodEffects[food]?['experience'] ?? 3;

        hunger = (hunger + hungerGain).clamp(0, 100);
        happiness = (happiness + happinessGain).clamp(0, 100);
        droppedFoodImage = 'assets/images/foods/${food}_food.png';
      });

      addExperience(foodEffects[food]?['experience'] ?? 3);

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

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => droppedFoodImage = null);
      });
    } catch (e) {
      print("Error feeding tiger: $e");
      if (mounted) {
        setState(() {
          foodInventory[food] = (foodInventory[food] ?? 0) + 1;
        });
      }
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
    bool leveledUp = false;

    try {
      setState(() {
        experience += amount;

        // Check for level up
        while (level < 99 && experience >= thresholds[level]!) {
          experience -= thresholds[level]!;
          level++;
          leveledUp = true;
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

      if (leveledUp) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Level Up! You're now at Level $level"))
        );
      }
    } catch (e) {
      print("Error adding experience: $e");
    }
  }

  // Method to handle food purchase
  Future<void> _buyFood(String food, int price) async {
    if (coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough coins!'))
      );
      return;
    }

    try {
      // First update local state
      setState(() {
        coins -= price;
        foodInventory[food] = (foodInventory[food] ?? 0) + 1;
      });

      // Then update database
      String userId = _auth.currentUser!.uid;
      await dbService.updateDatabase(
        userId: userId,
        hunger: hunger,
        happiness: happiness,
        energy: energy,
        currentPetImage: currentPetImage,
        currentBlinkImage: currentBlinkImage,
        coins: coins, // Make sure coins is included here
        level: level,
        experience: experience,
        foodInventory: foodInventory,
        lastUpdated: DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased 1 ${food.capitalize()}!'))
      );
    } catch (e) {
      print("Error buying food: $e");
      // Revert local changes if database update fails
      setState(() {
        coins += price;
        foodInventory[food] = (foodInventory[food] ?? 1) - 1;
      });
    }
  }

  // Consistent dialog styling for all three functions
  var dialogPadding = EdgeInsets.all(20.0);
  var dialogTitleStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  var dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
  );
  var dialogHeightFactor = 0.7; // 70% of screen height

  void openShop() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: dialogShape,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: dialogPadding,
        height: MediaQuery.of(context).size.height * dialogHeightFactor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Shop', style: dialogTitleStyle),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_money, color: Colors.amber),
                Text(' $coins', style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.8,
                ),
                itemCount: foodKeys.length,
                itemBuilder: (context, index) {
                  final food = foodKeys[index];
                  final price = _getFoodPrice(food);

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/foods/${food}_food.png',
                            height: 60,
                          ),
                          Text(
                            food.capitalize(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('$price coins', style: TextStyle(color: Colors.amber)),
                          ElevatedButton(
                            onPressed: () => _buyFood(food, price),
                            child: Text('Buy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: coins >= price ? Colors.green : Colors.grey,
                              minimumSize: Size(double.infinity, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openBag() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: dialogShape,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: dialogPadding,
        height: MediaQuery.of(context).size.height * dialogHeightFactor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Bag', style: dialogTitleStyle),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.9,
                ),
                itemCount: foodKeys.length,
                itemBuilder: (context, index) {
                  final foodName = foodKeys[index];
                  final quantity = foodInventory[foodName] ?? 0;
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/foods/${foodName}_food.png',
                            height: 60,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            foodName.capitalize(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'x$quantity',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openGames() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: dialogShape,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: dialogPadding,
        height: MediaQuery.of(context).size.height * dialogHeightFactor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mini Games', style: dialogTitleStyle),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: [
                  buildGameCard('Memory Match', 'assets/images/games/memorymatch.png'),
                  buildGameCard('Endless Run', 'assets/images/games/DinoRun.png'),
                  // Add more games as needed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGameCard(String title, String imagePath) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              imagePath,
              height: 80,
            ),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () {
                _onPlayButtonPressed(title); // Pass title to determine which game was pressed
              },
              child: Text('Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPlayButtonPressed(String title) async {
    if (title == 'Memory Match') {
      // Show a confirmation dialog before spending energy for Memory Match
      if (energy >= 10) {
        bool? confirmPlay = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Text(
                'Memory Match Game!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: Text(
                'This game will cost you 10 Energy. Do you want to continue?',
                style: TextStyle(fontSize: 16),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);  // User cancels the action
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);  // User confirms the action
                  },
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              backgroundColor: Colors.lightGreen,
            );
          },
        );

        // If the user confirms, proceed with the energy deduction and navigation
        if (confirmPlay == true) {
          setState(() {
            energy -= 10;  // Reduce energy by 10
          });

          // Update Firestore with the new energy value
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
          // Navigate to the Memory Match game screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StartUpPage()),
          );
        }
      } else {
        // Show an alert dialog for not enough energy
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop();  // Close the dialog
                  },
                ),
              ),
              content: Text(
                'Not enough energy to play! Tomas needs to rest.',
                style: TextStyle(fontSize: 25),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.lightGreen,
            );
          },
        );
      }
    } else if (title == 'Endless Run') {
      // Directly navigate to the Endless Run game screen without confirmation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: dialogShape,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: dialogPadding,
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Settings', style: dialogTitleStyle),
            const SizedBox(height: 20),

            // Background Color Picker
            Text('Background Color', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildColorOption(Colors.green[300]!, 'Default'),
                  _buildColorOption(Colors.blue[200]!, 'Blue'),
                  _buildColorOption(Colors.purple[200]!, 'Purple'),
                  _buildColorOption(Colors.orange[200]!, 'Orange'),
                  _buildColorOption(Colors.pink[200]!, 'Pink'),
                ],
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Log Out', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void toggleLamp() {
    setState(() {
      isLampOn = !isLampOn;

      if (isLampOn) {
        currentPetImage = 'assets/images/tiger/tiger_blink.png';
        currentBlinkImage = 'assets/images/tiger/tiger_blink.png';

        sleepTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
          if (energy < 100) {
            setState(() {
              energy += 1;
            });

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
              lastUpdated: DateTime.now(),
            );
          } else {
            toggleLamp(); // Stop sleep when full
          }
        });
      } else {
        sleepTimer?.cancel();
        sleepTimer = null;

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

        // Save stats when lamp is turned off
        dbService.updateDatabase(
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
          lastUpdated: DateTime.now(),
        );
      }
    });
  }

  Widget _buildColorOption(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _backgroundColor = color;
              });
              // Save the color preference to Firestore
              dbService.saveBackgroundPreference(currentUser!.uid, label.toLowerCase());
              Navigator.pop(context);
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _backgroundColor == color ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String selectedFood = foodKeys[selectedFoodIndex];
    final thresholds = generateExperienceThresholds();
    if (_isLoading) {
      return const SplashScreen(); // Replace with your custom splash widget
    }
    return Scaffold(
      backgroundColor: _backgroundColor,
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
            // New row for games and settings buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Games button on left
                  IconButton(
                    icon: Image.asset('assets/images/etc/games_icon.png', height: 40),
                    onPressed: openGames,
                    tooltip: 'Mini Games',
                  ),
                  IconButton(
                    icon: Icon(
                      isLampOn ? Icons.lightbulb : Icons.lightbulb_outline,
                      size: 50,
                      color: isLampOn ? Colors.black : Colors.yellow,
                    ),
                    onPressed: toggleLamp,
                    tooltip: 'Toggle Sleep Lamp',
                  ),
                  // Settings button on right
                  IconButton(
                    icon: Icon(Icons.settings, size: 30),
                    onPressed: _openSettings,
                    tooltip: 'Settings',
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
                      onWillAccept: (food) {
                        // Change tiger image when food hovers over it
                        setState(() {
                          currentPetImage = 'assets/images/tiger/tiger_open_mouth.png';
                        });
                        return true; // Allow the food to be accepted
                      },
                      onLeave: (food) {
                        // Reset image when food leaves without being dropped
                        setState(() {

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
                      },
                      onAccept: (food) {
                        // Finalize feeding and image
                        feedTiger(food); // Your feeding logic

                        setState(() {
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
                      },
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
                  const SizedBox(width: 10),
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}