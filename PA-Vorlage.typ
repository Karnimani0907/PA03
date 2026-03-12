#import "template.typ": caption_with_source, project



#show: project.with(
  lang: "de",
  is_digital: true,
  confidentiality_clause: true,
  ai_clause: true,

  title_long: "Erkennung ungenutzter Bibliotheken in Deployments zur risikobasierten 
Priorisierung von Sicherheitsbefunden",
  title_short: "a",
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
    // Security & Vulnerability
    (key: "CVE",  short: "CVE",  long: "Common Vulnerabilities and Exposures"),
    (key: "NVD",  short: "NVD",  long: "National Vulnerability Database"),
    (key: "CVSS", short: "CVSS", long: "Common Vulnerability Scoring System"),
    (key: "CWE",  short: "CWE",  long: "Common Weakness Enumeration"),
    (key: "CPE",  short: "CPE",  long: "Common Platform Enumeration"),

    // Tools & Standards
    (key: "OWASP", short: "OWASP", long: "Open Worldwide Application Security Project"),
    (key: "SBOM",  short: "SBOM",  long: "Software Bill of Materials"),
    (key: "SPDX",  short: "SPDX",  long: "Software Package Data Exchange"),
    (key: "SCA",   short: "SCA",   long: "Software Composition Analysis"),
    (key: "npm",   short: "npm",   long: "Node Package Manager"),

    // Institutions
    (key: "NIST", short: "NIST", long: "National Institute of Standards and Technology"),
    (key: "NTIA", short: "NTIA", long: "National Telecommunications and Information Administration"),

    // Technical
    (key: "AST", short: "AST", long: "Abstract Syntax Tree"),
    (key: "TS",  short: "TS",  long: "TypeScript"),
    (key: "PoC", short: "PoC", long: "Proof of Concept"),
    (key: "FP",  short: "FP",  long: "False Positive"),
    (key: "FN",  short: "FN",  long: "False Negative"),
    (key: "DI",    short: "DI",    long: "Dependency Injection"),
(key: "IoC",   short: "IoC",   long: "Inversion of Control"),
(key: "ReDoS", short: "ReDoS", long: "Regular Expression Denial of Service"),
  ),
)


= Einleitung

== Motivation <Motivation>

Dependency Scanner wie npm audit und OWASP Dependency-Check sind aus der modernen Softwareentwicklung nicht mehr wegzudenken @ponta2020detection. Diese Tools basieren primär auf Software Bill of Materials (SBOM) und operieren ausschließlich auf Package-Ebene @ponta2018beyond. Aktuelle Forschung zeigt jedoch fundamentale Limitierungen dieser Ansätze, die zu erheblichen praktischen Problemen führen.

Die Unfähigkeit zu erkennen, ob Code tatsächlich zur Laufzeit geladen wird, führt zu zwei kritischen Problemen. Erstens akkumulieren Projekte obsolete Dependencies, die erhebliche Wartungskosten verursachen @2022Chuang. Empirische Analysen zeigen, dass 75,1% aller Maven-Dependencies als "bloated" klassifiziert werden können, wobei 57% der transitiven Dependencies vollständig ungenutzt sind @sotovalero2021maven. Im JavaScript-Ökosystem ist die Situation vergleichbar: 50,6% der Dependencies in CommonJS-Packages sind bloated @Liu2025. /* Die Entfernung einer einzigen direkten bloated Dependency kann kaskadenartig zur Elimination von bis zu 679 indirekten Dependencies führen @Liu2025. */

Diese obsoleten Dependencies entstehen durch verschiedene Mechanismen. Transitive Abhängigkeiten werden automatisch in die Dependency-Hierarchie eingefügt, ohne dass Entwickler sich deren Präsenz bewusst sind @2022Chuang. Darüber hinaus werden Dependencies während der Entwicklung hinzugefügt und bei Code-Refactorings nicht entfernt @Liu2025. Das Entfernen ist jedoch oft schwierig, weil Entwickler nicht mit ausreichender Sicherheit beurteilen können, ob eine Dependency wirklich entbehrlich ist @2022Chuang. Die resultierenden Kosten manifestieren sich in erhöhten Binary-Größen, verlängerten Build-Zeiten, erhöhtem Speicherverbrauch und gesteigertem Sicherheitsrisiko durch eine vergrößerte Angriffsfläche @sotovalero2021maven @soto2023coverage. In containerisierten Deployments wird die Problematik besonders sichtbar, da Images teils eine große Menge veralteter oder verwundbarer JavaScript-Pakete enthalten @8667984.

Zweitens führt die Fokussierung auf Package-Level-Analysen zu einer hohen Rate an False-Positive-Warnungen. Die zentrale Herausforderung liegt in der fehlenden Granularität: SBOM-basierte Tools können nicht zwischen deployed und nicht-deployed Code differenzieren @2022Pashchenko, noch können sie feststellen, ob vulnerable Funktionen tatsächlich vom Anwendungscode aufgerufen werden. /* Während Call-Graph-basierte Forschungsansätze zeigen, dass eine feinere Analyseebene die False-Positive-Rate um 81% reduzieren kann @2021Nielsen */

== Problemstellung und Forschungsfragen <Problemstellung>

Dependency-Scanner wie `npm audit` melden eine Dependency als verwundbar,
sobald Paketname und Version in den betroffenen Versionsbereich eines
CVE-Eintrags fallen – unabhängig davon, ob die vulnerable Funktion im
konkreten Anwendungskontext je aufgerufen wird. Ob und in welchem Ausmaß
statische Nutzungsanalyse diese Befundqualität verbessern kann und welche
inhärenten Grenzen sie dabei aufweist, ist für TypeScript/Node.js-Projekte
empirisch nicht hinreichend untersucht.

Der übergeordnete Erkenntnisrahmen lässt sich in folgender Leitfrage
zusammenfassen:

#quote(block: true)[
  Inwiefern verbessert statische Nutzungsanalyse die Aussagekraft
  metadatenbasierter Vulnerability-Scanner für
  TypeScript/Node.js-Deployments, und unter welchen Bedingungen stößt
  dieser Ansatz an seine inhärenten Grenzen?
]

Diese Leitfrage konkretisiert sich in zwei zentralen Forschungsfragen:

