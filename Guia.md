Claro. Agora vou refazer como **guia-mãe definitivo do SpaceRails**, partindo do princípio correto:

# **SPACERAILS É RAILS FULL-STACK**

### Rails governa backend, domínio, renderização e experiência da interface.

Esse documento deve impedir tanto o **design genérico de IA** quanto a tendência de algum agente olhar para uma animação complexa e decidir “vamos meter React nisso”.

Eu salvaria como:

```text
docs/ai/SPACERAILS_AI_GUIDE.md
```

e colocaria uma referência obrigatória no `AGENTS.md`.

---

# SPACERAILS — AI DEVELOPMENT & EXPERIENCE GUIDE

## **Mandatory Rails Full-Stack Product Contract**

### World Design · UI/UX · Rails Architecture · Interaction · Quality

```text
PROJECT
────────────────────────────────────────────
SpaceRails

APPLICATION ARCHITECTURE
────────────────────────────────────────────
Ruby on Rails Full-Stack

BACKEND
────────────────────────────────────────────
Rails

FRONTEND / PRESENTATION
────────────────────────────────────────────
Rails application
Server-rendered architecture and the
existing Rails frontend stack

DOMAIN / DATABASE
────────────────────────────────────────────
Rails / Active Record / existing persistence

PRODUCT NATURE
────────────────────────────────────────────
Interactive interstellar scientific database
Diegetic scientific-station experience

PRIMARY EXPERIENCE
────────────────────────────────────────────
The user should feel they are operating
systems inside a scientific space facility.

NOT
────────────────────────────────────────────
Generic sci-fi website
SaaS dashboard
CRUD with a space wallpaper
Cyberpunk admin panel
React SPA
Generic card interface
```

# 1. REGRA ABSOLUTA

SpaceRails não é:

> um CRUD em Rails que recebeu uma skin espacial.

SpaceRails é:

# **uma estação científica interativa construída como aplicação Rails.**

Os dados são reais.

O domínio é real.

O CRUD é real.

Mas a experiência deve fazer essas operações parecerem ações executadas em:

* laboratórios;
* terminais;
* arquivos científicos;
* câmaras;
* sistemas de observação;
* instalações de pesquisa.

---

# 2. PRINCÍPIO CENTRAL

# **DON'T DESIGN PAGES. BUILD THE FACILITY.**

Não pensar:

```text
Aliens page
Planets page
Powers page
```

Pensar:

```text
Xenobiology Laboratory
Planetary Observation Facility
Anomalous Energy Research Sector
```

Cada rota representa acesso a um setor da mesma instalação.

---

# 3. SEGUNDO PRINCÍPIO

# **DON'T PUT DATA IN CARDS. MAKE THE FACILITY READ THE DATA.**

Evitar:

```text
┌────────────────────┐
│ Alien              │
│ Name: Testao       │
│ Planet: B          │
│ Power: Fire        │
└────────────────────┘
```

Preferir algo conceitualmente como:

```text
SUBJECT ANALYSIS // A-001

IDENTIFICATION
Testao

ORIGIN
Planet B

REGISTERED ABILITY
Fire

BIOLOGICAL STATUS
CATALOGUED
```

O dado continua vindo da aplicação Rails.

Somente sua apresentação muda.

---

# 4. RAILS FULL-STACK CONTRACT

Rails é a arquitetura da aplicação inteira.

Antes de qualquer mudança, assumir:

```text
Rails owns the domain.
Rails owns persistence.
Rails owns routing.
Rails owns request handling.
Rails owns server rendering.
Rails owns the primary application lifecycle.
```

Não assumir que existe:

* React;
* Vue;
* Next.js;
* frontend separado;
* API frontend/backend;
* SPA.

---

# 5. NÃO “MODERNIZAR” O PROJETO SEM AUTORIZAÇÃO

PROIBIDO introduzir por conta própria:

```text
React
Vue
Next.js
Nuxt
Vite SPA architecture
Redux
Zustand
frontend API layer
GraphQL
separate Node frontend
```

porque uma interface possui animações ou interações complexas.

Uma experiência visual sofisticada não exige abandonar Rails.

---

# 6. NÃO CRIAR API PARA RESOLVER PROBLEMA DE VIEW

Se Rails já possui os dados necessários durante a request:

não criar:

```text
GET /api/aliens/:id
```

apenas para um componente poder exibir um alien.

Primeiro verificar se a arquitetura existente pode resolver através de:

