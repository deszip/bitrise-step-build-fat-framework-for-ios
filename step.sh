#!/bin/bash
set -ex

echo "Input:"
echo "workspace: ${workspace_path}"
echo "project: ${project_path}"
echo "configuration: ${configuration_name}"
echo "scheme: ${scheme_name}"

#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.
# A very simple example:

#envman add --key EXAMPLE_STEP_OUTPUT --value 'the value you want to share'

# Envman can handle piped inputs, which is useful if the text you want to
# share is complex and you don't want to deal with proper bash escaping:
#  cat file_with_complex_input | envman add --KEY EXAMPLE_STEP_OUTPUT
# You can find more usage examples on envman's GitHub page
#  at: https://github.com/bitrise-io/envman

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.

# Inputs
workspace_path='/tmp/foo/AppSpectorSDK.xcworkspace'
project_path=''
configuration_name='Release'
scheme_name='AppSpectorSDK Release'
framework_name='AppSpector'

# Compile build command
BUILD_COMMAND='xcodebuild '
BINARY_NAME=$scheme_name

# Workspace / project
if [ -n $workspace_path ]
then
BUILD_COMMAND+='-workspace '
BUILD_COMMAND+=$workspace_path
BINARY_NAME=$workspace_path
else
BUILD_COMMAND+='-project '
BUILD_COMMAND+=$project_path
BINARY_NAME=$project_path
fi

# Scheme
if [ -n $scheme_name ]
then
BUILD_COMMAND+=' -scheme '
BUILD_COMMAND+=$scheme_name
fi

# Configuration
if [ -n $configuration_name ]
then
BUILD_COMMAND+=' -configuration '
BUILD_COMMAND+=$configuration_name
fi

BUILD_COMMAND+=' -derivedDataPath $BITRISE_DEPLOY_DIR/'

# Arch build commands
SIM_BUILD_COMMAND=$BUILD_COMMAND'iphonesimulator -sdk iphonesimulator clean build'
OS_BUILD_COMMAND=$BUILD_COMMAND'iphoneos -sdk iphoneos clean build'

echo "Build commands:"
echo "Sim: ${SIM_BUILD_COMMAND}"
echo "OS: ${OS_BUILD_COMMAND}"

# Run builds
eval $SIM_BUILD_COMMAND
eval $OS_BUILD_COMMAND

# Make fat binary
if [ -n $framework_name ]
then
BINARY_NAME=framework_name
else
BINARY_NAME=$BINARY_NAME | sed -r "s/.+\/(.+)\..+/\1/"
fi

mkdir $BITRISE_DEPLOY_DIR/fat
cp -R $BITRISE_DEPLOY_DIR/iphoneos/Build/Products/Release-iphoneos/$BINARY_NAME.framework $BITRISE_DEPLOY_DIR/fat
lipo -create $BITRISE_DEPLOY_DIR/iphoneos/Build/Products/Release-iphoneos/$BINARY_NAME.framework/$BINARY_NAME \
$BITRISE_DEPLOY_DIR/iphonesimulator/Build/Products/Release-iphonesimulator/$BINARY_NAME.framework/$BINARY_NAME \
-output $BITRISE_DEPLOY_DIR/fat/$BINARY_NAME.framework/$BINARY_NAME

#...

# Build x86 and arm alices
#xcodebuild -workspace MySDK.xcworkspace -scheme MySDK -configuration Release -derivedDataPath $BITRISE_DEPLOY_DIR/iphoneos -sdk iphoneos clean build
#xcodebuild -workspace MySDK.xcworkspace -scheme MySDK -configuration Release -derivedDataPath $BITRISE_DEPLOY_DIR/iphonesimulator -sdk iphonesimulator clean build

# Create a fat binary
#mkdir $BITRISE_DEPLOY_DIR/fat
#cp -R $BITRISE_DEPLOY_DIR/iphoneos/Build/Products/Release-iphoneos/MySDK.framework $BITRISE_DEPLOY_DIR/fat
#lipo -create $BITRISE_DEPLOY_DIR/iphoneos/Build/Products/Release-iphoneos/MySDK.framework/MySDK $BITRISE_DEPLOY_DIR/iphonesimulator/Build/Products/Release-iphonesimulator/MySDK.framework/MySDK -output $BITRISE_DEPLOY_DIR/fat/MySDK.framework/MySDK

# envman add --key BINARY_PATH --value ''