*FF1a (FP-Reduktion):* Inwiefern reduziert statische Import- und
Erreichbarkeitsanalyse die Rate der False-Positive-Befunde
metadatenbasierter Vulnerability-Scanner in TypeScript/Node.js-Projekten
gegenüber reiner Präsenzanalyse?

*FF1b (Priorisierung):* Inwiefern ermöglicht ein aus Import- und
Erreichbarkeitsevidenz abgeleiteter Konfidenz-Score eine risikobasierte
Priorisierung der verbleibenden Vulnerability-Befunde?

FF1a und FF1b werden durch drei Leitfragen strukturiert:

*LF1 (Identifikation):* Mit welcher Genauigkeit und unter welchen
Voraussetzungen lassen sich bloated Dependencies in
TypeScript/Node.js-Deployments durch statische Import- und
Erreichbarkeitsanalyse identifizieren, gemessen an einem manuell
validierten Ground-Truth-Korpus?

*LF2 (Messung):* In welchem Ausmaß sinkt die False-Positive-Rate
metadatenbasierter Scanner, wenn Befunde um statische Import-Evidenz
und Erreichbarkeitsevidenz angereichert werden?

*LF3 (Grenzen):* Unter welchen Bedingungen verliert die statische
Import- und Erreichbarkeitsanalyse ihre Aussagekraft in
TypeScript/Node.js-Projekten, und welche Klassen von Dependencies
entziehen sich dem Ansatz prinzipiell – mit der Erwartung, dass
Projekte mit hohem Anteil dynamischer Imports oder
@DI#[]-Mechanismen strukturell außerhalb des Geltungsbereichs
der statischen Analyse fallen?

LF1 leitet die Designentscheidungen der Analysepipeline in Kapitel 4.
LF2 wird in der Evaluation (Kapitel 6) quantitativ beantwortet, indem
die Befundsätze der einzelnen Analysestufen gegenübergestellt werden.
LF3 verpflichtet die Arbeit dazu, die in @UES-Geltungsbereich
eingeführten Ausnahmeklassen als eigenständige Bedrohungen der externen
Validität zu operationalisieren. Die Antworten auf LF1 bis LF3 münden
gemeinsam in die Beantwortung von FF1a und FF1b, die im Fazit
(Kapitel 7) synthetisiert werden.

Die Arbeit vertritt dabei die These, dass bereits eine Import-basierte
Analysestufe einen messbaren, bisher nicht quantifizierten
Sicherheitsmehrwert gegenüber reiner Präsenzanalyse liefert – und
dass dieser Mehrwert durch eine zusätzliche Erreichbarkeitsanalyse
weiter steigerbar ist.


== Zielsetzung und Abgrenzung <Zielsetzung>

=== Zielsetzung

Diese Arbeit verfolgt ein exploratives Ziel: Sie untersucht, in welchem
Ausmaß und unter welchen Bedingungen statische Nutzungsanalyse geeignet
ist, Vulnerability-Befunde metadatenbasierter Scanner in
TypeScript/Node.js-Projekten risikobasiert zu priorisieren. Die in
@Problemstellung formulierten Forschungsfragen – insbesondere FF1a und
FF1b zur messbaren FP-Reduktion und Priorisierbarkeit sowie LF1 bis LF3
zu Identifikationsgenauigkeit, Reduktionsausmaß und inhärenten Grenzen –
werden dabei durch einen prototypischen @PoC operationalisiert und
quantitativ evaluiert.

Als Ergebnis entsteht eine prototypische Analysepipeline, die
Vulnerability-Befunde anhand statischer Nutzungsevidenz stufenweise
priorisiert und quantitativ evaluiert. Damit wird – im Rahmen der für
diese Arbeit durchgeführten Literaturrecherche wurde kein Beitrag
identifiziert, der dies bereits leistet – erstmals der isolierte
Erkenntnisgewinn einer Import-basierten Analysestufe gegenüber reiner
Präsenzanalyse in einem Sicherheitskontext messbar gemacht (vgl. LF2).

=== Begründung für den statischen Analyseansatz <Begruendung>

Die Entscheidung für einen rein statischen Ansatz folgt nicht aus einer
methodischen Präferenz, sondern aus dem Anwendungsfall, den diese Arbeit
adressiert: die Analyse fremder TypeScript/Node.js-Deployments im Rahmen
von Sicherheitsbewertungen.

In diesem Kontext ist dynamische Laufzeitanalyse methodisch nicht
anwendbar. Dynamische Methoden wie V8 Coverage, Runtime-Tracing oder
eBPF-basiertes Monitoring setzen Kontrolle über die Laufzeitumgebung
voraus: Die Anwendung muss gestartet, instrumentiert und unter realem
oder simuliertem Traffic betrieben werden können. Im beschriebenen
Anwendungskontext sind diese Voraussetzungen grundsätzlich nicht gegeben.
Erstens fehlt bei der Analyse fremder Systeme typischerweise der Zugriff
auf die produktive Laufzeitumgebung – Kunden stellen Quellcode und
Artefakte zur Verfügung, nicht aber eine instrumentierbare
Staging-Umgebung. Zweitens verbieten Datenschutzanforderungen,
Lizenzbestimmungen und das Risiko unerwünschter Seiteneffekte die
Ausführung einer Kundenanwendung in einer externen Umgebung
typischerweise. Drittens sind viele Projekte ohne umfangreiche
Konfiguration, externe Dienste oder Datenbanken nicht startbar, während
statische Analyse ausschließlich Quellcode und installierte Packages
erfordert.

Ansätze, die eine partielle Laufzeitbeobachtung durch kontrollierte
Testausführung simulieren, setzen ebenfalls eine ausführbare Umgebung
voraus und sind damit denselben Einschränkungen unterworfen. Statische
Analyse operiert hingegen ausschließlich auf Quellcode und
Dependency-Metadaten und ist damit die primär anwendbare Analyseklasse
in diesem Kontext. Zugleich steht dieser Ansatz im Einklang mit einer
Reihe etablierter Forschungsarbeiten wie JSLIM, Mininode und DepClean,
die ebenfalls rein statisch operieren (vgl. Kapitel 3) @Liu2025 @2021Nielsen.

Aus diesen Rahmenbedingungen und dem explorativen Charakter der Arbeit
ergeben sich die folgenden bewussten Einschränkungen des
Untersuchungsumfangs.

=== Abgrenzung

