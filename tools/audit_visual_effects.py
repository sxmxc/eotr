"""Rebuild the technical-art inventory from sources, including vendor/demo effects.

No engine, network, or game state required. Retains baseline records for removed
implementations. Assessments are editorial; discovery is mechanical and repeatable.
"""
import json
import re
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'ai/visual/reference/battlefield-vfx-inventory.json'
ABILITY_ART = json.loads((ROOT / 'ai/visual/reference/battlefield-ability-direction.json').read_text(encoding='utf-8'))
EXTENSIONS = {'.gd', '.tscn', '.tres', '.gdshader', '.gdshaderinc'}
SIGNALS = re.compile(r'create_tween|tween_property|visual_fx|projectile_fx|Utils\.shake|apply_hitstop|\.instantiate\(|\.play\(|draw_|shader_parameter|set_shader_parameter|AnimationPlayer|AnimatedSprite|Particles2D|modulate|\.show\(|\.hide\(|\.emitting\s*=|(?:Effect|FX)\.new\(|\.execute\(|stats\.heal\(')
SHADERS = {
    'spell_blast': ('Refine', 'Pressure front, broken fracture spokes and concentrated direct impact; replace concentric soft rings with tapered shock facets.'),
    'spell_strike': ('Refine', 'Jab, delayed chrono ticks, phase cut, severed tether and overload; sharpen primary cuts and give release a short bright core.'),
    'spell_flame': ('Refine', 'Ascending tongues; reduce identical sine tongues with staggered release and tapered ash.'),
    'spell_corrosion': ('Refine', 'Creeping corrosion and falling drops; replace arbitrary polar sine web with branching capillary paths.'),
    'spell_void': ('Refine', 'Inward shards / three-way fracture / vertical aperture; suppress initial and terminal phantom ring, orient shards radially.'),
    'spell_support': ('Refine', 'Assembling ward, attunement, knowledge, echo and rising energy; replace square sci-fi grid with staggered stone-like ward plates.'),
    'spell_presence': ('Keep', 'Eight alpha taps give illustrated sprites a restrained ink surround; texture-space sampling and explicit tint preserve fading.'),
    'unit_outline': ('Keep', 'Eight outline samples and upper-left inner rim preserve illustrated silhouette; per-unit material isolates hit flash.'),
    'fog_of_war': ('Keep', 'Two world-space noise samples, atlas alpha mask and fade tint; continuous low-frequency fog conceals unrevealed artwork.'),
    'rift_gate': ('Keep', 'Compact elliptical orbit and aperture, event-driven burst; local material and fog visibility owned by board overlay.'),
    'ground_presence': ('Keep', 'Small grounding shadow and team ring; stays beneath feet, low-frequency pulse.'),
    'tile_target_highlight': ('Replace', 'Sample the canonical texture alpha, including atlas-backed batched tiles; vertex-derived local UVs were incorrect for TileMapLayer batching. Shared aligned teal treatment for movement, legal targets and cursor.'),
    'white_sprite_material': ('Keep', 'Flat white flash preserves incoming alpha and modulation; no screen sampling.'),
    'electrical_arc_v2': ('Keep', 'Native Line2D ink/body/core bands; isolated fade uniform and bounded local geometry.'),
    'card_burnable': ('Keep', 'Authored card dissolve uses a noise texture, not a screen read; radius owned by card burn animation.'),
    'dark_noise_vignette': ('Replace', 'Seven procedural noise octaves over a full-screen transition are disproportionate; use broad quiet elliptical ink veil.'),
    'battle_over_vignette': ('Refine', 'Screen-space aspect-aware veil without screen texture; guard zero softness.'),
    'vignette': ('Keep', 'Simple UI edge darkening, protected radius divisor and CanvasItem tint; no screen read.'),
    'electric_arc': ('Refine', 'Legacy sandbox gradient arc; preserve demo but guard zero width/scale defaults to avoid NaN.'),
    'terrain_surface': ('Keep', 'Shared atlas material; one texture sample, broad world-space pigment variation and restrained plum-pigment breathing, no screen read.'),
    'collapse_warning': ('Keep', 'Warm intermittent fracture contour with slow breath; separates disappearing-edge warning from filled cyan targeting.'),
    'rift_void': ('Keep', 'One illustrated background sample, aspect-correct SCREEN_UV and subpixel slow drift; SCREEN_UV is a coordinate, no screen-texture read. Quiet center, peripheral ruins, restrained exposure.'),
    'illustrated_palette': ('Keep', 'Remap authored pigment while preserving dark ink, ivory core and alpha. Used selectively for ochre Sever, violet Overload and green healing; not a replacement for distinct composition.'),
    'phase_afterimage': ('Keep', 'Dissolve snapshots of the actual player illustration into short horizontal fragments with preserved source alpha. No screen read or displacement of the real character, collision or terrain.'),
}

