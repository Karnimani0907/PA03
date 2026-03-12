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
  ),
)


= Einleitung

== Motivation <Motivation>

Dependency Scanner wie npm audit und OWASP Dependency-Check sind aus der modernen Softwareentwicklung nicht mehr wegzudenken @ponta2020detection. Diese Tools basieren primär auf Software Bill of Materials (SBOM) und operieren ausschließlich auf Package-Ebene @ponta2018beyond. Aktuelle Forschung zeigt jedoch fundamentale Limitierungen dieser Ansätze, die zu erheblichen praktischen Problemen führen.

Die Unfähigkeit zu erkennen, ob Code tatsächlich zur Laufzeit geladen wird, führt zu zwei kritischen Problemen. Erstens akkumulieren Projekte obsolete Dependencies, die erhebliche Wartungskosten verursachen @2022Chuang. Empirische Analysen zeigen, dass 75,1% aller Maven-Dependencies als "bloated" klassifiziert werden können, wobei 57% der transitiven Dependencies vollständig ungenutzt sind @sotovalero2021maven. Im JavaScript-Ökosystem ist die Situation vergleichbar: 50,6% der Dependencies in CommonJS-Packages sind bloated @Liu2025. /* Die Entfernung einer einzigen direkten bloated Dependency kann kaskadenartig zur Elimination von bis zu 679 indirekten Dependencies führen @Liu2025. */

Diese obsoleten Dependencies entstehen durch verschiedene Mechanismen. Transitive Abhängigkeiten werden automatisch in die Dependency-Hierarchie eingefügt, ohne dass Entwickler sich deren Präsenz bewusst sind @2022Chuang. Darüber hinaus werden Dependencies während der Entwicklung hinzugefügt und bei Code-Refactorings nicht entfernt @Liu2025. Das Entfernen ist jedoch oft schwierig, weil Entwickler nicht mit ausreichender Sicherheit beurteilen können, ob eine Dependency wirklich entbehrlich ist @2022Chuang. Die resultierenden Kosten manifestieren sich in erhöhten Binary-Größen, verlängerten Build-Zeiten, erhöhtem Speicherverbrauch und gesteigertem Sicherheitsrisiko durch eine vergrößerte Angriffsfläche @sotovalero2021maven @soto2023coverage. In containerisierten Deployments wird die Problematik besonders sichtbar, da Images teils eine große Menge veralteter oder verwundbarer JavaScript-Pakete enthalten @8667984.

Zweitens führt die Fokussierung auf Package-Level-Analysen zu einer hohen Rate an False-Positive-Warnungen. Die zentrale Herausforderung liegt in der fehlenden Granularität: SBOM-basierte Tools können nicht zwischen deployed und nicht-deployed Code differenzieren @2022Pashchenko, noch können sie feststellen, ob vulnerable Funktionen tatsächlich vom Anwendungscode aufgerufen werden. /* Während Call-Graph-basierte Forschungsansätze zeigen, dass eine feinere Analyseebene die False-Positive-Rate um 81% reduzieren kann @2021Nielsen */

== Problemstellung und Forschungsfragen <Problemstellung>

// TODO: Forschungsfragen ausformulieren
// Leitfragen:
// - Wie können ungenutzte Abhängigkeiten in TypeScript/Node.js-Deployments
//   zuverlässig erkannt werden, um Vulnerability-Scanner-Befunde risikobasiert
//   zu priorisieren?
// - Inwieweit lässt sich eine statische Erreichbarkeitsanalyse (L2a) für
//   TypeScript/Node.js prototypisch umsetzen und wie viele False-Positive-
//   Befunde lassen sich damit gegenüber einer reinen Präsenzanalyse (L0)
//   reduzieren?

== Zielsetzung und Abgrenzung <Zielsetzung>

// TODO: Zielbeschreibung (PoC), Abgrenzung (kein Produktivsystem,
//       kein vollständiger JS-Sprachsupport), grobe Vorgehensweise

== Aufbau der Arbeit <Aufbau>

