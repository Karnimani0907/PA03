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
  signature_place: "K",
  matriculation_number: "",
  course: "TIN",
  submission_date: "05.01.2026",
  processing_period: "20.10.2025 - 05.01.2026",
  supervisor_company: "",
  supervisor_university: "---",
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

Die Unfähigkeit zu erkennen, ob Code tatsächlich zur Laufzeit ausgeführt wird, führt zu zwei kritischen Problemen. Erstens akkumulieren Projekte obsolete Dependencies, die erhebliche Wartungskosten verursachen @2022Chuang. Empirische Analysen zeigen, dass 75,1% aller Maven-Dependencies als "bloated" klassifiziert werden können, wobei 57% der transitiven Dependencies vollständig ungenutzt sind @sotovalero2021maven. Im JavaScript-Ökosystem ist die Situation vergleichbar: 50,7% der Dependencies in CommonJS-Packages sind bloated @Liu2025. /* Die Entfernung einer einzigen direkten bloated Dependency kann kaskadenartig zur Elimination von bis zu 679 indirekten Dependencies führen @Liu2025. */

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
== Dependency Management <Dependency_Management>

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

=== Definition und Abgrenzung

Als *bloated* werden Dependencies bezeichnet, die im Deployment einer
Anwendung installiert sind, aber zur Laufzeit nie verwendet werden
@SotoValero2021MavenBloat. Bestehende Analyse-Tools fokussieren primär auf
veraltete (_outdated_) und verwundbare (_vulnerable_) Dependencies. Eine
Dependency kann jedoch veraltet sein, ohne ungenutzt zu sein, und eine
verwundbare Dependency muss nicht zwingend bloated sein. Diese Arbeit ergänzt
die bestehenden Dimensionen um den Aspekt der genutzten Codebasis.

=== Kategorisierung

Bloated Dependencies lassen sich nach ihrer Herkunft in zwei für npm
relevante Typen einteilen. *Direkte* bloated Dependencies sind explizit im
Manifest deklariert, werden jedoch nie vom Anwendungscode aufgerufen.
*Transitive* bloated Dependencies wurden automatisch als Abhängigkeiten
anderer Packages installiert, ohne dass die Anwendung sie je verwendet
@SotoValero2021MavenBloat. Transitive bloated Dependencies sind in der Praxis
dominierend, da der Dependency-Auflösungsmechanismus sie automatisch und ohne
direktes Zutun der Entwickler in den Abhängigkeitsbaum einfügt
(vgl. @Dependency_Management). Im Maven-Ökosystem existiert zusätzlich die
Kategorie *geerbter* Dependencies aus Parent-POMs, die in npm keine
Entsprechung hat und daher in dieser Arbeit nicht weiter betrachtet wird.

=== Entstehungsmechanismen

Bloated Dependencies entstehen durch verschiedene Mechanismen. Bei *direkten*
Dependencies tritt häufig evolutionäre Akkumulation auf: Wenn Features umgebaut
oder entfernt werden, bleiben die zugehörigen Packages oft im Manifest erhalten
@2022Chuang. Bei *transitiven* Dependencies ist der Mechanismus fundamentaler:
Sie werden automatisch installiert, sobald eine direkte Dependency sie benötigt.
Entfernt man später Code, der diese direkte Dependency nutzte, muss die
Deklaration manuell aus dem Manifest entfernt werden. Geschieht dies nicht,
bleiben alle transitiven Dependencies dieser Dependency installiert, selbst
wenn keine davon mehr genutzt wird (vgl. @Dependency_Management).

Das nachträgliche Entfernen ist für Entwickler riskant. Statische Analysetools
melden zahlreiche False Positives, weil sie dynamische Sprachfeatures wie
`eval()`, `require()` mit variablen Parametern oder dynamische Imports nicht
vollständig erfassen können. Empirisch zeigt sich, dass Ansätze, die
Call-Graph-Analyse mit einer Klassifikation der Dependency-Beziehungen
kombinieren, rund ein Drittel dieser False Positives eliminieren können
@2022Chuang. Eine explorative Studie mit 23 Pull Requests deutet an, dass
erhebliche Unsicherheiten besonders bei transitiven Dependencies bestehen:
Während Entwickler 14 von 15 Vorschlägen zur Entfernung direkter bloated
Dependencies akzeptierten, nahmen sie nur 4 von 8 Vorschläge zu transitiven
Dependencies an @SotoValero2021MavenBloat.

=== Empirische Evidenz

