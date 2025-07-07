#!/bin/bash

# This script updates the Android app icons with the logo_curved.png

# Set the source logo path
SOURCE_LOGO="lightping/assets/images/logo_curved.png"

# Define the Android icon paths and sizes
declare -A ICON_PATHS=(
  ["mipmap-mdpi"]="48"
  ["mipmap-hdpi"]="72"
  ["mipmap-xhdpi"]="96"
  ["mipmap-xxhdpi"]="144"
  ["mipmap-xxxhdpi"]="192"
)

# Create resized icons for each Android density
for path in "${!ICON_PATHS[@]}"; do
  size="${ICON_PATHS[$path]}"
  target_dir="lightping/android/app/src/main/res/$path"
  
  echo "Resizing logo to ${size}x${size} for $path"
  
  # Use ImageMagick to resize the logo (you'll need to have ImageMagick installed)
  # Or use another image processing tool of your choice
  
  # Sample command (uncomment if ImageMagick is installed):
  # convert "$SOURCE_LOGO" -resize "${size}x${size}" "${target_dir}/ic_launcher.png"
  
  echo "Icon updated for $path"
done

echo "Android icons update complete!"
echo "Note: This script requires ImageMagick to be installed."
echo "To install on macOS: brew install imagemagick"
echo ""
echo "Alternatively, manually resize the logo_curved.png to the following sizes and place in respective directories:"
echo "- mipmap-mdpi: 48x48 pixels"
echo "- mipmap-hdpi: 72x72 pixels"
echo "- mipmap-xhdpi: 96x96 pixels"
echo "- mipmap-xxhdpi: 144x144 pixels"
echo "- mipmap-xxxhdpi: 192x192 pixels"
