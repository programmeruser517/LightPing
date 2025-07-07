# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.support.** { *; }

# Keep custom model classes if used
-keepclassmembers class * implements org.tensorflow.lite.Interpreter$Options { *; }
-keepclassmembers class * implements org.tensorflow.lite.gpu.GpuDelegate$Options { *; }
-keepclassmembers class * implements org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}
