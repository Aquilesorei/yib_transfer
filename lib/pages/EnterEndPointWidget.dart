import 'package:flutter/material.dart';

import '../models/PeerEndpoint.dart';
import '../routes/FileTransfert.dart';

class EnterEndPointWidget extends StatefulWidget {
  const EnterEndPointWidget({super.key});

  @override
  State<EnterEndPointWidget>createState() => _EnterEndPointWidgetState();
}

class _EnterEndPointWidgetState extends State<EnterEndPointWidget> {
  final TextEditingController _endpointController = TextEditingController();
  String _validationError = '';
  @override
  void dispose() {
    _endpointController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Peer Endpoint'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _endpointController,
                decoration:  InputDecoration(
                  labelText: 'Peer Endpoint',
                  border: const OutlineInputBorder(),
                  errorText:  _validationError,
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  String enteredEndpoint = _endpointController.text;
                  if(isValidEnPoint(enteredEndpoint)){
                    final ep = PeerEndpoint.parse(enteredEndpoint);
                    FileTransfer.instance.connectedEndpoints.add(ep);

                    FileTransfer.instance.register();

                    setState(() {
                      _validationError = '';
                    });
                  }else{

                    setState(() {
                      _validationError = 'Enter a valid endpoint (e.g., 192.168.1.1:8080)';
                    });
                  }

                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}