*Forschungsprototyp, kein Produktivsystem.* Der @PoC demonstriert
Machbarkeit und misst den Erkenntnisgewinn. Aspekte wie Skalierbarkeit,
Fehlertoleranz und CI/CD-Integration sind nicht Gegenstand dieser Arbeit.

*Keine dynamische Laufzeitanalyse.* Aus den in @Begruendung dargelegten
Gründen ist laufzeitbasierte Erreichbarkeitsanalyse nicht implementiert;
die erreichbarkeitsbezogenen Aussagen sind statische Schätzungen mit
quantifizierter Konfidenz, keine durch Laufzeitdaten verifizierten Fakten.
Dynamische Laufzeitanalyse wird in Kapitel 7 als natürlicher Folgeschritt
diskutiert.

*Eingeschränkter JavaScript-Sprachsupport.* Dynamische Sprachkonstrukte
wie `require(variable)` oder `eval()`, Plugin-Systeme, die Packages
über Konfigurationsstrings laden, sowie @DI#[]-Mechanismen wie der
NestJS-@IoC#[]-Container sind für die statische Analyse prinzipiell
nicht erfassbar. Der @PoC ist für Projekte mit hohem Anteil solcher
Konstrukte nur bedingt geeignet; diese Fälle werden in
@UES-Geltungsbereich als Ausnahmeklassen eingeführt und in Kapitel 6
als Bedrohungen der externen Validität operationalisiert.

*TypeScript/Node.js als Zielökosystem.* Andere JavaScript-Laufzeiten
wie Deno oder Bun sowie reine JavaScript-Projekte ohne Typsystem sind
nicht Gegenstand der Evaluation.


//== Problemstellung und Forschungsfragen <Problemstellung>

// TODO: Forschungsfragen ausformulieren
// Leitfragen:
// - Wie können ungenutzte Abhängigkeiten in TypeScript/Node.js-Deployments
//   zuverlässig erkannt werden, um Vulnerability-Scanner-Befunde risikobasiert
//   zu priorisieren?
// - Inwieweit lässt sich eine statische Erreichbarkeitsanalyse (L2a) für
//   TypeScript/Node.js prototypisch umsetzen und wie viele False-Positive-
//   Befunde lassen sich damit gegenüber einer reinen Präsenzanalyse (L0)
//   reduzieren?

//== Zielsetzung und Abgrenzung <Zielsetzung>

// TODO: Zielbeschreibung (PoC), Abgrenzung (kein Produktivsystem,
//       kein vollständiger JS-Sprachsupport), grobe Vorgehensweise



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

== Software Bill of Materials (SBOM) <Software-Bill-of-Materials>

Wie in der Motivation beschrieben, basieren Scanner wie npm audit oder OWASP Dependency-Check auf Software Bills of Materials (SBOMs).
Ein SBOM ist eine maschinenlesbare Liste aller Softwarekomponenten eines Produkts @ntia2021sbomoverview. 
Im Gegensatz zu Manifest-Dateien wie `package.json`, die nur direkte Dependencies auflisten, erfasst ein SBOM auch alle transitiven Dependencies mit exakten Versionen.
Die NTIA spezifiziert Mindestinhalte @ntia2021minimumelements, das verbreitetste Format ist SPDX (ISO/IEC 5962:2021) @isoiec5962spdx2021.

SBOMs werden typischerweise durch spezialisierte Tools wie CycloneDX, Syft oder das Microsoft SBOM Tool aus den Dependency-Informationen eines Projekts generiert. Jeder SBOM-Eintrag dokumentiert eine Softwarekomponente mit folgenden Informationen: Paketname (z.B. `express`), Version (`4.18.2`), eindeutiger Identifikator als Package-URL (`pkg:npm/express@4.18.2`), Lizenzinformation (`MIT`), Lieferant sowie die Liste der direkten Dependencies dieser Komponente. Für ein typisches Node.js-Projekt mit 50 direkten Dependencies kann ein SBOM mehrere hundert Einträge umfassen, da auch alle transitiven Dependencies erfasst werden müssen.

Die fundamentale Einschränkung von SBOMs liegt im Detailgrad der Dokumentation: Dependencies werden auf Package-Ebene dokumentiert. Eine Bibliothek wird als Ganzes erfasst, unabhängig davon, welche ihrer Funktionen tatsächlich genutzt werden. Bindet ein Projekt die Bibliothek `lodash` ein und nutzt nur die Funktion `_.debounce()`, erfasst das SBOM lediglich `lodash@4.17.21` als Dependency, ohne zu dokumentieren, welche der über 300 verfügbaren Funktionen von lodash im Code aufgerufen werden.

== Bloated Dependencies <Bloated-Dependencies>

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
Kategorie *geerbter* Dependencies aus Parent-POMs, die in @TS keine
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
@2022Chuang. Eine explorative Studie mit 31 Pull Requests (23 davon beantwortet) deutet an, dass erhebliche Unsicherheiten besonders bei transitiven Dependencies bestehen:
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
@Anteil-Bloated-Maven und @Anteil-Bloated-npm zeigen die Verteilung nach Typ.

#figure(
  table(
    columns: (auto, auto),
    align: (left, center),
    [*Typ*], [*Anteil (N = 723.444)*],
    [Direkt (bloated)],    [2,7%],
    [Inherited (bloated)], [15,4%],
    [Transitiv (bloated)], [57,0%],
    [*Gesamt bloated*],    [*75,1%*],
  ),
  caption: [Bloated Dependencies im Maven-Ökosystem @SotoValero2021MavenBloat.]
)<Anteil-Bloated-Maven>

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, center, center),
    [*Typ*], [*Anzahl*], [*Anteil der Kategorie*],
    [Direkt (bloated)],   [120 / 869],       [13,8%],
    [Indirekt (bloated)], [25.446 / 49.619], [51,3%],
    [*Gesamt bloated*],   [*25.566 / 50.488*], [*50,6%*],
  ),
  caption: [Bloated Dependencies im CommonJS/npm-Ökosystem @Liu2025.]
)<Anteil-Bloated-npm>

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

== Vulnerability-Datenbanken und Dependency Scanner <Vulnerability-Datenbanken>

Dieses Kapitel beschreibt den Aufbau der Schwachstellendatenbanken, auf
denen Dependency-Scanner basieren, und den konkreten Prüfprozess, der zu
einem Scanner-Befund führt. Beides bildet die technische Grundlage, um
nachzuvollziehen, warum metadatenbasierte Scanner nicht zwischen erreichbaren
und nicht erreichbaren Schwachstellen unterscheiden können.

