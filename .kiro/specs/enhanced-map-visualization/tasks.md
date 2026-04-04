# Implementation Plan: Enhanced Map Visualization

## Overview

This implementation plan breaks down the enhanced map visualization feature into discrete coding tasks. The feature replaces standard Google Maps markers with custom circular dots color-coded by tree health, includes clustering for zoomed-out views, provides filtering capabilities, and displays a collapsible legend. Each task builds incrementally on previous work, with property-based tests to validate correctness properties from the design document.

## Tasks

- [x] 1. Set up core data models and enums
  - Create HealthStatus enum (healthy, needsAttention, critical, newPlantation)
  - Create TreeHealthStatus class with status, color, reason, daysSinceUpdate fields
  - Create FilterMode enum (showAll, healthyOnly, needsAttentionOnly, criticalOnly)
  - Create MapItem abstract class with IndividualTreeItem and ClusterItem implementations
  - _Requirements: 1.1, 1.6, 1.7, 4.1_

- [ ]* 1.1 Write property test for data model validation
  - **Property 1: Health Status Consistency** - Verify status enum matches color (green=healthy, yellow=needsAttention, red=critical, gray=newPlantation)
  - **Validates: Requirements 1.1, 1.2, 1.3, 1.5**

- [x] 2. Implement HealthCalculator service
  - [x] 2.1 Create HealthCalculator class with calculateHealth() static method
    - Implement logic for new plantations (no updates → gray)
    - Implement logic for good condition with time-based degradation (< 30 days → green, 30-60 days → yellow, 60+ days → red)
    - Implement logic for moderate condition (→ yellow)
    - Implement logic for poor condition (→ red)
    - Calculate daysSinceLastUpdate accurately
    - Generate human-readable reason strings
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_
  
  - [x] 2.2 Create getHealthColor() helper method
    - Map HealthStatus enum to Flutter Color objects
    - Use colors from AppTheme for consistency
    - _Requirements: 1.1, 1.2, 1.3, 1.5, 12.1_
  
  - [x] 2.3 Create getDaysSinceLastUpdate() helper method
    - Parse ISO 8601 datetime strings
    - Calculate day difference from current date
    - Handle edge cases (no updates, invalid dates)
    - _Requirements: 1.6_

- [ ]* 2.4 Write unit tests for HealthCalculator
  - Test new plantation returns gray status
  - Test good condition with recent update returns green
  - Test good condition with 30+ day old update returns yellow
  - Test good condition with 60+ day old update returns red
  - Test moderate condition returns yellow
  - Test poor condition returns red
  - Test edge cases: exactly 30 days, exactly 60 days
  - Test invalid date handling with default to "Good" condition
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.3_

- [ ]* 2.5 Write property test for time-based health degradation
  - **Property 9: Time-Based Health Degradation** - Verify trees with 60+ days since update are never healthy
  - **Validates: Requirements 1.3, 1.5**

- [x] 3. Implement MarkerGenerator service
  - [x] 3.1 Create MarkerGenerator class with marker cache
    - Implement LRU cache with max 50 entries
    - Create cache key generation (color + size + pulse)
    - Implement cache clear functionality
    - _Requirements: 2.5, 11.1_
  
  - [x] 3.2 Implement createCircularMarker() method
    - Use Flutter Canvas API to draw circular markers
    - Accept color, size, and shouldPulse parameters
    - Implement pulsing effect for critical markers
    - Convert Canvas to BitmapDescriptor
    - Cache generated markers
    - _Requirements: 2.1, 2.4, 2.5_
  
  - [x] 3.3 Implement marker size calculation logic
    - Base size of 24 pixels
    - Add 2 pixels per update count
    - Cap maximum size at 40 pixels
    - _Requirements: 2.2, 2.3_
  
  - [x] 3.4 Implement generateMarkersForTrees() method
    - Calculate health status for each tree
    - Determine marker size based on update count
    - Generate or retrieve cached marker icons
    - Create Marker objects with unique markerIds
    - Configure InfoWindow with tree name and health info
    - Bind onTap callback to each marker
    - _Requirements: 2.1, 2.6, 7.1, 7.3, 9.3_
  
  - [x] 3.5 Implement createClusterMarker() method
    - Draw circular marker with count label
    - Use appropriate color for cluster
    - Size based on cluster count
    - _Requirements: 3.7_

