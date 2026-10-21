# AI visual production

Requires an imported Godot 4 project, Python 3.10+ and a full FFmpeg build on PATH (or explicit paths). No Python packages are required. Captures use Godot Movie Writer with the actual AutoWalker runner and null telemetry, isolated project configuration and saves. Native rendering is essential: do not use --headless. On Ubuntu without a desktop use `xvfb-run -a python ...` with working Mesa/OpenGL drivers. Windows needs a working graphics driver. Missing imports/display/tools produce errors; inspect console.log and godot.log for renderer failures.

From the repository root, in PowerShell:

```powershell
$godot = 'D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe'
$ffmpeg = 'ffmpeg'
python tools/visual_pipeline/run.py arcane-bolt --label bolt-before --godot "$godot" --ffmpeg "$ffmpeg"
# Inspect evidence, write direction in ai/visual/specs/, implement the change.
python tools/visual_pipeline/run.py arcane-bolt --label bolt-after --baseline .qa-tmp/visual/bolt-before --godot "$godot" --ffmpeg "$ffmpeg"
```

On Ubuntu substitute `/path/to/godot` and `ffmpeg`; CLI flags are identical. GODOT and FFMPEG environment variables can supply paths. Each label must be new. After a dependency/extraction failure, rerun with the same label and `--evidence-only` to preserve the video and regenerate sparse evidence. Existing persistent reviews are never overwritten. Evidence-only reads the recorded scenario rather than replacing it with the current JSON.

Each run writes `.qa-tmp/visual/<label>/capture.avi`, timing.json, scenario.json, command.json, console/godot logs, local telemetry, frames.json and at most 18 representative PNGs. With --baseline it also writes comparison.json and a silent side-by-side comparison.mp4. Videos contain native game audio; sampled frames and the comparison video cannot establish audio quality. Movie Writer records the project viewport (currently 1920x1080), independent of the smaller window. Disk use is tens of MB per short capture; captures are temporary, keep only evidence needed. No custom encoder or AI API client is involved.

Start with ai/visual/workflows/discover.md and follow direct, implement, critique. The CLI generates ai/visual/reviews/<label>.md with status awaiting inspection. The agent must open images/video using its own tools and replace the placeholders with an honest review. Persistent direction/reviews refer to temporary evidence; archive evidence separately if long-term reproducibility is needed.

For another event copy scenarios/arcane-bolt.json, set event, real encounter resource, seed, policy (greedy/random/stress), duration (up to 120s), fps (1..60), and optionally expect_card (exact display name). Pass its name or JSON path. Optional replay is an absolute or repository-relative AutoWalker simulation report; the runner loads its seed, encounter, policy and real action trace, with checkpoint divergence checks. Use a scenario long enough for the desired event and examine timing.json to confirm it happened. New abilities use their real registered card/config/executor; make them available through actual starting resources or a replay, not a second spell implementation. Non-card events omit expect_card and require agent confirmation in the trace/frames. Extend fixture signal metadata for precise phases when available; current offsets are samples, not asserted impact times.

Deterministic gameplay seed does not guarantee pixel-identical GPU particles, camera noise or wall-clock watchdogs. Comparison reports action identity, boundary drift and final observation equality; it cannot prove all mechanics unchanged or grade artistic quality. A time-limited capture may end during an action and cause native exit resource warnings; inspect script errors separately. Sparse stills miss brief impulses and continuous motion. The demonstration does not establish every shared effect or collapse regression. No network telemetry or provider-specific inference runs.

The `ruin` scenario accepts the optional `fixture: "ruin"` field (other fixture
names are rejected). It pauses policy decisions, sets the occupied tile to a
ruin, restricts its effect pool to block and then empty, and calls the real
`apply_tile_effects` API twice. Startup effects still run. This tests repeatable
tile feedback, not a natural movement replay. `ruin_activation` and `ruin_frame`
events record timing; six phase PNGs are saved alongside the native movie without
FFmpeg. This fallback does not provide video extraction or continuous-motion
review. Use matching fixture settings for baseline and revised captures.
