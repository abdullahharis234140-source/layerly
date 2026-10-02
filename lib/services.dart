import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const kIds = {'layerly_pro_monthly', 'layerly_pro_yearly'};

class AppState extends ChangeNotifier {
  bool pro = false, cloud = false;
  String? uid;
  List<ProductDetails> products = [];

  DocumentReference<Map<String, dynamic>>? get _doc =>
      uid == null ? null : FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      uid = (await FirebaseAuth.instance.signInAnonymously()).user!.uid;
      cloud = true;
      _doc!.snapshots().listen((s) {
        pro = s.data()?['pro'] == true;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Firebase not configured, running local mode: $e');
    }
    try {
      final iap = InAppPurchase.instance;
      if (await iap.isAvailable()) {
        iap.purchaseStream.listen(_onPurchase);
        products = (await iap.queryProductDetails(kIds)).productDetails;
        products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      }
    } catch (e) {
      debugPrint('IAP error: $e');
    }
    notifyListeners();
  }

  Future<void> _onPurchase(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        pro = true;
        // PRODUCTION: verify receipt in a Cloud Function before granting Pro.
        await _doc?.set({'pro': true, 'plan': p.productID, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
      if (p.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(p);
    }
    notifyListeners();
  }

  void buy(ProductDetails p) =>
      InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
  void restore() => InAppPurchase.instance.restorePurchases();
  void debugToggle() { pro = !pro; notifyListeners(); }
  Future<void> logExport() async =>
      _doc?.set({'exports': FieldValue.increment(1)}, SetOptions(merge: true));
}