- [ ]* 3.6 Write unit tests for MarkerGenerator
  - Test circular marker creation with various colors
  - Test marker size calculation (24-40 pixel range)
  - Test pulsing marker for critical status
  - Test cache hit/miss scenarios
  - Test cluster marker with count label
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ]* 3.7 Write property test for marker uniqueness
  - **Property 2: Marker Uniqueness** - Verify all markerIds in generated set are unique
  - **Validates: Requirements 7.1, 7.2, 7.3**

- [ ]* 3.8 Write property test for marker size bounds
  - **Property 8: Marker Size Bounds** - Verify all markers are between 24-40 pixels
  - **Validates: Requirements 2.3**

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement ClusteringService
  - [x] 5.1 Create ClusteringService class with clustering constants
    - Define clusteringZoomThreshold (12.0)
    - Define clusteringDistanceThreshold (0.01 degrees)
    - _Requirements: 3.1, 3.2_
  
  - [x] 5.2 Implement clusterTrees() method
    - Check zoom level against threshold
    - Return individual items if zoomed in
    - Apply grid-based clustering algorithm if zoomed out
    - Calculate grid cell size based on zoom level
    - Group trees into grid cells
    - Create IndividualTreeItem for single-tree cells
    - Create ClusterItem for multi-tree cells
    - _Requirements: 3.1, 3.2, 3.3, 3.6_
  
  - [x] 5.3 Implement cluster center calculation
    - Calculate centroid (average lat/lng) of trees in cluster
    - Validate center is within bounds of constituent trees
    - _Requirements: 3.4_
  
  - [x] 5.4 Implement getClusterColor() method
    - Determine worst health status in cluster
    - Return color for worst status (critical > needsAttention > healthy > newPlantation)
    - _Requirements: 3.5_

- [ ]* 5.5 Write unit tests for ClusteringService
  - Test no clustering when zoom >= threshold
  - Test clustering when zoom < threshold
  - Test single tree in cell remains individual
  - Test multiple trees in cell create cluster
  - Test cluster center calculation
  - Test cluster color determination (worst health)
  - Test empty tree list handling
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ]* 5.6 Write property test for tree conservation
  - **Property 3: Tree Conservation in Clustering** - Verify total trees before clustering equals total in result
  - **Validates: Requirements 3.6**

- [ ]* 5.7 Write property test for cluster minimum size
  - **Property 5: Cluster Minimum Size** - Verify all clusters contain at least 2 trees
  - **Validates: Requirements 3.3**

- [ ]* 5.8 Write property test for cluster color worst-case
  - **Property 10: Cluster Color Worst-Case** - Verify cluster color matches worst health in cluster
  - **Validates: Requirements 3.5**

- [x] 6. Implement FilterController
  - [x] 6.1 Create FilterController class extending ChangeNotifier
    - Maintain _currentFilter state (default: showAll)
    - Implement setFilter() method with notifyListeners()
    - _Requirements: 4.1, 4.5_
  
  - [x] 6.2 Implement applyFilter() method
    - Calculate health status for each tree
    - Filter based on current filter mode
    - Maintain original tree order
    - Handle showAll, healthyOnly, needsAttentionOnly, criticalOnly modes
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.7_
  
  - [x] 6.3 Implement getHealthCounts() method
    - Calculate count for each HealthStatus
    - Return Map<HealthStatus, int>
    - Ensure counts are non-negative
    - _Requirements: 5.2_

- [ ]* 6.4 Write unit tests for FilterController
  - Test showAll returns all trees
  - Test healthyOnly returns only healthy trees
  - Test needsAttentionOnly returns only yellow trees
  - Test criticalOnly returns only red trees
  - Test health count calculation accuracy
  - Test filter change notification
  - Test empty tree list handling
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.7_

- [ ]* 6.5 Write property test for filter correctness
  - **Property 4: Filter Correctness** - Verify filtered trees match active filter mode
  - **Validates: Requirements 4.2, 4.3, 4.4, 4.5**