def review(path, kind):
    name = Path(path).stem
    ability = name.removesuffix('_signature')
    if ability in ABILITY_ART and ('/cards/' in path or '_signature' in name):
        return 'Refine', ABILITY_ART[ability]
    if path.startswith('addons/'):
        return 'Keep', 'Vendor editor/camera presentation. Retain dependency source; excluded from shipping-effect quality claims.'
    if kind == 'shader':
        return SHADERS.get(name, ('Keep', 'Shader dependency; inspect consumers and parameter defaults before changes.'))
    if 'ambient_particles' in path:
        return 'Replace', 'Six 1000-particle, 100-second emitters with high velocity, turbulence and sub-emitters; replace with 48 slow motes across six existing origins and a lifetime alpha ramp.'
    if name == 'pause_menu':
        return 'Consolidate', 'Remove six embedded 1000-particle emitters and their duplicated process materials; instance shared ambient scene at the pause layer.'
    if name in ('fireball_projectile_fx', 'fireball_small_projectile_fx', 'obelisk_projectile_fx'):
        return 'Consolidate', 'Shared fast 1550px/s body flight, 75–260ms duration, actual-motion wake bounded to 54 world pixels, source release and target impact separated. Complete at arrival; target WeakRef and detached-impact cleanup protect cancellation.'
    if name == 'hex_trail':
        return 'Refine', 'Long HDR trace can form an opaque aiming wall; reduce lifetime, count, brightness and emission offset.'
    if name == 'tile_sprite':
        return 'Replace', 'Collapse spins a fog-textured whole hex; sample actual visible atlas region and fracture five irregular textured pieces with undersides, accelerated fall and fading seams/dust.'
    if name == 'proc-gen-tilemap':
        return 'Refine', 'Keep all state transitions and waits; capture the actual visible tile for cosmetic collapse before authoritative erasure.'
    if name == 'board_overlay':
        return 'Refine', 'Keep legal target pool and gate authority; coalesce refreshes and add warm broken danger seams distinct from cyan targets.'
    if name == 'terrain_depth':
        return 'Refine', 'Cosmetic cached exposed-edge polygons from TileMapLayer only. Consume authoritative presentation_changed and map_generated as well as layer.changed so shrink erasures cannot leave stale perimeter geometry.'
    if name == 'text_fx':
        return 'Refine', 'Uniform simultaneous float/fade/scale loses impact; quick readable pop, held opacity, then eased rise and fade; retain theme colors.'
    if name in ('intent_ui', 'stats_ui'):
        return 'Refine', 'Repeated updates can overlap pulse tweens; replace active pulse and return to authored scale.'
    if name == 'impact_profile':
        return 'Keep', 'Restore original 10/14/20 local impact hierarchy after the first pass weakened feedback. Keep original hitstop and per-weight reaction.'
    if name == 'card_resolver':
        return 'Keep', 'Restore original card camera strengths/default impacts; preserve authoritative resolution, target lists, callbacks and sequencing.'
    if name == 'red_flash':
        return 'Refine', 'Restore 50% player-hit veil and retain the new eased short dissipation through the existing hit event and timer.'
    if name == 'moving_enemy':
        return 'Refine', 'Movement squash now scales the illustration child only; logical root follows its existing movement sequence and destination.'
    if name == 'player':
        return 'Refine', 'Keep authoritative damage/movement callbacks and original camera feedback; cool block tint/text, child-only movement squash and slower mana motes.'
    if name == 'enemy':
        return 'Refine', 'Keep death timing and illustrated death families; fully mitigated hits use cool flash/text and light impulse. Material isolation remains per entity.'
    if name == 'obelisk_enemy':
        return 'Refine', 'Remove legacy (-4,-30) illustration offset so grounded feet, ground ring and occupied hex agree. Preserve summon/death timing and scene artwork.'
    if name == 'card_visuals':
        return 'Refine', 'Restore card-play trail to 96 particles after the 36-particle first pass lost useful density; keep 0.35-second lifetime and scene ownership.'
    if name == 'ember_burst_fx':
        return 'Refine', 'Ten warm embers use a narrow rising cone and upward acceleration, instead of isotropic sparks; finite one-shot cleanup remains shared.'
    if name == 'explosion_fx':
        return 'Refine', 'Eight authored dust-sheet particles settle under downward acceleration, with a 0.42-second burst instead of weightless radial dust.'
    if name == 'summon_wisp_fx':
        return 'Refine', 'Eight plum wisps ascend in a narrow cone after actual placement; fixed 0.4-second one-shot and bounded cleanup.'
    if name == 'rift_tactics_action':
        return 'Refine', 'Previously silent variant attacks, mends, wards and curses now consume the existing signature/illustrated scenes. No new waits, targeting or outcome changes.'
    if name == 'game_world':
        return 'Refine', 'Retain PhantomCamera, illustrated art and TileMap; add exposed perimeter drawing, quieter parallax and coherent new atlas.'
    if name == 'spell_signature' or '_signature' in name:
        return 'Refine', 'Reusable owner-bound playback only; artistic composition is authored individually in each scene. Sample complete frame sequences across their lifetime and independent layer timelines.'
    if path.startswith('scenes/enemy/') and ('attack_action' in name or name in ('bulwark_cleave_action', 'void_spectre_defend_action')):
        return 'Refine', 'Keep attack callbacks and their timing; animate illustration child for lunge rather than authoritative entity root.'
    if path.startswith('ui/fx/'):
        return 'Keep', 'Retain specialized illustrated/particle family; owner-bound playback and finite cleanup. Dependencies and emitter configuration are recorded individually.'
    if path.startswith('resources/vfx/'):
        return 'Keep', 'Authored frame resource; preserves illustrated silhouettes. Animation speed, looping and texture dependencies recorded.'
    if path.startswith('resources/data/cards/'):
        return 'Keep', 'Ability mechanics and configured VFX identity remain authoritative; shared-family refinements apply through existing scene references.'
    if path.startswith('scenes/treasure/'):
        return 'Keep', 'Four twelve-particle reward bursts: upward velocity 200-300, gravity 98, 1.2-second one-shot, alpha/scale curves; retain as rare treasure reveal rather than routine combat feedback.'
    if path.startswith('scenes/relic_handler/'):
        return 'Keep', 'Scene-authored hover/flash AnimationPlayer plus cancelable page tween; readable infrequent reward response, no persistent emitter.'
    if path.startswith('scenes/map/'):
        return 'Keep', 'Scene-authored route selection/highlight and short centering tween; opaque node faces and trimmed connections already meet readability requirements.'
    if path.startswith('scripts/ref_counted/effects/') or path.startswith('scripts/resources/status'):
        return 'Keep', 'Existing authoritative effect/status application and its visual consumer; no extra always-running status emitter.'
    if path.startswith('scenes/sandbox/') or path.startswith('scripts/tests/'):
        return 'Keep', 'Developer fixture/demo presentation retained; not an additional production system.'
    return 'Keep', 'Retain existing scene/theme-owned presentation and signal sequencing; dependencies and animated properties recorded for traceability.'

