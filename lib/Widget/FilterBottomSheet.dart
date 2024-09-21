import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:Doune/Filters/Models/filter.dart';
import 'package:Doune/Filters/Data/filter_data.dart';

class FilterBottomSheet extends StatefulWidget {
  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  bool _isSearchMode = false;
  TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Save'; // Default to 'Save' category
  String? _selectedFilter;
  List<Filters> _filteredFilters = [];
  List<Filters> _allFilters = filters; // Keep a list of all filters

  final Map<String, List<Filters>> _filters = {
    'Save': filters,
    'Trending': TrendingFilters,
    'New': filters,
    'Funny': FunnyFilters,
    'Beauty': BeautyFilters,
  };

  @override
  void initState() {
    super.initState();
    _filteredFilters = _filters[_selectedCategory] ?? [];
  }

  void _filterSearchResults(String query) {
    if (query.isNotEmpty) {
      setState(() {
        _filteredFilters = _allFilters
            .where((filter) => filter.nameFilter.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } else {
      setState(() {
        _filteredFilters = _filters[_selectedCategory] ?? []; // Reset to the current category filters
      });
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredFilters = _filters[category] ?? [];
    });
  }

  // Generate a random color
  Color _getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: FractionallySizedBox(
            heightFactor: 0.6, // Adjust heightFactor to reduce height
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.0,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSearchMode ? Icons.close : Icons.filter_alt_outlined,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isSearchMode) {
                              _isSearchMode = false;
                              _searchController.clear();
                              _filteredFilters = _filters[_selectedCategory] ?? [];
                            } else {
                              Navigator.pop(context);
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: _isSearchMode
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search filter...',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(Icons.search),
                                onPressed: () {
                                  _filterSearchResults(_searchController.text);
                                },
                              ),
                            ),
                            onChanged: (value) {
                              _filterSearchResults(value);
                            },
                          ),
                        )
                            : Container(
                          height: 50,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _filters.keys.map((category) {
                              return FilterButton(
                                category,
                                isSelected: _selectedCategory == category,
                                onTap: () {
                                  _selectCategory(category);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (!_isSearchMode)
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            setState(() {
                              _isSearchMode = true;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(3.0), // Reduce padding to fit content
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Number of items per row
                      crossAxisSpacing: 4.0, // Reduce spacing between items
                      mainAxisSpacing: 4.0, // Reduce spacing between items
                    ),
                    itemCount: _filteredFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _filteredFilters[index];
                      final isSelected = _selectedFilter == filter.filterPath;
                      final itemColor = _getRandomColor(); // Get a random color for the item
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter.filterPath;
                          });
                          // Notify parent about the selected filter
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blueAccent : itemColor,
                            borderRadius: BorderRadius.circular(8.0), // Adjust border radius
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Center align items
                            crossAxisAlignment: CrossAxisAlignment.center, // Center align items
                            children: [
                              SizedBox(
                                width: 35, // Adjust width of the image
                                height: 35, // Adjust height of the image
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0), // Adjust border radius
                                  child: Image.asset(
                                    filter.imagePath, // Path to your filter images
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0), // Increase padding slightly
                                child: Text(
                                  filter.nameFilter, // Display filter name
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontSize: isSelected ? 10.0 : 12.0, // Adjust font size
                                    fontWeight: FontWeight.bold, // Bold font
                                  ),
                                  textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton(this.text, {required this.isSelected, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0), // Reduce horizontal padding
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(text),
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.black,
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}

void _showFilterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(),
  );
}