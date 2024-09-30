import 'package:flutter/material.dart';
import 'package:Doune/Tract/Report.dart';
import 'package:Doune/Tract/Share.dart';
import 'package:Doune/Tract/Block.dart';
import 'package:Doune/Widget/DraggableHandle.dart';

class TractSheet extends StatelessWidget {
  final int userId;

  TractSheet({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const DraggableHandle(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildListItem(
                  context,
                  'Report',
                  Icons.report,
                  Colors.lightBlueAccent,
                  Colors.redAccent,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportTractSheet()),
                  ),
                ),
                _buildListItem(
                  context,
                  'Block',
                  Icons.block,
                  Colors.lightBlueAccent,
                  Colors.redAccent,
                      () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) {
                        return BlockTractSheet(userid: userId);
                      },
                    );
                  },
                ),
                _buildListItem(
                  context,
                  'Share This Account',
                  Icons.share,
                  Colors.lightBlueAccent,
                  Colors.blueAccent,
                      () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const ShareThisAccount(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context,
      String title,
      IconData icon,
      Color backgroundColor,
      Color iconColor,
      VoidCallback onTap,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        title: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        trailing: Icon(icon, size: 20, color: iconColor),
        onTap: onTap,
      ),
    );
  }
}