* controller;
* view;
* partial;
* Turbo;
* Stimulus;
* server rendering;
* mecanismos Rails já presentes.

---

# 7. ANTES DE PROGRAMAR: AUDITORIA RAILS

Todo agente deve primeiro identificar a arquitetura REAL do projeto.

Auditar:

```text
config/routes.rb

app/controllers
app/models
app/views
app/helpers

layouts
partials

services
form objects
concerns
presenters
components
se existirem

JavaScript existente

Stimulus
Turbo
Hotwire
se existirem

CSS architecture
asset pipeline
import strategy

Active Record relationships
validations
callbacks

migrations
schema

tests
```

Não presumir stack.

# Ler o projeto.

---

# 8. NÃO ALTERAR DOMÍNIO PARA CONSEGUIR VISUAL

Uma alteração de:

```text
layout
animation
laboratory environment
scanner
drawer
archive
```

não autoriza alteração automática em:

```text
model
database
migration
association
business rule
validation
controller semantics
```

---

# 9. DOMAIN FIRST

Dados reais continuam pertencendo ao domínio Rails.

Exemplo:

```text
Alien
Planet
Power
```

ou as entidades reais existentes.

Não criar entidades fictícias como:

```text
LaboratoryPanel
ScannerAnimation
ContainmentVisualState
StationDecoration
```

no banco apenas por causa da apresentação.

---

# 10. ACTIVE RECORD CONTINUA SOURCE OF TRUTH

Não duplicar estado de domínio no JavaScript.

Evitar:

```text
Rails Alien
+
JS Alien Store
+
JSON cache
+
client state
```

para operações que o Rails já controla.

---

# 11. JAVASCRIPT É PARA INTERAÇÃO

JavaScript deve ser utilizado principalmente para:

```text
animation
mechanical response
scanner sequence
chamber behavior
panel reveal
window movement
ambient motion
small client interactions
```

Não para reconstruir Rails no navegador.

---

# 12. STIMULUS / HOTWIRE / TURBO

Se o projeto já utiliza essas tecnologias:

# preferir a arquitetura existente.

Exemplos adequados:

```text
Stimulus controller
→ controlar scanner

Stimulus controller
→ abrir/fechar janela

Stimulus controller
→ sequência visual da chamber

Turbo
→ atualizar conteúdo sem reconstruir SPA
```

Não introduzir Hotwire apenas porque este documento mencionou Hotwire.

Primeiro auditar.

---

# 13. NÃO RECRIAR REACT MANUALMENTE

Evitar JavaScript com:

* state manager global;
* virtual component hierarchy;
* manual client-side routing;
* duplicação dos models;
* renderização completa do app pelo browser;

se Rails já governa essas responsabilidades.

---

# 14. RAILS VIEW DISCIPLINE

Diegese não justifica:

```text
index.html.erb
→ 2.400 linhas
```

Extrair partials quando correspondem a unidades reais da experiência.

Exemplos possíveis:

```text
_specimen_chamber.html.erb
_subject_terminal.html.erb
_bio_scanner.html.erb
_specimen_archive.html.erb
_archive_file.html.erb
_facility_status.html.erb
```

---

# 15. NÃO FRAGMENTAR POR FRAGMENTAR

Também evitar:

```text
_line.html.erb
_small_label.html.erb
_single_icon.html.erb
```

sem reutilização ou responsabilidade clara.

Partial deve representar:

> uma unidade visual/conceitual significativa.

---

# 16. HELPERS

Usar helpers para apresentação quando adequado.

Não esconder business logic complexa em helper.

---

# 17. CONTROLLERS

Controllers devem continuar coordenando requests.

Não empurrar lógica de negócio para controller apenas porque uma tela nova precisa dela.

---

# 18. MODELS

Não transformar models em depósito de comportamento visual.

---

# 19. WORLD DESIGN CONTRACT

Todo componente importante deve responder:

> **O que este objeto é dentro da estação?**

Exemplos:

```text
Generic card
→ scientific file

Modal
→ terminal / analysis interface

Sidebar
→ sector control rail

Image panel
→ observation chamber

Progress bar
→ scanner readout

List
→ archive index

Status badge
→ system status

Form
→ registration console
```

---

# 20. SE A RESPOSTA FOR “É UM CARD”

Provavelmente o design ainda está genérico.

---

# 21. WORLD REACTS TO DATA

Regra crítica:

# **THE FACILITY MUST REACT TO THE OPERATION.**

Exemplo:

