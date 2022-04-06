

mdivs = [
    "No. 2 Entreact",
    "No. 3 Soldatenlied",
    "No. 5a Entreact",
    "No. 5b Entreact",
    "No. 6e Studentenlied",
    "No. 7 Das Lied vom großen Floh",
    "No. 9 Erster Entreact",
    "No. 10 Zweiter Entreact",
    "No. 11 Margaretens Lied in der Kammer",
    "No. 12 Entreact",
    "No. 13 Margarethens Lied am Spinnrade",
    "No. 16 Entreact",
    "No. 18 Ganz zum Schlusse"
]

parts = [
    "Flauto I, II",
    "Oboe I, II",
    "Clarinetto I, II in La",
    "Fagotto I, II",
    "Trombe I, II in La",
    "Corno I, II in Mi",
    "Corno Solo in Fa",
    "Corno in Re, Mi ",
    # "Corno Solo in Fa",
    "Trombone Basso",
    "Trombone Tenore",
    "Trombone Alto",
    "Violino I",
    "Violino II",
    "Viola I, II",
    "Basso e Cello",
]

for mdiv in mdivs:
    for part in parts:
        print("<mdiv>{} - {}</mdiv>".format(mdiv, part))
