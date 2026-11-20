"""Symulacja ekonomii Star Watcher (Etap 1 i 2): ile dni zajmuje drzewko i sklep, ile $ i PW przynosi noc.

Czyta stałe z game/game.gd (SCIENCE, SHOP, SCIENCE2, SHOP2, SKY2, gwiazdozbiory), a zachowanie gracza modeluje prosto:
- w nocy łapie obiekty od najcenniejszych, każdy zajmuje T_OBJ sekund (krócej z ulepszeniami celownika i autofokusem),
- dysk ogranicza tylko $ (raport można wysłać w nocy, więc przyjmujemy 2 opróżnienia na noc),
- rano kupuje najtańsze dostępne węzły drzewka i rzeczy ze sklepu (najpierw te, które podnoszą zarobek).
Kalibracja: wynik bazowy ma się zgadzać z grą autora (Etap 1 wykupiony ok. 9. dnia; 1. noc Etapu 2: ~$46k i ~54k PW).
usage: python tools/balance_sim.py [wariant ...]   (bez argumentów: wszystkie warianty z VARIANTS)
"""
import re, sys, random
from pathlib import Path

SRC = (Path(__file__).resolve().parent.parent / "game" / "game.gd").read_text(encoding="utf-8")


def table(name):
    i = SRC.index(f"const {name} := ["); j = SRC.index("\n]", i)
    return [dict(id=a, cost=int(c), tier=int(t), path=int(p), req=r)
            for a, c, t, p, r in re.findall(r'\["(\w+)", "(?:[^"\\]|\\.)+", (\d+), (\d), (\d), "(\w*)"', SRC[i:j])]


def sky2():
    i = SRC.index("const SKY2 := {"); j = SRC.index("\n}", i)
    return {k: dict(cat=c, req=r, pw=int(p), price=int(pr)) for k, c, r, p, pr in
            re.findall(r'"(\w+)": \{"name": "[^"]+", "cat": "(\w+)", "req": "(\w*)", "pw": (\d+), "price": (\d+)', SRC[i:j])}


def sky1():
    out = {k: dict(cat=c, req=r, pw=int(p), price=int(pr)) for k, c, r, p, pr in
           re.findall(r'"(\w+)": \{"name": "[^"]+", "cat": "(\w+)", "req": "(\w*)", "pw": (\d+), "price": (\d+)', SRC[:SRC.index("const CONSTELLATIONS")])}
    i = SRC.index("const CONSTELLATIONS"); j = SRC.index("\n]", i)
    for cid, req, pts in re.findall(r'\["(\w+)", "[^"]+", ("?\w*"?|\d), "([^"]+)"', SRC[i:j]):
        n = len(pts.split()); zod = not req.startswith('"')
        out[cid] = dict(cat="zodiac" if zod else "const", req="podstawowe" if zod else req.strip('"'), pw=n + (20 if zod else 8),
                        price=(40 if zod else 12) + n * (2 if zod else 3), pts=n)
    return out


SCI1, SHOP1, SCI2, SHOP2 = table("SCIENCE"), table("SHOP"), table("SCIENCE2"), table("SHOP2")
SKY1, SKY2 = sky1(), sky2()
SKY2_0 = {k: dict(o) for k, o in SKY2.items()}
QUAL = 0.8          # średnia jakość pomiaru
T_OBJ = 6.0         # s na obiekt przed ulepszeniami
INC = 1.5           # kalibracja: oferty, popyt, zgłoszenia, sprytniejsze zakupy niż „najtańsze najpierw” (autor: Etap 1 w ~9-10 dni)
RARE = {"zodiac", "planet", "deep", "comet", "nebula", "moons", "blackhole"}
SPEC = {"planet", "moons", "nebula", "deep", "blackhole"}