```text
user selects specimen
↓
selection state changes
↓
chamber activates
↓
scan sequence responds
↓
specimen becomes visible
↓
terminal receives data
↓
related instruments react
```

Isso pode envolver:

* Rails-rendered content;
* Turbo;
* Stimulus;
* CSS animations;

conforme a arquitetura existente.

---

# 22. NÃO TRANSFORMAR REAÇÃO VISUAL EM NOVA REGRA DE NEGÓCIO

`scanner active` pode ser estado visual.

Não precisa virar:

```ruby
alien.scanning = true
```

salvo se isso realmente tiver semântica persistente no produto.

---

# 23. SPACE OUTSIDE. FACILITY INSIDE.

Essa é uma regra visual central.

## Exterior

```text
black
deep navy
stars
planets
comets
distant objects
cosmic light
```

## Interior

```text
white
ivory
bright metal
glass
cyan
scientific equipment
clean illumination
```

---

# 24. CONTRASTE ENTRE OS DOIS MUNDOS

O espaço representa:

> vastidão e exterior.

A instalação representa:

> controle e ciência.

Não transformar todo o projeto em um ambiente escuro só porque é sci-fi.

---

# 25. CIANO

Ciano é a cor operacional principal.

Representa:

```text
system active
scan
analysis
energy
interaction
reading
```

Não espalhar ciano indiscriminadamente.

---

# 26. CYAN ≠ NEON CYBERPUNK

O ciano deve lembrar:

> instrumentação científica.

Não:

> nightclub futurista.

---

# 27. MATERIALIDADE

Preferir:

```text
white polymer
light metal
brushed metal
glass
acrylic
medical material
scientific equipment
```

---

# 28. NÃO CONSTRUIR TUDO COM DIVS TRANSPARENTES

O usuário deve perceber objetos.

Não apenas:

```text
rectangle
rectangle
rectangle
rectangle
```

---

# 29. GLASS

Vidro deve possuir função física.

Exemplo:

* chamber;
* protective screen;
* observation window;
* monitor layer.

Não simplesmente:

> glassmorphism porque é futurista.

---

# 30. ANTI-GLASSMORPHISM RULE

Não usar automaticamente:

```css
background: rgba(...);
backdrop-filter: blur(...);
border: 1px solid rgba(...);
border-radius: 24px;
```

em toda surface.

---

# 31. SHADOW

Sombras devem sugerir objeto físico:

* equipamento afastado da parede;
* painel projetado;
* chamber;
* terminal.

Não aplicar `shadow-xl` em tudo.

---

# 32. BORDER RADIUS

Não usar o mesmo radius universal.

Objetos diferentes possuem construções diferentes.

Exemplo:

```text
laboratory machine
→ industrial rounded corners

archive file
→ flatter geometry

monitor
→ small radius

containment tube
→ strongly rounded physical shape
```

---

# 33. DEPTH

O ambiente deve possuir profundidade.

Pensar em:

```text
FOREGROUND
equipment / archive

MIDGROUND
laboratory workspace

BACKGROUND
facility wall / windows

EXTERIOR
space
```

---

# 34. ALIENS SECTOR

Conceito oficial:

# **XENOBIOLOGY LABORATORY**

Função:

```text
register
catalogue
observe
analyse
inspect
archive
```

---

# 35. ASSINATURA DO ALIENS SECTOR

Principal equipamento:

# **SPECIMEN CONTAINMENT CHAMBER**

O alien selecionado deve ser apresentado através dela.

---

# 36. CHAMBER EMPTY

Quando nenhum espécime estiver selecionado:

pode comunicar:

```text
CHAMBER 01

NO SPECIMEN

READY
```

ou linguagem consistente equivalente.

---

# 37. CHAMBER ACTIVE

Quando houver espécime:

* chamber reage;
* conteúdo aparece;
* scanner pode reagir;
* terminal atualiza.

---

# 38. ALIEN NÃO É AVATAR

Não representar principalmente como:

```text
circular profile image
avatar
user profile
```

Alien é:

# espécime científico.

---

# 39. SUBJECT ANALYSIS

Detalhes devem parecer análise de laboratório.

Exemplo:

```text
SUBJECT ANALYSIS // 017

IDENTIFICATION
...

ORIGIN
...

REGISTERED ABILITY
...

FILE STATUS
...
```

---

# 40. RESTRICTED SPECIMEN ARCHIVE

O catálogo inferior é um:

# arquivo restrito.

Não um marketplace/card carousel.

