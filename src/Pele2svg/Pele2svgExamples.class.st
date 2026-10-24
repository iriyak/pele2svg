"
GToolkit examples for Pele2svg: each <gtExample> method renders a Mermaid diagram through pele2svg and answers a BlSkiaSvgElement. Open the class in the GT Coder and click the example results to see the diagrams. Requires Node.js (or Bun) and `npm install` in the Iceberg clone of pele2svg.

The 58 featured... methods use the Mermaid sources of the featured examples of pele (https://pele.run/examples, https://github.com/obsidianmd/pele, MIT License, Copyright (c) 2026 kepano), copied unchanged; the same sources are in test/fixtures/featured.json of the repository. The other examples (flowchart, sequenceDiagram, ...) are short diagrams written for this package.

The optionsXxx examples show the options of Pele2svgOptions (defaults, #during:, the global default, values set on a converter, precedence). They do not run Node.js or Bun, except optionsRuntimeReachesTheProcess, which tries to start a runtime that does not exist.
"
Class {
	#name : 'Pele2svgExamples',
	#superclass : 'Object',
	#category : 'Pele2svg-Examples',
	#package : 'Pele2svg',
	#tag : 'Examples'
}

{ #category : 'examples' }
Pele2svgExamples >> architecture [
	<gtExample>
	^ self elementFor: 'architecture-beta
  group api(cloud)[API]
  service db(database)[DB] in api'
]

{ #category : 'examples' }
Pele2svgExamples >> block [
	<gtExample>
	^ self elementFor: 'block-beta
  columns 2
  a b'
]

{ #category : 'examples' }
Pele2svgExamples >> c4Context [
	<gtExample>
	^ self elementFor: 'C4Context
  Person(a, "User")
  System(b, "Sys")
  Rel(a, b, "uses")'
]

{ #category : 'examples' }
Pele2svgExamples >> classDiagram [
	<gtExample>
	^ self elementFor: 'classDiagram
  Animal <|-- Dog
  Animal : +name
  Dog : +bark()'
]

{ #category : 'private' }
Pele2svgExamples >> elementFor: aMermaidString [
	"Answer a BlSkiaSvgElement sized from the SVG viewBox."
	^ self renderer elementFromSvg: (self svgFor: aMermaidString)
]

{ #category : 'examples' }
Pele2svgExamples >> erDiagram [
	<gtExample>
	^ self elementFor: 'erDiagram
  CUSTOMER ||--o{ ORDER : places'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredAgentflow1 [
	<gtExample>
	^ self elementFor: 'agentflow-beta TB
  flow intake["Intake"]
    receive["Receive request"]@{ shape: input }
  end

  flow processing["Processing"]
    validate["Validate"]@{ shape: task }
    enrich["Enrich"]@{ shape: task }
    validate --> enrich
  end
  processing@{ view: "collapsed" }

  flow output["Output"]
    publish["Publish"]@{ shape: action }
  end

  receive --> validate
  enrich --> publish
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredAgentflow2 [
	<gtExample>
	^ self elementFor: 'agentflow-beta TB
  connector llm["LLM API"]
  llm@{ protocol: "http", endpoint: "https://api.example.com/chat" }

  flow coffee_team["Coffee Team"]
    city["city"]@{ shape: input, value: "Stockholm" }

    flow researcher["Researcher"]
      research["research_location"]@{ shape: tool, params: "city :: String", returns: "Report" }
      write["write_copy"]@{ shape: tool, connectorRef: "llm.chat", returns: "CoffeeCopy" }
      city --> research --> write
    end
    researcher@{ instruction: "Research the city and draft English coffee copy citing sources." }

    flow designer["Designer"]
      render["generate_html"]@{ shape: tool, connectorRef: "llm.chat", returns: "String" }
      brand["Nordic Brand Guide"]@{ shape: refdoc }
      render -.- brand
    end

    researcher --> designer
  end
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredArchitecture1 [
	<gtExample>
	^ self elementFor: 'architecture-beta
    service left_disk(disk)[Disk]
    service top_disk(disk)[Disk]
    service bottom_disk(disk)[Disk]
    service top_gateway(internet)[Gateway]
    service bottom_gateway(internet)[Gateway]
    junction junctionCenter
    junction junctionRight

    left_disk:R -- L:junctionCenter
    top_disk:B -- T:junctionCenter
    bottom_disk:T -- B:junctionCenter
    junctionCenter:R -- L:junctionRight
    top_gateway:B -- T:junctionRight
    bottom_gateway:T -- B:junctionRight
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredArchitecture2 [
	<gtExample>
	^ self elementFor: 'architecture-beta
    group sources(cloud)[Sources]
        service src_a(server)[Source A] in sources
        service src_b(server)[Source B] in sources
        service src_c(server)[Source C] in sources

    group storage(database)[Storage]
        service db_one(database)[DB One] in storage
        service db_two(database)[DB Two] in storage
        service db_three(database)[DB Three] in storage

    group output(disk)[Output]
        service brief(disk)[Brief] in output
        service analyst(server)[Analyst] in output
        service delivery(cloud)[Delivery] in output

    src_a:B --> T:db_one
    src_b:B --> T:db_two
    src_c:B --> T:db_three
    db_two:B --> T:brief
    brief:R --> L:analyst
    analyst:R --> L:delivery

    align row src_a src_b src_c
    align row db_one db_two db_three
    align row brief analyst delivery

    align column src_a db_one
    align column src_b db_two brief
    align column src_c db_three
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredBlock1 [
	<gtExample>
	^ self elementFor: 'block
  blockArrowId<["Label"]>(right)
  blockArrowId2<["Label"]>(left)
  blockArrowId3<["Label"]>(up)
  blockArrowId4<["Label"]>(down)
  blockArrowId5<["Label"]>(x)
  blockArrowId6<["Label"]>(y)
  blockArrowId7<["Label"]>(x, down)
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredBlock2 [
	<gtExample>
	^ self elementFor: 'block
  columns 3
  a:3
  block:group1:2
    columns 2
    h i j k
  end
  g
  block:group2:3
    %% columns auto (default)
    l m n o p q r
  end
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredC41 [
	<gtExample>
	^ self elementFor: '    C4Component
    title Component diagram for Internet Banking System - API Application

    Container(spa, "Single Page Application", "javascript and angular", "Provides all the internet banking functionality to customers via their web browser.")
    Container(ma, "Mobile App", "Xamarin", "Provides a limited subset to the internet banking functionality to customers via their mobile device.")
    ContainerDb(db, "Database", "Relational Database Schema", "Stores user registration information, hashed authentication credentials, access logs, etc.")
    System_Ext(mbs, "Mainframe Banking System", "Stores all of the core banking information about customers, accounts, transactions, etc.")

    Container_Boundary(api, "API Application") {
        Component(sign, "Sign In Controller", "MVC Rest Controller", "Allows users to sign in to the internet banking system")
        Component(accounts, "Accounts Summary Controller", "MVC Rest Controller", "Provides customers with a summary of their bank accounts")
        Component(security, "Security Component", "Spring Bean", "Provides functionality related to singing in, changing passwords, etc.")
        Component(mbsfacade, "Mainframe Banking System Facade", "Spring Bean", "A facade onto the mainframe banking system.")

        Rel(sign, security, "Uses")
        Rel(accounts, mbsfacade, "Uses")
        Rel(security, db, "Read & write to", "JDBC")
        Rel(mbsfacade, mbs, "Uses", "XML/HTTPS")
    }

    Rel_Back(spa, sign, "Uses", "JSON/HTTPS")
    Rel(spa, accounts, "Uses", "JSON/HTTPS")

    Rel(ma, sign, "Uses", "JSON/HTTPS")
    Rel(ma, accounts, "Uses", "JSON/HTTPS")

    UpdateRelStyle(spa, sign, $offsetY="-40")
    UpdateRelStyle(spa, accounts, $offsetX="40", $offsetY="40")

    UpdateRelStyle(ma, sign, $offsetX="-90", $offsetY="40")
    UpdateRelStyle(ma, accounts, $offsetY="-40")

        UpdateRelStyle(sign, security, $offsetX="-160", $offsetY="10")
        UpdateRelStyle(accounts, mbsfacade, $offsetX="140", $offsetY="10")
        UpdateRelStyle(security, db, $offsetY="-40")
        UpdateRelStyle(mbsfacade, mbs, $offsetY="-40")

'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredClass1 [
	<gtExample>
	^ self elementFor: '---
config:
  class:
    hierarchicalNamespaces: false
---
classDiagram
    namespace Earth.Volcano.Summit {
        class Crater {
            +erupt()
        }
    }
    namespace Earth.Volcano.Slope {
        class LavaFlow {
            +buildLand()
        }
    }
    namespace Earth {
        class Hotspot {
            +meltRock()
        }
    }
    Hotspot --> Crater : feeds
    Hotspot --> LavaFlow : feeds
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredClass2 [
	<gtExample>
	^ self elementFor: '---
title: Reef animal example
---
classDiagram
    note "From Turtle till Whale"
    Animal <|-- Turtle
    note for Turtle "can swim<br>can dive<br>can nest on beaches<br>can live for decades"
    Animal <|-- Shark
    Animal <|-- Whale
    Animal : +int age
    Animal : +String name
    Animal: +isMammal()
    Animal: +migrate()
    class Turtle{
        +String shellColor
        +swim()
        +nest()
    }
    class Shark{
        -int sizeInFeet
        -canHunt()
    }
    class Whale{
        +bool is_humpback
        +sing()
    }
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredCynefin1 [
	<gtExample>
	^ self elementFor: 'cynefin-beta
  title Strategy Categorization

  complex
    "Market research"

  complicated
    "Competitive analysis"

  clear
    "Standard pricing"

  chaotic
    "Crisis management"

  complex --> complicated : "Pattern identified"
  complicated --> clear : "Best practice codified"
  clear --> chaotic : "Complacency"
  chaotic --> complex : "Stabilized"
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredEr1 [
	<gtExample>
	^ self elementFor: 'erDiagram
    subgraph title1
        CUSTOMER
        CUSTOMER {
            string name
            string custNumber
            string sector
        }
    end
    subgraph title2
        CAR ||--o{ NAMED-DRIVER : allows
        subgraph title3
            PERSON
            PERSON {
                string firstName
                string lastName
                int age
            }
        end
    end
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredEr2 [
	<gtExample>
	^ self elementFor: 'erDiagram
    CAR ||--o{ NAMED-DRIVER : allows
    CAR {
        string registrationNumber PK
        string make
        string model
        string[] parts
    }
    PERSON ||--o{ NAMED-DRIVER : is
    PERSON {
        string driversLicense PK "The license #"
        string(99) firstName "Only 99 characters are allowed"
        string lastName
        string phone UK
        int age
    }
    NAMED-DRIVER {
        string carRegistrationNumber PK, FK
        string driverLicense PK, FK
    }
    MANUFACTURER only one to zero or more CAR : makes
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredEventmodeling1 [
	<gtExample>
	^ self elementFor: 'eventmodeling

timeframe 01 ui CartUI
timeframe 02 command AddItem [[AddItem01]]
timeframe 03 event ItemAdded [[ItemAdded]]
timeframe 04 command AddItem [[AddItem02]]
timeframe 05 event ItemAdded [[ItemAdded]]

data AddItem01 {
  description: ''john''
  image: ''avatar_john''
  price: 20.4
}

data AddItem02 {
  description: ''jack''
  image: ''avatar_jack''
  price: 12.5
}

data ItemAdded {
  description: string
  image: string
  price: number
}
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredEventmodeling2 [
	<gtExample>
	^ self elementFor: 'eventmodeling

timeframe 01 ui CartUI
timeframe 02 command AddItem
timeframe 03 event ItemAdded

resetframe 04 event External.InventoryChanged
timeframe 05 processor InventoryProcessor
timeframe 06 command ChangeInventory
timeframe 07 event Cart.InventoryChanged
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredFlowchart1 [
	<gtExample>
	^ self elementFor: 'flowchart LR
    subgraph subgraph1
        direction TB
        top1[top] --> bottom1[bottom]
    end
    subgraph subgraph2
        direction TB
        top2[top] --> bottom2[bottom]
    end
    %% ^ These subgraphs are identical, except for the links to them:

    %% Link *to* subgraph1: subgraph1 direction is maintained
    outside --> subgraph1
    %% Link *within* subgraph2:
    %% subgraph2 inherits the direction of the top-level graph (LR)
    outside ---> top2
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredFlowchart2 [
	<gtExample>
	^ self elementFor: '---
config:
  theme: default
  look: classic
  layout: dagre
---
flowchart LR
  subgraph Client
    UI[Web app]
    Cache[(Local cache)]
  end
  subgraph Services
    API[API gateway]
    Auth[Auth service]
    Orders[Order service]
  end
  subgraph Storage
    DB[(Orders DB)]
  end
  UI --> API
  UI --> Cache
  API --> Auth
  API --> Orders
  Orders --> DB
  Auth -. token .-> UI
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredGantt1 [
	<gtExample>
	^ self elementFor: 'gantt
    title Git Issues - days since last update
    dateFormat X
    axisFormat %s
    section Issue19062
    71   : 0, 71
    section Issue19401
    36   : 0, 36
    section Issue193
    34   : 0, 34
    section Issue7441
    9    : 0, 9
    section Issue1300
    5    : 0, 5
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredGantt2 [
	<gtExample>
	^ self elementFor: 'gantt
    title A Gantt Diagram
    %% This is a comment
    dateFormat YYYY-MM-DD
    section Section
        A task          :a1, 2014-01-01, 30d
        Another task    :after a1, 20d
    section Another
        Task in Another :2014-01-12, 12d
        another task    :24d
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredGit1 [
	<gtExample>
	^ self elementFor: '    gitGraph
        commit id: "ZERO"
        branch develop
        branch release
        commit id:"A"
        checkout main
        commit id:"ONE"
        checkout develop
        commit id:"B"
        checkout main
        merge develop id:"MERGE"
        commit id:"TWO"
        checkout release
        cherry-pick id:"MERGE" parent:"B"
        commit id:"THREE"
        checkout develop
        commit id:"C"
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredGit2 [
	<gtExample>
	^ self elementFor: '---
config:
  logLevel: ''debug''
  theme: ''neutral''
---
      gitGraph
        commit
        branch hotfix
        checkout hotfix
        commit
        branch develop
        checkout develop
        commit id:"ash" tag:"abc"
        branch featureB
        checkout featureB
        commit type:HIGHLIGHT
        checkout main
        checkout hotfix
        commit type:NORMAL
        checkout develop
        commit type:REVERSE
        checkout featureB
        commit
        checkout main
        merge hotfix
        checkout featureB
        commit
        checkout develop
        branch featureA
        commit
        checkout develop
        merge hotfix
        checkout featureA
        commit
        checkout featureB
        commit
        checkout develop
        merge featureA
        branch release
        checkout release
        commit
        checkout main
        commit
        checkout release
        merge main
        checkout develop
        merge release
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredIshikawa1 [
	<gtExample>
	^ self elementFor: 'ishikawa-beta
    Blurry Photo
    Process
        Out of focus
        Shutter speed too slow
        Protective film not removed
        Beautification filter applied
    User
        Shaky hands
    Equipment
        LENS
            Inappropriate lens
            Damaged lens
            Dirty lens
        SENSOR
            Damaged sensor
            Dirty sensor
    Environment
        Subject moved too quickly
        Too dark
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredJourney1 [
	<gtExample>
	^ self elementFor: 'journey
    title My working day
    section Go to work
      Make tea: 5: Me
      Go upstairs: 3: Me
      Do work: 1: Me, Cat
    section Go home
      Go downstairs: 5: Me
      Sit down: 5: Me
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredKanban1 [
	<gtExample>
	^ self elementFor: 'kanban
todo[Todo]
  id3[Update Database Function]@{ ticket: MC-2037, assigned: ''knsv'', priority: ''High'' }
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredKanban2 [
	<gtExample>
	^ self elementFor: '---
config:
  kanban:
    ticketBaseUrl: ''https://mermaidchart.atlassian.net/browse/#TICKET#''
---
kanban
  Todo
    [Create Documentation]
    docs[Create Blog about the new diagram]
  [In progress]
    id6[Create renderer so that it works in all cases. We also add some extra text here for testing purposes. And some more just for the extra flare.]
  id9[Ready for deploy]
    id8[Design grammar]@{ assigned: ''knsv'' }
  id10[Ready for test]
    id4[Create parsing tests]@{ ticket: MC-2038, assigned: ''K.Sveidqvist'', priority: ''High'' }
    id66[last item]@{ priority: ''Very Low'', assigned: ''knsv'' }
  id11[Done]
    id5[define getData]
    id2[Title of diagram is more than 100 chars when user duplicates diagram with 100 char]@{ ticket: MC-2036, priority: ''Very High''}
    id3[Update DB function]@{ ticket: MC-2037, assigned: knsv, priority: ''High'' }

  id12[Can''t reproduce]
    id3[Weird flickering in Firefox]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredMindmap1 [
	<gtExample>
	^ self elementFor: 'mindmap
  root((Hawaiʻi))
    History
      Old legends
      ::icon(fa fa-book)
      Voyaging
        Polynesian navigators who sailed by the stars
    Nature
      Mountains<br/>and volcanoes
      Ocean life
        Reef
            Sea turtles
            Monk seals
            Parrotfish
    Culture
      Hula and lei
      ʻUkulele
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredMindmap2 [
	<gtExample>
	^ self elementFor: 'mindmap
    id1["`**Pele** is the
goddess of volcanoes
Unicode works too: 🌋`"]
      id2["`She lives in **the** crater of Kīlauea... a *very old story* that is still told today`"]
      id3[Lava builds new land]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredPacket1 [
	<gtExample>
	^ self elementFor: '---
title: "TCP Packet"
---
packet
0-15: "Source Port"
16-31: "Destination Port"
32-63: "Sequence Number"
64-95: "Acknowledgment Number"
96-99: "Data Offset"
100-105: "Reserved"
106: "URG"
107: "ACK"
108: "PSH"
109: "RST"
110: "SYN"
111: "FIN"
112-127: "Window"
128-143: "Checksum"
144-159: "Urgent Pointer"
160-191: "(Options and Padding)"
192-255: "Data (variable length)"
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredPacket2 [
	<gtExample>
	^ self elementFor: '---
config:
  packet:
    showBits: true
    bitOrder: descending
    bitsPerRow: 16
---
packet
0-7: "DATA"
8-11: "TYPE"
12: "EN"
13-15: "RESERVED"
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredPie1 [
	<gtExample>
	^ self elementFor: 'pie title Fish caught by the crew
    "ʻAhi" : 386
    "Mahimahi" : 85
    "Ono" : 15
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredQuadrant1 [
	<gtExample>
	^ self elementFor: 'quadrantChart
    title Reach and engagement of campaigns
    x-axis Low Reach --> High Reach
    y-axis Low Engagement --> High Engagement
    quadrant-1 We should expand
    quadrant-2 Need to promote
    quadrant-3 Re-evaluate
    quadrant-4 May be improved
    Campaign A: [0.3, 0.6]
    Campaign B: [0.45, 0.23]
    Campaign C: [0.57, 0.69]
    Campaign D: [0.78, 0.34]
    Campaign E: [0.40, 0.34]
    Campaign F: [0.35, 0.78]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredRadar1 [
	<gtExample>
	^ self elementFor: 'radar-beta
  title Restaurant Comparison
  axis food["Food Quality"], service["Service"], price["Price"]
  axis ambiance["Ambiance"]

  curve a["Restaurant A"]{4, 3, 2, 4}
  curve b["Restaurant B"]{3, 4, 3, 3}
  curve c["Restaurant C"]{2, 3, 4, 2}
  curve d["Restaurant D"]{2, 2, 4, 3}

  graticule polygon
  max 5

'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredRadar2 [
	<gtExample>
	^ self elementFor: '---
title: "Grades"
---
radar-beta
  axis m["Math"], s["Science"], e["English"]
  axis h["History"], g["Geography"], a["Art"]
  curve a["Alice"]{85, 90, 80, 70, 75, 90}
  curve b["Bob"]{70, 75, 85, 80, 90, 85}

  max 100
  min 0
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredRailroad1 [
	<gtExample>
	^ self elementFor: 'railroad-ebnf-beta
title "Arithmetic Expression Grammar"

expression = term ( ( "+" | "-" ) term )* ;
term = factor ( ( "*" | "/" ) factor )* ;
factor = number | "(" expression ")" ;
number = digit+ ;
digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredRailroad2 [
	<gtExample>
	^ self elementFor: 'railroad-beta
title Expression Grammar

expression = sequence(
    nonterminal("term"),
    zeroOrMore(sequence(
        choice(terminal("+"), terminal("-")),
        nonterminal("term")
    ))
) ;
term = sequence(
    nonterminal("factor"),
    zeroOrMore(sequence(
        choice(terminal("*"), terminal("/")),
        nonterminal("factor")
    ))
) ;
factor = choice(
    nonterminal("number"),
    sequence(terminal("("), nonterminal("expression"), terminal(")"))
) ;
number = oneOrMore(nonterminal("digit")) ;
digit = choice(terminal("0"), terminal("1"), terminal("2"), terminal("3"), terminal("4"), terminal("5"), terminal("6"), terminal("7"), terminal("8"), terminal("9")) ;
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredRequirement1 [
	<gtExample>
	^ self elementFor: '---
config:
  theme: default
  look: classic
  layout: dagre
---
requirementDiagram
  requirement checkout_req {
    id: 1
    text: Orders must be payable online.
    risk: high
    verifymethod: test
  }
  functionalRequirement payment_req {
    id: 1.1
    text: Card payments must be authorized.
    risk: high
    verifymethod: test
  }
  element checkout_service {
    type: service
  }
  checkout_req - contains -> payment_req
  checkout_service - satisfies -> payment_req
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredRequirement2 [
	<gtExample>
	^ self elementFor: 'requirementDiagram

direction LR

requirement test_req {
    id: 1
    text: the test text.
    risk: high
    verifymethod: test
}

element test_entity {
    type: simulation
}

test_entity - satisfies -> test_req
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredSankey1 [
	<gtExample>
	^ self elementFor: '---
config:
  sankey:
    showValues: false
    nodeWidth: 15
    nodePadding: 20
---
sankey

Electricity grid,Heating and cooling - homes,113.726
Electricity grid,Industry,342.165
Electricity grid,Losses,56.691
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredSankey2 [
	<gtExample>
	^ self elementFor: 'sankey

%% source,target,value
Electricity grid,Over generation / exports,104.453
Electricity grid,Heating and cooling - homes,113.726
Electricity grid,H2 conversion,27.14
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredSequence1 [
	<gtExample>
	^ self elementFor: '---
config:
  theme: default
  look: classic
---
sequenceDiagram
  autonumber
  actor Customer
  participant Web as Web app
  participant API as API gateway
  participant Bank
  Customer->>Web: Place order
  Web->>API: POST /orders
  activate API
  API->>Bank: Authorize payment
  Bank-->>API: Approved
  API-->>Web: 201 Created
  deactivate API
  Web-->>Customer: Order confirmed
  Note over Customer,Bank: One order, one transaction
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredSequence2 [
	<gtExample>
	^ self elementFor: 'sequenceDiagram
    participant Alice
    participant John
    link Alice: Dashboard @ https://dashboard.contoso.com/alice
    link Alice: Wiki @ https://wiki.contoso.com/alice
    link John: Dashboard @ https://dashboard.contoso.com/john
    link John: Wiki @ https://wiki.contoso.com/john
    Alice->>John: Hello John, how are you?
    John-->>Alice: Great!
    Alice-)John: See you later!
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredState1 [
	<gtExample>
	^ self elementFor: '---
config:
  theme: default
  look: classic
  layout: dagre
---
stateDiagram-v2
  [*] --> Draft
  Draft --> Submitted : submit
  state Review {
    [*] --> Screening
    Screening --> Decision
  }
  Submitted --> Review
  Review --> Published : approved
  Review --> Draft : rejected
  Published --> [*]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredState2 [
	<gtExample>
	^ self elementFor: 'stateDiagram-v2
    [*] --> Active

    state Active {
        [*] --> NumLockOff
        NumLockOff --> NumLockOn : EvNumLockPressed
        NumLockOn --> NumLockOff : EvNumLockPressed
        --
        [*] --> CapsLockOff
        CapsLockOff --> CapsLockOn : EvCapsLockPressed
        CapsLockOn --> CapsLockOff : EvCapsLockPressed
        --
        [*] --> ScrollLockOff
        ScrollLockOff --> ScrollLockOn : EvScrollLockPressed
        ScrollLockOn --> ScrollLockOff : EvScrollLockPressed
    }
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredSwimlane1 [
	<gtExample>
	^ self elementFor: 'swimlane-beta LR
  subgraph Customer
    request[Request service]
    receive[Receive update]
  end

  subgraph Support
    triage[Triage request]
    answer[Send answer]
  end

  subgraph Engineering
    investigate[Investigate issue]
    fix[Prepare fix]
  end

  request --> triage
  triage -->|Known issue| answer
  triage -->|Needs code change| investigate
  investigate --> fix --> answer
  answer --> receive
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredSwimlane2 [
	<gtExample>
	^ self elementFor: 'swimlane-beta LR
  subgraph Applicant
    apply[Submit application]
    sign[Sign agreement]
  end

  subgraph Reviewer
    screen[Screen application]
    decide{Approved?}
  end

  subgraph System
    create[Create account]
    notify[Send welcome email]
  end

  apply -->|Application received| screen
  screen --> decide
  decide -->|Approved| create --> notify --> sign
  decide -->|Needs changes| apply
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredTimeline1 [
	<gtExample>
	^ self elementFor: 'timeline
    title Timeline of the Hawaiian Islands
    section Older islands
        Kauaʻi : 5 million years old, Canyons, Sea <br>cliffs
        Oʻahu : 3 million years old, Diamond Head, Surf breaks
        Molokaʻi : 2 million years old, Fishponds, Tall cliffs
    section Younger islands
        Maui : 1 million years old, Haleakalā, Whale watching
        Hawaiʻi : Still growing, Mauna Kea, Kīlauea
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredTimeline2 [
	<gtExample>
	^ self elementFor: 'timeline
        title Hawaiʻi''s History Timeline
        section Voyagers
          1000 AD : Polynesian voyagers reach Hawaiʻi in sailing canoes
          1778 : Captain Cook lands on Kauaʻi.<br> Islanders and Europeans meet for the first time.
        section Kingdom
          1810 : King Kamehameha unites the islands. <br>They are ruled as one kingdom for the first time.
                  : Ships from around the world stop to trade.
          1882 : ʻIolani Palace is completed in Honolulu.<br> It soon has electric lights and telephones.
                  : Most people in the kingdom can read and write.
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredTreemap1 [
	<gtExample>
	^ self elementFor: '---
config:
  treemap:
    valueFormat: ''$0,0''
---
treemap-beta
"Budget"
    "Operations"
        "Salaries": 700000
        "Equipment": 200000
        "Supplies": 100000
    "Marketing"
        "Advertising": 400000
        "Events": 100000
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredTreemap2 [
	<gtExample>
	^ self elementFor: 'treemap-beta
"Products"
    "Electronics"
        "Phones": 50
        "Computers": 30
        "Accessories": 20
    "Clothing"
        "Men''s": 40
        "Women''s": 40
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredTreeview1 [
	<gtExample>
	^ self elementFor: '---
config:
  treeView:
    showIcons: true
    defaultIconPack: material-icon-theme
    filenameIcons:
      Dockerfile: docker
    extensionIcons:
      .ts: typescript
      .tsx: react-ts
      .txt: none
---
treeView-beta
    src/
        App.tsx
        utils.ts
    Dockerfile
    notes.txt
    README.md
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredTreeview2 [
	<gtExample>
	^ self elementFor: 'treeView-beta
    my-project/
        src/
            App.tsx :::highlight icon(logos:react) ## main component
            index.js ## entry point
        .env ## environment variables
        Dockerfile
        package.json
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredUsecase1 [
	<gtExample>
	^ self elementFor: '---
config:
  usecase:
    actorFontSize: 16
    actorFontFamily: Arial
    actorFontWeight: bold
    usecaseFontSize: 14
    usecaseFontFamily: Georgia
    usecaseFontWeight: normal
    nodeSpacing: 60
    rankSpacing: 70
    diagramPadding: 24
    colorScheme: role
    useMaxWidth: false
---
usecase-beta
direction LR
actor Customer
Browse("Browse catalog")
Customer --> Browse
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredUsecase2 [
	<gtExample>
	^ self elementFor: '---
config:
  theme: default
  look: classic
  layout: dagre
---
usecase-beta
direction LR
actor Customer
actor Support
systemBoundary Storefront
  Browse("Browse catalog")
  Checkout("Checkout")
end
systemBoundary Fulfilment
  Track("Track delivery")
end
Customer --> Browse
Customer --> Checkout
Customer --> Track
Support --> Track
Checkout ..> : include Browse
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredVenn1 [
	<gtExample>
	^ self elementFor: '---
config:
  theme: default
  look: classic
---
venn-beta
  title What makes a good feature
  set Desirable
  set Feasible
  set Viable
  union Desirable,Feasible["Buildable"]
  union Feasible,Viable["Sustainable"]
  union Desirable,Viable["Marketable"]
  union Desirable,Feasible,Viable["Ship it"]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredVenn2 [
	<gtExample>
	^ self elementFor: 'venn-beta
  set A["Frontend"]
    text A1["React"]
    text A2["Design Systems"]
  set B["Backend"]
    text B1["API"]
  union A,B["Shared"]
    text AB1["OpenAPI"]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredWardley1 [
	<gtExample>
	^ self elementFor: 'wardley-beta
title Tea Shop Value Chain

anchor Business [0.95, 0.63]
component Cup of Tea [0.79, 0.61]
component Tea [0.63, 0.81]
component Hot Water [0.52, 0.80]
component Kettle [0.43, 0.35]
component Power [0.10, 0.70]

Business -> Cup of Tea
Cup of Tea -> Tea
Cup of Tea -> Hot Water
Hot Water -> Kettle
Kettle -> Power

evolve Kettle 0.62
evolve Power 0.89

note "Standardizing power allows Kettles to evolve faster" [0.30, 0.49]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredWardley2 [
	<gtExample>
	^ self elementFor: 'wardley-beta
title Sourcing Strategy

anchor Customer [0.80, 0.95]
component Custom App [0.45, 0.85] (build)
component Off-the-shelf Tool [0.85, 0.65] (buy)
component Managed Service [0.60, 0.40] (outsource)
component Cloud Platform [0.95, 0.25] (market)

Customer -> Custom App
Custom App -> Off-the-shelf Tool
Custom App -> Managed Service
Off-the-shelf Tool -> Cloud Platform
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredXychart1 [
	<gtExample>
	^ self elementFor: 'xychart
    title "Ocean Temperature"
    x-axis [jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec]
    y-axis "Temperature (in °F)" 74 --> 82
    bar [76.3, 75.9, 76.0, 76.7, 77.8, 78.9, 79.9, 80.7, 81.1, 80.5, 79.1, 77.4]
    line [76.3, 75.9, 76.0, 76.7, 77.8, 78.9, 79.9, 80.7, 81.1, 80.5, 79.1, 77.4]
'
]

{ #category : 'examples' }
Pele2svgExamples >> featuredXychart2 [
	<gtExample>
	^ self elementFor: '---
config:
    xyChart:
        showDataLabel: true
        showDataLabelOutsideBar: true
---
xychart
    title "Animals seen in reef survey of 2025"
    x-axis [turtles, eels, tangs, wrasses, "parrot fish", other]
    y-axis "Number of Animals" 0 --> 30
    bar [12,2,20,25,17,24]
'
]

{ #category : 'examples' }
Pele2svgExamples >> flowchart [
	<gtExample>
	^ self elementFor: 'flowchart LR
  A[Start] --> B{OK?}
  B -- yes --> C[Done]
  B -- no --> D[Retry]
  D --> B'
]

{ #category : 'examples' }
Pele2svgExamples >> flowchartSubgraph [
	<gtExample>
	^ self elementFor: 'flowchart TB
  subgraph GT
    direction LR
    Coder --> Inspector
  end
  subgraph Pharo
    VM --> Image
  end
  GT --> Pharo'
]

{ #category : 'examples' }
Pele2svgExamples >> gantt [
	<gtExample>
	^ self elementFor: 'gantt
  title Plan
  dateFormat YYYY-MM-DD
  section A
  Task1 :a1, 2026-01-01, 5d'
]

{ #category : 'examples' }
Pele2svgExamples >> gitGraph [
	<gtExample>
	^ self elementFor: 'gitGraph
  commit
  branch dev
  commit
  checkout main
  merge dev'
]

{ #category : 'examples' }
Pele2svgExamples >> invalidSourceSignalsError [
	<gtExample>
	| message |
	message := [ self renderer render: 'this is not mermaid(((' . nil ]
		on: Pele2svgError
		do: [ :error | error messageText ].
	self assert: message isNotNil.
	^ message
]

{ #category : 'examples' }
Pele2svgExamples >> japaneseLabels [
	<gtExample>
	^ self elementFor: 'flowchart LR
  A[開始] --> B{判定}
  B -- はい --> C[完了]
  B -- いいえ --> D[再試行]'
]

{ #category : 'examples' }
Pele2svgExamples >> journey [
	<gtExample>
	^ self elementFor: 'journey
  title Day
  section Work
  Code: 5: Me'
]

{ #category : 'examples' }
Pele2svgExamples >> kanban [
	<gtExample>
	^ self elementFor: 'kanban
  todo[Todo]
    t1[Task]'
]

{ #category : 'examples' }
Pele2svgExamples >> mindmap [
	<gtExample>
	^ self elementFor: 'mindmap
  root((GT))
    Pharo
    Skia'
]

{ #category : 'examples' }
Pele2svgExamples >> optionsDefaults [
	<gtExample>
	| options |
	options := Pele2svgOptions globalDefault.
	self assert: (options at: #runtime) equals: 'node'.
	self assert: (options at: #timeout) equals: 30000.
	self assert: (options at: #installTimeout) equals: 300000.
	self assert: (options at: #theme) isNil.
	self assert: (options at: #script) isNil.
	^ options
]

{ #category : 'examples' }
Pele2svgExamples >> optionsDuringIsLocal [
	<gtExample>
	"A clone of the global default, activated for a block only."

	| options inside |
	options := Pele2svgOptions globalDefault clone at: #runtime put: 'bun'; yourself.
	inside := options during: [ self renderer runtime ].
	self assert: inside equals: 'bun'.
	self assert: self renderer runtime equals: 'node'.
	^ options
]

{ #category : 'examples' }
Pele2svgExamples >> optionsEnclosingDuringWins [
	<gtExample>
	"The options of an enclosing #during: take precedence over what was set on the converter."

	| pele inside |
	pele := self renderer runtime: '/path/to/node'; yourself.
	inside := Pele2svgOptions globalDefault clone
		at: #runtime put: 'bun';
		during: [ pele runtime ].
	self assert: inside equals: 'bun'.
	self assert: pele runtime equals: '/path/to/node'.
	^ pele
]

{ #category : 'examples' }
Pele2svgExamples >> optionsGlobalDefaultIsWritable [
	<gtExample>
	"Changing the global default changes every converter that has not been set otherwise. The example restores the default."

	| changed |
	changed := [
		Pele2svgOptions globalDefault at: #runtime put: 'bun'.
		self renderer runtime ]
			ensure: [ Pele2svgOptions resetGlobalDefault ].
	self assert: changed equals: 'bun'.
	self assert: self renderer runtime equals: 'node'.
	^ changed
]

{ #category : 'examples' }
Pele2svgExamples >> optionsRootIsReadOnly [
	<gtExample>
	| root message |
	root := Pele2svgOptions root.
	message := [ root at: #runtime put: 'bun'. nil ]
		on: ModificationForbidden
		do: [ :error | error messageText ].
	self assert: message isNotNil.
	^ root
]

{ #category : 'examples' }
Pele2svgExamples >> optionsRuntimeReachesTheProcess [
	<gtExample>
	"A runtime that cannot be started is reported as Pele2svgError, which shows that the option reaches the process."

	| message |
	message := [
		self renderer runtime: 'no-such-runtime-for-pele2svg'; render: 'flowchart LR
  A --> B'.
		nil ]
			on: Pele2svgError
			do: [ :error | error messageText ].
	self assert: message isNotNil.
	^ message
]

{ #category : 'examples' }
Pele2svgExamples >> optionsSetOnTheInstance [
	<gtExample>
	"What is set on a converter is kept in the converter, as in a ZnClient. Another converter is not affected."

	| pele |
	pele := self renderer runtime: 'bun'; timeout: 5000; yourself.
	self assert: pele runtime equals: 'bun'.
	self assert: pele timeout equals: 5000.
	self assert: pele theme isNil.
	self assert: self renderer runtime equals: 'node'.
	^ pele
]

{ #category : 'examples' }
Pele2svgExamples >> optionsUnknownKeyIsRejected [
	<gtExample>
	| message |
	message := [ Pele2svgOptions globalDefault at: #nope put: 1. nil ]
		on: KeyNotFound
		do: [ :error | error messageText ].
	self assert: message isNotNil.
	^ message
]

{ #category : 'examples' }
Pele2svgExamples >> pieChart [
	<gtExample>
	^ self elementFor: 'pie title Pets
  "Dogs" : 5
  "Cats" : 3'
]

{ #category : 'examples' }
Pele2svgExamples >> quadrantChart [
	<gtExample>
	^ self elementFor: 'quadrantChart
  title T
  x-axis Low --> High
  y-axis Low --> High
  A: [0.3, 0.6]'
]

{ #category : 'private' }
Pele2svgExamples >> renderer [
	"The converter used by all examples."
	^ Pele2svg new
]

{ #category : 'examples' }
Pele2svgExamples >> requirementDiagram [
	<gtExample>
	^ self elementFor: 'requirementDiagram
  requirement r1 {
    id: 1
    text: x
    risk: low
    verifymethod: test
  }'
]

{ #category : 'examples' }
Pele2svgExamples >> sankey [
	<gtExample>
	^ self elementFor: 'sankey-beta
A,B,10'
]

{ #category : 'examples' }
Pele2svgExamples >> sequenceDiagram [
	<gtExample>
	^ self elementFor: 'sequenceDiagram
  Alice->>Bob: Hello
  Bob-->>Alice: Hi'
]

{ #category : 'examples' }
Pele2svgExamples >> sequenceLoopAndNote [
	<gtExample>
	^ self elementFor: 'sequenceDiagram
  participant GT
  participant Node
  GT->>Node: run pele2svg
  loop until exit
    Node-->>GT: wait
  end
  Note over GT,Node: timeout 30 s'
]

{ #category : 'examples' }
Pele2svgExamples >> stateDiagram [
	<gtExample>
	^ self elementFor: 'stateDiagram-v2
  [*] --> Idle
  Idle --> Running
  Running --> [*]'
]

{ #category : 'private' }
Pele2svgExamples >> svgFor: aMermaidString [
	| svg |
	svg := self renderer render: aMermaidString.
	self assert: (svg beginsWith: '<svg').
	self assert: (svg includesSubstring: 'var(') not.
	self assert: (svg includesSubstring: '<style') not.
	^ svg
]

{ #category : 'examples' }
Pele2svgExamples >> themeFromDictionary [
	<gtExample>
	| svg |
	svg := self renderer
			theme: {'--pele-fg' -> '#abcdef'} asDictionary;
			render: 'sequenceDiagram
  Alice->>Bob: Hello'.
	self assert: (svg includesSubstring: '#abcdef').
	^ self elementFor: 'sequenceDiagram
  Alice->>Bob: Hello'
]

{ #category : 'examples' }
Pele2svgExamples >> timeline [
	<gtExample>
	^ self elementFor: 'timeline
  title History
  2020 : A
  2021 : B'
]

{ #category : 'examples' }
Pele2svgExamples >> xyChart [
	<gtExample>
	^ self elementFor: 'xychart-beta
  x-axis [a, b, c]
  bar [1, 2, 3]'
]
