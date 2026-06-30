# Graph Report - paperclip  (2026-06-19)

## Corpus Check
- 7 files · ~13,354 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 92 nodes · 91 edges · 13 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]

## God Nodes (most connected - your core abstractions)
1. `PRD1: Desktop Application` - 9 edges
2. `PRD2: Web/PWA Application` - 9 edges
3. `Architecture Options and Technical Decisions` - 8 edges
4. `Tutorial: Web App User Guide` - 7 edges
5. `3. Functional Specifications & Feature Requirements` - 6 edges
6. `3. Functional Specifications & Feature Requirements` - 5 edges
7. `Especificações técnicas do utilitário de captura` - 5 edges
8. `paperclip.show()` - 4 edges
9. `Paperclip` - 4 edges
10. `Recursos necessários para o utilitário` - 4 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (13 total, 0 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.11
Nodes (18): 2.1. Fluxo de Dados e Topologia de Redes, 2.2. Robustez e Tratamento de Exceções Criptográficas, 2. System Architecture & Ecosystem Topology, 3.1. Keyboard-First Interface & Window Lifecycle, 3.2. Contextual Tab Architecture & Dynamic Routing, 3.3. Arquitetura Local-First e Sincronização Concorrente, 3.4. Local Clipboard Integration, 3.5. Pipeline de Transcrição de Áudio (Whisper + VAD) (+10 more)

### Community 1 - "Community 1"
Cohesion: 0.12
Nodes (16): 1.1. Contexto de Mobilidade e Acessibilidade Universal, 1.2. Objetivos Estratégicos, 1. Vision & Purpose, 2.1. Mitigação de Limitações Serverless, 2. System Architecture & Ecosystem Topology, 4.1. Código Completo de Estilo e Layout (HTML + CSS Incorporado), 4. Visual & Interface Design Guidelines, 5.1. Protocolo de Segurança Web e Envio Cifrado (+8 more)

### Community 2 - "Community 2"
Cohesion: 0.17
Nodes (12): Abordagens para a aplicação, Architecture Options and Technical Decisions, Captura contextual por aplicação, Captura de dados e contexto, Decisão estratégica sobre stack tecnológico, Estratégias para reduzir a fricção, Funcionalidades de captura estruturada, Interface e controlo em segundo plano (+4 more)

### Community 3 - "Community 3"
Cohesion: 0.18
Nodes (10): 1. Configuração Inicial e Instalação (Fricção Zero), 2. O Fluxo Diário de Captura de Texto, 3. O Fluxo de Captura por Voz (Mãos Livres), 4. Comportamento Offline (Gestão de Redes Móveis Instáveis), 5. O Ciclo de Ingestão no PC/Mac (A Ligação ao Second Brain), Document Index, Paperclip Project Draft, PRD3: Technical Specifications (+2 more)

### Community 4 - "Community 4"
Cohesion: 0.52
Nodes (6): paperclip.captureContext(), paperclip.hide(), paperclip.populateYAML(), paperclip.saveNote(), paperclip.show(), paperclip.toggle()

### Community 5 - "Community 5"
Cohesion: 0.40
Nodes (3): Project Tracks, Objectives, Track: Mac Parity Implementation

### Community 6 - "Community 6"
Cohesion: 0.40
Nodes (5): 3.1. Interface Web Progressiva (PWA) e Responsividade, 3.2. Menu Superior de Abas e Atalhos Touch/Teclado, 3.3. Integração com Clipboard do Android/Browser, 3.4. Captura de Voz Nativa (Web Audio API + Whisper Cloud), 3. Functional Specifications & Feature Requirements

### Community 7 - "Community 7"
Cohesion: 0.40
Nodes (5): Arquitetura e desempenho, Compatibilidade com o segundo cérebro, Especificações técnicas do utilitário de captura, Integrações de contexto e ecossistema, Mecanismos de captura e redução de fricção

### Community 8 - "Community 8"
Cohesion: 0.40
Nodes (4): 🛠️ Architecture, 🚀 Key Features, Paperclip, 📊 Performance

### Community 9 - "Community 9"
Cohesion: 0.67
Nodes (3): 1.1. Contexto Académico e Profissional, 1.2. Objetivos Estratégicos, 1. Vision & Purpose

### Community 10 - "Community 10"
Cohesion: 0.67
Nodes (3): 5.1. Segurança, Cifragem Simétrica e Autenticação Cloud, 5.2. Pipeline do Script de Ingestão Local (`pull_pocketbase.py`), 5. System Integration & Second Brain Alignment

## Knowledge Gaps
- **55 isolated node(s):** `🚀 Key Features`, `🛠️ Architecture`, `📊 Performance`, `Project Tracks`, `Objectives` (+50 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `PRD1: Desktop Application` connect `Community 0` to `Community 9`, `Community 10`, `Community 3`?**
  _High betweenness centrality (0.330) - this node is a cross-community bridge._
- **Why does `PRD2: Web/PWA Application` connect `Community 1` to `Community 3`, `Community 6`?**
  _High betweenness centrality (0.295) - this node is a cross-community bridge._
- **Why does `Architecture Options and Technical Decisions` connect `Community 2` to `Community 3`, `Community 7`?**
  _High betweenness centrality (0.244) - this node is a cross-community bridge._
- **What connects `🚀 Key Features`, `🛠️ Architecture`, `📊 Performance` to the rest of the system?**
  _55 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._