---

# 41. ARCHIVE FILE

Pode parecer:

```text
XENO FILE // A-001
CATALOGUED

TESTAO

ORIGIN
Planet B

OPEN FILE →
```

---

# 42. NOVO ALIEN

Visualmente pode ser apresentado como:

```text
REGISTER NEW SPECIMEN
```

desde que clareza permaneça.

---

# 43. FORMS

Um formulário Rails continua sendo formulário Rails.

Mas pode ser apresentado como:

# console de registro.

---

# 44. NÃO SACRIFICAR `label`

Inputs continuam precisando:

* labels reais;
* erros;
* validação;
* acessibilidade.

Não substituir labels por decoração sci-fi.

---

# 45. ERRORS

Validation errors devem continuar claros.

Pode usar linguagem do universo apenas se não prejudicar entendimento.

---

# 46. PLANETS SECTOR

Direção conceitual:

# **PLANETARY OBSERVATION FACILITY**

ou nome equivalente aprovado futuramente.

Não reaproveitar Xenobiology Lab trocando o alien por planeta.

---

# 47. PLANETS — EQUIPAMENTO

Possíveis conceitos:

```text
orbital projector
planetary scanner
observation window
star chart
gravity monitor
atmospheric analysis
orbital diagram
```

---

# 48. PLANETS — DIFFERENT FACILITY

Mais:

```text
astronomy
cartography
optics
orbital mechanics
```

Menos:

```text
medical equipment
bio tanks
specimen containment
```

---

# 49. POWERS SECTOR

Direção:

# **ANOMALOUS ENERGY RESEARCH FACILITY**

---

# 50. POWERS — VISUAL LANGUAGE

Pode possuir:

```text
energy chamber
waveform
energy spectrum
containment field
stability readings
oscilloscope
output monitors
```

---

# 51. POWERS NÃO É RPG

Não usar automaticamente:

```text
damage
rarity
mana
skill tree
legendary
level
```

O tom padrão é científico.

---

# 52. SAME STATION, DIFFERENT SECTORS

Aliens, Planets e Powers devem compartilhar:

* typography;
* cyan language;
* system labels;
* navigation;
* security language;
* material quality;
* interaction quality.

Mas possuir equipamentos diferentes.

---

# 53. NAVBAR

Navbar representa navegação entre sistemas/setores.

Manter relativamente simples.

Não transformar navbar em cockpit.

---

# 54. STARFIELD

O exterior espacial pode estar vivo.

Permitido:

```text
stars
slow planet movement
comets
distant celestial bodies
subtle parallax
```

---

# 55. NO SCREENSAVER

Movimento precisa ser lento e secundário.

O usuário está operando o sistema.

Não assistindo a uma animação.

---

# 56. WINDOWS

Janelas físicas podem revelar espaço.

Se houver ação de abrir/fechar:

ela deve parecer mecânica.

---

# 57. MOTION CONTRACT

# **NO MOTION WITHOUT CAUSE.**

Antes de animar algo, responder:

> Qual evento físico ou de sistema causou isso?

---

# 58. MOTION ACEITÁVEL

```text
door opening
scanner pass
terminal activation
pressure change
specimen loading
mechanical arm
window mechanism
data acquisition
system response
```

---

# 59. MOTION RUIM

```text
button bouncing
random floating cards
icons pulsing forever
everything moving because sci-fi
```

---

# 60. MOTION STYLE

Preferir:

```text
precise
mechanical
controlled
short
deliberate
```

---

# 61. EQUIPMENT CONNECTION

Tubos precisam parecer conectados.

Cabos precisam possuir origem/destino visual.

Sensores precisam parecer medir alguma coisa.

---

# 62. NÃO DESENHAR DECORAÇÃO IMPOSSÍVEL

Um tubo que nasce e termina no nada reduz a credibilidade do laboratório.

---

# 63. ENVIRONMENT DETAILS

Elementos úteis:

```text
vents
screws
seals
access panels
cable channels
warning stripes
sector labels
serial numbers
pressure plates
maintenance ports
```

Com moderação.

---

# 64. NÃO SUPERLOTAR

Detalhe existe para dar credibilidade.

Não para preencher todos os pixels.

---

# 65. TYPOGRAPHY

Combinação recomendada:

```text
PRIMARY
clean futuristic sans/display

TECHNICAL
monospace
```

---

# 66. DISPLAY FONT

Usar em:

* branding;
* sector names;
* major interfaces.

