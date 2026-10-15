from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Flowable,
    Frame,
    PageTemplate,
    PageBreak,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    KeepTogether,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "Stick_Arena_Diagram_and_Test_Cases.pdf"
FONT_REG = Path("C:/Windows/Fonts/arial.ttf")
FONT_BOLD = Path("C:/Windows/Fonts/arialbd.ttf")
pdfmetrics.registerFont(TTFont("Arial", str(FONT_REG)))
pdfmetrics.registerFont(TTFont("Arial-Bold", str(FONT_BOLD)))

NAVY = colors.HexColor("#142238")
BLUE = colors.HexColor("#2878B9")
PALE_BLUE = colors.HexColor("#EAF3FA")
TEAL = colors.HexColor("#168A83")
PALE_TEAL = colors.HexColor("#E8F5F2")
GOLD = colors.HexColor("#E4AA47")
INK = colors.HexColor("#243447")
MUTED = colors.HexColor("#63758A")
LINE = colors.HexColor("#D5DEE8")
PALE = colors.HexColor("#F5F8FB")
GREEN = colors.HexColor("#18794E")
PALE_GREEN = colors.HexColor("#EAF6EF")
AMBER = colors.HexColor("#98620A")
PALE_AMBER = colors.HexColor("#FFF4DC")
RED = colors.HexColor("#A23B3B")
PALE_RED = colors.HexColor("#FBEDED")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="CoverTitle", fontName="Arial-Bold", fontSize=25, leading=30, textColor=NAVY, alignment=TA_CENTER, spaceAfter=5))
styles.add(ParagraphStyle(name="CoverSub", fontName="Arial", fontSize=11, leading=16, textColor=MUTED, alignment=TA_CENTER, spaceAfter=12))
styles.add(ParagraphStyle(name="Section", fontName="Arial-Bold", fontSize=17, leading=21, textColor=NAVY, spaceBefore=4, spaceAfter=8))
styles.add(ParagraphStyle(name="Subsection", fontName="Arial-Bold", fontSize=11, leading=14, textColor=BLUE, spaceBefore=6, spaceAfter=4))
styles.add(ParagraphStyle(name="Body", fontName="Arial", fontSize=9.2, leading=13, textColor=INK, spaceAfter=5))
styles.add(ParagraphStyle(name="Small", fontName="Arial", fontSize=7.6, leading=10, textColor=INK))
styles.add(ParagraphStyle(name="SmallMuted", fontName="Arial", fontSize=7.4, leading=9.5, textColor=MUTED))
styles.add(ParagraphStyle(name="TableHead", fontName="Arial-Bold", fontSize=7.7, leading=9.5, textColor=colors.white))
styles.add(ParagraphStyle(name="BoxTitle", fontName="Arial-Bold", fontSize=9, leading=11, textColor=NAVY, alignment=TA_CENTER))
styles.add(ParagraphStyle(name="BoxBody", fontName="Arial", fontSize=7.5, leading=9.4, textColor=INK, alignment=TA_CENTER))
styles.add(ParagraphStyle(name="Banner", fontName="Arial-Bold", fontSize=10, leading=14, textColor=NAVY, alignment=TA_CENTER))


