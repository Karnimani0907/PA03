#let __cc_messages = (
  title: (
    "de": "Erklärung zur Nutzung Künstlicher Intelligenz",
    "en": "Clause of AI Usage",
  ),
  subtitle: (
    "de": "",
    "en": "",
  ),
  clause: (
    "de": "Für die folgende Arbeit wurde die Unterstützung Künstlicher Intelligenz genutzt.
Gemini 2.5 Flash und Gemini 2.5 Pro wurden genutzt, um bei der Literatur Recherche und Fachterminologie Suche zu unterstützen und Rechtschreibung, Grammatik und Ausdruck zu verbessern.
Obwohl diese Hilfsmittel meine Fähigkeiten erweitert und zu meinen Erkenntnissen beigetragen haben, ist es wichtig darauf hinzuweisen das sie inhärente Einschränkungen aufweisen. Ich habe mich bemüht jegliche Unterstützung Künstlicher Intelligenz transparent und verantwortungsvoll zu nutzen.

Diese Erklärung wurde von mir übersetzt, jedoch automatisch von AI Usage Cards generiert. https://ai-cards.org",


    "en": "In the conduct of this research project, we used specific artificial intelligence tools and algorithms Gemini 2.5 Flash, Gemini 2.5 Pro to assist with literature search, spelling, grammar, phrasing. While these tools have augmented our capabilities and contributed to our findings, it's pertinent to note that they have inherent limitations. We have made every effort to use AI in a transparent and responsible manner. Any conclusions drawn are a result of combined human and machine insights.

  This is an automatic report generated with AI Usage Cards. https://ai-cards.org",
  ),
)

#let confidentialityClauseWith(
  lang: "de",
) = [
  #let __cc(name) = __cc_messages.at(name).at(lang)

  #heading(outlined: false, numbering: none, __cc("title"))

  #__cc("subtitle")


  #__cc("clause")
]

#confidentialityClauseWith(lang: "de")
