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
== Software Bill of Materials (SBOM)
Wie schon erwähnt (vgl. @Motivation)  basieren übliche Scanner wie npm audit oder @OWASP auf den sogenannten @SBOM, um diese zu verstehen muss man auch diese verstehen.
Ein @SBOM ist eine maschinenlesbare Liste aller Softwarekomponenten eines Produkts @ntia2021sbomoverview. Die NTIA spezifiziert Mindestinhalte wie Komponentenname, Version und Identifikatoren @ntia2021minimumelements. Das verbreitetste SBOM-Format ist SPDX, standardisiert als ISO/IEC 5962:2021 @isoiec5962spdx2021.

SBOMs dokumentieren Dependencies auf Package-Ebene. Eine Bibliothek wird als Ganzes erfasst, unabhängig davon, welche ihrer Funktionen tatsächlich genutzt werden. Diese Package-Level-Granularität führt zu den beschriebenen Limitierungen im Vulnerability Management (siehe Motivation) @nsa2023sbommanagement.
== Dependency Management
== Bloated Dependencies
/* 
== Software Composition Analysis (SCA) und SBOM
== Funktionsweise klassischer Scanner (z. B. npm audit)
== Node.js/TypeScript: Modul-, Build- und Deployment-Grundlagen
== Call-Graph-Grundlagen für JavaScript/TypeScript
== Fehlerbilder und Begriffe (FP/FN, Soundness/Precision) */

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