class ArchitectureDiagram(Flowable):
    def __init__(self, width=176 * mm, height=86 * mm):
        super().__init__()
        self.width = width
        self.height = height

    def _box(self, c, x, y, w, h, fill, title, body, stroke=None):
        c.setFillColor(fill)
        c.setStrokeColor(stroke or LINE)
        c.setLineWidth(0.8)
        c.roundRect(x, y, w, h, 7, fill=1, stroke=1)
        c.setFillColor(NAVY)
        c.setFont("Arial-Bold", 8.2)
        c.drawCentredString(x + w / 2, y + h - 14, title)
        c.setFillColor(INK)
        c.setFont("Arial", 6.7)
        for i, line in enumerate(body.split("\n")):
            c.drawCentredString(x + w / 2, y + h - 27 - i * 9, line)

    def _arrow(self, c, x1, y1, x2, y2, label=""):
        c.setStrokeColor(BLUE)
        c.setFillColor(BLUE)
        c.setLineWidth(1.15)
        c.line(x1, y1, x2, y2)
        c.saveState()
        c.translate(x2, y2)
        angle = 0
        if abs(x2 - x1) > abs(y2 - y1):
            angle = 0 if x2 >= x1 else 180
        else:
            angle = 90 if y2 >= y1 else 270
        c.rotate(angle)
        p = c.beginPath()
        p.moveTo(0, 0)
        p.lineTo(-5, 2.5)
        p.lineTo(-5, -2.5)
        p.close()
        c.drawPath(p, fill=1, stroke=0)
        c.restoreState()
        if label:
            c.setFillColor(MUTED)
            c.setFont("Arial", 6.1)
            c.drawCentredString((x1 + x2) / 2, (y1 + y2) / 2 + 4, label)

    def draw(self):
        c = self.canv
        w, h = self.width, self.height
        c.setFillColor(PALE_BLUE)
        c.setStrokeColor(colors.HexColor("#C8DDED"))
        c.roundRect(0, h - 40, w, 38, 7, fill=1, stroke=1)
        c.setFillColor(BLUE)
        c.setFont("Arial-Bold", 8.5)
        c.drawString(9, h - 15, "FRONT END  |  What the player sees and uses")

        box_w, box_h = 43 * mm, 24 * mm
        y = h - 35 - box_h
        x1, x2, x3 = 6 * mm, 66 * mm, 129 * mm
        self._box(c, x1, y, box_w, box_h, colors.white, "Player input", "Keyboard controls\nMenus and match actions")
        self._box(c, x2, y, box_w, box_h, colors.white, "main.tscn", "Main menu and pause\nHUD, bars, timer, messages")
        self._box(c, x3, y, box_w, box_h, colors.white, "Rendered game", "Arena, fighters, effects\nand sound feedback")
        self._arrow(c, x1 + box_w, y + box_h / 2, x2, y + box_h / 2)
        self._arrow(c, x2 + box_w, y + box_h / 2, x3, y + box_h / 2)

        by = 9 * mm
        bh = 28 * mm
        c.setFillColor(PALE_TEAL)
        c.setStrokeColor(colors.HexColor("#B9DED7"))
        c.roundRect(0, by - 4, w, bh + 22, 7, fill=1, stroke=1)
        c.setFillColor(TEAL)
        c.setFont("Arial-Bold", 8.5)
        c.drawString(9, by + bh + 8, "LOCAL GAME LOGIC  |  No separate server or web backend")
        logic_y = by
        self._box(c, 5 * mm, logic_y, 53 * mm, bh, colors.white, "main.gd - game controller", "Menus, modes, CPU, timer\nRounds, weapons, blasts\nHUD updates, audio, effects", stroke=colors.HexColor("#B9DED7"))
        self._box(c, 77 * mm, logic_y, 44 * mm, bh, colors.white, "fighter.gd - each fighter", "Movement and collision\nHealth, attacks, block\nKnockback and super meter", stroke=colors.HexColor("#B9DED7"))
        self._box(c, 138 * mm, logic_y, 38 * mm, bh, colors.white, "arena.tscn", "Floor and bounds\nArena 2 lava platform\nPhysics surfaces", stroke=colors.HexColor("#B9DED7"))
        self._arrow(c, 58 * mm, logic_y + bh / 2, 77 * mm, logic_y + bh / 2, "commands")
        self._arrow(c, 77 * mm, logic_y + 6 * mm, 58 * mm, logic_y + 6 * mm, "signals")
        self._arrow(c, 138 * mm, logic_y + bh / 2, 121 * mm, logic_y + bh / 2, "physics")
        self._arrow(c, 58 * mm, y, 32 * mm, logic_y + bh, "input")
        self._arrow(c, 102 * mm, logic_y + bh, 150 * mm, y, "state / visuals")


