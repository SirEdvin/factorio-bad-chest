# Recipe parameterization regression

Use Factorio 2.1.9 or newer (verified with headless 2.1.23), an isolated config/write-data directory, and a throwaway save. Never run the fixture in a real campaign: it clears its test area.

Place the packaged `rec-blue-plus` mod and a copy of `tests/rec-blue-plus-tests` in the isolated mods directory. Enable both in `mod-list.json`. For base-only testing, explicitly disable `quality`, `elevated-rails`, `recycler`, and `space-age`; for the Space Age case, enable all four.

Run, with the paths pointing at that isolated setup:

```sh
"$FACTORIO" --config "$CONFIG" --mod-directory "$MODS" --create "$SAVE" --map-gen-seed 12345
"$FACTORIO" --config "$CONFIG" --mod-directory "$MODS" --benchmark "$SAVE" --benchmark-ticks 60 --benchmark-runs 1
```

Require both commands to exit successfully, `RBP command 2 deployment passed` in the benchmark log, and `script-output/recipe-regression.json` under write-data with `passed: true`.

The fixture checks single-category replacement, a match only in the second recipe category, incompatible and unknown recipes, and quality preservation when enabled. It then drives a real B.A.D. Chest with command 2, `0=23`, `1=24`, and matching recipe signals, verifying two deployed ghosts and an unchanged source blueprint. Space Age uses foundries with `casting-copper-cable` and `molten-copper-from-lava`; base uses assemblers. Unmodified upstream 1.5.2 fails with `LuaRecipePrototype doesn't contain key category`.

The empty-request regression uses the reporter's exact three circuit signals: `rbp-command=2`, `signal-0=1012`, and recipe `advanced-circuit=1012`. Its blueprint contains an assembler with `parameter-0` and a requester chest with an empty section. It checks native serialization of absent/empty requests, mixed empty/populated/grouped sections, item replacement and quality/count preservation, actual ghost deployment, and an unchanged source blueprint. The published 1.5.3 ZIP fails at `parameterization.lua:254` because Factorio omits `filters` for an empty section.

The test mod is not included in release ZIPs. These are headless runtime/circuit checks, not graphical-client or multiplayer acceptance.