---

# 67. MONOSPACE

Usar em:

```text
serial
coordinates
scanner status
security level
technical readings
metadata
```

---

# 68. NÃO USAR MONOSPACE EM PARÁGRAFOS LONGOS

Legibilidade vem primeiro.

---

# 69. MICROCOPY

Tom:

```text
technical
clinical
scientific
concise
restricted
```

---

# 70. NÃO ESCREVER MARKETING

PROIBIDO:

```text
Explore a universe of possibilities.
Unlock incredible cosmic experiences.
Discover aliens like never before.
```

SpaceRails não está vendendo SaaS.

---

# 71. MICROCOPY APROPRIADA

```text
SECTOR 04 // XENOBIOLOGY LAB

ACCESS LVL 3 // AUTHORIZED

BIO-SCAN ACTIVE

CHAMBER READY

SPECIMEN CATALOGUED

PRESSURE
97.4 KPA
```

---

# 72. DECORATIVE TECH DATA

Pode existir.

Mas precisa ser claramente decorativo/ambiental.

---

# 73. DOMAIN DATA

Informação do usuário/banco:

# nunca inventar.

---

# 74. NÃO INVENTAR

Exemplo:

Se `Alien` não possui temperatura corporal:

não exibir:

```text
BODY TEMP 37.8C
```

como se fosse dado real.

---

# 75. STATIC ENVIRONMENTAL DATA

Labels como:

```text
SYSTEM ONLINE
SECTOR 04
ACCESS AUTHORIZED
```

podem ser ambientação.

---

# 76. NÃO CONFUNDIR USUÁRIO

Dado decorativo nunca deve parecer uma informação persistida do registro se não for.

---

# 77. UI PRIMITIVES

Não definir `Card` como base universal.

Pensar em:

```text
FacilityPanel
InstrumentDisplay
ArchiveEntry
TerminalPanel
StatusReadout
ControlConsole
SpecimenChamber
SectorHeader
```

Mas só extrair componentes realmente reutilizáveis.

---

# 78. NÃO CRIAR UM FRAMEWORK INTERNO GIGANTE

Não construir:

```text
SpaceRailsSciFiEngine
```

apenas porque vários componentes compartilham ciano.

---

# 79. EXTRACT AFTER PROOF

Primeiro construir setores bem.

Depois extrair padrões reais.

---

# 80. CSS DISCIPLINE

Não espalhar valores aleatórios em dezenas de views.

Usar arquitetura CSS já existente.

Se houver tokens/variables:

reutilizar.

---

# 81. NÃO INTRODUZIR NOVO CSS FRAMEWORK SEM AUTORIZAÇÃO

Não adicionar Tailwind, Bootstrap etc. se projeto não usa.

---

# 82. ASSET PIPELINE

Respeitar mecanismo Rails existente.

Auditar:

* Propshaft;
* Sprockets;
* importmap;
* bundling;

ou o que o projeto realmente usa.

Não assumir.

---

# 83. RESPONSIVE CONTRACT

Desktop:

# environment-first.

Mobile:

# operation-first.

---

# 84. MOBILE

Em telas pequenas, preservar:

* registro atual;
* controle;
* equipamento principal;
* acesso ao arquivo.

Pode reduzir parte do environment.

---

# 85. NÃO ESPREMER O LABORATÓRIO

Não reduzir o cenário desktop inteiro para 375px.

Recompor.

---

# 86. ACCESSIBILITY

Obrigatório:

```text
semantic HTML
keyboard
focus-visible
contrast
labels
accessible forms
reduced-motion
dialogs
Escape behavior
touch targets
```

---

# 87. SCI-FI NÃO JUSTIFICA TEXTO MICROSCÓPICO

Metadata pode ser pequena.

Informação principal não.

---

# 88. REDUCED MOTION

Todos os efeitos ambientais relevantes devem respeitar:

```css
prefers-reduced-motion
```

---

# 89. TIMER / LOOP DISCIPLINE

Evitar múltiplos loops permanentes de animação.

---

# 90. PERFORMANCE

Cuidado especial com:

```text
Canvas
WebGL
particle systems
blur
large images
requestAnimationFrame
box shadows
continuous transforms
```

---

# 91. O PC NÃO PRECISA SOFRER PARA PARECER FUTURISTA

Qualidade visual vem de design.

Não de consumo de GPU.

---

# 92. RAILS PERFORMANCE

Não introduzir N+1 queries por causa de UI nova.

