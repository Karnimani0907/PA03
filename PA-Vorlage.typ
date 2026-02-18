#import "template.typ": caption_with_source, project

#show: project.with(
  lang: "de",
  is_digital: true,
  confidentiality_clause: true,
  ai_clause: true,

  title_long: "Erkennung ungenutzter Bibliotheken in Deployments zur risikobasierten 
Priorisierung von Sicherheitsbefunden",
  title_short: "Datenaugmentation",
  thesis_type: "Projektarbeit 1 (T4_1000)",
  firstname: "",
  lastname: "",
  signature_place: "Karlsruhe",
  matriculation_number: "",
  course: "TINF25B6",
  submission_date: "05.01.2026",
  processing_period: "20.10.2025 - 05.01.2026",
  supervisor_company: "",
  supervisor_university: "Prof. Nuo Li",
  abstract: (
    (
      "en",
      "English",
      [ Abstract1
      ],
    ),
    (
      "de",
      "Deutsch",
      [
        Abstract2
      ],
    ),
  ),

  library_paths: "Erkennung-ungenutzter-Bibliotheken-in-Deployments/PA03.bib",

  acronyms: (
    (key: "NN", short: "NN", long: "Neural Network"),
    (key: "SG", short: "SG", long: "Singular"),
    (key: "OWASP", short: "OWASP", long: "Open Worldwide Application Security Project"),
    (key: "SBOM", short: "SBOM", long: "Software Bill of Materials"),
  ),
)

= Einleitung
== Motivation <Motivation>

Dependency Scanner wie npm audit und OWASP Dependency-Check sind aus der modernen Softwareentwicklung nicht mehr wegzudenken @ponta2020detection. Diese Tools basieren primär auf Software Bill of Materials (SBOM) und operieren ausschließlich auf Package-Ebene @ponta2018beyond. Aktuelle Forschung zeigt jedoch fundamentale Limitierungen dieser Ansätze, die zu erheblichen praktischen Problemen führen.

Die Unfähigkeit zu erkennen, ob Code tatsächlich zur Laufzeit ausgeführt wird, führt zu zwei kritischen Problemen. Erstens akkumulieren Projekte obsolete Dependencies, die erhebliche Wartungskosten verursachen @2022Chuang. Empirische Analysen zeigen, dass 75,1% aller Maven-Dependencies als "bloated" klassifiziert werden können, wobei 57% der transitiven Dependencies vollständig ungenutzt sind @sotovalero2021maven. Im JavaScript-Ökosystem ist die Situation vergleichbar: 50,7% der Dependencies in CommonJS-Packages sind bloated @Liu2025. Die Entfernung einer einzigen direkten bloated Dependency kann kaskadenartig zur Elimination von bis zu 679 indirekten Dependencies führen @Liu2025.

Diese obsoleten Dependencies entstehen durch verschiedene Mechanismen. Transitive Abhängigkeiten werden automatisch in die Dependency-Hierarchie eingefügt, ohne dass Entwickler sich deren Präsenz bewusst sind @2022Chuang. Darüber hinaus werden Dependencies während der Entwicklung hinzugefügt und bei Code-Refactorings nicht entfernt @Liu2025. Das Entfernen ist jedoch oft schwierig, weil Entwickler nicht mit ausreichender Sicherheit beurteilen können, ob eine Dependency wirklich entbehrlich ist @2022Chuang. Die resultierenden Kosten manifestieren sich in erhöhten Binary-Größen, verlängerten Build-Zeiten, erhöhtem Speicherverbrauch und gesteigertem Sicherheitsrisiko durch eine vergrößerte Angriffsfläche @sotovalero2021maven @soto2023coverage. In containerisierten Deployments wird die Problematik besonders sichtbar, da Images teils eine große Menge veralteter oder verwundbarer JavaScript-Pakete enthalten @8667984.