Das Problem ist weit verbreitet. Im JavaScript-Ökosystem sind 50,6% aller
Dependencies bloated @Liu2025. Im Maven-Ökosystem fällt das Bild noch
deutlicher aus: 75,1% aller Dependencies sind bloated, wie eine Analyse von
9.639 Artefakten zeigt @SotoValero2021MavenBloat. Die Messgrößen unterscheiden
sich dabei methodisch: Maven erfasst Dependency-Beziehungen als Kanten im
Dependency-Graph (N = 723.444), npm hingegen einzelne Package-Installationen
(N = 50.488). Die Prozentwerte sind daher nur bedingt direkt vergleichbar,
zeigen aber in beiden Ökosystemen einen hohen Anteil ungenutzter Dependencies.
@Anteil-Bloated-Dependecies zeigt die Verteilung nach Typ.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, center, center),
    [*Typ*], [*Maven*], [*CommonJS/npm*],
    [Direkt (bloated)],    [2,7%],   [13,8%],
    [Transitiv (bloated)], [57,0%],  [51,3%],
    [*Gesamt bloated*],    [*75,1%*],[*50,6%*],
  ),
  caption: [Anteil bloated Dependencies nach Typ in Maven und npm-Ökosystem.
            Quellen: @SotoValero2021MavenBloat, @Liu2025.]
)<Anteil-Bloated-Dependecies>

Über beide Ökosysteme hinweg zeigt sich ein konsistentes Muster: Transitive
Dependencies machen den Großteil des Bloats aus, während direkte Dependencies
seltener betroffen sind. Im Maven-Ökosystem existiert zusätzlich die Kategorie
geerbter Dependencies aus Parent-POMs (15,4% bloated), die in npm keine
Entsprechung hat. Auf Projektebene ist die Verbreitung besonders hoch: 86,2%
aller Maven-Artefakte und 98,9% aller untersuchten CommonJS-Packages enthalten
mindestens eine bloated-transitive Dependency @SotoValero2021MavenBloat @Liu2025.

Die Hebelwirkung des Entfernens lässt sich am Package `podcast-search`
verdeutlichen @Liu2025. Das Projekt hat zwei direkte Dependencies, von denen
`npm` zur Laufzeit nie verwendet wird. Alle 679 transitiven Dependencies
stammen ausschließlich von dieser einen ungenutzten Dependency. Das Entfernen
einer einzigen Zeile in der `package.json` eliminiert so 680 von insgesamt
681 installierten Dependencies, ohne Funktionsverlust.

=== Konsequenzen

Dependency Bloat hat technische, wirtschaftliche und sicherheitskritische
Folgen. Überflüssige Packages erhöhen die Binary-Größe, verlängern
Installations- und Build-Zeiten und steigern den Speicherbedarf. In
containerisierten Deployments, wo TypeScript-Anwendungen typischerweise
betrieben werden, wird dies besonders sichtbar: Analysen offizieller
Docker-Images zeigen, dass alle untersuchten Images verwundbare npm-Packages
enthalten, im Durchschnitt 16,6 Security-Vulnerabilities pro Container
@8667984.

Dependency-Scanner erkennen diese Vulnerabilities unabhängig von der
tatsächlichen Erreichbarkeit des betroffenen Codes. Sicherheitskritisch ist
dabei vor allem die vergrößerte Angriffsfläche: Jede zusätzlich installierte
Bibliothek kann bekannte Schwachstellen (CVEs) einbringen. SBOM-basierte
Scanner erfassen eine Bibliothek als Ganzes, ohne zu berücksichtigen, welche
ihrer Funktionen tatsächlich aufgerufen werden. Ponta et al. zeigen, dass
erst eine code-zentrische, nutzungsbasierte Analyse feststellen kann, ob
vulnerable Funktionen im konkreten Anwendungskontext tatsächlich erreichbar
sind @ponta2018beyond. Eine bloated Dependency mit einer bekannten Schwachstelle
löst daher eine Warnung aus, obwohl kein Codepfad die Schwachstelle je
erreichen könnte. Die Reduktion von Dependency Bloat ist damit nicht nur eine
Maintenance-Maßnahme, sondern eine Voraussetzung für präziseres
Vulnerability-Management.
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
== L1: Loaded-Heuristiken 
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

/* = Diskussion und Validität
== Limitationen (JS/TS-Dynamik, Bundling, Reflection, DI)
== Threats to Validity (intern/extern/konstrukt) */

= Fazit und Ausblick
== Fazit (Rückbezug auf Forschungsfragen)
== Ausblick (z. B. L2, bessere CVE->Symbol-Zuordnung, CI/CD-Integration)
