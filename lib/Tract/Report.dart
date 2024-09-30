import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package

class ReportTractSheet extends StatelessWidget {
  const ReportTractSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          'Report User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Close the sheet
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why do you want to report this user?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'If you see anyone behaving dangerously or violating social norms, please report it to us!',
              ),
              const SizedBox(height: 16),
              _buildDetailItem(context, 'Impersonation'),
              _buildDetailItem(context, 'Fake Account'),
              _buildDetailItem(context, 'Fake Name'),
              _buildDetailItem(context, 'Harassment or Bullying'),
              _buildDetailItem(context, 'Other Issues'),
              _buildDetailItem(context, 'I want to help'),
              const SizedBox(height: 20), // Spacing before the Lottie animation
              Center(
                child: Lottie.network(
                  'https://lottie.host/a07f9d00-35ff-48bc-982a-5df1aa286fbd/Ywys6vMZD4.json',
                  height: 250, // Set the height of the Lottie animation
                  width: 250, // Set the width to fill the container

                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String title) {
    return Column(
      children: [
        ReportItem(title: title),
        const Divider(thickness: 1.0), // Line under each item
      ],
    );
  }
}

class ReportItem extends StatefulWidget {
  final String title;

  const ReportItem({required this.title});

  @override
  _ReportItemState createState() => _ReportItemState();
}

class _ReportItemState extends State<ReportItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          // Handle tap action for the detail item
          Navigator.pop(context); // You can replace this with your desired action
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 0), // Space between items
          child: ListTile(
            title: Text(widget.title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16), // Arrow icon
            tileColor: _isHovered ? Colors.lightBlueAccent.withOpacity(0.2) : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