Auditar collections usadas em:

```erb
<% @aliens.each do |alien| %>
```

e relações associadas.

---

# 93. NÃO RESOLVER N+1 COM JS

Resolver corretamente na camada Rails apropriada.

---

# 94. PARTIAL PERFORMANCE

Não criar centenas de requests desnecessárias ou renderização fragmentada sem benefício.

---

# 95. TURBO

Se usado:

aproveitar streams/frames quando forem realmente adequados.

Não usar cada div como Turbo Frame.

---

# 96. STIMULUS

Um controller deve possuir responsabilidade clara.

Exemplo:

```text
specimen_chamber_controller
```

faz sentido.

Um controller global com 1.800 linhas:

não.

---

# 97. JAVASCRIPT NAMING

Código pode usar nomenclatura descritiva.

Não precisa fingir ser código de nave espacial.

---

# 98. CODE QUALITY > THEME

Código Rails deve continuar:

* convencional;
* previsível;
* simples;
* testável.

A ficção está na experiência.

---

# 99. ROUTES

Não criar routes apenas para efeitos.

---

# 100. CONTROLLERS

Não criar controller para equipamento visual sem recurso real.

---

# 101. DATABASE

Não criar migrations para:

* animação;
* posição;
* brilho;
* scanner visual;
* estado puramente transitório.

---

# 102. TESTS

Preservar testes existentes.

Mudança visual não autoriza remover teste que ficou inconveniente.

---

# 103. TESTAR COMPORTAMENTO

Testar conforme infraestrutura existente:

```text
model
request/controller
system/integration
view
JavaScript
```

quando aplicável.

---

# 104. VISUAL QA

Build/test green não significa interface aprovada.

Mudanças relevantes devem ser vistas em browser real.

---

# 105. SCREENSHOT REVIEW

Antes de declarar redesign terminado:

capturar:

* estado vazio;
* estado populated;
* seleção;
* detalhe;
* create/edit;
* desktop;
* tablet;
* mobile.

---

# 106. HUMAN REVIEW

Design de SpaceRails não deve ser congelado automaticamente pelo agente.

Primeiro:

```text
IMPLEMENTATION
↓
SCREENSHOT
↓
HUMAN REVIEW
↓
POLISH
↓
APPROVAL
```

---

# 107. GIT CONTRACT

Salvo instrução explícita:

não executar automaticamente:

```text
git add
git commit
git push
```

depois de grandes mudanças visuais.

---

# 108. ANTI-GENERIC TEST

Antes da entrega, remover mentalmente:

```text
SPACERAILS logo
```

e perguntar:

> isso poderia ser qualquer template sci-fi do Dribbble?

Se SIM:

# não está pronto.

---

# 109. FACILITY TEST

Perguntar:

> Eu consigo explicar o que cada grande objeto é dentro desta instalação?

Se NÃO:

refinar.

---

# 110. DATA TEST

Perguntar:

> A informação parece ter sido lida por um sistema ou simplesmente inserida num card?

Preferência:

# sistema.

---

# 111. MOTION TEST

Perguntar:

> Por que este elemento está se movendo?

Se resposta:

> porque ficou bonito,

remover.

---

# 112. MATERIAL TEST

Perguntar:

> vejo equipamentos ou vejo rectangles?

Se rectangles:

refinar.

---

# 113. MODULE TEST

Perguntar:

> Aliens, Planets e Powers parecem setores diferentes da mesma estação?

Esperado:

# SIM.

---

# 114. USABILITY TEST

Perguntar:

> mesmo sem entender a lore, o usuário entende como usar?

Esperado:

# SIM.

---

# 115. RAILS TEST

Perguntar:

> esta mudança respeitou a arquitetura Rails existente ou criou um mini frontend paralelo?

Se criou frontend paralelo:

reconsiderar.

---

# 116. ANTI-AI PATTERNS

Procurar ativamente e eliminar:

```text
generic rounded cards
gradient blobs
purple neon
random glow
huge marketing hero
generic dashboard stats
floating feature cards
card soup
glassmorphism everywhere
AI motivational copy
unnecessary frontend framework
duplicate client state
```

---

# 117. CURRENT ALIENS DESIGN CONTRACT

A direção atualmente estabelecida é:

