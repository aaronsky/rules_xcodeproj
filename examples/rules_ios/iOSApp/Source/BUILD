load("@build_bazel_rules_apple//apple:apple.bzl", "local_provisioning_profile")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_group")
load(
    "@build_bazel_rules_ios//rules:app.bzl",
    rules_ios_ios_application = "ios_application",
)
load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)
load("@build_bazel_rules_ios//rules:precompiled_apple_resource_bundle.bzl", "precompiled_apple_resource_bundle")
load("@rules_xcodeproj//xcodeproj:defs.bzl", "xcode_provisioning_profile")
load(
    "//:xcodeproj_targets.bzl",
    "IOS_BUNDLE_ID",
    "TEAMID",
)

config_setting(
    name = "release_build",
    values = {
        "compilation_mode": "opt",
    },
)

rules_ios_ios_application(
    name = "iOSApp",
    app_icons = glob(["Assets.xcassets/AppIcon.appiconset/**"]),
    bundle_id = IOS_BUNDLE_ID,
    bundle_name = "iOSApp",
    entitlements = "ios app.entitlements",
    executable_name = "iOSApp_ExecutableName",
    extensions = ["//WidgetExtension"],
    families = ["iphone"],
    infoplists = [":Info.plist"],
    launch_storyboard = "Launch.storyboard",
    minimum_os_version = "15.0",
    provisioning_profile = select({
        "@build_bazel_apple_support//constraints:device": ":xcode_profile",
        "//conditions:default": None,
    }),
    resource_bundles = {
        "UnprocessedResources": ["data.json"],
    },
    resources = glob(
        ["Assets.xcassets/**"],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
    strings = glob(["*.lproj/Localizable.strings"]),
    version = "//iOSApp:Version",
    visibility = [
        "//iOSApp:__pkg__",
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        ":iOSApp.library",
        "//UI",
        "//iOSApp/Source/CoreUtilsObjC",
    ],
)

xcode_provisioning_profile(
    name = "xcode_profile",
    managed_by_xcode = True,
    provisioning_profile = ":xcode_managed_profile",
    tags = ["manual"],
)

local_provisioning_profile(
    name = "xcode_managed_profile",
    profile_name = "iOS Team Provisioning Profile: {}".format(IOS_BUNDLE_ID),
    tags = ["manual"],
    team_id = TEAMID,
)

apple_resource_group(
    name = "ResourceGroup",
    resources = glob(
        [
            "Assets.xcassets/**",
        ],
        exclude = ["Assets.xcassets/AppIcon.appiconset/**"],
    ),
)

precompiled_apple_resource_bundle(
    name = "PrecompiledResourceBundle",
    resources = glob(
        [
            "AssetsPrecompiled.xcassets/**",
        ],
    ),
)

rules_ios_apple_framework(
    name = "iOSApp.library",
    srcs = glob(["**/*.swift"]),
    data = [
        ":PrecompiledResourceBundle",
    ],
    module_name = "iOSApp",
    platforms = {
        "ios": "15.0",
    },
    tags = ["manual"],
    visibility = ["//iOSApp/Test:__subpackages__"],
    deps = [
        "//UI",
        "//iOSApp/Source/CoreUtilsMixed/MixedAnswer",
        "//iOSApp/Source/CoreUtilsObjC",
    ],
)

rules_ios_apple_framework(
    name = "VendoredFramework",
    vendored_xcframeworks = [
        {
            "name": "VendoredFramework",
            "slices": [
                {
                    "build_type": {
                        "linkage": "dynamic",
                        "packaging": "framework",
                    },
                    "identifier": "ios-arm64",
                    "path": "Vendored/VendoredFramework.xcframework/ios-arm64/VendoredFramework.framework",
                    "platform": "ios",
                    "platform_variant": "",
                    "supported_archs": ["arm64"],
                },
                {
                    "build_type": {
                        "linkage": "dynamic",
                        "packaging": "framework",
                    },
                    "identifier": "ios-arm64_x86_64-simulator",
                    "path": "Vendored/VendoredFramework.xcframework/ios-arm64_x86_64-simulator/VendoredFramework.framework",
                    "platform": "ios",
                    "platform_variant": "simulator",
                    "supported_archs": [
                        "arm64",
                        "x86_64",
                    ],
                },
            ],
        },
    ],
    visibility = ["//visibility:public"],
)