=== CVE und die National Vulnerability Database

Das @CVE#[]-Programm ist der zentrale Standard zur einheitlichen Benennung
öffentlich bekannter Sicherheitslücken @cveprogram. Jede Schwachstelle
erhält einen eindeutigen Bezeichner in der Form CVE-JAHR-NUMMER, der eine
ökosystemübergreifende Referenzierung ermöglicht. Die @NVD#[] des @NIST baut
auf diesem Standard auf und reichert jeden @CVE#[]-Eintrag mit strukturierten
Metadaten an: einer Schweregradbewertung nach @CVSS, einer
Schwachstellentyp-Klassifikation nach @CWE sowie einer Liste betroffener
Produkte nach @CPE @Anwar2022CleaningNVD. Anwar et al. erfassten in einem
Snapshot von Mai 2018 über 107.200 @CVE#[]-Einträge, die der @NVD über
zwei Jahrzehnte hinzugefügt wurden @Anwar2022CleaningNVD.

@CPE ist ein standardisiertes Namensschema zur eindeutigen Identifikation
von Software-Produkten und -Versionen. Der @CPE#[]-Eintrag ist für
@NVD#[]-basierte Dependency-Scanner das entscheidende Matching-Feld:
Er codiert betroffene Produkte im Format
`cpe:2.3:a:HERSTELLER:PRODUKT:VERSION` und definiert damit, welche
Package-Versionen als verwundbar gelten @Anwar2022CleaningNVD. Allerdings
verwenden @CPE#[]-Bezeichner eine andere Granularität und Konvention als
Package-Repository-Koordinaten, was zu ungenauem Package-Mapping führt
@2022Pashchenko. Metadatenbasierte Scanner prüfen zudem nicht, ob die
vulnerable Funktion einer Bibliothek im konkreten Anwendungskontext
tatsächlich aufgerufen wird; das ist der zentrale Unterschied zu
code-zentrischen Ansätzen @ponta2020detection.

=== Von der Datenbank zum Scanner-Befund

@SCA#[]-Tools wie `npm audit`, das in @npm#[] integrierte
Kommandozeilenwerkzeug zur Sicherheitsprüfung von Abhängigkeiten, oder
@OWASP Dependency-Check, ein verbreitetes Open-Source-Tool der Open
Worldwide Application Security Project Foundation, erzeugen automatisch ein
Inventar aller eingesetzten Open-Source-Komponenten und gleichen dieses gegen
Schwachstellendatenbanken ab @Imtiaz2021ComparativeSCA. Dabei unterscheiden
sich die genutzten Datenquellen je nach Tool: @OWASP Dependency-Check bezieht
Schwachstellendaten unter anderem aus der @NVD und nutzt @CPE#[]-Matching zur
Identifikation betroffener Packages @Imtiaz2021ComparativeSCA, während
`npm audit` seit Oktober 2021 auf die GitHub Advisory Database mit
Package-URL (purl) als Identifikator setzt @githubAdvisoryNpm2021. Trotz unterschiedlicher Datenquellen lässt sich der Ablauf auf drei
grundlegende Schritte reduzieren @Imtiaz2021ComparativeSCA:

+ *Inventarisierung:* Der Scanner liest Dependency-Manifest-Dateien wie
  `package-lock.json` und erzeugt daraus eine Liste aller Packages mit
  exakten Versionen @Imtiaz2021ComparativeSCA. Alternativ kann ein @SBOM
  (vgl. @Software-Bill-of-Materials) als Eingabequelle dienen, das den in
  @Dependency_Management beschriebenen Dependency-Tree in maschinenlesbarer
  Form abbildet.
+ *Matching:* Jedes Package wird gegen die Einträge der jeweiligen
  Datenbank abgeglichen. Ein Treffer liegt vor, wenn Paketname und Version
  in den betroffenen Versionsbereich eines Schwachstellen-Eintrags fallen.
+ *Meldung:* Jeder Treffer wird als Befund ausgegeben, inklusive @CVE#[]-ID,
  @CVSS#[]-Score und betroffener Version.

#figure(
  /* Abbildung folgt */
  rect(width: 100%, height: 6em, stroke: 0.5pt),
  caption: [Dreistufiger Prüfprozess eines metadatenbasierten
            Dependency-Scanners (Inventarisierung, Matching, Meldung).]
) <Dreischritt-Scanner>

Ausschließlich Paketname und Versionsnummer bestimmen das Ergebnis. Ob
die vulnerable Funktion im konkreten Anwendungskontext erreichbar ist,
geht in diesen Prozess nicht ein (vgl. die in @Bloated-Dependencies
quantifizierten Limitierungen). Genau diese Lücke adressiert der @PoC
dieser Arbeit.


= Verwandte Arbeiten

== Dynamische Ansätze (Runtime-Tracing, Coverage)

// TODO

== Statische Ansätze (Call-Graph, Reachability)

// TODO

== Einordnung der Ansätze nach L0–L2 und Eignung für TypeScript/Node.js

// TODO

= Konzept und Designentscheidung

// Das Usage-Evidence-Schema bildet die konzeptuelle Grundlage für alle
// Designentscheidungen und wird daher hier als erstes Unterkapitel geführt
// 
Dieses Kapitel entwickelt das konzeptuelle und methodische Fundament des
PoC in drei aufeinander aufbauenden Schritten. Zunächst wird ein gestuftes
Evidenzmodell eingeführt, das die in @Vulnerability-Datenbanken und
@Bloated-Dependencies beschriebenen Limitierungen metadatenbasierter Scanner
formalisiert; es bildet den Bewertungsrahmen für alle nachfolgenden
Entscheidungen. Auf dieser Grundlage werden die funktionalen Anforderungen
an den PoC abgeleitet und die methodische Entscheidung für eine statische
Erreichbarkeitsanalyse (L2a) begründet. Abschließend wird die
Gesamtarchitektur der Analysepipeline beschrieben, die diese Entscheidungen
in eine konkrete Implementierungsstruktur überführt.


== Usage-Evidence-Schema <Usage-Evidence-Schema>

