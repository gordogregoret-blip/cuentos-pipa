#!/usr/bin/env python3
"""Fuente de "El huevo que brillaba" (stories/dino/story.json).

El texto vive acá para poder leerlo y revisarlo cómodo; este script escribe el story.json.
Reglas de escritura: lenguaje literal, sin ironías ni metáforas; cada vez que cambia el
colgante se nombra el color y la emoción de Pipa.

Uso: python3 tools/content/dino.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "stories" / "dino" / "story.json"


def T(simple, cuento, aventura):
    return {"simple": simple, "cuento": cuento, "aventura": aventura}


def tap(id, art, x, y, size, anim, sfx, word, flag=None):
    d = {"id": id, "art": art, "x": x, "y": y, "size": size, "anim": anim, "sfx": f"sfx/{sfx}.ogg", "word": word}
    if flag:
        d["flag"] = flag
    return d


def ch(id, x, y, scale=0.42, state=None, flip=False):
    d = {"id": id, "x": x, "y": y, "scale": scale}
    if state:
        d["state"] = state
    if flip:
        d["flip"] = True
    return d


def huella(flag, x, y):
    return tap("huella_dorada", "art/huella_dorada.svg", x, y, 120, "grow", "campanita", "¡Una huella dorada!", flag)


EQUIPO = [ch("pipa", 0.24, 0.66), ch("fido", 0.37, 0.66, 0.36), ch("bubu", 0.11, 0.66, 0.4)]

pages = {}

pages["p1"] = {
    "background": "art/bg_plaza.svg",
    "text": T(
        "Pipa, Fido y Bubu están en la plaza. La puerta verde se abre. Sale un huevo que brilla. "
        "El colgante está violeta. Pipa está sorprendida.",
        "Pipa, Fido y Bubu juegan en la plaza, al lado del Árbol de las Puertas. De pronto, la puerta "
        "verde se abre despacio. Un huevo grande rueda hasta los pies de Pipa. ¡El huevo brilla! "
        "El colgante está violeta. Pipa está sorprendida.",
        "Es una mañana tranquila en la plaza del pueblo. Pipa, Fido y Bubu juegan al lado del Árbol de "
        "las Puertas. De pronto se escucha un ruido suave: la puerta verde se abre despacio. Un huevo "
        "grande y redondo rueda por el pasto y se detiene a los pies de Pipa. El huevo brilla con una "
        "luz tibia. El colgante está violeta. Pipa está sorprendida."),
    "pendant": [{"color": "violeta", "at": 0.72}],
    "characters": [ch("pipa", 0.3, 0.66, 0.45, "sorpresa"), ch("bubu", 0.13, 0.66, 0.42)],
    "tappables": [
        tap("huevo", "art/huevo.svg", 0.5, 0.6, 200, "grow", "brillo", "¡Brilla! El huevo"),
        tap("puerta", "art/puerta_verde.svg", 0.72, 0.4, 260, "wiggle", "puerta", "La puerta verde"),
        tap("fido", "cast:fido", 0.86, 0.6, 260, "hop", "guau", "¡Guau! Fido"),
        huella("huella_1", 0.6, 0.22),
    ],
    "next": "p2",
}

pages["p2"] = {
    "background": "art/bg_valle.svg",
    "text": T(
        "Fido huele el suelo. Encuentra huellas grandes. Son huellas de dinosaurio. "
        "El colgante está amarillo. Pipa está contenta. Hay dos caminos.",
        "Fido acerca la nariz al suelo y huele. ¡Encuentra huellas grandes! Son huellas de dinosaurio. "
        "Pipa quiere devolver el huevo a su mamá. El colgante está amarillo. Pipa está contenta. "
        "Hay dos caminos: el río de las burbujas y el bosque que canta.",
        "Detrás de la puerta verde hay un valle con plantas gigantes. Fido acerca la nariz al suelo y "
        "huele con mucha atención. ¡Encuentra huellas enormes, con tres dedos! Son huellas de "
        "dinosaurio. Pipa decide devolver el huevo a su mamá. El colgante está amarillo. Pipa está "
        "contenta. Fido encuentra dos caminos: uno va por el río de las burbujas y el otro va por el "
        "bosque que canta."),
    "pendant": [{"color": "amarillo", "at": 0.62}],
    "characters": EQUIPO,
    "tappables": [
        tap("huellas", "art/huellas.svg", 0.55, 0.62, 220, "grow", "paso", "Huellas de dinosaurio"),
        tap("helecho", "art/helecho.svg", 0.78, 0.38, 240, "wiggle", "hojas", "Un helecho gigante"),
        tap("huevo", "art/huevo.svg", 0.42, 0.42, 150, "grow", "brillo", "El huevo brilla"),
        tap("nariz", "cast:fido", 0.66, 0.3, 280, "hop", "olfato", "Fido huele"),
    ],
    "decision": {"options": [
        {"text": "Por el río de las burbujas", "image": "art/op_rio.svg", "to": "a3"},
        {"text": "Por el bosque que canta", "image": "art/op_bosque.svg", "to": "b3"},
    ]},
}

pages["a3"] = {
    "background": "art/bg_rio.svg",
    "text": T(
        "El río es ancho. El colgante está naranja. Pipa está nerviosa. Tina, la triceratops bebé, "
        "los lleva en su lomo. El colgante está amarillo. Pipa está contenta.",
        "El río de las burbujas es ancho y profundo. El colgante está naranja. Pipa está nerviosa. "
        "Entonces llega Tina, una triceratops bebé. Tina dice: “Suban a mi lomo, yo los llevo”. "
        "Todos cruzan el río sobre Tina. El colgante está amarillo. Pipa está contenta.",
        "El río de las burbujas es ancho y profundo. Del agua salen burbujas redondas que suben y "
        "explotan sin ruido. Pipa no sabe cómo cruzar. El colgante está naranja. Pipa está nerviosa. "
        "Entonces se acerca Tina, una triceratops bebé con tres cuernos cortos. Tina dice: “Suban a "
        "mi lomo. Yo sé cruzar”. Pipa, Fido y Bubu suben con cuidado y cruzan el río sobre Tina. "
        "El colgante está amarillo. Pipa está contenta."),
    "pendant": [{"color": "naranja", "at": 0.25}, {"color": "amarillo", "at": 0.9}],
    "characters": [ch("pipa", 0.22, 0.66, 0.4), ch("bubu", 0.09, 0.66, 0.38)],
    "tappables": [
        tap("tina", "art/tina.svg", 0.55, 0.55, 360, "hop", "paso", "¡Hola! Soy Tina"),
        tap("burbuja", "art/burbuja.svg", 0.78, 0.3, 140, "float", "burbuja", "¡Plop! Una burbuja"),
        tap("pez", "art/pez.svg", 0.84, 0.62, 170, "wiggle", "agua", "Un pez naranja"),
        tap("fido", "cast:fido", 0.36, 0.45, 280, "hop", "guau", "¡Guau! Fido"),
        huella("huella_2", 0.66, 0.18),
    ],
    "next": "a4",
}

pages["a4"] = {
    "background": "art/bg_cascada.svg",
    "text": T(
        "Llegan a una cascada muy alta. El nido está arriba. El colgante está violeta. "
        "Pipa está sorprendida. Pueden subir por las piedras o pedirle ayuda a Brachi.",
        "Tina los deja al lado de una cascada muy alta. Fido huele: el nido de la mamá del huevo está "
        "arriba. El colgante está violeta. Pipa está sorprendida. Hay piedras que forman una escalera. "
        "También está Brachi, un braquiosaurio de cuello largo.",
        "Tina los deja al pie de una cascada muy alta. El agua cae con un ruido fuerte y constante. "
        "Fido levanta la nariz y huele: el nido de la mamá del huevo está arriba de la cascada. "
        "El colgante está violeta. Pipa está sorprendida. Al costado hay piedras planas que forman "
        "una escalera. Un poco más lejos come hojas Brachi, un braquiosaurio de cuello muy largo."),
    "pendant": [{"color": "violeta", "at": 0.5}],
    "characters": EQUIPO,
    "tappables": [
        tap("cascada", "art/cascada.svg", 0.58, 0.35, 260, "float", "agua", "La cascada"),
        tap("piedra", "art/piedra.svg", 0.46, 0.6, 160, "bounce", "paso", "Una piedra plana"),
        tap("brachi", "art/brachi.svg", 0.82, 0.42, 340, "float", "hojas", "Brachi come hojas"),
        tap("arcoiris", "art/arcoiris.svg", 0.42, 0.2, 200, "grow", "campanita", "Un arcoíris"),
    ],
    "decision": {"options": [
        {"text": "Subir paso a paso por las piedras", "image": "art/op_piedras.svg", "to": "p5_pasos"},
        {"text": "Pedirle ayuda a Brachi", "image": "art/op_brachi.svg", "to": "p5_brachi"},
    ]},
}

pages["b3"] = {
    "background": "art/bg_bosque.svg",
    "text": T(
        "En el bosque aparece Rex. Rex es enorme. El colgante está naranja. Pipa tiene miedo. "
        "Bubu dice: “Tranqui… yo también soy grandote”. El colgante está verde. Pipa está tranquila.",
        "Los árboles del bosque suenan con el viento. Detrás de un árbol aparece Rex. Rex es enorme "
        "y mira el piso con vergüenza. El colgante está naranja. Pipa tiene miedo. Bubu se pone al "
        "lado de Rex y dice: “Tranqui… yo también soy grandote”. Rex sonríe un poco. "
        "El colgante está verde. Pipa está tranquila.",
        "En este bosque, el viento pasa entre las hojas y los árboles hacen un sonido parecido a una "
        "canción. De pronto, detrás de un árbol, aparece Rex, un tiranosaurio enorme. Rex no ruge: "
        "mira el piso y se esconde un poco, porque es tímido. Pero es tan grande que Pipa se asusta. "
        "El colgante está naranja. Pipa tiene miedo. Bubu camina despacio hasta Rex y le dice: "
        "“Tranqui… yo también soy grandote”. Rex sonríe un poco. El colgante está verde. "
        "Pipa está tranquila."),
    "pendant": [{"color": "naranja", "at": 0.38}, {"color": "verde", "at": 0.92}],
    "characters": [ch("pipa", 0.2, 0.66, 0.4), ch("fido", 0.32, 0.66, 0.34)],
    "tappables": [
        tap("rex", "art/rex.svg", 0.7, 0.45, 420, "wiggle", "rugido_suave", "Rex es tímido"),
        tap("bubu", "cast:bubu", 0.47, 0.55, 260, "hop", "abrazo", "Bubu da abrazos"),
        tap("arbol", "art/arbol_canta.svg", 0.12, 0.35, 240, "wiggle", "campanitas", "El árbol suena"),
        huella("huella_2", 0.36, 0.2),
    ],
    "next": "b4",
}

pages["b4"] = {
    "background": "art/bg_bosque.svg",
    "text": T(
        "Rex sabe dónde está el nido. Rex quiere ir con ellos. Pueden ir con Rex o ir solos.",
        "Rex dice con voz bajita: “Yo sé dónde está el nido de mamá Ptera”. Fido mueve la cola. "
        "Pipa piensa. Pueden ir con Rex, o pueden ir solos y después presentarle a Rex a mamá Ptera.",
        "Rex habla con una voz muy bajita: “Yo sé dónde está el nido de mamá Ptera. Está en la "
        "montaña”. Fido mueve la cola. Bubu le da una palmadita a Rex. Pipa piensa con calma. Los "
        "otros dinosaurios no conocen bien a Rex y a veces se asustan cuando lo ven. Pueden ir todos "
        "juntos con Rex, o pueden ir solos primero y después presentarle a Rex a mamá Ptera."),
    "characters": EQUIPO,
    "tappables": [
        tap("rex", "art/rex.svg", 0.72, 0.45, 400, "hop", "rugido_suave", "Rex saluda"),
        tap("montana", "art/montana.svg", 0.45, 0.22, 240, "float", "viento", "La montaña"),
        tap("mariposa", "art/mariposa.svg", 0.52, 0.5, 130, "float", "aleteo", "Una mariposa azul"),
        tap("huevo", "art/huevo.svg", 0.38, 0.6, 140, "grow", "brillo", "El huevo brilla"),
    ],
    "decision": {"options": [
        {"text": "Ir con Rex", "image": "art/op_rex.svg", "to": "p5_rex"},
        {"text": "Ir solos y después presentarle a Rex", "image": "art/op_solos.svg", "to": "p5_amigo"},
    ]},
}


def p5(bg, text, characters, extra_taps):
    return {
        "background": bg, "text": text, "pendant": [{"color": "amarillo", "at": 0.85}],
        "characters": characters,
        "tappables": extra_taps + [huella("huella_3", 0.88, 0.2)],
    }


pages["p5_pasos"] = p5("art/bg_cascada.svg", T(
    "Suben despacio, una piedra por vez. Bubu lleva el huevo. Llegan arriba. "
    "El colgante está amarillo. Pipa está contenta.",
    "Pipa dice: “Vamos paso a paso”. Suben una piedra, y después otra, y después otra. Bubu lleva "
    "el huevo con mucho cuidado. Al final llegan arriba de la cascada. El colgante está amarillo. "
    "Pipa está contenta.",
    "Pipa mira la escalera de piedras y dice: “Vamos paso a paso”. Suben una piedra, y después "
    "otra, y después otra. Cuando se cansan, se sientan un ratito y respiran. Bubu lleva el huevo "
    "en sus brazos con mucho cuidado. Al final llegan arriba de la cascada. El colgante está "
    "amarillo. Pipa está contenta."),
    [ch("pipa", 0.3, 0.6, 0.38), ch("bubu", 0.16, 0.74, 0.38)],
    [tap("piedra", "art/piedra.svg", 0.45, 0.7, 160, "bounce", "paso", "Un paso"),
     tap("huevo", "art/huevo.svg", 0.58, 0.45, 150, "grow", "brillo", "El huevo brilla"),
     tap("fido", "cast:fido", 0.72, 0.62, 280, "hop", "guau", "¡Guau! Fido")])
pages["p5_pasos"]["next"] = "p6_pasos"
pages["p5_pasos"]["secret_next"] = "s6"

pages["p5_brachi"] = p5("art/bg_cascada.svg", T(
    "Pipa le pide ayuda a Brachi. Brachi baja su cuello largo. Todos suben. "
    "El colgante está amarillo. Pipa está contenta.",
    "Pipa se acerca a Brachi y dice: “¿Nos ayudás a subir, por favor?”. Brachi dice que sí y baja "
    "su cuello largo hasta el piso. Todos suben con cuidado. El colgante está amarillo. "
    "Pipa está contenta.",
    "Pipa respira hondo, se acerca a Brachi y le dice: “Hola, Brachi. Queremos llevar este huevo "
    "al nido de arriba. ¿Nos ayudás a subir, por favor?”. Brachi dice que sí. Baja su cuello largo "
    "hasta el piso y espera. Pipa, Fido y Bubu suben despacio por el cuello y Brachi los levanta "
    "hasta arriba de la cascada. El colgante está amarillo. Pipa está contenta."),
    [ch("pipa", 0.22, 0.66, 0.4), ch("fido", 0.33, 0.66, 0.34)],
    [tap("brachi", "art/brachi.svg", 0.62, 0.42, 380, "float", "hojas", "Gracias, Brachi"),
     tap("huevo", "art/huevo.svg", 0.42, 0.5, 150, "grow", "brillo", "El huevo brilla"),
     tap("bubu", "cast:bubu", 0.1, 0.62, 200, "hop", "abrazo", "Bubu sube")])
pages["p5_brachi"]["next"] = "p6_brachi"
pages["p5_brachi"]["secret_next"] = "s6"

pages["p5_rex"] = p5("art/bg_montana.svg", T(
    "Van con Rex. Los dinosaurios se asustan. Rex saluda despacio. "
    "El colgante está amarillo. Pipa está contenta.",
    "Todos caminan con Rex hasta la montaña. Los dinosaurios ven a Rex y se asustan. Rex se agacha "
    "y saluda despacio. Pipa dice: “Rex es nuestro amigo”. El colgante está amarillo. "
    "Pipa está contenta.",
    "Todos caminan con Rex hasta la montaña. Rex da pasos cortos para no hacer ruido. Cuando los "
    "otros dinosaurios ven a Rex, se esconden detrás de las piedras. Rex se agacha, baja la cabeza "
    "y saluda despacio. Pipa explica: “Rex es nuestro amigo. Nos mostró el camino”. Los "
    "dinosaurios salen de a poco. El colgante está amarillo. Pipa está contenta."),
    [ch("pipa", 0.22, 0.66, 0.4), ch("bubu", 0.09, 0.66, 0.38)],
    [tap("rex", "art/rex.svg", 0.62, 0.45, 400, "wiggle", "rugido_suave", "Rex saluda"),
     tap("piedra", "art/piedra.svg", 0.82, 0.6, 150, "bounce", "paso", "Una piedra"),
     tap("fido", "cast:fido", 0.36, 0.62, 280, "hop", "guau", "¡Guau! Fido")])
pages["p5_rex"]["next"] = "p6_rex"
pages["p5_rex"]["secret_next"] = "s6"

pages["p5_amigo"] = p5("art/bg_montana.svg", T(
    "Van solos a la montaña. Rex los espera abajo. Encuentran el nido. "
    "El colgante está amarillo. Pipa está contenta.",
    "Pipa, Fido y Bubu suben solos a la montaña. Rex los espera abajo, al lado de un árbol. "
    "Fido huele y encuentra el nido de mamá Ptera. El colgante está amarillo. Pipa está contenta.",
    "Pipa, Fido y Bubu suben solos a la montaña. Rex se queda abajo, al lado de un árbol, y dice: "
    "“Los espero acá”. Fido huele el viento, sigue el olor y encuentra el nido de mamá Ptera "
    "entre unas rocas. Pipa piensa que después va a presentar a Rex. El colgante está amarillo. "
    "Pipa está contenta."),
    [ch("pipa", 0.24, 0.66, 0.4), ch("bubu", 0.11, 0.66, 0.38)],
    [tap("nido", "art/nido.svg", 0.62, 0.5, 260, "grow", "hojas", "El nido"),
     tap("fido", "cast:fido", 0.4, 0.6, 280, "hop", "olfato", "Fido huele"),
     tap("rex_lejos", "art/rex.svg", 0.84, 0.6, 180, "wiggle", "rugido_suave", "Rex espera")])
pages["p5_amigo"]["next"] = "p6_amigo"
pages["p5_amigo"]["secret_next"] = "s6"


def p6(ending_id, title, bg, text, characters, taps):
    return {"background": bg, "text": text, "characters": characters, "tappables": taps,
            "ending": {"id": ending_id, "title": title}, "next": "p7"}


TAPS_NIDO = [
    tap("mama", "art/mama_ptera.svg", 0.62, 0.38, 360, "float", "aleteo", "Mamá Ptera"),
    tap("bebe", "art/ptera_bebe.svg", 0.5, 0.6, 170, "hop", "pio", "¡Pío! La ptera bebé"),
    tap("nido", "art/nido.svg", 0.78, 0.6, 200, "grow", "hojas", "El nido"),
]

pages["p6_pasos"] = p6("paso_a_paso", "Paso a paso se llega lejos", "art/bg_nido.svg", T(
    "Mamá Ptera los espera. Pipa le da el huevo. ¡Crac! Sale una ptera bebé. "
    "Paso a paso se llega lejos.",
    "Arriba de la cascada está mamá Ptera. Pipa le da el huevo. ¡Crac! El huevo se abre y sale una "
    "ptera bebé. Mamá Ptera dice: “Gracias por subir hasta acá”. Pipa sabe algo nuevo: paso a "
    "paso se llega lejos.",
    "Arriba de la cascada, mamá Ptera mira para todos lados. Está buscando su huevo. Pipa se acerca "
    "y se lo da. ¡Crac! El huevo se abre y sale una ptera bebé que mueve las alas. Mamá Ptera dice: "
    "“Gracias por subir hasta acá, piedra por piedra”. Pipa mira la escalera larga y piensa en "
    "todo lo que subieron. Paso a paso se llega lejos."),
    EQUIPO, TAPS_NIDO)

pages["p6_brachi"] = p6("pedir_ayuda", "Pedir ayuda es de valientes", "art/bg_nido.svg", T(
    "Brachi los deja al lado del nido. Pipa le da el huevo a mamá Ptera. ¡Crac! Sale una ptera "
    "bebé. Pedir ayuda es de valientes.",
    "Brachi los deja al lado del nido. Mamá Ptera recibe el huevo. ¡Crac! Sale una ptera bebé. "
    "Mamá Ptera dice: “Gracias”. Pipa le dice a Brachi: “Gracias por ayudarnos”. "
    "Pedir ayuda es de valientes.",
    "Brachi baja la cabeza con cuidado y los deja justo al lado del nido. Mamá Ptera recibe el huevo "
    "con sus alas. ¡Crac! El huevo se abre y sale una ptera bebé. Mamá Ptera dice: “Gracias”. "
    "Pipa mira a Brachi y le dice: “Gracias por ayudarnos. Solos no podíamos subir”. "
    "Brachi está contento. Pedir ayuda es de valientes."),
    EQUIPO, TAPS_NIDO[:2] + [tap("brachi", "art/brachi.svg", 0.85, 0.42, 300, "float", "hojas", "Brachi")])

pages["p6_rex"] = p6("rex_gigante_bueno", "Rex, el gigante bueno", "art/bg_nido.svg", T(
    "Rex lleva el huevo con cuidado. Mamá Ptera dice: “Gracias, Rex”. ¡Crac! Sale una ptera bebé. "
    "Rex es un gigante bueno.",
    "Rex lleva el huevo con mucho cuidado hasta el nido. Mamá Ptera se sorprende. Después dice: "
    "“Gracias, Rex”. ¡Crac! Sale una ptera bebé. Ahora todos saben que Rex es un gigante bueno.",
    "Rex lleva el huevo entre sus patas cortas, con mucho cuidado, hasta el nido. Mamá Ptera se "
    "sorprende al ver a un tiranosaurio tan grande. Rex le da el huevo despacio. Mamá Ptera dice: "
    "“Gracias, Rex”. ¡Crac! El huevo se abre y sale una ptera bebé. Los otros dinosaurios aplauden. "
    "Ahora todos saben que Rex es un gigante bueno."),
    [ch("pipa", 0.22, 0.66, 0.4), ch("fido", 0.34, 0.66, 0.34)],
    TAPS_NIDO[:2] + [tap("rex", "art/rex.svg", 0.85, 0.48, 360, "hop", "rugido_suave", "Rex, el gigante bueno")])

pages["p6_amigo"] = p6("amigo_nuevo", "Hacer un amigo nuevo", "art/bg_nido.svg", T(
    "Pipa le da el huevo a mamá Ptera. ¡Crac! Sale una ptera bebé. Después Pipa le presenta a Rex. "
    "Ahora son amigos.",
    "Pipa le da el huevo a mamá Ptera. ¡Crac! Sale una ptera bebé. Después Pipa dice: “Te quiero "
    "presentar a Rex. Él nos ayudó”. Mamá Ptera saluda a Rex. Ahora tienen un amigo nuevo.",
    "Pipa le da el huevo a mamá Ptera. ¡Crac! El huevo se abre y sale una ptera bebé. Después, "
    "Pipa le dice a mamá Ptera: “Te quiero presentar a alguien. Se llama Rex. Es grande, pero es "
    "tímido, y nos mostró el camino”. Rex se acerca despacio. Mamá Ptera lo mira, sonríe y lo "
    "saluda. Ahora Rex tiene un amigo nuevo, y mamá Ptera también."),
    EQUIPO, TAPS_NIDO[:2] + [tap("rex", "art/rex.svg", 0.85, 0.5, 340, "wiggle", "rugido_suave", "Rex saluda")])

pages["s6"] = {
    "background": "art/bg_cielo.svg",
    "text": T(
        "Las tres huellas doradas brillan. Sale la ptera bebé. Pipa le enseña a volar. "
        "¡La ptera bebé vuela! El colgante está amarillo. Pipa está contenta.",
        "Las tres huellas doradas brillan juntas. ¡Crac! Sale la ptera bebé. Pipa abre sus alas y "
        "dice: “Mirá, así”. La ptera bebé mueve las alas, una vez, dos veces… ¡y vuela! "
        "El colgante está amarillo. Pipa está contenta.",
        "Las tres huellas doradas que encontraron en el camino brillan juntas. ¡Crac! El huevo se "
        "abre y sale la ptera bebé. Pipa también es un pájaro, así que abre sus alas y dice: "
        "“Mirá, así: arriba y abajo, despacio”. La ptera bebé mueve las alas una vez, dos veces, "
        "tres veces… ¡y vuela! Mamá Ptera vuela a su lado. El colgante está amarillo. "
        "Pipa está contenta."),
    "pendant": [{"color": "amarillo", "at": 0.9}],
    "characters": [ch("pipa", 0.25, 0.6, 0.42, "contento"), ch("bubu", 0.1, 0.66, 0.38)],
    "tappables": [
        tap("bebe", "art/ptera_bebe.svg", 0.55, 0.35, 220, "float", "aleteo", "¡Vuela, ptera bebé!"),
        tap("mama", "art/mama_ptera.svg", 0.78, 0.28, 300, "float", "aleteo", "Mamá Ptera"),
        tap("nube", "art/nube.svg", 0.4, 0.15, 220, "float", "viento", "Una nube"),
        tap("fido", "cast:fido", 0.6, 0.6, 280, "hop", "guau", "¡Guau! Fido"),
    ],
    "ending": {"id": "secreto_volar", "title": "La ptera bebé aprende a volar", "secret": True},
    "next": "p7",
}

pages["p7"] = {
    "background": "art/bg_plaza.svg",
    "text": T(
        "Vuelven a la plaza. Pipa planta una semilla de luz en el árbol. El colgante está verde. "
        "Pipa está tranquila. Pipa dice: “Lo distinto no da miedo cuando lo conocés”.",
        "Pipa, Fido y Bubu vuelven a la plaza por la puerta verde. Pipa planta una semilla de luz en "
        "el Árbol de las Puertas. El colgante está verde. Pipa está tranquila. Pipa dice: "
        "“Lo distinto no da miedo cuando lo conocés”.",
        "Pipa, Fido y Bubu vuelven a la plaza por la puerta verde. La puerta se cierra despacio. "
        "Pipa saca una semilla de luz de su bolsillo y la planta en el Árbol de las Puertas. "
        "La semilla brilla entre las hojas. El colgante está verde. Pipa está tranquila. "
        "Pipa dice: “Lo distinto no da miedo cuando lo conocés”."),
    "pendant": [{"color": "verde", "at": 0.6}],
    "characters": EQUIPO,
    "tappables": [
        tap("semilla", "art/semilla.svg", 0.6, 0.3, 160, "grow", "campanita", "Una semilla de luz"),
        tap("puerta", "art/puerta_verde.svg", 0.78, 0.42, 240, "wiggle", "puerta", "La puerta verde"),
        tap("arbol", "art/arbol_plaza.svg", 0.5, 0.42, 260, "wiggle", "hojas", "El Árbol de las Puertas"),
    ],
    "closing": True,
}

STORY = {
    "schema": 1,
    "id": "dino",
    "title": "El huevo que brillaba",
    "cast": ["pipa", "fido", "bubu"],
    "message": "Lo distinto no da miedo cuando lo conocés.",
    "start": "p1",
    "door_color": "#7FC28E",
    "secret": {"requires": ["huella_1", "huella_2", "huella_3"], "page": "s6"},
    "pages": pages,
}

if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(STORY, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"escrito {OUT}")