Zweitens führt die Fokussierung auf Package-Level-Analysen zu einer hohen Rate an False-Positive-Warnungen. Die zentrale Herausforderung liegt in der fehlenden Granularität: SBOM-basierte Tools können nicht zwischen deployed und nicht-deployed Code differenzieren @2022Pashchenko, noch können sie feststellen, ob vulnerable Funktionen tatsächlich vom Anwendungscode aufgerufen werden. /* Während Call-Graph-basierte Forschungsansätze zeigen, dass eine feinere Analyseebene die False-Positive-Rate um 81% reduzieren kann @2021Nielsen */



== Zielsetzung der Arbeit
= Methodik

/* = Begriffe, Modell und Anforderungen
== Begriffsdefinitionen
== Usage-Evidence-Schema (L0–L2)
== Anforderungen an den PoC
 */
= Grundlagen
== Dependency Management

Modern entwickelte JavaScript- und TypeScript-Anwendungen stützen sich 
in hohem Maße auf externe Bibliotheken. Um diese zu verwalten, verwenden 
Entwickler den Package Manager npm (Node Package Manager). Ein Package 
Manager übernimmt drei zentrale Aufgaben: Er liest Manifest-Dateien wie 
`package.json`, lädt die deklarierten Bibliotheken aus dem zentralen 
npm-Registry herunter und installiert sie lokal im Projekt 
@Mens2017SevenEcosystems. Dabei löst er nicht nur die explizit 
angeforderten Dependencies auf, sondern rekursiv auch alle deren 
Abhängigkeiten.

Dependencies lassen sich in zwei Kategorien einteilen. Direkte 
Dependencies werden explizit im Projekt-Manifest deklariert, 
beispielsweise `express` in der `package.json`. Der Anwendungscode 
importiert und nutzt diese Bibliotheken direkt. Transitive Dependencies 
hingegen sind Abhängigkeiten dieser direkten Dependencies 
@SotoValero2021MavenBloat. Wenn ein Node.js-Projekt `express@4.18.2` 
deklariert, installiert npm automatisch auch die 31 Dependencies von 
express, darunter `body-parser`, `cookie` und `debug`. Alle installierten 
Packages werden im `node_modules`-Verzeichnis abgelegt.

Dieser Mechanismus führt zum Phänomen der Dependency Amplification: Eine 
einzelne direkte Dependency zieht eine Kaskade weiterer Dependencies nach 
sich @Kikas2022DemystifyingNPM. Ein Projekt mit 50 direkten 
Dependencies kann so auf mehrere hundert installierte Packages anwachsen 
@Kikas2022DemystifyingNPM.

Bei TypeScript-Projekten wird diese Amplification zusätzlich verstärkt: 
Für jede JavaScript-Bibliothek ohne eingebaute Typdefinitionen muss ein 
separates Type-Definition-Package aus dem `@types/*`-Namespace installiert 
werden. Nutzt ein Projekt beispielsweise `express`, muss zusätzlich 
`@types/express` installiert werden, um TypeScript-Typen zu erhalten. 
npm unterscheidet zwischen `dependencies` (zur Laufzeit benötigt) und 
`devDependencies` (nur für Build/Test). Type-Definition-Packages werden 
als `devDependencies` deklariert, da sie ausschließlich zur Compile-Zeit 
erforderlich sind.

Diese Dependency Amplification führt zu einem fundamentalen Problem: Bei 
hunderten automatisch installierten Packages verlieren Entwickler den 
Überblick, welche Dependencies tatsächlich vom Anwendungscode genutzt 
werden. Die in @Motivation beschriebenen Konsequenzen (akkumulierte 
bloated dependencies, erhöhte Sicherheitsrisiken und False-Positive-Warnungen 
in Vulnerability Scannern) sind direkte Folgen dieses Mechanismus.

== Software Bill of Materials (SBOM)

Wie in der Motivation beschrieben, basieren Scanner wie npm audit oder OWASP Dependency-Check auf Software Bills of Materials (SBOMs).
Ein SBOM ist eine maschinenlesbare Liste aller Softwarekomponenten eines Produkts @ntia2021sbomoverview. 
Im Gegensatz zu Manifest-Dateien wie `package.json`, die nur direkte Dependencies auflisten, erfasst ein SBOM auch alle transitiven Dependencies mit exakten Versionen.
Die NTIA spezifiziert Mindestinhalte @ntia2021minimumelements, das verbreitetste Format ist SPDX (ISO/IEC 5962:2021) @isoiec5962spdx2021.

