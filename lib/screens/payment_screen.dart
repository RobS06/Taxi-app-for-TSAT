import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment Successful! Ride confirmed.'),
            backgroundColor: Colors.green));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter Mock Payment Details',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Card Number',
                        hintText: 'xxxx xxxx xxxx xxxx'),
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.length < 16)
                        ? 'Enter a valid card number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Expiry Date (MM/YY)',
                              hintText: 'MM/YY'),
                          keyboardType: TextInputType.datetime,
                          validator: (val) => (val == null || val.length < 5)
                              ? 'Enter MM/YY'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'CVC', hintText: 'xxx'),
                          keyboardType: TextInputType.number,
                          validator: (val) => (val == null || val.length < 3)
                              ? 'Enter CVC'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _processPayment,
                          child: const Text('Pay Now')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