def dimensions(kind, assessment, properties):
    """Editorial dimensions; do not misrepresent source coverage as per-item render QA."""
    config = properties.get('configuration', '')
    if kind == 'emitter':
        amount = re.search(r'^amount = (.+)', config, re.M)
        lifetime = re.search(r'^lifetime = (.+)', config, re.M)
        efficiency = f"Amount {amount[1] if amount else 'native default'}; lifetime {lifetime[1] if lifetime else 'native default'}; texture/process links and full bounds configuration retained below."
        lifecycle = 'One-shot completion / shared owner deadline.' if 'one_shot = true' in config else 'Continuous, owned by its scene; player buff toggles emitting from existing state.'
    else:
        efficiency = 'No new screen texture read or always-running emitter. Shader source and scene/script operations recorded below; representative overlap QA only.'
        lifecycle = 'Transient playback remains owner-bound; retained UI animations live with their UI owner. Review per-path notes for cancellation and headless handling.'
    return {
        'artistic_quality': assessment,
        'aesthetic': 'Muted illustrated stone/ink; cyan focused magic, plum Rift, ochre resources, cool green mend, warm amber danger. Vendor/demo resources retained in their own context.',
        'readability': 'Preserve character silhouettes and actual target/area bindings; thin amber danger differs from filled cyan targeting. See per-path caveats.',
        'motion_and_timing': 'Existing authoritative callbacks/waits preserved. Short cosmetic release/dissipation or scene-authored UI timing; full animation/emitter configuration recorded below.',
        'technical_correctness': 'Source inspection plus native Godot 4.7.2 resource/representative render checks. Not every item was separately exercised on screen.',
        'rendering_efficiency': efficiency,
        'cleanup_and_lifecycle': lifecycle,
        'reuse_and_maintenance': 'Existing scene/theme/effect consumers retained. Shared shader families, particle cleanup and animated flight avoid parallel effect systems.',
        'necessity': 'Keep existing semantic feedback or developer/vendor fixture; redundant sources explicitly marked Remove/Consolidate.',
        'native_capability': 'Shader for per-pixel shape/tint; particles for bounded independent motion; AnimationPlayer for authored cycles; owner-bound tween for procedural transitions.',
    }