Das Schema unterscheidet drei Evidenzstufen: L0 (Präsenz), L1 (Import)
und L2 (Erreichbarkeit), die in einer priorisierungsrelevanten
Implikationskette vereint sind. Die zentrale These lautet: Metadatenbasierte
Scanner operieren auf Präsenzbasis; da sie nicht zwischen Präsenz und
Exploitierbarkeit unterscheiden, erzeugen sie strukturell einen überhöhten
Befundsatz. Eine stufenweise Evidenzerhebung nach Import- und
Erreichbarkeitskriterien erhöht mit jeder Stufe die Wahrscheinlichkeit,
dass eine gemeldete Dependency zur Laufzeit nicht ausgeführt wird und ihre
Schwachstelle damit strukturell nicht exploitierbar ist. Auf dieser
Grundlage können Vulnerability-Befunde risikobasiert priorisiert werden.
Diese These verpflichtet den @PoC zur Implementierung von L1 und L2a
(Kapitel 5), die Evaluation zur quantitativen Messung des stufenweisen
Gewinns (Kapitel 6) und die Priorisierungslogik zur expliziten Verwendung
der Stufenzugehörigkeit als Rankingkriterium.

Die nachfolgende Literaturauswahl erhebt keinen Anspruch auf
Vollständigkeit, illustriert jedoch durch unabhängige Forschungsarbeiten
konsistent belegte Befunde auf drei verschiedenen Betrachtungsebenen.
Ponta et al. formulieren das Grundproblem konzeptionell: Ob eine verwundbare
Funktion tatsächlich aufgerufen wird, lässt sich ausschließlich durch eine
nutzungsbasierte Analyse feststellen, wobei „nutzungsbasiert" bedeutet,
dass nicht der bloße Abgleich von Paketname und Version, sondern der
tatsächliche Aufruf einer Funktion im Anwendungskontext als Maßstab gilt
@ponta2018beyond. Dieselbe Forschungsgruppe zeigt, dass 88,8% der von
@OWASP Dependency-Check gemeldeten Befunde @FP#[s] sind, gemessen an der
statischen Aufruf-Erreichbarkeit der verwundbaren Funktion
@ponta2020detection. Imtiaz et al. bestätigen dies mit einem unabhängigen
Werkzeug: In ihrer vergleichenden @SCA#[]-Tool-Analyse zeigt Steadys
statische Analyse, dass bei 84,2% der gemeldeten Befunde das betroffene
Package im Anwendungskontext nicht genutzt wird, wobei „genutzt" bedeutet,
dass kein statischer Aufrufpfad zu einer Funktion des Packages existiert
@Imtiaz2021ComparativeSCA. Beide Erhebungen operieren damit auf L2a-Niveau
und quantifizieren die Diskrepanz zwischen L0- und L2a-Befundsätzen.
Pashchenko et al. messen eine verwandte, aber konzeptuell eigenständige
Dimension: den Unterschied zwischen installierten und tatsächlich deployten
Dependencies. Sie zeigen, dass diese Unterscheidung in beobachteten
Projekten die Anzahl der Warnungen für Development-only-Dependencies
gegenüber den Laufzeit-Dependencies um bis zu das Dreifache reduziert
@2022Pashchenko. Damit motivieren sie die L0-Grenze selbst: Bereits auf
Präsenzebene ist unklar, ob eine installierte Dependency überhaupt im
Produktivkontext aktiv ist. Diese drei Studien belegen unabhängig
voneinander, dass das Problem der Überschätzung durch Präsenzanalyse auf
verschiedenen Abstraktionsebenen auftritt: von der Funktionsebene (Ponta)
über die Package-Ebene (Imtiaz) bis zur Deployment-Ebene (Pashchenko). Ein
Modell, das zumindest zwischen Präsenz und Erreichbarkeit differenziert,
ist damit durch die Forschungslage motiviert; die Stufung als dreistufige
Hierarchie ist darüber hinaus durch die unterschiedlichen Analyseebenen der
Studien nahegelegt. Mögliche Gegenevidenz, etwa Ökosysteme mit hohem Anteil
dynamischer Imports, in denen L1 systematisch an seine Grenzen stößt, wird
in der Evaluation (Kapitel 6) als Bedrohung der externen Validität
behandelt.

Bevor das Schema formal eingeführt wird, ist eine Abgrenzung zu bestehenden
Import-Analyse-Werkzeugen notwendig, um den eigenständigen Beitrag dieser
Arbeit zu verorten. Bestehende Werkzeuge wie `depcheck` @depcheck-github,
`knip` @knip-github und `ts-prune` @ts-prune-github setzen Import-Analyse
als Maintenance-Funktion bereits implizit um. Diese Werkzeuge zeigen, dass
Import-Analyse technisch machbar ist; für den Sicherheitskontext dieser
Arbeit sind jedoch vier zusätzliche Eigenschaften konstitutiv, die keines
dieser Werkzeuge aufweist: erstens eine formale Definition von L1 mit
explizitem Geltungsbereich und Ausnahmeklassen; zweitens die Verknüpfung
von Import-Evidenz mit Vulnerability-Priorisierung, die diese Werkzeuge
nicht leisten, da sie ohne Vulnerability-Bezug operieren @Liu2025; drittens
die Differenzierung von L2 in L2a und L2b, die bestehende
Forschungsansätze präziser einordnet; und viertens die in der
einschlägigen Literatur bisher fehlende#footnote[Die Formulierung bezieht
sich auf den Stand der im Rahmen dieser Arbeit konsultierten Literatur;
eine vollständige systematische Literaturrecherche wurde nicht
durchgeführt.] Messung des L0→L1-Gaps in einem Sicherheitskontext, die in
Kapitel 6 durchgeführt wird. L0 und L2 sind in der Forschungsliteratur
verankert @ponta2018beyond @2021Nielsen; der Beitrag dieser Arbeit liegt
damit nicht in der Erfindung der Konzepte, sondern in der formalen
Definition von L1 als eigenständiger Evidenzstufe mit expliziten
Geltungsbedingungen sowie in ihrer Einbettung in eine
priorisierungsrelevante Implikationskette. Damit beantwortet dieser
Abschnitt die leitende Frage, unter welchen formal definierten Bedingungen
Import-Evidenz als eigenständige Sicherheitsschwelle zwischen Präsenz- und
Erreichbarkeitsanalyse operieren kann. Kapitel 3 ordnet bestehende Ansätze
anhand dieses Schemas ein.

=== Terminologie <UES-Terminologie>

