class PlantSpecies {
  final String name;
  final String scientificName;
  final String category;
  final String description;
  final int avgGrowthDaysToMaturity;
  final double avgHeightMeters;
  final String wateringNeeds;
  final String sunlightNeeds;
  final List<String> benefits;
  final String icon;

  PlantSpecies({
    required this.name,
    required this.scientificName,
    required this.category,
    required this.description,
    required this.avgGrowthDaysToMaturity,
    required this.avgHeightMeters,
    required this.wateringNeeds,
    required this.sunlightNeeds,
    required this.benefits,
    required this.icon,
  });
}

class SpeciesDatabase {
  static final List<PlantSpecies> _species = [
    // Fruit Trees
    PlantSpecies(
      name: 'Mango',
      scientificName: 'Mangifera indica',
      category: 'Fruit Tree',
      description: 'Tropical fruit tree producing sweet mangoes',
      avgGrowthDaysToMaturity: 1095, // 3 years
      avgHeightMeters: 10.0,
      wateringNeeds: 'Moderate - Water regularly during dry season',
      sunlightNeeds: 'Full sun (6-8 hours daily)',
      benefits: ['Fruit production', 'Shade', 'Carbon sequestration'],
      icon: '🥭',
    ),
    PlantSpecies(
      name: 'Coconut',
      scientificName: 'Cocos nucifera',
      category: 'Fruit Tree',
      description: 'Tall palm tree producing coconuts',
      avgGrowthDaysToMaturity: 1825, // 5 years
      avgHeightMeters: 20.0,
      wateringNeeds: 'High - Needs consistent moisture',
      sunlightNeeds: 'Full sun (8+ hours daily)',
      benefits: ['Fruit production', 'Oil production', 'Fiber'],
      icon: '🥥',
    ),
    PlantSpecies(
      name: 'Banana',
      scientificName: 'Musa',
      category: 'Fruit Tree',
      description: 'Fast-growing tropical plant producing bananas',
      avgGrowthDaysToMaturity: 270, // 9 months
      avgHeightMeters: 5.0,
      wateringNeeds: 'High - Water daily in hot weather',
      sunlightNeeds: 'Full sun to partial shade',
      benefits: ['Quick fruit production', 'Soil improvement'],
      icon: '🍌',
    ),
    PlantSpecies(
      name: 'Papaya',
      scientificName: 'Carica papaya',
      category: 'Fruit Tree',
      description: 'Fast-growing tree with nutritious fruits',
      avgGrowthDaysToMaturity: 180, // 6 months
      avgHeightMeters: 4.0,
      wateringNeeds: 'Moderate - Regular watering needed',
      sunlightNeeds: 'Full sun (6+ hours daily)',
      benefits: ['Quick fruit production', 'Medicinal properties'],
      icon: '🍈',
    ),
    PlantSpecies(
      name: 'Guava',
      scientificName: 'Psidium guajava',
      category: 'Fruit Tree',
      description: 'Hardy tree producing vitamin C-rich fruits',
      avgGrowthDaysToMaturity: 730, // 2 years
      avgHeightMeters: 6.0,
      wateringNeeds: 'Low to Moderate - Drought tolerant',
      sunlightNeeds: 'Full sun preferred',
      benefits: ['Fruit production', 'Medicinal leaves', 'Hardy'],
      icon: '🍐',
    ),

    // Medicinal Trees
    PlantSpecies(
      name: 'Neem',
      scientificName: 'Azadirachta indica',
      category: 'Medicinal Tree',
      description: 'Versatile medicinal tree with pest-repellent properties',
      avgGrowthDaysToMaturity: 1095, // 3 years
      avgHeightMeters: 15.0,
      wateringNeeds: 'Low - Very drought tolerant',
      sunlightNeeds: 'Full sun',
      benefits: ['Medicinal', 'Natural pesticide', 'Shade', 'Air purification'],
      icon: '🌿',
    ),
    PlantSpecies(
      name: 'Tulsi (Holy Basil)',
      scientificName: 'Ocimum sanctum',
      category: 'Medicinal Plant',
      description: 'Sacred medicinal plant with healing properties',
      avgGrowthDaysToMaturity: 90, // 3 months
      avgHeightMeters: 0.6,
      wateringNeeds: 'Moderate - Keep soil moist',
      sunlightNeeds: 'Full sun to partial shade',
      benefits: ['Medicinal', 'Air purification', 'Spiritual significance'],
      icon: '🌱',
    ),
    PlantSpecies(
      name: 'Ashwagandha',
      scientificName: 'Withania somnifera',
      category: 'Medicinal Plant',
      description: 'Ayurvedic herb known for stress relief',
      avgGrowthDaysToMaturity: 180, // 6 months
      avgHeightMeters: 1.5,
      wateringNeeds: 'Low - Drought tolerant',
      sunlightNeeds: 'Full sun',
      benefits: ['Medicinal', 'Adaptogenic properties'],
      icon: '🌿',
    ),

    // Timber Trees
    PlantSpecies(
      name: 'Teak',
      scientificName: 'Tectona grandis',
      category: 'Timber Tree',
      description: 'Valuable hardwood tree',
      avgGrowthDaysToMaturity: 7300, // 20 years
      avgHeightMeters: 30.0,
      wateringNeeds: 'Moderate - Seasonal watering',
      sunlightNeeds: 'Full sun',
      benefits: ['Timber', 'Carbon sequestration', 'Soil conservation'],
      icon: '🌳',
    ),
    PlantSpecies(
      name: 'Bamboo',
      scientificName: 'Bambusoideae',
      category: 'Timber/Grass',
      description: 'Fast-growing versatile plant',
      avgGrowthDaysToMaturity: 1095, // 3 years
      avgHeightMeters: 12.0,
      wateringNeeds: 'High - Needs consistent moisture',
      sunlightNeeds: 'Full sun to partial shade',
      benefits: ['Construction material', 'Fast growth', 'Erosion control'],
      icon: '🎋',
    ),

    // Flowering Trees
    PlantSpecies(
      name: 'Gulmohar',
      scientificName: 'Delonix regia',
      category: 'Flowering Tree',
      description: 'Beautiful tree with red-orange flowers',
      avgGrowthDaysToMaturity: 1825, // 5 years
      avgHeightMeters: 12.0,
      wateringNeeds: 'Low to Moderate',
      sunlightNeeds: 'Full sun',
      benefits: ['Ornamental', 'Shade', 'Nitrogen fixation'],
      icon: '🌺',
    ),
    PlantSpecies(
      name: 'Jacaranda',
      scientificName: 'Jacaranda mimosifolia',
      category: 'Flowering Tree',
      description: 'Stunning purple flowering tree',
      avgGrowthDaysToMaturity: 2555, // 7 years
      avgHeightMeters: 15.0,
      wateringNeeds: 'Moderate',
      sunlightNeeds: 'Full sun',
      benefits: ['Ornamental', 'Shade'],
      icon: '💜',
    ),

    // Native/Indigenous Trees
    PlantSpecies(
      name: 'Peepal',
      scientificName: 'Ficus religiosa',
      category: 'Native Tree',
      description: 'Sacred tree with spiritual significance',
      avgGrowthDaysToMaturity: 3650, // 10 years
      avgHeightMeters: 20.0,
      wateringNeeds: 'Low - Very hardy',
      sunlightNeeds: 'Full sun',
      benefits: ['Oxygen production', 'Spiritual', 'Shade', 'Wildlife habitat'],
      icon: '🌳',
    ),
    PlantSpecies(
      name: 'Banyan',
      scientificName: 'Ficus benghalensis',
      category: 'Native Tree',
      description: 'Massive tree with aerial roots',
      avgGrowthDaysToMaturity: 3650, // 10 years
      avgHeightMeters: 25.0,
      wateringNeeds: 'Low to Moderate',
      sunlightNeeds: 'Full sun',
      benefits: ['Massive shade', 'Wildlife habitat', 'Cultural significance'],
      icon: '🌳',
    ),
  ];

