import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class LightDetectionService {
  // Singleton instance
  static final LightDetectionService _instance = LightDetectionService._internal();
  factory LightDetectionService() => _instance;
  LightDetectionService._internal();
  
  // Previous intensity values for comparison
  double _previousIntensity = 0.0;
  
  // Detection thresholds (configurable)
  double _intensityThreshold = 0.25;
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Debug mode
  bool _debugMode = false;
  
  /// Initialize the light detection service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // No need to load any external models, we use our own algorithm
    _isInitialized = true;
    print('Light detection service initialized with custom HSV-based detection');
  }
  
  /// Detect light changes in the given image
  /// Returns true if a significant light change is detected
  Future<bool> detectLightChange(XFile imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Read the image file
      final imageBytes = await File(imageFile.path).readAsBytes();
      
      // Decode the image
      final image = img.decodeImage(Uint8List.fromList(imageBytes));
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Calculate the light intensity using HSV-based detection
      final intensity = _calculateLightIntensity(image);
      
      // Calculate the difference from previous intensity
      final intensityDifference = (intensity - _previousIntensity).abs();
      
      // Update previous intensity
      _previousIntensity = intensity;
      
      // Check if the difference exceeds the threshold
      final isLightChange = intensityDifference > _intensityThreshold;
      
      // Debug info
      if (_debugMode || isLightChange) {
        print('Light intensity: $intensity, Difference: $intensityDifference, Detected: $isLightChange');
      }
      
      return isLightChange;
    } catch (e) {
      print('Error during light detection: $e');
      return false;
    }
  }
  
  /// Calculate the light intensity of an image using HSV color space
  /// Returns a value between 0.0 (no intensity) and 1.0 (max intensity)
  double _calculateLightIntensity(img.Image image) {
    // Sample pixels for efficiency (don't need to check every pixel)
    const sampleStep = 10;
    double totalIntensity = 0.0;
    int sampleCount = 0;
    
    for (int y = 0; y < image.height; y += sampleStep) {
      for (int x = 0; x < image.width; x += sampleStep) {
        // Get pixel color
        final pixel = image.getPixel(x, y);
        
        // Extract RGB components
        final r = pixel.r.toInt() / 255.0;
        final g = pixel.g.toInt() / 255.0;
        final b = pixel.b.toInt() / 255.0;
        
        // Convert RGB to HSV (Hue, Saturation, Value)
        final hsv = _rgbToHsv(r, g, b);
        
        // Extract saturation and value (brightness)
        final saturation = hsv[1];
        final value = hsv[2];
        
        // Calculate intensity based on saturation and value
        // This approach detects bright lights regardless of color
        final pixelIntensity = value * (1.0 + saturation * 0.5);
        
        totalIntensity += pixelIntensity;
        sampleCount++;
      }
    }
    
    // Calculate average intensity
    return sampleCount > 0 ? totalIntensity / sampleCount : 0.0;
  }
  
  /// Convert RGB to HSV color space
  /// Input: r,g,b values from 0.0 to 1.0
  /// Output: [h, s, v] where h is in degrees (0-360), s and v are 0.0-1.0
  List<double> _rgbToHsv(double r, double g, double b) {
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final delta = max - min;
    
    // Value is the maximum of r, g, b
    final v = max;
    
    // Saturation is 0 if max is 0, otherwise it's delta/max
    final s = max == 0.0 ? 0.0 : delta / max;
    
    // Hue calculation
    double h = 0.0;
    
    if (delta > 0.0) {
      if (max == r) {
        h = ((g - b) / delta) % 6.0;
      } else if (max == g) {
        h = ((b - r) / delta) + 2.0;
      } else { // max == b
        h = ((r - g) / delta) + 4.0;
      }
      
      h *= 60.0; // Convert to degrees
      if (h < 0.0) h += 360.0;
    }
    
    return [h, s, v];
  }
  
  /// Set the intensity threshold for light change detection
  void setIntensityThreshold(double threshold) {
    _intensityThreshold = threshold.clamp(0.05, 0.5);
  }
  
  /// Enable or disable debug mode
  void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }
  
  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