Um die Implikationskette formal beschreiben zu können, sind vier Begriffe
zu klären, die im Schema durchgehend verwendet werden und deren Abgrenzung
für die Korrektheit der Kette entscheidend ist. Das Schema ist konzeptuell
auf alle Laufzeitumgebungen übertragbar, die den ECMAScript-Modulstandard
implementieren @ecmascript2024, darunter Deno, Bun und Browser-Umgebungen.
Der @PoC dieser Arbeit ist jedoch auf TypeScript/Node.js-Projekte
beschränkt, da die verwendeten Analyse-Tools und die verfügbare
Forschungslage auf dieses Ökosystem ausgerichtet sind.

Als *Konstrukt* gilt jede referenzierbare Einheit des Laufzeit-relevanten
Interfaces einer Dependency, also exportierte Funktionen, Klassen, Objekte
und Konstanten. TypeScript-`type`- und `interface`-Deklarationen sind
ausgeschlossen, da sie ausschließlich zur Compile-Zeit existieren und kein
Laufzeitverhalten erzeugen. Im Kontext dieses Schemas, das auf
TypeScript/Node.js-Projekte beschränkt ist, gelten TypeScript-Dekoratoren
als Konstrukte im obigen Sinne. Grund ist ihre Laufzeitsemantik: Sie werden
über den Reflection-Mechanismus ausgeführt und können dabei potenziell
verwundbare Codepfade aktivieren.

Als *Anwendungscode* gilt der Teil des Projekts außerhalb des
`node_modules`-Verzeichnisses#footnote[Der Begriff `node_modules`
bezeichnet hier stellvertretend das jeweilige Paketverzeichnis der
Laufzeitumgebung. In Deno etwa entspricht dies dem globalen Cache-Verzeichnis,
in Bun dem `.bun`-Verzeichnis. Der Geltungsbereich des Schemas umfasst
konzeptuell alle ECMAScript-konformen Laufzeitumgebungen @ecmascript2024;
die Benennung folgt der im @PoC verwendeten Node.js-Konvention.].

Als *Side-Effect-Import* gilt ein Import der Form `import 'modulname'` ohne
Named- oder Default-Import. Ein typisches Beispiel ist
`import 'reflect-metadata'`, das in NestJS-Projekten verwendet wird, um
den Reflection-Mechanismus für Dekoratoren zu aktivieren: Das Modul wird
beim Laden sofort ausgeführt und registriert globale Metadaten, ohne dass
ein Konstrukt im obigen Sinne exportiert wird. Side-Effect-Imports sind
L1-positiv, können aber nicht auf L2-Niveau eingeordnet werden, da kein
adressierbares Konstrukt für die Aufrufstrukturanalyse identifizierbar ist.
Das Schema kann damit nicht differenzieren, ob der Top-Level-Code des
Moduls verwundbare Pfade aktiviert oder nicht. Da im Sicherheitskontext
ein nicht erkannter verwundbarer Pfad (@FN) schwerwiegender ist als ein
fälschlich gemeldeter Befund (@FP), entsprechend dem Principle of
Fail-Safe Defaults, das Saltzer und Schroeder als eines von acht
grundlegenden Sicherheitsprinzipien für Systemdesign formulieren
@saltzer1975protection, werden Side-Effect-Imports konservativ als hoch
priorisiert. Die Behandlung in der Priorisierungslogik wird in Kapitel 5
erläutert.

Als *@DI#[]-Mechanismus* gilt jedes Verfahren, bei dem Abhängigkeiten
nicht über eine explizite `import`- oder `require()`-Anweisung referenziert
werden, sondern zur Laufzeit automatisch durch ein Framework aufgelöst
werden. In NestJS etwa wird eine `DatabaseService`-Klasse als
Konstruktor-Parameter deklariert und vom @IoC#[]-Container automatisch
instanziiert, ohne dass ein expliziter `require()`-Aufruf im Quellcode des
konsumierenden Moduls erscheint @nestjs-docs. Da der Modulpfad dabei im
Quellcode nicht sichtbar ist, entziehen sich @DI#[]-geladene Dependencies
der L1- und L2a-Analyse.

=== Formaler Rahmen und Geltungsbereich <UES-Geltungsbereich>

Die beschriebenen Teilmengenrelationen lassen sich als Trichtermodell
visualisieren, das die echte Inklusion der Evidenzstufen verdeutlicht
(@Trichter-Schema): Die Menge der importierten Dependencies ist eine echte
Teilmenge der installierten, und die Menge der erreichbaren Konstrukte ist
eine echte Teilmenge der importierten.

#figure(
  rect(width: 100%, height: 10em, stroke: 0.5pt),
  caption: [Trichtermodell: Jede Evidenzstufe beschreibt eine echte Teilmenge
            der vorherigen.]
) <Trichter-Schema>

Das Trichtermodell gilt unter einer zentralen Annahme, die den operativen
Geltungsbereich des Schemas begrenzt: der Closed-World-Annahme $A$. Das
Schema erhebt keinen Anspruch auf logische Vollständigkeit unter beliebigen
Laufzeitbedingungen, sondern formuliert eine operational definierte
heuristische Implikationskette L2 → L1 → L0, deren Anwendungsbereich
durch $A$ explizit begrenzt ist. $A$ besagt: Alle relevanten Imports sind
im statisch analysierbaren Quellcode sichtbar, und kein Modul wird über
nicht-sichtbare Mechanismen geladen. Unter $A$ folgt aus L2a-Evidenz
L1-Evidenz, und aus L1-Evidenz L0-Evidenz. Vier Ausnahmeklassen können $A$
verletzen: dynamische Imports wie `require(someVariable)`, bei denen der
Modulpfad erst zur Laufzeit bekannt ist; Conditional-Requires wie
`if (process.env.DEBUG) require('debug-lib')`, die nur unter bestimmten
Laufzeitbedingungen ausgeführt werden; @DI#[]-Mechanismen, die
Abhängigkeiten ohne explizite Import-Anweisung zur Laufzeit auflösen; und
`peerDependencies`, bei denen ein Package eine Laufzeit-Abhängigkeit
deklariert, die vom Host-Projekt bereitgestellt wird, ohne einen eigenen
Import-Statement zu erzeugen. Ein Beispiel ist ein ESLint-Plugin, das
`eslint` als `peerDependency` deklariert und zur Laufzeit nutzt, ohne
`require('eslint')` im eigenen Quellcode zu schreiben
@Zimmermann2022NotAllDeps @npm-peerdeps. Die Gültigkeit der
Implikationskette setzt Annahme $A$ voraus; ihre Grenzen werden in
Kapitel 6 als Bedrohungen der externen Validität operationalisiert. Für
den in dieser Arbeit verwendeten Testkorpus, der keine
@DI#[]-lastigen Projekte oder Plugin-Architekturen enthält, ist die
praktische Relevanz dieser Ausnahmeklassen begrenzt. Sie werden dennoch
vollständig in Kapitel 6 dokumentiert.