def collect():
    files = sorted(p for p in ROOT.rglob('*') if p.is_file() and p.suffix in EXTENSIONS and not any(part in {'.git', '.godot', '.qa-tmp', 'build', 'qa'} for part in p.relative_to(ROOT).parts))
    texts = {p.relative_to(ROOT).as_posix(): p.read_text(encoding='utf-8-sig') for p in files}
    records = []
    for path, source in texts.items():
        dependencies = sorted(set(re.findall(r'res://[^"\s)]+', source)))
        def add(kind, locator, properties=None):
            disposition, assessment = review(path, kind)
            props = properties or {}
            records.append(dict(path=path, locator=locator, kind=kind, scope='vendor' if path.startswith('addons/') else 'first_party', purpose=Path(path).stem.replace('_', ' '), assessment=assessment, review=dimensions(kind, assessment, props), planned_disposition=disposition, final_disposition=disposition, properties=props, dependencies=dependencies))
        if path.endswith(('.gdshader', '.gdshaderinc')):
            add('shader', 'file', {'uniforms': re.findall(r'^uniform .+', source, re.M), 'screen_read': 'hint_screen_texture' in source, 'consumers': [p for p, t in texts.items() if 'res://' + path in t]})
        if path.endswith(('.tscn', '.tres')):
            for match in re.finditer(r'^\[(node|sub_resource|resource)\b([^\n]*)\]\n(.*?)(?=^\[|\Z)', source, re.M | re.S):
                header, body = match[2], match[3]
                type_match = re.search(r'type="([^"]+)"', header)
                typ = type_match[1] if type_match else ''
                if match[1] == 'resource':
                    root_type = re.search(r'^\[gd_resource type="([^"]+)"', source)
                    typ = root_type[1] if root_type else ''
                kind = {'GPUParticles2D':'emitter', 'CPUParticles2D':'emitter', 'ParticleProcessMaterial':'particle_material', 'ShaderMaterial':'shader_material', 'VisualShader':'shader', 'Animation':'animation', 'AnimatedSprite2D':'animated_sprite', 'AnimatedTexture':'animated_texture', 'SpriteFrames':'sprite_frames', 'AnimationPlayer':'animation_player', 'Parallax2D':'environment_layer', 'Line2D':'line_geometry', 'Polygon2D':'polygon_geometry'}.get(typ)
                if kind:
                    add(kind, header.strip() or 'resource', {'type': typ, 'configuration': body.strip()})
            if path.startswith('ui/fx/') or path in {'ui/world_ui/unit_presence.tscn', 'ui/world_ui/rift_gate.tscn', 'ui/world_ui/target_highlight.tscn', 'ui/world_ui/collapse_outline.tscn', 'ui/world_ui/battle_presentation.tscn'}:
                add('vfx_scene', 'scene')
            for idx, line in enumerate(source.splitlines(), 1):
                if re.match(r'(material|material_override|process_material|texture) = ExtResource', line):
                    add('material_or_texture_binding', f'line {idx}', {'binding':line})
        if path.endswith('.gd'):
            functions = list(re.finditer(r'^(?:static )?func (\w+).*?(?=^(?:static )?func |\Z)', source, re.M | re.S))
            for match in functions:
                lines = [l.strip() for l in match[0].splitlines() if SIGNALS.search(l)]
                if lines:
                    add('script_presentation', match[1], {'line':source[:match.start()].count('\n') + 1, 'visual_operations':lines})
        if path.startswith('resources/data/cards/') and path.endswith('.tres'):
            add('ability_binding', 'card', {'bindings': [l for l in source.splitlines() if re.search(r'visual_fx|projectile|cast_fx', l)]})
    return records

def main():
    records = collect()
    if OUTPUT.exists():
        previous = json.loads(OUTPUT.read_text(encoding='utf-8'))
        keys = {(r['path'], r['kind'], r['locator']) for r in records}
        for old in previous['items']:
            if (old['path'], old['kind'], old['locator']) not in keys:
                old['final_disposition'] = 'Remove'
                if 'Superseded source section' not in old['assessment']:
                    old['assessment'] += ' Superseded source section is absent in the final source scan.'
                records.append(old)
    counts = dict(Counter(r['kind'] for r in records if r['final_disposition'] != 'Remove'))
    OUTPUT.write_text(json.dumps({'date':'2026-10-18', 'scope':'All source directories including vendor and sandbox; generated/import caches excluded. Script rows are candidate methods (including wiring and fixtures), not unique effects. Scenes/materials/animations are separate resources. Reviews are source coverage plus representative native QA, not a claim of individual rendered approval.', 'baseline':{'shaders':19, 'emitters':26, 'particle_materials':17, 'ui_fx_scenes':49, 'world_fx_scenes':5}, 'counts':counts, 'items':records}, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(counts, indent=2))

if __name__ == '__main__':
    main()