TESTS = [
    ("MENU-01", "Main menu navigation", "Launch the game. Open Play, Settings, and Controls with Up/Down and Enter. Use Esc to return from submenus.", "The main menu appears first; menu navigation and back behavior work.", "Partial pass", "Launch menu and Play handler tested; physical navigation and Esc not tested."),
    ("MENU-02", "Mode and stage selection", "Choose CPU difficulty, 2 Players, or Practice. Select an opponent where offered, then choose Arena 1 or Arena 2.", "All intended modes and stages lead to the correct match setup.", "Partial pass", "Practice-to-dummy-to-stage flow and stage toggle tested; keyboard navigation and CPU choices not tested."),
    ("MENU-03", "Settings and controls reference", "Change master volume and screen-shake toggle. Open Controls and compare the displayed keys.", "Volume affects sound; shake toggle works; controls reference is accurate.", "Not run", "Settings/audio behavior and navigation need interactive verification."),
    ("MATCH-01", "Movement and Arena 1 bounds", "In a two-player match, move both fighters to arena edges and toward each other; jump and land.", "Correct keys move each fighter; fighters face each other, do not pass through, stay in bounds, and land on the floor.", "Not run", "Movement, physical collisions, and edge behavior not covered by the smoke harness."),
    ("MATCH-02", "Punch, damage number, cooldown", "Land an unblocked punch, then rapidly tap or hold attack.", "Punch removes 20 health, shows applied damage, and respects the existing cooldown.", "Partial pass", "20 damage, damage label, and cooldown tested; reach/facing not tested."),
    ("MATCH-03", "Block and chip damage", "Block Player 1 with S and Player 2 with Down; receive a normal punch.", "Blocked punch removes 5 health, shows -5, and causes no knockback.", "Pass", "5 chip damage and no knockback tested."),
    ("MATCH-04", "Bat pickup, attack, and disarm", "Walk over the bat, attack while holding it, then take a hit while armed.", "Pickup appears in hand and on HUD; bat hit removes 35; a hit disarms the holder.", "Partial pass", "Equip state, 35 damage, and disarm/drop tested; pickup overlap and recollection not tested."),
    ("MATCH-05", "Super meter and projectile", "Build meter, fire a special, test blocked/unblocked damage, and attempt a second blast while one is active.", "Meter fills and resets; damage is 40/10; only one blast per fighter; effects and sounds appear.", "Partial pass", "Damage, firing, meter consumption, trail node, and one-blast rule tested; physical input, impact, and sound/visual quality not tested."),
    ("MATCH-06", "Round timer and timeout", "Let the round timer reach zero with equal and unequal health; pause during a live round.", "Timer starts with FIGHT, stops when appropriate, displays TIME!, resolves higher health, and replays a draw.", "Partial pass", "Timeout, draw, and higher-health winner logic tested; full countdown, red pulse, and TIME display timing not tested."),
    ("MATCH-07", "Best-of-three match end", "Win two rounds, then repeat with the other player as winner.", "Win indicators update and the first fighter to two round wins gets the match-end screen.", "Pass", "Two round wins reaching match end tested."),
    ("MATCH-08", "Pause, resume, restart, main menu", "Press Esc during a match and try Resume, Restart, and Main Menu.", "Pause options work; timer and gameplay stop while paused.", "Partial pass", "Pause/resume states tested; key navigation, restart, and main-menu action not tested."),
    ("STAGE-01", "Arena 1 floor and no hazard", "Play Arena 1 and move or get knocked near either edge.", "Full-width floor and current boundary behavior remain; no lava damage occurs.", "Not run", "Arena 1 visual and physical boundary behavior not exercised."),
    ("STAGE-02", "Arena 2 lava and weapon respawn", "Walk or get knocked into lava; drop the bat into a pit and wait for respawn.", "Lava causes periodic damage and recoil; bat disappears and returns to safe platform after delay.", "Partial pass", "Lava damage, stage physics toggle, and weapon loss scheduling tested; actual fall, intervals, effects, and respawn completion not tested."),
    ("CPU-01", "CPU behavior and difficulty", "Play Easy, Normal, and Hard; test weapon seeking and CPU special use at range.", "CPU difficulty changes reaction/block/attack behavior; CPU uses weapons and full-meter special appropriately.", "Partial pass", "Arena 2 edge-avoidance logic tested; randomized combat, difficulty, weapon seeking, and special timing not tested."),
    ("PRACTICE-01", "Practice mode selection", "Choose Practice, select CPU or dummy and difficulty, then select each stage.", "Practice offers opponent choices and both arenas start correctly.", "Partial pass", "Practice-to-dummy-to-stage handler path tested; CPU difficulty selection not tested."),
    ("PRACTICE-02", "No timer or round win", "Start Practice and continue through a KO.", "No countdown or round/match win; the bout continues.", "Pass", "Hidden/stopped timer and no awarded round on KO tested."),
    ("PRACTICE-03", "Passive dummy behavior", "Wait while facing the dummy, then hit and knock it back.", "Dummy does not move or attack by itself but can be hit and moved.", "Pass", "Dummy move direction and attack disabled state tested."),
    ("PRACTICE-04", "Manual super-meter fill", "Press M in Practice; verify normal matches do not allow manual fill. Test N only if P2 is human-controlled.", "Practice key fills the intended fighter meter only in Practice.", "Not run", "Physical M key not verified by headless input. Current Practice offers CPU/dummy, so human P2/N path is unavailable."),
    ("PRACTICE-05", "Recovery after lethal damage", "Reduce a fighter to zero health and time recovery; repeat for both fighters.", "KO fighter restores to full health after about one second without ending Practice.", "Pass", "One-second recovery scheduling and full-health restore tested."),
    ("PRACTICE-06", "Applied damage numbers", "Test punch, block, bat, special, and lava hits, including low remaining health.", "Damage number reflects the actual health removed for each hit.", "Partial pass", "Punch and lava labels tested; other label values not tested."),
    ("PRACTICE-07", "Pause and restart in Practice", "Pause, wait, resume, and test Restart and Main Menu.", "Pause flow works; timers/recovery stop while paused; restart/menu return correctly.", "Not run", "Interactive pause/restart/menu behavior not tested."),
    ("VISUAL-01", "Visual and audio feedback", "Review both arenas, hits, blocks, specials, KO, settings, and sound effects in a live match.", "Bars, indicators, hit feedback, particles, stages, camera, and sounds look and respond correctly.", "Not run", "Visual quality and audible output need an in-game review."),
]