- [x] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement MapLegendWidget
  - [x] 8.1 Create MapLegendWidget StatefulWidget
    - Accept healthCounts and initiallyExpanded parameters
    - Create _MapLegendWidgetState with _isExpanded state
    - _Requirements: 5.1, 5.3_
  
  - [x] 8.2 Implement legend UI layout
    - Position legend in non-intrusive location (top-right or bottom-left)
    - Use floating overlay with semi-transparent background
    - Apply consistent styling from AppTheme
    - _Requirements: 5.5, 12.1, 12.2, 12.4_
  
  - [x] 8.3 Implement _buildLegendItem() method
    - Display color circle with health status label
    - Show count for each status
    - Use consistent typography
    - _Requirements: 5.1, 5.2, 12.4_
  
  - [x] 8.4 Implement expand/collapse functionality
    - Add toggle button with icon
    - Animate expansion/collapse with 300ms duration
    - Preserve expanded state during filter changes
    - _Requirements: 5.3, 12.5_
  
  - [x] 8.5 Implement dynamic count updates
    - Update displayed counts when healthCounts prop changes
    - Ensure sum of counts equals total visible trees
    - _Requirements: 5.4, 5.6_

- [ ]* 8.6 Write widget tests for MapLegendWidget
  - Test legend displays all health statuses
  - Test counts are displayed correctly
  - Test expand/collapse functionality
  - Test count updates when prop changes
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ]* 8.7 Write property test for legend count accuracy
  - **Property 7: Legend Count Accuracy** - Verify sum of legend counts equals total visible trees
  - **Validates: Requirements 5.6**

- [x] 9. Implement MapVisualizationWidget
  - [x] 9.1 Create MapVisualizationWidget StatefulWidget
    - Accept trees and onTreeTap parameters
    - Create _MapVisualizationWidgetState with necessary state variables
    - Initialize FilterController
    - _Requirements: 9.1, 9.3_
  
  - [x] 9.2 Implement _onMapCreated() callback
    - Store GoogleMapController reference
    - Apply any queued marker updates
    - _Requirements: 10.4_
  
  - [x] 9.3 Implement _onCameraMove() callback
    - Debounce with 300ms delay
    - Update _currentZoom state
    - Trigger marker regeneration if zoom crosses clustering threshold
    - _Requirements: 8.4, 8.5_
  
  - [x] 9.4 Implement _updateMarkers() method
    - Apply filter to trees
    - Determine if clustering needed based on zoom
    - Call ClusteringService.clusterTrees() if needed
    - Generate markers using MarkerGenerator
    - Update _markers state
    - Calculate health counts for legend
    - _Requirements: 3.1, 3.2, 4.6, 8.5_
  
  - [x] 9.5 Implement _onFilterChanged() callback
    - Update filter in FilterController
    - Trigger _updateMarkers() with smooth animation
    - _Requirements: 4.6, 12.5_
  
  - [x] 9.6 Implement coordinate validation
    - Validate latitude (-90 to 90) and longitude (-180 to 180)
    - Log warning for invalid coordinates
    - Skip marker generation for invalid trees
    - Continue processing remaining trees
    - Display error notification for admin users
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [x] 9.7 Implement error handling
    - Catch marker generation failures and fall back to default markers
    - Implement clustering timeout (2 seconds) with fallback to individual markers
    - Queue marker updates if controller not initialized
    - Handle filter state inconsistency with recalculation and reset
    - Log all errors with detailed information
    - _Requirements: 10.1, 10.2, 10.4, 10.5, 10.6_
  
  - [x] 9.8 Build widget tree
    - Create GoogleMap widget with initial camera position
    - Configure map with markers set
    - Add MapLegendWidget as Stack overlay
    - Wire up all callbacks (onMapCreated, onCameraMove, marker onTap)
    - Apply consistent styling (border radius, border color)
    - _Requirements: 2.6, 5.5, 9.3, 12.2_

- [ ]* 9.9 Write widget tests for MapVisualizationWidget
  - Test map initialization
  - Test marker updates on filter change
  - Test marker updates on zoom change
  - Test coordinate validation
  - Test error handling scenarios
  - _Requirements: 4.6, 6.1, 6.2, 6.3, 10.1, 10.2, 10.4_

- [ ]* 9.10 Write property test for coordinate validity
  - **Property 6: Coordinate Validity** - Verify all markers have valid coordinates within bounds
  - **Validates: Requirements 6.1, 6.2**

