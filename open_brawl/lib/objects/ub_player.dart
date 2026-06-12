enum PlayerRace { mensch, elf, zwerg, ork, troll }

class UbPlayer {
  int key;
  String name;

  int body;
  int agility;
  int reaction;
  int strength;
  int willpower;
  int logic;
  int intuition;
  int charisma;
  double essence = 6;
  int edge;
  int initative = 0;
  int conSave = 0;
  int menSave = 0;
  int bodyDamage = 0;
  int mentalDamage = 0;
  int movementPointsWalk = 0;
  int movementPointsRun = 0;

  int armor = 0;
  var playerRace = PlayerRace.mensch;

  UbPlayer({
    required this.key,
    required this.name,
    required this.body,
    required this.agility,
    required this.reaction,
    required this.strength,
    required this.willpower,
    required this.logic,
    required this.intuition,
    required this.charisma,
    required this.edge,
  });

  void calculateBaseValues() {
    initative = intuition + reaction;
    conSave = body + willpower;
    menSave = logic + willpower;
    bodyDamage = 8 + (body ~/ 2);
    mentalDamage = 8 + (willpower ~/ 2);
    movementPointsWalk = agility * 2;
    movementPointsRun = agility * 4;
  }

  int calcSprint() {
    /*    Probe: Laufen + Stärke

    Effekt: Jeder Erfolg auf die Probe erhöht deine zurückgelegte Distanz in dieser Runde um zusätzliche 2 Meter (bei Zwergen und Trollen nur 1 Meter pro Erfolg).

    Beispiel: Dein Mensch mit Beweglichkeit 5 (Laufrate 20m) sprintet und erzielt 3 Erfolge. Er kann sich in dieser Runde insgesamt 20 + (3 x 2) = 26 Meter bewegen. */
    return 0;
  }
}