```text
SECTOR
────────────────────────────────────────────
Xenobiology Laboratory

ENVIRONMENT
────────────────────────────────────────────
Deep space exterior
Bright laboratory interior

PRIMARY EQUIPMENT
────────────────────────────────────────────
Specimen chamber

SECONDARY EQUIPMENT
────────────────────────────────────────────
Bio scanners
Pressure monitors
Mechanical systems
Technical terminal

DATA PRESENTATION
────────────────────────────────────────────
Subject Analysis

ARCHIVE
────────────────────────────────────────────
Restricted Specimen Archive

PRIMARY ACCENT
────────────────────────────────────────────
Cyan

MATERIALS
────────────────────────────────────────────
White
Ivory
Bright metal
Glass
Acrylic

TONE
────────────────────────────────────────────
Clinical
Restricted
Scientific
Interstellar
```

---

# 118. NÃO REGREDIR

Não voltar para:

```text
generic black interface
blue neon everything
SaaS cards
cyberpunk dashboard
hacker terminal
```

---

# 119. NOMENCLATURA CONSISTENTE

Criar glossário do produto e respeitar.

Exemplo inicial:

```text
Alien
→ Specimen / Subject

Alien details
→ Subject Analysis

Alien record
→ Specimen File

List
→ Specimen Archive

Create alien
→ Register Specimen

Planet
→ Planetary Object / Planet

Power
→ Ability / Anomaly
```

Adaptar com aprovação humana.

---

# 120. NÃO RENOMEAR CLASSES DO DOMÍNIO SÓ PELA LORE

Pode continuar:

```ruby
class Alien < ApplicationRecord
end
```

Não precisa virar:

```ruby
class XenobiologicalSpecimenEntity < ApplicationRecord
end
```

---

# 121. PRESENTATION ≠ CODE NAMING

UI pode dizer:

```text
SPECIMEN FILE
```

enquanto código continua:

```ruby
Alien
```

Perfeito.

---

# 122. NÃO ESCREVER “SCI-FI CODE”

A arquitetura precisa ser mais simples que a interface.

---

# 123. PRIORIDADE DE DECISÃO

Em caso de conflito:

```text
1. FUNCTIONAL CORRECTNESS
2. DATA INTEGRITY
3. USABILITY
4. ACCESSIBILITY
5. RAILS ARCHITECTURAL COHERENCE
6. WORLD COHERENCE
7. VISUAL IDENTITY
8. DECORATION
```

---

# 124. PROCESSO OBRIGATÓRIO PARA QUALQUER AGENTE

```text
1. READ THIS GUIDE

2. AUDIT THE RAILS IMPLEMENTATION

3. IDENTIFY THE DOMAIN OWNERS

4. IDENTIFY THE FACILITY ROLE

5. IDENTIFY EXISTING INTERACTIONS

6. PRESERVE BUSINESS SEMANTICS

7. DESIGN THE EXPERIENCE

8. IMPLEMENT USING EXISTING RAILS CONVENTIONS

9. TEST FUNCTIONALITY

10. TEST RESPONSIVENESS

11. TEST ACCESSIBILITY

12. VISUAL QA

13. SCREENSHOTS

14. HUMAN REVIEW

15. ONLY THEN CONSIDER FREEZE / COMMIT
```

---

# 125. REQUIRED AGENT REPORT

Para grandes modificações, relatar:

```text
A. Existing Rails architecture audited
B. Routes affected
C. Controllers affected
D. Models affected
E. Views affected
F. Partials created/changed
G. Helpers affected
H. Stimulus/JS affected
I. Turbo behavior affected
J. CSS/assets affected
K. Domain changes
L. Database changes
M. Migrations
N. Visual concept
O. Facility role
P. Interactions
Q. Accessibility
R. Responsive behavior
S. Tests
T. Remaining visual debts
U. Git status
```

---

# 126. DOMAIN CHANGE GATE

Se qualquer grande design task resultar em:

```text
Model changed
Migration created
Database changed
New API
```

o agente deve explicar:

# por quê.

Visual redesign sozinho não é justificativa.

---

# 127. EXPECTED DEFAULT FOR VISUAL TASKS

Normalmente:

```text
Models
NONE

Database
NONE

Migrations
NONE

Routes
NONE or minimal

Views
YES

Partials
POSSIBLE

CSS
YES

Stimulus / JS
POSSIBLE

Assets
POSSIBLE
```

---

# 128. FINAL DEFINITION

SpaceRails é:

# **uma aplicação Rails full-stack que simula a operação de uma estação científica interplanetária.**

Rails é o motor real.

A instalação é a experiência.

O usuário não precisa perceber:

```text
controller
ERB
Active Record
Turbo
Stimulus
SQL
```