def P(text, style="Body"):
    return Paragraph(text, styles[style])


def status_cell(status):
    if status == "Pass":
        bg, fg = PALE_GREEN, GREEN
    elif status == "Partial pass":
        bg, fg = PALE_AMBER, AMBER
    else:
        bg, fg = PALE_RED, RED
    return Table([[Paragraph(f'<font color="{fg.hexval()}"><b>{status}</b></font>', styles["Small"])]], colWidths=[25 * mm], style=TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg), ("BOX", (0, 0), (-1, -1), 0.35, colors.white),
        ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))


def header_footer(canvas, doc):
    canvas.saveState()
    width, height = A4
    canvas.setFillColor(NAVY)
    canvas.rect(0, height - 8 * mm, width, 8 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white)
    canvas.setFont("Arial-Bold", 7.5)
    canvas.drawString(18 * mm, height - 5.5 * mm, "STICK ARENA  |  ARCHITECTURE + TESTS")
    canvas.setStrokeColor(LINE)
    canvas.line(18 * mm, 14 * mm, width - 18 * mm, 14 * mm)
    canvas.setFillColor(MUTED)
    canvas.setFont("Arial", 7)
    canvas.drawString(18 * mm, 9 * mm, "Godot 4.7.2 stable  |  Test run: 2026-10-09")
    canvas.drawRightString(width - 18 * mm, 9 * mm, f"Page {doc.page}")
    canvas.restoreState()


class Doc(BaseDocTemplate):
    def __init__(self, filename):
        super().__init__(filename, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=15 * mm, bottomMargin=19 * mm, title="Stick Arena - Architecture Diagram and Test Cases", author="Codex")
        frame = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="normal", leftPadding=0, rightPadding=0, topPadding=2 * mm, bottomPadding=0)
        self.addPageTemplates([PageTemplate(id="all", frames=[frame], onPage=header_footer)])


def case_table(rows):
    data = [[P("ID", "TableHead"), P("Test case / procedure / expected result", "TableHead"), P("Result", "TableHead")]]
    for test_id, title, steps, expected, status, evidence in rows:
        body = f'<b>{title}</b><br/><font color="#63758A">Steps:</font> {steps}<br/><font color="#63758A">Expected:</font> {expected}<br/><font color="#63758A">Run note:</font> {evidence}'
        data.append([P(test_id, "Small"), P(body, "Small"), status_cell(status)])
    table = Table(data, colWidths=[27 * mm, 116 * mm, 25 * mm], repeatRows=1, hAlign="LEFT", splitByRow=1, splitInRow=0)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.35, LINE),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PALE]),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    return table