SBOMs werden typischerweise durch spezialisierte Tools wie CycloneDX, Syft oder das Microsoft SBOM Tool aus den Dependency-Informationen eines Projekts generiert. Jeder SBOM-Eintrag dokumentiert eine Softwarekomponente mit folgenden Informationen: Paketname (z.B. `express`), Version (`4.18.2`), eindeutiger Identifikator als Package-URL (`pkg:npm/express@4.18.2`), Lizenzinformation (`MIT`), Lieferant sowie die Liste der direkten Dependencies dieser Komponente. Für ein typisches Node.js-Projekt mit 50 direkten Dependencies kann ein SBOM mehrere hundert Einträge umfassen, da auch alle transitiven Dependencies erfasst werden müssen.

Die fundamentale Einschränkung von SBOMs liegt im Detailgrad der Dokumentation: Dependencies werden auf Package-Ebene dokumentiert. Eine Bibliothek wird als Ganzes erfasst, unabhängig davon, welche ihrer Funktionen tatsächlich genutzt werden. Bindet ein Projekt die Bibliothek `lodash` ein und nutzt nur die Funktion `_.debounce()`, erfasst das SBOM lediglich `lodash@4.17.21` als Dependency, ohne zu dokumentieren, welche der über 300 verfügbaren Funktionen von lodash im Code aufgerufen werden.
== Bloated Dependencies
/* 
== Software Composition Analysis (SCA) und SBOM
== Funktionsweise klassischer Scanner (z. B. npm audit)
== Node.js/TypeScript: Modul-, Build- und Deployment-Grundlagen
== Call-Graph-Grundlagen für JavaScript/TypeScript
== Fehlerbilder und Begriffe (FP/FN, Soundness/Precision) */

== Vulnerability Datenbanken

= Der aktuelle Forschungsstand
== Überblick und Einordnung (statisch vs. dynamisch; Evidence-Level)
== Dynamische Ansätze (Tracing, Coverage, Runtime-Instrumentierung)
== Statische Ansätze (Reachability, Call-Graphs, modulare Analysen)
== Vergleich der Ansätze anhand Kriterien (Genauigkeit, Aufwand, K8s-Fit)
== Ableitungen für den PoC in TypeScript/Node/Kubernetes

= Methodenauswahl und PoC-Designentscheidung
== Bewertungsmatrix und Entscheidungsprozess
== Gewählte Methode: L2-Reachability via Call-Graph
== Zielartefakte und Schnittstellen (UsageFactor/Risk-Scoring)

= Konzept des Proof of Concept
== Gesamtpipeline und Architektur
== L0: Präsenzermittlung (Dependency-Tree/SBOM)
== L1: Loaded-Heuristiken (optional, falls umgesetzt)
== L2: Reachability-Analyse (Entry Points, Graph, Mapping)
== Ergebnisformat und Reporting

= Implementierung
== Tooling-Stack und Projektstruktur
== Dependency- und Code-Parsing (TS/AST)
== Call-Graph-Konstruktion und Datenstrukturen
== Mapping: Vulnerability/Package -> relevante Code-Elemente
== Beispiel-Durchlauf (Demo-Projekt)

= Evaluation
== Setup und Testkorpus
== Metriken (Laufzeit, Abdeckung, FP/FN-Stichprobe)
== Ergebnisse
== Vergleich zur Baseline (z. B. npm audit)
== Interpretation

= Diskussion und Validität
== Limitationen (JS/TS-Dynamik, Bundling, Reflection, DI)
== Threats to Validity (intern/extern/konstrukt)

= Fazit und Ausblick
== Fazit (Rückbezug auf Forschungsfragen)
== Ausblick (z. B. L3, bessere CVE->Symbol-Zuordnung, CI/CD-Integration)
