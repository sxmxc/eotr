# ⬆️ Godot Auto Version Code

If you're building games for Google Play using the [Godot Game Engine](https://godotengine.org/), you'll need to increment the version code each time you upload a new APK.

This plugin will automatically increment the version code for you.

It works by registering an [Export Plugin](https://docs.godotengine.org/en/stable/classes/class_editorexportplugin.html). After each non-debug export, it will search the `export_presets.cfg` file for `version/code` keys and increment them by one.

It's super simple, so feel free to modify it to suit your needs.

## Installation

Install it using the [Asset Library](https://godotengine.org/asset-library/asset/3286) or place the `auto_version_code` folder in your `addons` folder manually.

## Tipp:

This plugin works well in combination with the [Auto Export Version Plugin](https://godotengine.org/asset-library/asset/1430), which will allow you to get the version code in your game.
For that you'll need to configure it to use the Android version code.

[![forthebadge](https://forthebadge.com/images/featured/featured-uses-badges.svg)](https://forthebadge.com) [![forthebadge](https://forthebadge.com/images/featured/featured-made-with-crayons.svg)](https://forthebadge.com)