`writex` ist ein @npm#[]-Tool zum Konvertieren von Markdown-Dateien in
LaTeX, das Nielsen et al. als Motivationsbeispiel für die Unzulänglichkeit
von @npm audit verwenden @2021Nielsen. Es wird hier als durchgehendes
Beispiel übernommen, um den Erkenntnisgewinn jeder Evidenzstufe direkt
vergleichbar zu machen. Die drei Evidenzstufen werden nun anhand dieses
Beispiels sequenziell durchlaufen.

*L0 (Präsenz)* bildet die Baseline des Schemas. Da Scanner ausschließlich
auf Paketname und Version prüfen, werden Dependencies als verwundbar
gemeldet, unabhängig davon, ob ihr Code je ausgeführt wird. Für `writex`
meldet @npm audit 10 Vulnerabilities aus 5 Advisories, darunter eine
Prototype-Pollution-Schwachstelle in `lodash`, die gleich zweimal gemeldet
wird, weil `lodash` über zwei verschiedene Dependency-Chains installiert
ist: `writex → lodash-template-stream → lodash` und
`writex → gaze → globule → lodash` @2021Nielsen. Insgesamt sind 53
Packages installiert, einschließlich aller transitiven Dependencies, die
durch den in @Dependency_Management beschriebenen Kaskadeneffekt
installiert wurden. L0 meldet alle davon als potenziell betroffen, ohne zu
unterscheiden, welche tatsächlich geladen werden. Auf dieser Stufe lässt
sich am wenigsten eingrenzen, ob eine gemeldete Dependency zur Laufzeit
tatsächlich ausgeführt wird.

*L1 (Import)* verfeinert L0 durch eine zentrale Sicherheitsbeobachtung:
Jede ECMAScript-konforme Laufzeitumgebung initialisiert ein Modul genau
dann, wenn es über einen expliziten `import`- oder `require()`-Aufruf
geladen wird @ecmascript2024 @nodejs-modules. Eine Dependency, die nie
importiert wird, wird nie initialisiert; auch ihre potenziell verwundbaren
Funktionen können daher strukturell nicht ausgeführt werden. Damit markiert
L1 im Schema die erste Evidenzstufe mit einer sicherheitsrelevanten
Implikation: Nicht-Laden schließt einen Ausführungspfad strukturell aus.
Fehlt der Import-Nachweis, steigt die Wahrscheinlichkeit, dass die
Dependency zur Laufzeit nicht ausgeführt wird und eine gemeldete
Schwachstelle strukturell nicht exploitierbar ist. Unter Annahme $A$ bildet
die Menge der L1-positiven Dependencies eine obere Schranke der zur
Laufzeit geladenen Dependencies: Jede Dependency, die nicht importiert
wird, kann nicht ausgeführt werden. Für `writex` bedeutet das: Von den 53
installierten Packages umfassen deren JavaScript-Quelldateien insgesamt 187
Module; L1 filtert alle Packages heraus, die in keiner dieser Moduldateien
per Import-Statement referenziert werden. Diese Garantie gilt für den
Geltungsbereich dieser Evaluation; auf beliebige TypeScript/Node.js-Projekte
ist sie nicht übertragbar, da dynamische Imports, `peerDependencies` oder
@DI#[]-Mechanismen Annahme $A$ verletzen können (vgl. Ausnahmeklassen in
@UES-Geltungsbereich).

Die wesentliche Einschränkung von L1 gegenüber L2a besteht darin, dass
L1 nicht unterscheiden kann, ob eine importierende Datei selbst vom
Einstiegspunkt der Anwendung erreichbar ist. Eine Datei
`legacy-convert.ts`, die `lodash` importiert, aber vom Einstiegspunkt von
`writex` nie aufgerufen wird, klassifiziert `lodash` als L1-positiv,
obwohl zur Laufzeit kein Ausführungspfad von diesem Import ausgeht. L1
garantiert, dass nicht-importierte Dependencies keine Laufzeit-Relevanz
besitzen. Gleichwohl überschätzt L1 die tatsächliche Nutzung systematisch:
Es kann nicht ausgeschlossen werden, dass eine importierende Datei selbst
vom Einstiegspunkt der Anwendung unerreichbar ist. Genau diese Lücke
schließt L2a durch eine Erreichbarkeitsanalyse vom Einstiegspunkt.

Als formale Sicherheitsevidenzstufe ist L1 in der Forschungsliteratur
nicht beschrieben, wie im vorigen Absatz dargelegt. Werkzeuge wie
`depcheck`, `knip` und `ts-prune` analysieren Import-Statements als
Maintenance-Werkzeuge ohne Vulnerability-Bezug und ohne definierten
Geltungsbereich @Liu2025; Nielsen et al. springen direkt von L0 zu L2a,
ohne eine Import-Stufe zu formalisieren @2021Nielsen. Der isolierte
Sicherheitsmehrwert von L1 gegenüber L0 wird in der Evaluation (Kapitel 6)
erstmals gemessen.