def run(v, days=40, seed=1, log=False):
    rnd = random.Random(seed)
    for k, o in SKY2_0.items():  # wartości nieba Etapu 2 (wariant może je obniżyć)
        SKY2[k]["price"] = round(o["price"] * v.get("s2_price", 1)); SKY2[k]["pw"] = round(o["pw"] * v.get("s2_pw", 1))
    has = set(); pw = v.get("pw0", 0); money = v.get("money0", 0); stage = 1; disc = set(); res = []
    for row in SCI1 + SHOP1:
        row["cost1"] = round(row["cost"] * (v.get("t3_1", 1) if row["tier"] == 3 and row["id"] not in ("manifest", "certyfikat") else 1))
        if row["id"] in ("manifest", "certyfikat"):
            row["cost1"] = v.get(row["id"], row["cost"])
    for row in SCI2 + SHOP2:
        row["cost1"] = round(row["cost"] * (v.get("s2_cost", 1) if row["id"] != "heavy" else v.get("heavy", 1)))
    for d in range(1, days + 1):
        L = 60 + 15 * ("poduszka" in has) + 20 * ("termos" in has) + 10 * ("nocny1" in has) + 15 * ("nocny2" in has)
        t = T_OBJ
        for k, f in [("kawa", .9), ("kursor1", .95), ("statyw", .95), ("montaz", .9), ("szukacz", .85), ("auto1", .9), ("auto2", .85),
                     ("samoistne", .85), ("radio", .95), ("mikro", .95), ("kalibracja", .9), ("smar", .95)]:
            t *= f if k in has else 1
        sky = SKY1 if stage == 1 else {**SKY1, **SKY2}
        avail = [k for k, o in sky.items() if (o["req"] == "" or o["req"] in has) and not (stage == 1 and k in SKY2)]
        n_const = 5 if "podstawowe" in has else 4
        pick = [k for k in avail if sky[k]["cat"] == "const"][:n_const]
        pick += [k for k in avail if sky[k]["cat"] == "zodiac"][:1]
        for cat in ("nebula", "planet", "deep"):
            pick += [k for k in avail if sky[k]["cat"] == cat][:1 if stage < 2 else 2]
        if stage >= 2:
            for cat in ("moons", "blackhole"):
                pick += [k for k in avail if sky[k]["cat"] == cat][:2]
        if "newton" in has:
            pick += [k for k in avail if sky[k]["cat"] in ("const", "zodiac", "nebula") and k not in pick][:10]
        bonus = sum(b for k, b in [("achromat", .2), ("lcd", .25), ("vga", .2), ("astrotax", .15), ("modem", .1)] if k in has)
        def price(k):
            o = sky[k]; s2obj = k in SKY2
            keep = not (s2obj and v.get("no_carry"))
            base = o["price"] * (1.5 if "newton" in has and keep and not v.get("add") else 1)
            inst = 2.0 if "licencja" in has and o["cat"] in RARE and keep and not v.get("add") else 1.0
            b = (bonus if keep else 0) + (0.2 if "okular_hr" in has and o["cat"] in ("deep", "blackhole") else 0)
            if v.get("add"):  # wszystkie bonusy do ceny w jednej puli: Newton +50%, Licencja +100% (rzadkie), komputer jak dziś
                b += 0.5 * ("newton" in has) + (1.0 if "licencja" in has and o["cat"] in RARE else 0)
            if stage >= 2 and "spektro" in has and o["cat"] in SPEC:
                inst *= 1.5 + .1 * ("katalog" in has) + .25 * ("filtry" in has)
            return base * QUAL * 1.1 * (1 + b) * inst
        def pwv(k):
            o = sky[k]; g = o["pw"] * (1.5 if stage >= 2 and "spektro" in has and o["cat"] in SPEC else 1)
            if "pts" in o:
                g += o["pts"] * ((1 if "nawyk1" in has else 0) + (2 if "nawyk2" in has else 0))
            return g
        pick.sort(key=lambda k: -(price(k) + pwv(k)))
        n = int(L / t)
        cap = 5 + sum(c for k, c in [("dd", 5), ("hd", 10), ("pudelko", 10), ("stacja", 20), ("nas", 50)] if k in has)
        got = pick[:n]
        sold = got[:cap * 2]
        rep = v.get("repeat", 1.0)  # ponowny pomiar znanego obiektu: ułamek ceny i PW
        dollars = sum(price(k) * (rep if k in disc else 1) for k in sold)
        pm = (1 + .1 * ("pamiec1" in has) + .15 * ("pamiec2" in has)) * (1.5 if "notatki" in has else 1)
        pts = sum(pwv(k) * (rep if k in disc else 1) for k in got) + 50 * ("materac" in has) + 25 * (L / 50) * ("meteory" in has)
        disc |= set(got)
        if "encyklopedia" in has:
            pts += 0.5 * min(len(disc), 20) * L
        if "kometa" in has and d % 4 == 0:
            pts += 150; dollars += 520 * QUAL * (1 + bonus) * (2 if "licencja" in has else 1)
        dollars *= INC; pts *= INC
        pw += pts * pm
        money += dollars
        if "wzor" in has:
            pw += dollars * v.get("wzor", 1.0)
        res.append((d, stage, round(dollars), round(pts * pm + ("wzor" in has) * dollars * v.get("wzor", 1.0)), round(money), round(pw)))
        # zakupy rano: najpierw drzewko (najtańsze dostępne), potem sklep
        sci = SCI1 if stage == 1 else SCI2
        shp = SHOP1 if stage == 1 else SHOP2
        def tier_ok(row, tab):
            c = lambda t: sum(1 for r in tab if r["tier"] == t and r["id"] in has)
            if v.get("tree") and row["tier"] > 1 and not any(r["tier"] == row["tier"] - 1 and r["path"] == row["path"] and r["id"] in has for r in tab):
                return False
            return not (row["tier"] == 2 and c(1) < 3 or row["tier"] == 3 and c(2) < 4 or row["id"] == "wniosek" and c(3) < 4)
        bought = True
        while bought:
            bought = False
            for row in sorted(sci, key=lambda r: r["cost1"]):
                if row["id"] in has or (row["req"] and row["req"] not in has) or not tier_ok(row, sci):
                    continue
                if row["id"] in ("manifest", "wniosek") and not all(r["id"] in has for r in sci if r["id"] not in ("manifest", "wniosek")):
                    continue
                if pw >= row["cost1"]:
                    pw -= row["cost1"]; has.add(row["id"]); bought = True; break
            for row in sorted(shp, key=lambda r: r["cost1"]):
                if row["id"] in has or (row["req"] and row["req"] not in has):
                    continue
                if row["id"] == "certyfikat" and "manifest" not in has or row["id"] == "heavy" and "wniosek" not in has:
                    continue
                if row["id"] in ("certyfikat", "heavy") and not all(r["id"] in has for r in shp if r["id"] not in ("certyfikat", "heavy")):
                    continue
                if money >= row["cost1"]:
                    money -= row["cost1"]; has.add(row["id"]); bought = True; break
        if stage == 1 and "certyfikat" in has:
            res.append(("ETAP2", d, round(money), round(pw)))
            stage = 2
            if v.get("reset"):
                money, pw = v["reset"]
        elif stage == 2 and "heavy" in has and "wniosek" in has:
            res.append(("KONIEC", d, round(money), round(pw)))
            break
    return res


VARIANTS = {  # stałe czytane z game.gd są już po pakiecie P2 (niebo E2 /2, ceny E2 x2,5, Heavy $100k); flagi = logika z kodu
    "teraz (P2)": {"add": True, "wzor": 0.25, "tree": True, "repeat": 0.5},
    "P2 + drzewko E2 x1,4 (gdyby PW się przelewało)": {"add": True, "wzor": 0.25, "tree": True, "repeat": 0.5, "s2_cost": 1.4, "heavy": 1},
}

if __name__ == "__main__":
    names = sys.argv[1:] or list(VARIANTS)
    for name in names:
        r = run(VARIANTS[name])
        print("==", name)
        for row in r:
            if isinstance(row[0], str):
                print("  ", row)
        s1 = [x for x in r if not isinstance(x[0], str) and x[1] == 1]
        s2 = [x for x in r if not isinstance(x[0], str) and x[1] == 2]
        print("   E1 noce: $/noc", [x[2] for x in s1][::2], " PW/noc", [x[3] for x in s1][::2])
        print("   E2 noce: $/noc", [x[2] for x in s2][:12], " PW/noc", [x[3] for x in s2][:12])
