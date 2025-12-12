import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';

// paytm payment Gateway
class PaytmPaymentScreen extends StatefulWidget {
  const PaytmPaymentScreen({super.key});

  @override
  State<PaytmPaymentScreen> createState() => _PaytmPaymentScreenState();
}

class _PaytmPaymentScreenState extends State<PaytmPaymentScreen> {
  bool isLoading = false;

  Future<void> startPayment() async {
    setState(() {
      isLoading = true;
    });

    String orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";

    String customerId = "CUST1001";
    String amount = "1";

    /// Step 1 → Call your backend to get txnToken
    final response = await http.post(
      Uri.parse(
          "https://www.bestbus.in/webservices/api/paytm_generate_txn_token"),
      body: {
        "orderId": orderId,
        "customerId": customerId,
        "amount": amount,
      },
    );

    final data = jsonDecode(response.body);

    print("Full Paytm Response: $data");

    String mid = "TRAINN43760507490919";
    String txnToken = data["result"]["body"]["txnToken"];

    print("Extracted TxnToken = $txnToken");

    /// Step 2 → Start Paytm Transaction
    try {
      var result = await AllInOneSdk.startTransaction(
        mid,
        orderId,
        amount,
        txnToken,
        "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId",
        false, // true = staging, false = production
        false,
      );

      debugPrint("Payment Success: $result");
      if (result!["STATUS"] == "TXN_SUCCESS") {
        String orderId = result["ORDERID"];
        String txnId = result["TXNID"];
        String bankTxnId = result["BANKTXNID"];
        String amount = result["TXNAMOUNT"];
        String message = result["RESPMSG"];
        String date = result["TXNDATE"];

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Payment Successful 🎉"),
            content: Text("Order ID: $orderId\n"
                "Txn ID: $txnId\n"
                "Bank Ref: $bankTxnId\n"
                "Amount: ₹$amount\n"
                "Message: $message\n"
                "Date: $date\n"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

      /// Step 3 → Verify payment from server
      // verifyPayment(orderId);
    } catch (error) {
      debugPrint("Payment Failed: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> verifyPayment(String orderId) async {
    final res = await http.post(
      Uri.parse("https://yourserver.com/getPaymentStatus"),
      body: {"orderId": orderId},
    );

    debugPrint("Final Payment Status: ${res.body}");

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Completed: ${res.body}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paytm Payment"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: startPayment,
                child: const Text("Pay ₹1"),
              ),
      ),
    );
  }
  // permissions
  //          <!-- paytm-->
  //       <activity
  //         android:name="com.paytm.pgsdk.PaytmPGActivity"
  //         android:exported="false"/>

  //     <activity
  //         android:name="com.paytm.pgsdk.IntentService"
  //         android:exported="false"/>
  //     <activity
  // android:name="com.paytm.pgsdk.threeds.ThreeDSWebviewActivity"
  // android:exported="false" />
}
