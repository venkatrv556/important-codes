import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';

class PayUPaymentScreen extends StatefulWidget {
  const PayUPaymentScreen({super.key});

  @override
  State<PayUPaymentScreen> createState() => _PayUPaymentScreenState();
}

class _PayUPaymentScreenState extends State<PayUPaymentScreen>
    implements PayUCheckoutProProtocol {
  late PayUCheckoutProFlutter checkoutPro;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final productCtrl = TextEditingController();

  String? currentTxnId;

  @override
  void initState() {
    super.initState();
    checkoutPro = PayUCheckoutProFlutter(this);
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PayU Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name")),
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email")),
            TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount")),
            TextField(
                controller: productCtrl,
                decoration: const InputDecoration(labelText: "Product")),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: startPayUPayment,
              child: const Text("Pay Now", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // START PAYMENT  (NO HASH HERE)
  // -----------------------------------------------------------
  void startPayUPayment() {
    final fullName = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final amount = amountCtrl.text.trim();
    final product = productCtrl.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        amount.isEmpty ||
        product.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    currentTxnId = "TXN${DateTime.now().millisecondsSinceEpoch}";

    print("========================================");
    print("🚀 STARTING PAYMENT");
    print("TXNID = $currentTxnId");
    print("========================================");
    final additionalParam = {
      PayUAdditionalParamKeys.merchantAccessKey:
          "Z0a39c36545699d9a0184e90cf9ce250d92da7c8c0cf14eb4bcb5840be4cae669djaJP",
      PayUAdditionalParamKeys.sourceId: "android",

      // Optional but allowed
      PayUAdditionalParamKeys.udf1: "",
      PayUAdditionalParamKeys.udf2: "",
      PayUAdditionalParamKeys.udf3: "",
      PayUAdditionalParamKeys.udf4: "",
      PayUAdditionalParamKeys.udf5: "",
    };

    final Map<dynamic, dynamic> params = {
      PayUPaymentParamKey.key: "Z0jaJP",

      PayUPaymentParamKey.transactionId: currentTxnId!,
      PayUPaymentParamKey.amount: amount,
      PayUPaymentParamKey.productInfo: product,
      PayUPaymentParamKey.firstName: fullName,
      PayUPaymentParamKey.email: email,

      // Mandatory
      PayUPaymentParamKey.phone: "7416545580",

      // Mandatory
      PayUPaymentParamKey.userCredential: "Z0jaJP:$email",

      PayUPaymentParamKey.android_surl: "https://cbjs.payu.in/sdk/success",
      PayUPaymentParamKey.android_furl: "https://cbjs.payu.in/sdk/failure",

      PayUPaymentParamKey.environment: "PRODUCTION",
      PayUPaymentParamKey.additionalParam: additionalParam,
    };

    final Map<dynamic, dynamic> config = {
      PayUCheckoutProConfigKeys.merchantName: "VASU",
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen: false,
    };
    // print("------ FINAL PayU PARAMS ------");
    // params.forEach((k, v) {
    //   print("$k : $v  (TYPE = ${v.runtimeType})");
    // });
    // print("--------------------------------");

    checkoutPro.openCheckoutScreen(
      payUPaymentParams: params,
      payUCheckoutProConfig: config,
    );
  }

  // -----------------------------------------------------------
  // HASH GENERATION (PayU Dynamic)
  // -----------------------------------------------------------
  @override
  generateHash(Map response) async {
    final hashName = response[PayUHashConstantsKeys.hashName];
    final hashString = response[PayUHashConstantsKeys.hashString];
    final hashType = response[PayUHashConstantsKeys.hashType];
    final postSalt = response[PayUHashConstantsKeys.postSalt];

    print("Hash Required : $hashName");
    print("Hash String   : $hashString");
    print("Hash Type     : $hashType");
    print("Post Salt     : $postSalt");

    final hash =
        await callYourHashAPI(hashName, hashString, hashType, postSalt);

    checkoutPro.hashGenerated(hash: {hashName: hash});
  }

  // -----------------------------------------------------------
  // BACKEND API CALL
  // -----------------------------------------------------------
  Future<String> callYourHashAPI(
    String hashName,
    String hashString,
    String? hashType,
    String? postSalt,
  ) async {
    print("========================================");
    print("📡 CALLING BACKEND FOR HASH");
    print("SEND hashString = $hashString");
    print("SEND hashType   = $hashType");
    print("SEND postSalt   = $postSalt");
    print("========================================");

    final response = await http.post(
      Uri.parse(
          "https://getinfluencers.in/web_services/pricebargain_generate_payu_hash"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "secret_key": "U5Ga0Z1aaNlYHp0MjdEdXJ1aKVVVB1TP",
        "hashName": hashName,
        "hashString": hashString,
        "hashType": hashType,
        "postSalt": postSalt
      }),
    );

    print("⬅ RAW BACKEND RESPONSE = ${response.body}");

    final data = jsonDecode(response.body);
    print("PARSED = $data");

    return data["result"].toString();
  }

  // -----------------------------------------------------------
  // CALLBACKS
  // -----------------------------------------------------------
  @override
  onPaymentSuccess(response) {
    print("========================================");
    print("🎉 SUCCESS RESPONSE = $response");
    print("========================================");

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Payment Successful!")));
  }

  @override
  onPaymentFailure(response) {
    print("========================================");
    print("❌ FAILURE RESPONSE = $response");
    print("TYPE = ${response.runtimeType}");
    print("========================================");

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Payment Failed!")));
  }

  @override
  onPaymentCancel(response) {
    print("========================================");
    print("⚠ PAYMENT CANCELLED = $response");
    print("========================================");

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Payment Cancelled")));
  }

  @override
  onError(response) {
    print("========================================");
    print("⚠ PAYU ERROR = $response");
    print("========================================");

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Something went wrong")));
  }
}

//permissions
  //  <queries>
  //       <!-- Needed for URL launcher (UPI / Google Pay deep links) -->
  //       <intent>
  //           <action android:name="android.intent.action.VIEW"/>
  //           <category android:name="android.intent.category.BROWSABLE"/>
  //           <data android:scheme="upi"/>
  //       </intent>

  //       <intent>
  //           <action android:name="android.intent.action.VIEW"/>
  //           <category android:name="android.intent.category.BROWSABLE"/>
  //           <data android:scheme="https"/>
  //       </intent>
        
  //   </queries>

  
        // <!-- PayU Checkout Meta Data (Enable all payment options) -->
        // <meta-data android:name="payu_checkout_pro_wallet_enabled" android:value="true" />
        // <meta-data android:name="payu_checkout_pro_upi_enabled" android:value="true" />
        // <meta-data android:name="payu_checkout_pro_netbanking_enabled" android:value="true" />
        // <meta-data android:name="payu_checkout_pro_cards_enabled" android:value="true" />

        // <!-- Enable Google Pay using placeholders from build.gradle -->
        // <meta-data
        //     android:name="enableGPay"
        //     android:value="${enableGPay}" />
        // <meta-data
        //     android:name="enableGPaySdk"
        //     android:value="${enableGPaySdk}" />

        // <!-- Required for Google Pay integration -->
        // <activity
        //     android:name="com.payu.gpay.GPayResponseActivity"
        //     android:exported="true"
        //     android:launchMode="singleTask"
        //     android:theme="@android:style/Theme.Translucent.NoTitleBar"
        //    tools:replace="android:theme">
            
        //     <intent-filter>
        //         <action android:name="android.intent.action.VIEW" />
        //         <category android:name="android.intent.category.DEFAULT" />
        //         <data android:scheme="payu" />
        //     </intent-filter>
        // </activity>
