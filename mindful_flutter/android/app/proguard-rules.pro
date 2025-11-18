# Flutter specific rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Google APIs
-keep class com.google.api.client.** { *; }
-keep class com.google.auth.** { *; }
-keep class com.google.common.** { *; }
-dontwarn com.google.**

# Keep all custom app classes
-keep class com.neubofy.mindful.** { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