story = [
    Spacer(1, 5 * mm),
    P("STICK ARENA", "CoverTitle"),
    P("Front-end and game-logic diagram + test cases and runtime results", "CoverSub"),
    Table([[P("40 passed", "Banner"), P("0 failed", "Banner"), P("Godot 4.7.2", "Banner")]], colWidths=[56 * mm] * 3, style=TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), PALE_GREEN), ("BOX", (0, 0), (-1, -1), 0.5, LINE),
        ("INNERGRID", (0, 0), (-1, -1), 0.5, LINE), ("TOPPADDING", (0, 0), (-1, -1), 8), ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ])),
    Spacer(1, 5 * mm),
    P("System architecture", "Section"),
    P("This is a local Godot game. The term backend below means the game logic running inside the game; there is no separate web server, database, or online service.", "Body"),
    ArchitectureDiagram(),
    Spacer(1, 3 * mm),
    P("How the pieces connect", "Subsection"),
    P("The player uses keyboard input through the game scene. <b>main.gd</b> coordinates menus, modes, CPU behavior, rounds, timer, weapons, projectiles, HUD, audio, and effects. It sends actions to each <b>fighter.gd</b>; fighters report health, hits, knockouts, meter changes, and weapon drops back with signals. The arena scene supplies the floor, stage geometry, and collision surfaces.", "Body"),
    P("Project files: scenes/game/main.tscn, scenes/arenas/arena.tscn, scenes/player/fighter.tscn, scripts/game/main.gd, scripts/player/fighter.gd.", "SmallMuted"),
    PageBreak(),
    P("Runtime test summary", "Section"),
    P("The automated headless smoke harness directly exercises game methods and menu handlers. It is useful for core logic regression, but it does not fully replace playing the game with a keyboard or checking rendered visuals and sound.", "Body"),
    Table([
        [P("Check", "TableHead"), P("Result", "TableHead")],
        [P("Automated smoke harness", "Small"), P("40 passed, 0 failed", "Small")],
        [P("Main-scene launch", "Small"), P("90 frames; process exited with code 0; no scene/script errors", "Small")],
        [P("Environment warning", "Small"), P("Godot could not read the Windows root-certificate store. This did not stop either run.", "Small")],
        [P("Manual verification remaining", "Small"), P("Physical keyboard controls, movement/collision play, settings, full timer presentation, visual effects, and audible sound still need live review.", "Small")],
    ], colWidths=[55 * mm, 149 * mm], style=TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY), ("GRID", (0, 0), (-1, -1), 0.4, LINE),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PALE]), ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ])),
    Spacer(1, 4 * mm),
    P("Result meanings", "Subsection"),
    P("<b>Pass</b> means the documented behavior was exercised in the smoke harness. <b>Partial pass</b> means only the noted portion was checked; remaining steps need a live/manual test. <b>Not run</b> means the behavior was not exercised by this runtime run.", "Body"),
    P("How to rerun", "Subsection"),
    P("Open a terminal in the project folder and run the Godot 4.7.2 executable in headless mode with the project path and <b>--script res://tests/runtime_smoke.gd</b>. For a launch-only smoke check, use <b>--headless --path &lt;project-folder&gt; --quit-after 90</b>.", "Body"),
    PageBreak(),
    P("Test cases and results", "Section"),
    P("Run notes are from the 2026-10-09 headless test. For every partial or not-run case, use the procedure below in the game to complete the check. Record a date and any observed issue when doing manual testing.", "Body"),
]

groups = [
    ("Menu and setup", TESTS[0:3]),
    ("Normal match", TESTS[3:11]),
    ("Stages and CPU", TESTS[11:14]),
    ("Practice mode and presentation", TESTS[14:]),
]
for group_index, (heading, rows) in enumerate(groups):
    if group_index > 0:
        story.append(PageBreak())
    story.append(P(heading, "Subsection"))
    story.append(case_table(rows))
    story.append(Spacer(1, 3 * mm))

story.extend([
    PageBreak(),
    P("Controls reference", "Section"),
    Table([
        [P("Context", "TableHead"), P("Controls", "TableHead")],
        [P("Menus", "Small"), P("Up/Down navigate; Enter confirms; Left/Right changes settings or stage; Esc goes back or pauses; R restarts.", "Small")],
        [P("Player 1", "Small"), P("A/D move; W or Space jump; F attack; S block; G special.", "Small")],
        [P("Player 2", "Small"), P("Left/Right move; Up jump; O attack; Down block; P special.", "Small")],
        [P("Practice meter", "Small"), P("M fills Player 1 meter. N is described for Player 2 when human-controlled; the current Practice opponent choices are CPU or dummy, so that route is not currently selectable.", "Small")],
    ], colWidths=[39 * mm, 165 * mm], style=TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY), ("GRID", (0, 0), (-1, -1), 0.4, LINE),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PALE]), ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ])),
    Spacer(1, 7 * mm),
    P("Manual result recording", "Subsection"),
    P("For hands-on checks, record Pass, Fail, or Blocked for each case and add a short note (for example, exact key sequence, observed damage, screenshot location, or error message).", "Body"),
])

OUT.parent.mkdir(parents=True, exist_ok=True)
Doc(str(OUT)).build(story)
print(OUT)