- [x] 10. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Integrate with DashboardScreen
  - [x] 11.1 Replace existing GoogleMap widget with MapVisualizationWidget
    - Import MapVisualizationWidget
    - Pass _filteredTrees from dashboard state
    - Wire onTreeTap to navigate to tree detail screen
    - Preserve existing container styling (height, border radius, border)
    - _Requirements: 9.1, 9.3, 12.2_
  
  - [x] 11.2 Ensure search filter integration
    - Verify MapVisualizationWidget receives filtered trees from dashboard search
    - Test that search and health filters work together
    - _Requirements: 9.1, 9.2_
  
  - [x] 11.3 Implement navigation state preservation
    - Preserve map zoom level when returning from tree detail
    - Preserve filter settings when returning from tree detail
    - Reload data after tree detail screen updates
    - _Requirements: 9.4_

- [ ]* 11.4 Write integration tests for dashboard integration
  - Test map displays with sample tree data
  - Test marker tap navigates to tree detail
  - Test search filter affects map display
  - Test health filter affects map display
  - Test combined search and health filters
  - Test state preservation on navigation
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 12. Implement memory management
  - [x] 12.1 Add marker cache size limit enforcement
    - Implement LRU eviction when cache exceeds 50 entries
    - _Requirements: 11.1_
  
  - [x] 12.2 Implement cache clearing on app lifecycle events
    - Clear marker cache when app goes to background
    - Use WidgetsBindingObserver to detect lifecycle changes
    - _Requirements: 11.2_
  
  - [x] 12.3 Implement memory pressure handling
    - Detect memory pressure conditions
    - Reduce cache size and retry operations
    - _Requirements: 11.3_
  
  - [x] 12.4 Implement proper disposal
    - Dispose GoogleMapController in dispose() method
    - Dispose FilterController listeners
    - Clear marker cache on widget disposal
    - _Requirements: 11.4_
  
  - [x] 12.5 Implement device-appropriate marker resolution
    - Use MediaQuery to detect device pixel ratio
    - Adjust marker size based on pixel density
    - _Requirements: 11.5_

- [ ]* 12.6 Write tests for memory management
  - Test cache size limit enforcement
  - Test cache clearing on background
  - Test proper disposal of resources
  - _Requirements: 11.1, 11.2, 11.4_

- [x] 13. Performance optimization
  - [x] 13.1 Implement marker generation performance target
    - Profile marker generation with 500 trees
    - Optimize to complete in < 1 second
    - Use async/await to avoid blocking UI
    - _Requirements: 8.1_
  
  - [x] 13.2 Implement clustering performance target
    - Profile clustering with 1000 trees
    - Optimize to complete in < 500ms
    - Consider using isolates for large datasets
    - _Requirements: 8.2_
  
  - [x] 13.3 Verify frame rate during interactions
    - Test map panning and zooming
    - Ensure 60 FPS maintained
    - Profile and optimize any janky animations
    - _Requirements: 8.3_

- [ ]* 13.4 Write performance tests
  - Test marker generation time with 500 trees
  - Test clustering time with 1000 trees
  - Test frame rate during map interactions
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 14. Final integration and polish
  - [x] 14.1 Verify visual consistency with AppTheme
    - Ensure all colors match AppTheme constants
    - Verify border radius and styling consistency
    - Check typography matches dashboard
    - _Requirements: 12.1, 12.2, 12.4_
  
  - [x] 14.2 Verify color contrast for accessibility
    - Test health status colors for sufficient contrast
    - Ensure legend is readable
    - _Requirements: 12.3_
  
  - [x] 14.3 Test animation smoothness
    - Verify filter transitions use 300ms duration
    - Ensure smooth expand/collapse animations
    - Test marker update animations
    - _Requirements: 12.5_
  
  - [x] 14.4 Add any missing dependencies to pubspec.yaml
    - Verify google_maps_flutter version
    - Add collection package if needed for clustering utilities
    - _Requirements: All_

- [ ]* 14.5 Write end-to-end integration tests
  - Test complete workflow: load dashboard → view map → apply filters → tap marker → navigate
  - Test clustering behavior across zoom levels
  - Test legend updates with filter changes
  - Test error scenarios with invalid data
  - _Requirements: All_

- [x] 15. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties from the design document
- Checkpoints ensure incremental validation at key milestones
- The implementation uses Dart/Flutter as specified in the design document
- All marker generation and clustering operations should be optimized for performance
- Memory management is critical for handling large datasets (500+ trees)
