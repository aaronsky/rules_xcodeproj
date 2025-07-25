# Frequently Asked Questions

## Why do I get a visibility or unexported files error with `xcodeproj`?

Even though you might have your `xcodeproj` target declared in the same package
as your `top_level_targets`, internally rules_xcodeproj creates another target
in a sub-package under the `@rules_xcodeproj_generated` repo. You'll need
to adjust your `visibility`/`package_group` to include
`"@rules_xcodeproj//xcodeproj:generated"`, and export any files used in
`xcodeproj.{associated_,}extra_files`.

## Does the Archive action work?

Currently no effort is put into making the Archive action work correctly.
rules_xcodeproj’s primary goal is to support running and debugging of
targets, and might make optimizations that break the generated `.xcarchive` that
the Archive action produces.

Instead of using the Archive action to submit to the App Store, you should
instead [generate an IPA with
`bazel`](https://github.com/bazelbuild/rules_apple/blob/master/doc/tutorials/ios-app.md#find-the-build-outputs)
and upload that.

## Why are there multiple versions of some of my targets?

<img alt="Screenshot of an Xcode Targets list showing the 'FXPageControl (iOS 13.0)' and 'FXPageControl (iOS 15.0)' targets" src="https://user-images.githubusercontent.com/158658/225914670-4f9ebe5e-be18-4462-a551-b5886096c434.png" width="153" >

If the transitive closure of dependencies of targets specified by
`xcodeproj.top_level_targets` has targets with multiple configurations, they
will be included in the project with those various configurations. This can be
useful/expected, for example having multiple platform versions of a given
`swift_library`. When possible the generated project will have these various
versions of a target consolidated into a single Xcode target. When targets can’t
be consolidated, usually because they are functionally equivalent from the point
of view of Xcode, they will be separate Xcode targets.

<img alt="Screenshot of an Xcode Targets list showing the 'c_lib (8f0e2)', 'c_lib (56c24)', and 'с_lib (×86_64)' targets" src="https://user-images.githubusercontent.com/158658/225914621-8d8fd0b6-8268-4db5-9475-1d490a73998b.png" width="93">

If you have multiple _unexpected_ versions of some targets, usually with a
hash after their name, then this unexpected. Check to see if your build is
adding multiple configurations of the same targets to the build graph (e.g. app
extensions or tests having different minimum OS versions than the app, which can
possibly be fixed by using minimum deployment OS version instead). If you
need help, reach out to us.

One particular case that you have to watch out for (pun intended) is
accidentally including a `watchos_application` in `xcodeproj.top_level_targets`
when it's being embedded in an `ios_application` target. `watchos_application`
targets should only be included in `xcodeproj.top_level_targets` when they are
not being embedded by an `ios_application` target, since they will have a
different configuration applied to them, resulting in multiple Xcode targets.

## What is `CompileStub.m`?

If you have a top level target, such as `ios_application`, and its primary
library dependency is also directly depended on by another top level target,
such as `ios_unit_test`, then we can’t merge that library into the first top
level target. When that happens, the first top level target doesn’t have any
source files, so we need to add a stub one to allow Xcode to link to the proper
library target.

If this setup isn’t desired (e.g. wanting to have the target merged to enable
Xcode Previews), there are a couple ways to fix it. For tests, setting the
first top level target as the `test_host` will allow for the library to merge.
In other cases, refactor the build graph to have the shared code in its own
library separate from the top level target’s primary library.

## Why do some of my `swift_library`s compile twice in BwX mode?

If you have header based rules that depend on the Swift generated header (i.e.
custom modulemap or hmap rules), then when BwX mode generates those files with
Bazel, it causes Bazel to generate the Swift generated header by compiling the
swiftmodule.

Possible solutions are:

- Refactoring mixed-language targets to single language targets, removing the
  need for the custom modulemap that references the Swift generated header
- Remove the use of header maps (hmaps), or don’t include Swift generated
  headers in them
- Use BwB mode instead

## Why does Xcode complain about stale files?

The generated project tracks Bazel managed external and generated files. If you
remove a dependency on one of those files, or the path of one of those files
changes (e.g. because of a Bazel configuration change), and generate the project
without closing and reopening it, or performing a clean build, Xcode will warn
about the old paths. This seems to be a caching bug in Xcode.

## Why does “X” happen when switching between build modes?

The different build modes configure the project in different ways. Because of
this, if you switch the build mode of a project that has already built
something, the artifacts in Xcode’s Derived Data might cause warnings or errors
on subsequent builds. rules_xcodeproj thus doesn’t officially support this use
case, and recommends declaring a different [`xcodeproj`](bazel.md#xcodeproj)
target for each build mode if needed.

## Why I do not see any simulators after generating project using rules_xcodeproj?

This can happen if you have opened Xcode using `rosetta`, the solution is to get native arm simulator support for your app and disable rosetta.

## Why do I get an error like “Provisioning profile "PROFILE_NAME" is Xcode managed, but signing settings require a manually managed profile”?

This error should no longer happen, please report this as a bug.

The `provisioning_profile` you have set on your top level target (i.e
`ios_application` and the like) is resolving to an Xcode managed profile. This
is common if you use the `local_provisioning_profile` rule. If this is desired,
then you need to use the `xcode_provisioning_profile` rule to tell `xcodeproj`
that this is an Xcode managed profile:

```starlark
ios_application(
   ...
   provisioning_profile = ":xcode_profile",
   ...
)

xcode_provisioning_profile(
   name = "xcode_profile",
   managed_by_xcode = True,
   provisioning_profile = ":provisioning_profile",
)
```

Also, the `:provisioning_profile` target needs to be a rule that returns the
`AppleProvisioningProfileInfo` provider, such as `local_provisioning_profile`,
and the `team_id` attribute on that provider needs to be set, or `team_id` needs
to be set on the `:xcode_profile` target.

## Why do I get an error like “Xcode couldn't find any provisioning profiles matching 'TEAM_ID/PROFILE_NAME'”?

This error should no longer happen, please report this as a bug.

The `provisioning_profile` you have set on your top level target (i.e
`ios_application` and the like) is resolving to a provisioning profile that
hasn’t yet been installed to `~/Library/MobileDevice/Provisioning Profiles`.
This is common if you use the `local_provisioning_profile` rule and specify
fallback profiles, or if you use specify a profile in the workspace.

Copying the profile to `~/Library/MobileDevice/Provisioning Profiles` will
resolve the error.
