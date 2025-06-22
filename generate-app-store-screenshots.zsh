#!/bin/zsh

# App Store Screenshot Generation Script
# Based on https://blog.winsmith.de/english/ios/2020/04/14/xcuitest-screenshots.html
#
# This script runs UI tests to generate screenshots and extracts them 
# from Xcode's .xcresult bundles into organized directories for App Store use.

set -euo pipefail

# Configuration
PROJECT_ROOT="$(pwd)"
SCREENSHOTS_DIR="${PROJECT_ROOT}/DerivedData/UITestingScreenshots"
TEMP_DIR="/tmp/vinylogue-screenshots"
XCRESULT_DIR="${PROJECT_ROOT}/DerivedData/Vinylogue/Logs/Test"
DEVICE_OS="18.5"

# Device configurations
declare -A DEVICES=(
    ["iPhone-16-Pro"]="iPhone 16 Pro"
    ["iPhone-16"]="iPhone 16"
    ["iPhone-16e"]="iPhone 16e"
)

# Test configurations
SCHEME="VinylogueAppStoreScreenshotUITests"
PROJECT_FILE="Vinylogue.xcodeproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -d "${PROJECT_FILE}" ]]; then
        log_error "Project file ${PROJECT_FILE} not found. Make sure you're running this from the project root directory."
        log_error "Current directory: $(pwd)"
        log_error "Looking for: ${PROJECT_FILE}"
        log_error "Available files: $(ls -la | grep -E '\.(xcodeproj|xcworkspace)' || echo 'none found')"
        exit 1
    fi
    
    # Check if xcodebuild is available
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Make sure Xcode is installed."
        exit 1
    fi
    
    # Check if xcparse is available
    if ! command -v xcparse &> /dev/null; then
        log_warning "xcparse not found. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install chargepoint/xcparse/xcparse
        else
            log_error "xcparse not available and Homebrew not found. Please install xcparse manually:"
            log_error "https://github.com/ChargePoint/xcparse"
            exit 1
        fi
    fi
    
    log_success "Prerequisites check passed"
}

# Setup directories
setup_directories() {
    log_info "Setting up directories..."
    
    # Create screenshots directory if it doesn't exist
    mkdir -p "${SCREENSHOTS_DIR}"
    
    # Create temporary directory
    mkdir -p "${TEMP_DIR}"
    
    log_success "Directories setup complete"
}

# Clean previous results
clean_previous_results() {
    log_info "Cleaning previous results..."
    
    # Remove old screenshots from target directory
    if [[ -d "${SCREENSHOTS_DIR}" ]]; then
        find "${SCREENSHOTS_DIR}" -name "*.png" -delete 2>/dev/null || true
    fi
    
    # Clean temporary directory
    rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"
    
    log_success "Cleanup complete"
}

# Run UI tests for a specific device
run_tests_for_device() {
    local device_key="$1"
    local device_name="${DEVICES[$device_key]}"
    
    log_info "Running tests for ${device_name}..."
    
    # Use device name directly instead of UUID for simplicity
    local destination="platform=iOS Simulator,name=${device_name},OS=${DEVICE_OS}"
    
    log_info "Using destination: ${destination}"
    log_info "Executing UI tests..."
    
    # Run the UI tests
    xcodebuild \
        -project "${PROJECT_FILE}" \
        -scheme "${SCHEME}" \
        -destination "${destination}" \
        -resultBundlePath "${TEMP_DIR}/${device_key}.xcresult" \
        test \
        -only-testing:VinylogueAppStoreScreenshotUITests/AppStoreScreenshotTests
    
    log_success "Tests completed for ${device_name}"
}

# Extract screenshots from xcresult bundle
extract_screenshots() {
    local device_key="$1"
    local xcresult_path="${TEMP_DIR}/${device_key}.xcresult"
    local device_output_dir="${SCREENSHOTS_DIR}/${device_key}"
    
    log_info "Extracting screenshots for ${device_key}..."
    
    if [[ ! -d "$xcresult_path" ]]; then
        log_error "xcresult bundle not found: $xcresult_path"
        return 1
    fi
    
    # Create device-specific output directory
    mkdir -p "$device_output_dir"
    
    # Extract screenshots using xcparse
    log_info "Using xcparse to extract screenshots..."
    xcparse screenshots "$xcresult_path" "$device_output_dir"
    
    # Count and report extracted screenshots
    local screenshot_count
    screenshot_count=$(find "$device_output_dir" -name "*.png" -type f | wc -l | tr -d ' ')
    
    if [[ "$screenshot_count" -gt 0 ]]; then
        log_success "Extracted ${screenshot_count} screenshots for ${device_key}"
        
        # List extracted screenshots
        log_info "Screenshots extracted:"
        find "$device_output_dir" -name "*.png" -type f -exec basename {} \; | sort
    else
        log_warning "No screenshots found for ${device_key}"
    fi
}

