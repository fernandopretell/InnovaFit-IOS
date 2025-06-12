#!/bin/bash
set -e

xcodebuild clean test \
  -project InnovaFit.xcodeproj \
  -scheme InnovaFit \
  -destination "platform=iOS Simulator,name=iPhone 15"