  // Get all species
  static List<PlantSpecies> getAllSpecies() => _species;

  // Get species by category
  static List<PlantSpecies> getByCategory(String category) {
    return _species.where((s) => s.category == category).toList();
  }

  // Get all categories
  static List<String> getCategories() {
    return _species.map((s) => s.category).toSet().toList()..sort();
  }

  // Search species by name
  static List<PlantSpecies> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _species.where((s) => 
      s.name.toLowerCase().contains(lowerQuery) ||
      s.scientificName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get species by name
  static PlantSpecies? getByName(String name) {
    try {
      return _species.firstWhere((s) => s.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Get all species names for dropdown
  static List<String> getSpeciesNames() {
    return _species.map((s) => s.name).toList()..sort();
  }

  // Get growth expectations for a species
  static String getGrowthExpectation(String speciesName, int daysPlanted) {
    final species = getByName(speciesName);
    if (species == null) return 'Unknown species';

    final progress = (daysPlanted / species.avgGrowthDaysToMaturity * 100).clamp(0, 100);
    
    if (progress < 25) {
      return 'Early growth stage (${progress.toStringAsFixed(0)}% to maturity)';
    } else if (progress < 50) {
      return 'Developing stage (${progress.toStringAsFixed(0)}% to maturity)';
    } else if (progress < 75) {
      return 'Maturing stage (${progress.toStringAsFixed(0)}% to maturity)';
    } else if (progress < 100) {
      return 'Near maturity (${progress.toStringAsFixed(0)}% to maturity)';
    } else {
      return 'Mature tree';
    }
  }
}