// TODO: Kapitelübersicht in 1–2 Sätzen pro Kapitel



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


// ============================================================
// 3  VERWANDTE ARBEITEN
// ============================================================

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
Dieses Kapitel entwickelt das konzeptuelle Fundament des PoC. Als Ausgangspunkt wird ein gestuftes Evidenzmodell eingeführt, das die in Kapitel 2 beschriebenen Limitierungen metadatenbasierter Scanner formalisiert und als Bewertungsrahmen für alle nachfolgenden Designentscheidungen dient. Darauf aufbauend werden die Anforderungen an den PoC abgeleitet, die methodische Entscheidung für eine statische Erreichbarkeitsanalyse begründet und die Gesamtarchitektur der Analysepipeline beschrieben."

== Usage-Evidence-Schema <Usage-Evidence-Schema>

Metadatenbasierte Scanner setzen die Präsenz einer Dependency im
Deployment-Artefakt mit ihrer potenziellen Exploitierbarkeit gleich.
Diese Annahme ist empirisch nicht haltbar: Installiert zu sein ist eine
notwendige, aber keine hinreichende Bedingung dafür, dass eine verwundbare
Funktion im konkreten Anwendungskontext tatsächlich erreichbar ist. Der
in @Vulnerability-Datenbanken beschriebene Scanner-Prozess prüft
ausschließlich Paketname und Version gegen Schwachstellendatenbanken, ohne
zu berücksichtigen, ob die betroffene Funktion vom Anwendungscode je
aufgerufen wird. Gleichzeitig zeigt @Bloated-Dependencies, dass im
npm-Ökosystem 50,6% aller installierten Dependencies zur Laufzeit nie
verwendet werden. In Kombination führt dies dazu, dass Warnungen für
Dependencies gemeldet werden, die zwar installiert, aber nie referenziert
oder erreichbar sind. Das in @Motivation beschriebene Grundproblem, die
fehlende Erreichbarkeitsanalyse metadatenbasierter Scanner, lässt sich
damit als fehlende Differenzierung zwischen drei Evidenzstufen
formalisieren, die im Folgenden als L0, L1 und L2 eingeführt werden.

Drei unabhängige Arbeiten motivieren dieses Modell empirisch aus
verschiedenen Perspektiven. Ponta et al. begründen zunächst konzeptionell,
dass erst eine nutzungsbasierte Analyse feststellen kann, ob vulnerable
Konstrukte tatsächlich erreichbar sind @ponta2018beyond, und zeigen
empirisch, dass 88,8% der OWASP-DC-Befunde False Positives sind, wenn
tatsächliche Code-Erreichbarkeit als Maßstab gilt @ponta2020detection.
Imtiaz et al. analysieren komplementär dazu die Qualität von Steadys
eigenen Alerts: Bei 84,2% der durch Steady gemeldeten Befunde wird das
betroffene Package im Anwendungskontext gar nicht genutzt, was die
Notwendigkeit einer Erreichbarkeitsanalyse auch innerhalb code-zentrischer
Tools belegt @Imtiaz2021ComparativeSCA. Pashchenko et al. zeigen schließlich
aus der Perspektive der Deployment-Struktur, dass für manche Projekte
Warnungen für Development-only-Dependencies die der deployten um das
Dreifache übersteigen @2022Pashchenko. Gemeinsam belegen diese Arbeiten,
dass eine reine Präsenzanalyse unzureichend ist, und motivieren ein Modell,
das zwischen Präsenz, syntaktischer Referenzierung und tatsächlicher
Erreichbarkeit unterscheidet -- eine Unterscheidung, die sich direkt in den
Stufen L0 (Präsenz), L1 (Import) und L2 (Erreichbarkeit) widerspiegelt.