Ele precisa perceber:

```text
laboratory
terminal
scanner
archive
observation
containment
research
space
```

---

# 129. FINAL MANTRAS

Todo agente deve trabalhar sob estas quatro frases:

# **DON'T MAKE A PAGE. BUILD THE FACILITY.**

# **DON'T PUT DATA IN CARDS. MAKE THE FACILITY READ THE DATA.**

# **THE WORLD MUST REACT TO THE OPERATION.**

# **KEEP RAILS RAILS.**

---

# BLOCO PARA O `AGENTS.md`

E no arquivo que o Codex/agentes provavelmente encontram primeiro, eu colocaria algo bem curto e brutal:

```md
# SpaceRails — Mandatory AI Instructions

SpaceRails is a Ruby on Rails full-stack application.

Before making any relevant product, UI, UX, frontend, JavaScript or
architecture change, read:

`docs/ai/SPACERAILS_AI_GUIDE.md`

That document is a mandatory product and implementation contract.

## Core Rules

- SpaceRails is NOT a generic sci-fi website.
- It is an interactive interstellar scientific facility built as a Rails application.
- Do not design pages. Design facilities.
- Do not put domain data into generic cards. Build scientific instrumentation around it.
- The world should react to user/system operations.
- Rails remains responsible for the application architecture.
- Do not introduce React, Vue, Next.js or a parallel frontend architecture unless explicitly requested.
- Do not create APIs merely to support presentation that Rails can already render.
- Do not duplicate Rails domain state in JavaScript.
- Prefer the existing Rails rendering and interaction architecture.
- Use Stimulus/Turbo/Hotwire only when already present or explicitly justified.
- Never alter models, database schema or business semantics merely to support aesthetics.
- Avoid generic cyberpunk, neon-purple sci-fi, glassmorphism and card soup.
- Space outside; scientific facility inside.
- Motion must have an in-world cause.
- Different modules are different facilities inside the same station.
- Accessibility and usability take priority over decoration.
- Audit existing Rails code before modifying it.
- Do not commit or push major visual work before human review unless explicitly instructed.

## Anti-Generic Check

If removing the SpaceRails logo would make the result look like any generic
sci-fi dashboard/template, the work is not finished.

## Architecture Check

If a Rails visual redesign results in an unnecessary frontend framework,
parallel client state, API layer or domain rewrite, the implementation is
probably wrong.

## Primary Mantras

DON'T MAKE A PAGE. BUILD THE FACILITY.

DON'T PUT DATA IN CARDS. MAKE THE FACILITY READ THE DATA.

THE WORLD MUST REACT TO THE OPERATION.

KEEP RAILS RAILS.
```

---

# 130. SPECIMEN ENGINE DOCTRINE

Regras adicionadas após a implementação do Specimen Engine (morfologia,
locomoção e microambiente procedurais para Aliens):

```text
THE CONTAINMENT CHAMBER ADAPTS TO THE SPECIMEN.
THE SPECIMEN MUST NOT BE FORCED INTO A STANDARD POSE.

SPECIMENS OCCUPY A MICROENVIRONMENT.
THEY DO NOT EXECUTE DECORATIVE IDLE LOOPS.

BEHAVIOR IS EXPRESSED THROUGH ANATOMY.
DO NOT FORCE HUMAN EXPRESSIONS ON NON-HUMAN MORPHOLOGIES.

PROCEDURAL PRESENTATION MUST REMAIN OUTSIDE DOMAIN STATE
UNLESS EXPLICITLY PROMOTED TO PRODUCT DATA.
```

Não colar relatórios de implementação aqui. Este arquivo é doutrina, não changelog.

---

Esse é o que eu usaria como **documento constitucional do SpaceRails**.

Depois, em vez de deixá-lo chegar a 500 regras específicas, eu criaria skills subordinadas:

```text
docs/ai/
│
├── SPACERAILS_AI_GUIDE.md
│
└── skills/
    ├── XENOBIOLOGY.md
    ├── PLANETARY_OBSERVATION.md
    ├── ANOMALOUS_ENERGY.md
    ├── FACILITY_MOTION.md
    └── VISUAL_QA.md
```

Aí o primeiro arquivo ensina à IA **o que é SpaceRails e como trabalhar num Rails full-stack sem transformar o projeto em outra coisa**.

E os demais ensinam como construir cada setor. Isso é muito mais escalável do que repetir um prompt gigantesco em toda mudança.
