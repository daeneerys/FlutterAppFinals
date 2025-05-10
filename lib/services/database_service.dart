import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  Future<void> saveUserData(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'petStats': {
        'hunger': 50,
        'happiness': 50,
        'energy': 50,
        'lastUpdated': FieldValue.serverTimestamp(),
        'currentPetImage': 'assets/images/tiger/tiger_normal.png',
        'currentBlinkImage': 'assets/images/tiger/tiger_normal_blink.png',
        'coins': 100,
        'level': 1,
        'experience': 0,
      },
      'foodInventory': {
        'bread' : 1,
        'candy' : 1,
        'cheese': 1,
        'chocolate' : 1,
        'eggs' : 1,
        'hotdogsandwich' : 1,
        'icecream' : 1,
        'meat' : 1,
        'nuggetsfries' : 1,
        'pizza' : 1,
        'salad' : 1,
        'salmon' : 1
      },
    }, SetOptions(merge: true)); // Merge prevents overwriting existing data
  }

  //Update the Database
  Future<void> updateDatabase({
    required String userId,
    required int hunger,
    required int happiness,
    required int energy,
    required String currentPetImage,
    required String currentBlinkImage,
    required int coins,
    required int level,
    required int experience,
    required Map<String, int> foodInventory,
    required DateTime lastUpdated,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'petStats': {
          'hunger': hunger.clamp(0, 100),
          'happiness': happiness.clamp(0, 100),
          'energy': energy.clamp(0, 100),
          'currentPetImage': currentPetImage,
          'currentBlinkImage': currentBlinkImage,
          'coins': coins, // Ensure coins is included
          'level': level,
          'experience': experience,
          'lastUpdated': FieldValue.serverTimestamp()
        },
        'foodInventory': foodInventory, // Ensure foodInventory is included
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating database: $e");
      rethrow; // Important to propagate errors
    }
  }

  // 🟡 Update food inventory (e.g., when buying food)
  Future<void> updateFoodInventory(String userId, String foodName, int quantity) async {
    await _firestore.collection('users').doc(userId).update({
      'foodInventory.$foodName': quantity,
    });
  }

  // 🟡 Update tiger stats (e.g., when feeding)
  Future<void> updatePetStats(String userId, int hunger, int happiness) async {
    await _firestore.collection('users').doc(userId).update({
      'petStats.hunger': hunger.clamp(0, 100),
      'petStats.happiness': happiness.clamp(0, 100),
      'petStats.lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // 🟡 Fetch user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return null;
  }

  //Update coins
  Future<void> updateCoins(String userId, int newAmount) async {
    await _firestore.collection('users').doc(userId).update({
      'petStats.coins': newAmount,
      'petStats.lastUpdated': FieldValue.serverTimestamp(),
    });
  }

}