Für das Schema gelten folgende Begriffe. Als *Konstrukt* gilt jede
referenzierbare Einheit des Laufzeit-relevanten Interfaces einer Dependency,
also exportierte Funktionen, Klassen, Objekte und Konstanten; TypeScript-
`type`- und `interface`-Deklarationen bleiben ausgeklammert. Side-Effect-
Imports der Form `import 'reflect-metadata'` begründen L1-Evidenz, sind aber
nicht auf L2-Niveau einordenbar, da sie kein adressierbares Konstrukt
exponieren. Als *Anwendungscode* gilt der Teil des Projekts außerhalb des
`node_modules`-Verzeichnisses (vgl. @Dependency_Management). Das Schema
erhebt keinen Vollständigkeitsanspruch: Jede Stufe erzeugt strukturell
unvermeidbare False Negatives, deren Ursachen dynamische Sprachfeatures des
JavaScript-Ökosystems sind. Diese Grenzen werden in den Verwandten Arbeiten
(Kapitel 3) methodisch und in der Evaluation (Kapitel 6) als Limitation
des PoC behandelt.

@Trichter-Schema veranschaulicht, dass jede Stufe eine echte Teilmenge der
vorherigen beschreibt.

#figure(
  rect(width: 100%, height: 10em, stroke: 0.5pt),
  caption: [Trichtermodell: Jede Evidenzstufe beschreibt eine Teilmenge der
            vorherigen. Der Großteil installierter Dependencies erzeugt keine
            L1- oder L2-Evidenz.]
) <Trichter-Schema>

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (left, left, left, left),
    [*Stufe*], [*Frage*], [*Methode*], [*FN-Klasse / Mehrwert*],
    [L0 -- Präsenz],
      [Ist die Dependency\ installiert?],
      [SBOM, Dependency-Tree\ (vgl. @Dreischritt-Scanner)],
      [Keine FNs (statischer Tree);\ Baseline: Gesamtpräzision\ von npm audit 24%\ (N=12) @2021Nielsen],
    [L1 -- Import],
      [Wird die Dependency\ referenziert?],
      [Statische Quellcode-\ analyse der Imports],
      [FNs durch dynamische\ Imports; obere Schranke\ der Exposition;\ Mehrwert in Kap. 6 erhoben],
    [L2a -- statisch],
      [Ist ein Konstrukt\ erreichbar?],
      [Aufrufstrukturanalyse\ (vgl. Kapitel 3)],
      [FNs durch Reflection,\ DI, glob. Augmentierungen;\ 81% FP-Reduktion ggü.\ npm audit @2021Nielsen],
    [L2b -- dynamisch],
      [Wird ein Konstrukt\ ausgeführt?],
      [Laufzeitbeobachtung\ (vgl. Kapitel 3)],
      [FNs durch unvollständige\ Testabdeckung; präziseste\ Evidenz; im PoC nicht\ implementiert],
  ),
  caption: [Evidenzstufen des Usage-Evidence-Schemas mit Analysemethode,
            FN-Klassen und empirischer Einordnung.]
) <Evidence-Schema>

*L0 -- Präsenz:* Eine Dependency ist im statisch installierten
Dependency-Tree vorhanden (vgl. @Dreischritt-Scanner). L0 erzeugt zwei
FP-Klassen: transitiv installierte, aber nie referenzierte Dependencies,
adressierbar durch L1, sowie referenzierte Dependencies ohne erreichbaren
Aufrufpfad zu verwundbaren Konstrukten, adressierbar durch L2. FNs sind
innerhalb des statisch installierten Trees strukturell ausgeschlossen. Den
Mechanismus illustriert `writex`: Von fünf gemeldeten Advisories ist nur
eine ein True Positive, da die verwundbaren Funktionen der übrigen nie
aufgerufen werden @2021Nielsen; die Gesamtpräzision von npm audit über
zwölf Anwendungen ist @Evidence-Schema zu entnehmen.

