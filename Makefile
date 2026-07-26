PROJECT := LeanIsLaw/LeanIsLaw.xcodeproj
SCHEME  := LeanIsLaw
CONFIG  := Debug
BUILD   := build
APP     := $(BUILD)/Build/Products/$(CONFIG)-iphonesimulator/$(SCHEME).app

.PHONY: run clean

run:
	@set -e; \
	BOOTED=$$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/ {print $$2}'); \
	if [ -z "$$BOOTED" ]; then \
	  echo "No booted simulator. Booting one..."; \
	  UDID=$$(xcrun simctl list devices available | awk -F '[()]' '/iPhone [0-9].*\(.*\) \(Shutdown\)/ {print $$2; exit}'); \
	  if [ -z "$$UDID" ]; then echo "No available iPhone simulator found"; exit 1; fi; \
	  xcrun simctl boot "$$UDID"; \
	  BOOTED="$$UDID"; \
	fi; \
	FIRST=$$(echo "$$BOOTED" | head -n1); \
	open -a Simulator --args -CurrentDeviceUDID "$$FIRST"; \
	echo "Building..."; \
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) \
	  -destination "platform=iOS Simulator,id=$$FIRST" \
	  -derivedDataPath $(BUILD) build >/tmp/leanislaw-build.log 2>&1 || { tail -40 /tmp/leanislaw-build.log; exit 1; }; \
	BUNDLE_ID=$$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$(APP)/Info.plist"); \
	for UDID in $$BOOTED; do \
	  echo "Installing $$BUNDLE_ID on $$UDID"; \
	  xcrun simctl install "$$UDID" "$(APP)"; \
	  xcrun simctl launch "$$UDID" "$$BUNDLE_ID"; \
	done

clean:
	rm -rf $(BUILD)