# Organize screenshots with better naming
organize_screenshots() {
    log_info "Organizing screenshots..."
    
    for device_key in "${(@k)DEVICES}"; do
        local device_dir="${SCREENSHOTS_DIR}/${device_key}"
        
        if [[ -d "$device_dir" ]]; then
            # Rename screenshots to include device name and timestamp
            local timestamp
            timestamp=$(date +"%Y%m%d_%H%M%S")
            
            find "$device_dir" -name "*.png" -type f | while read -r screenshot; do
                local basename
                basename=$(basename "$screenshot" .png)
                local new_name="${basename}_${device_key}_${timestamp}.png"
                
                # Move to organized location
                mv "$screenshot" "${device_dir}/${new_name}"
                log_info "Renamed: $(basename "$screenshot") -> ${new_name}"
            done
        fi
    done
    
    log_success "Screenshot organization complete"
}

# Generate summary report
generate_report() {
    log_info "Generating summary report..."
    
    local report_file="${SCREENSHOTS_DIR}/screenshot_report.md"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    cat > "$report_file" << EOF
# App Store Screenshots Report

Generated on: ${timestamp}

## Summary

EOF
    
    local total_screenshots=0
    
    for device_key in "${(@k)DEVICES}"; do
        local device_name="${DEVICES[$device_key]}"
        local device_dir="${SCREENSHOTS_DIR}/${device_key}"
        local count=0
        
        if [[ -d "$device_dir" ]]; then
            count=$(find "$device_dir" -name "*.png" -type f | wc -l | tr -d ' ')
            total_screenshots=$((total_screenshots + count))
        fi
        
        cat >> "$report_file" << EOF
### ${device_name} (${device_key})
- Screenshots: ${count}
- Directory: \`${device_dir}\`

EOF
    done
    
    cat >> "$report_file" << EOF
**Total Screenshots Generated: ${total_screenshots}**

## Usage

Screenshots are organized by device type in the \`AppStoreScreenshots/\` directory:

EOF
    
    for device_key in "${(@k)DEVICES}"; do
        echo "- \`${device_key}/\` - ${DEVICES[$device_key]} screenshots" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Next Steps

1. Review screenshots for quality and content
2. Select the best screenshots for each device size
3. Upload to App Store Connect
4. Update metadata as needed

## Generated Files

All screenshots are saved with descriptive names including:
- Test name
- Device identifier  
- Generation timestamp

EOF
    
    log_success "Report generated: ${report_file}"
}

# Main execution
main() {
    log_info "Starting App Store screenshot generation..."
    log_info "Project: $(basename "$PROJECT_ROOT")"
    
    # Check if device argument is provided
    local target_device=""
    if [[ $# -gt 0 ]]; then
        target_device="$1"
        if [[ ! -v "DEVICES[$target_device]" ]]; then
            log_error "Unknown device: $target_device"
            log_info "Available devices: ${(k)DEVICES}"
            exit 1
        fi
        log_info "Running for specific device: ${DEVICES[$target_device]}"
    else
        log_info "Running for all configured devices"
    fi
    
    # Execute steps
    check_prerequisites
    setup_directories
    clean_previous_results
    
    # Run tests for specified device or all devices
    if [[ -n "$target_device" ]]; then
        run_tests_for_device "$target_device"
        extract_screenshots "$target_device"
    else
        for device_key in "${(@k)DEVICES}"; do
            log_info "Processing device: ${DEVICES[$device_key]}"
            run_tests_for_device "$device_key" || {
                log_warning "Failed to process ${DEVICES[$device_key]}, continuing with next device..."
                continue
            }
            extract_screenshots "$device_key"
        done
    fi
    
    organize_screenshots
    generate_report
    
    # Cleanup temporary files
    log_info "Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}"
    
    log_success "App Store screenshot generation complete!"
    log_info "Screenshots saved to: ${SCREENSHOTS_DIR}"
    log_info "Review the generated report: ${SCREENSHOTS_DIR}/screenshot_report.md"
}

# Show usage if help is requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
App Store Screenshot Generator

Usage: 
    $0                    # Generate screenshots for all devices
    $0 [device-key]       # Generate screenshots for specific device
    $0 --help            # Show this help

Available devices:
EOF
    for device_key in "${(@k)DEVICES}"; do
        echo "    ${device_key} - ${DEVICES[$device_key]}"
    done
    echo ""
    echo "Examples:"
    echo "    $0                        # All devices"
    echo "    $0 iPhone-16-Pro         # iPhone 16 Pro only"
    echo ""
    exit 0
fi

# Run main function
main "$@"