*L1 -- Import:* Eine Dependency wird durch einen statischen `import`- oder
`require()`-Aufruf mit literalem Modulpfad referenziert, einschließlich
Re-Exports und Namespace-Imports, wobei letztere die L2-Analyse erschweren,
da das konkret aufgerufene Konstrukt nicht allein aus dem Statement
bestimmbar ist. Da L1-Evidenz nicht voraussetzt, dass die importierende
Datei selbst erreichbar ist, überschätzt L1 die tatsächliche Nutzung
systematisch. L1 definiert damit, innerhalb des Geltungsbereichs statischer
Imports, eine obere Schranke der potenziell relevanten Dependencies und
damit eine konservative Aussage über die maximale Exposition gegenüber
installierten Schwachstellen. Als formale Evidenzstufe ist L1 in der
Forschungsliteratur nicht beschrieben, obwohl Werkzeuge wie `depcheck` oder
`knip` das Prinzip implizit einsetzen, ohne es gegen Vulnerability-Daten zu
beziehen. Der isolierte Mehrwert gegenüber L0 wird in der Evaluation
(Kapitel 6) erhoben.

*L2 -- Erreichbarkeit:* *L2a* bezeichnet den durch Aufrufstrukturanalyse
nachweisbaren Pfad vom Einstiegspunkt der Anwendung zu einem Konstrukt;
ob dieser Pfad zur Laufzeit tatsächlich durchlaufen wird, bleibt dabei
offen. L2a reduziert die FP-Rate gegenüber npm audit um 81% (N=12)
@2021Nielsen. *L2b* bezeichnet durch Laufzeitbeobachtung bestätigte
Ausführung und schließt damit die Lücke, die L2a offenlässt; L2b liefert
die präziseste verfügbare Evidenz, ist im PoC jedoch nicht implementiert.
Die methodischen Ansätze beider Unterebenen werden in den Verwandten
Arbeiten (Kapitel 3) eingeordnet.

Die Implikationskette L2 → L1 → L0 gilt unter der Annahme statischer
Modul-Referenzen. Vier Ausnahmeklassen können sie durchbrechen: dynamische
Imports, Conditional-Requires, DI-Mechanismen wie NestJS-Dekoratoren sowie
`peerDependencies` über Plugin-Mechanismen. Die praktische Verbreitung
dieser Ausnahmeklassen in TypeScript/Node.js-Projekten ist empirisch nicht
systematisch gemessen; ihre relative Häufigkeit bleibt eine offene empirische
Frage. Alle vier Fälle werden in der Evaluation (Kapitel 6) als Limitation
behandelt.

Für das Vulnerability-Management ergibt sich eine risikobasierte
Priorisierungslogik. Fehlt L1-Evidenz, existiert kein statischer
Referenzierungspfad; der Befund erhält niedrigste Priorität. Liegt L1-,
aber keine L2a-Evidenz vor, ist die Dependency aktiv eingebunden, sodass
ein Aufrufpfad über dynamische Mechanismen nicht ausgeschlossen werden kann;
der Befund erhält mittlere Priorität. Mit L1- und L2a-Evidenz existiert ein
nachweisbarer Aufrufpfad zu einem verwundbaren Konstrukt; der Befund erhält
hohe Priorität. L2b-Evidenz würde eine höchste Klasse begründen, da sie
dynamisch bestätigte Ausführung nachweist; diese ist im PoC nicht
implementiert. Die technische Umsetzung der Priorisierungslogik dokumentiert
die Implementierung (Kapitel 5).

Der Beitrag dieser Arbeit liegt in drei Leistungen: erstens der
Formalisierung von L1 als eigenständiger Evidenzstufe, wobei es sich um
eine Kategorie handelt, die Werkzeuge wie `depcheck` implizit umsetzen,
ohne sie formal zu beschreiben oder gegen Vulnerability-Daten zu beziehen;
zweitens der konzeptuellen Differenzierung von L2 in L2a und L2b, die
bestehende Forschungsansätze präziser einordnet und den
Implementierungsumfang des PoC klar abgrenzt; und drittens der
prototypischen Implementierung von L0, L1 und L2a für das
TypeScript/Node.js-Ökosystem. Kapitel 3 (Verwandte Arbeiten) ordnet
bestehende Ansätze anhand dieses Schemas ein.
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

== Ausblick

// TODO: L2b (dynamische Erreichbarkeit), bessere CVE→Symbol-Zuordnung,
//       CI/CD-Integration
