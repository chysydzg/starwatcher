# Do zrobienia (następna sesja)

## Scenki satelitów: wyreżyserować od nowa
Autor: „scenka wygląda bardzo źle”. Obecna wersja (`game/sat_scene.gd`, grafika `tools/art/satscene.js`,
dźwięki `tools/sfx/sat_sfx.py`) działa w grze tylko jako zaślepka:
- budowa: przy pierwszym zakupie satelity (`astroos.gd`, `tips.sat_build_cut`),
- start: rano, gdy pierwszy satelita dolatuje na orbitę (`game.gd` → `tips.sat_launch_pending`, `world.gd`).

Prośba autora: widok z boku na rusztowanie, zwierzątka chodzą po rusztowaniu i budują, podają sobie białe blachy,
przebicia montażowe jak przy remoncie obserwatorium, satelita składa się coraz bardziej, dźwięki młotków w metal
i śrub, w tle ramię robota i fragment dźwigu. Start: wystrzelenie w kosmos i wejście na orbitę.
Zacząć od rozpisania ujęć (storyboard) i pokazania ich autorowi przed kodem.
Młotek w blachę słaby w earshot (Clang 0.77, „metal clang” z +0.8): rozważyć nagranie CC0.

## Punkt 13 z listy 27.11
Teleskop w laboratorium jest identyczny jak na balkonie: przyciemnić czy pokazać Newtona? (czeka na autora)