*L2 (Erreichbarkeit)* schließt die verbleibende Lücke von L1. *L2a*
bezeichnet den durch Aufrufstrukturanalyse nachweisbaren Pfad vom
Einstiegspunkt zu einem Konstrukt. Fehlt dieser Pfad, erhöht sich die
Wahrscheinlichkeit weiter, dass die Dependency zur Laufzeit nicht
ausgeführt wird: Eine Dependency, die zwar importiert, aber vom
Einstiegspunkt aus nie aufgerufen wird, besitzt keinen nachweisbaren
Ausführungspfad über Anwendungslogik. Für `writex` zeigt die
Aufrufstrukturanalyse, dass von den 187 Modulen nur 90 tatsächlich vom
Einstiegspunkt aus erreichbar sind, was 42 von 53 Packages entspricht
@2021Nielsen. Von den 10 ursprünglichen @npm audit-Befunden verbleibt nach
L2a-Analyse genau einer als True Positive: eine
@ReDoS#[]-Schwachstelle in der Funktion `minimatch(path, pattern)` des
`minimatch`-Packages, die über die Kette `writex → globule → minimatch`
erreichbar ist. Die anderen 4 Advisories (9 Befunde) sind @FP#[s], weil
die verwundbaren Funktionen, darunter die `lodash`-Prototype-Pollution, vom
Anwendungscode nie aufgerufen werden @2021Nielsen. Nielsen et al. berichten
für L2a eine @FP#[]-Reduktion von ca. 81% gegenüber L0 (N=12; ohne
Konfidenzintervall), die hier als Orientierungsgröße dient. Dieser
Einschränkung begegnet die größere Studie von Zhou et al.: Sie messen für
@SBOM#[]-basierte Scanner über N=2.414 Repositories eine
@FP#[]-Rate von 97,5% (entsprechend einer Präzision von ca. 2,5%) sowie
eine @FP#[]-Reduktion von 63,3% durch Call-Graph-Reachability
@zhou2025reality, was zeigt, dass das Problem nicht auf den
Stichprobenumfang von Nielsen et al. (N=12) zurückzuführen ist.

*L2b (dynamisch/konzeptuell)* bezeichnet durch Laufzeitbeobachtung
bestätigte Ausführung: Selbst wenn ein Aufrufpfad zu `minimatch` existiert,
bleibt bei L2a offen, ob dieser Pfad in einer konkreten Ausführung
tatsächlich durchlaufen wird. L2b würde dies durch Instrumentierung zur
Laufzeit klären. Im @PoC dieser Arbeit ist L2b nicht implementiert, da die
erforderliche Laufzeitbeobachtung eine kontrollierte Deployment-Umgebung
voraussetzt, die den Rahmen dieser Arbeit übersteigt. Die methodischen
Ansätze beider Unterebenen werden in den Verwandten Arbeiten (Kapitel 3)
eingeordnet.

@Evidence-Schema fasst alle vier Stufen als Überblick zusammen. Die Spalte
*@FN#[]-Klasse* beschreibt, welche Arten von Dependencies eine Stufe
strukturell nicht erfassen kann. Die Spalte *Empirischer Mehrwert* gibt an,
welchen messbaren Vorteil eine Stufe gegenüber L0 liefert. Bei L1 fehlt
dieser Wert in der Literatur; die Messung in Kapitel 6 schließt diese
Lücke. L2b ist als konzeptueller Ausblick aufgenommen; die Implementierung
ist aus den oben genannten Gründen nicht Teil des @PoC und wird in
Kapitel 7 als zukünftige Arbeit aufgegriffen.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, left, left, left, left),
    [*Stufe*], [*Frage*], [*Methode*], [*@FN#[]-Klasse*], [*Empirischer Mehrwert*],
    [L0 (Präsenz)],
      [Ist die Dependency\ installiert?],
      [@SBOM, Dependency-Tree\ (vgl. @Dreischritt-Scanner)],
      [Keine @FN#[s]\ (alle installierten\ Packages erfasst)],
      [Baseline; @SBOM#[]-Scanner:\ ~2,5% Präzision\ (N=2.414) @zhou2025reality],
    [L1 (Import)],
      [Wird die Dependency\ geladen?],
      [Statische Quellcode-\ analyse der Imports],
      [Dynamische Imports,\ peerDependencies,\ @DI#footnote[Zu den Ausnahmeklassen, die Annahme $A$ verletzen, vgl. @UES-Geltungsbereich.]],
      [Bedingte obere\ Schranke; erstmals\ in Kap. 6 erhoben],
    [L2a (statisch)],
      [Ist ein Konstrukt\ erreichbar?],
      [Aufrufstrukturanalyse\ (vgl. Kapitel 3)],
      [Reflection, @DI,\ globale Augment.#footnote[Augmentierungen bezeichnen das nachträgliche Erweitern globaler Objekte zur Laufzeit, z.B. `Object.prototype.sanitize = ...`.]],
      [~81% / 63,3% @FP#[]-Red.\ ggü. L0\ (vgl. L2a-Beschr.)],
    [L2b (dynamisch)\ *(konzeptuell)*],
      [Wird ein Konstrukt\ ausgeführt?],
      [Laufzeitbeobachtung\ (vgl. Kapitel 3)],
      [Unvollständige\ Testabdeckung],
      [Präziseste Evidenz;\ nicht impl.\ (vgl. Kapitel 7)],
  ),
  caption: [Evidenzstufen des Usage-Evidence-Schemas als Überblick.
            L1 wird in dieser Arbeit erstmals als eigenständige
            Sicherheitsstufe formalisiert. Die zugehörige Messung
            erfolgt in Kapitel 6. L2b erfordert eine kontrollierte
            Laufzeitumgebung; seine Umsetzung wird in Kapitel 7 als
            Gegenstand künftiger Forschung diskutiert.]
) <Evidence-Schema>

Die technische Umsetzung der risikobasierten Priorisierungslogik wird in
Kapitel 5 beschrieben; ihre Validierung erfolgt in Kapitel 6.











== Anforderungen an den PoC

// TODO

== Bewertung und Methodenauswahl

// TODO

== Architektur der Gesamtpipeline

// TODO

= Implementierung

== Tooling-Stack und Projektstruktur

// TODO

== L0: Präsenzermittlung via Dependency-Tree/SBOM

// TODO


== L1: Loaded-Heuristiken

// TODO

== L2: Reachability-Analyse (Call-Graph, Entry Points, Mapping)

// TODO

== Ergebnisformat und Risk-Scoring

// TODO

== Beispiel-Durchlauf

// TODO


= Evaluation

== Setup und Testkorpus

// TODO

== Metriken und Vorgehen

// TODO

== Ergebnisse und Vergleich mit npm audit

// TODO

== Limitierungen (JS-Dynamik, Reflection, Bundling)


//       chapter. Covers: eval/dynamic require, DI-Frameworks (NestJS),
//       Bundling (webpack/esbuild), side-effect-only imports, Threats to Validity


= Fazit und Ausblick

== Fazit

// TODO: Rückbezug auf Forschungsfragen aus @Problemstellung

== Ausblick <Ausblick>

// TODO: L2b (dynamische Erreichbarkeit), bessere CVE→Symbol-Zuordnung,
//       CI/CD-Integration
