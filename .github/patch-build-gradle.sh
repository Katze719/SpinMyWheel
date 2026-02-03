#!/bin/bash
# Script to patch build.gradle.kts with signing configuration
# Following official Tauri documentation

BUILD_GRADLE="$1"

# 1. Add import at the very beginning
sed -i '1i import java.io.FileInputStream' "$BUILD_GRADLE"

# 2. Insert signingConfigs block BEFORE buildTypes block
awk '
/^[[:space:]]*buildTypes[[:space:]]*\{/ {
    # Insert signing config before buildTypes
    print "    signingConfigs {"
    print "        create(\"release\") {"
    print "            val keystorePropertiesFile = rootProject.file(\"keystore.properties\")"
    print "            val keystoreProperties = Properties()"
    print "            if (keystorePropertiesFile.exists()) {"
    print "                keystoreProperties.load(FileInputStream(keystorePropertiesFile))"
    print "            }"
    print "            keyAlias = keystoreProperties[\"keyAlias\"] as String"
    print "            keyPassword = keystoreProperties[\"password\"] as String"
    print "            storeFile = file(keystoreProperties[\"storeFile\"] as String)"
    print "            storePassword = keystoreProperties[\"password\"] as String"
    print "        }"
    print "    }"
    print ""
}
{ print }
' "$BUILD_GRADLE" > "$BUILD_GRADLE.tmp"
mv "$BUILD_GRADLE.tmp" "$BUILD_GRADLE"

# 3. Add signingConfig to release buildType
sed -i '/getByName("release")[[:space:]]*{/a\            signingConfig = signingConfigs.getByName("release")' "$BUILD_GRADLE"

echo "✅ build.gradle.kts patched successfully"
