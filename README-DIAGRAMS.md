# Schema Change Detection & Pipeline Automation - Process Diagrams

## 📋 Dokumenta saturs

Šis pakalpojums satur 4 detalizētas Mermaid diagrammas, kas vizualizē pilnu schema izmaiņu detektēšanas un automātiskas deployment procesa plūsmu.

---

## 🗺️ Diagrammu Apskats

### 1. **Process Flow Diagram** (`schema-change-process-diagram.mermaid`)
**Mērķis:** Augsta līmeņa pārskats par visu procesu no sākuma līdz beigām

**Kad lietot:**
- Prezentācijām stakeholder'iem
- Tehniskās dokumentācijas augstākajam līmenim
- Jaunu team locekļu onboarding

**Galvenie elementi:**
- ✅ 9 galvenās procesa fāzes
- ✅ Error handling flows
- ✅ Monitoring integrācija
- ✅ Krāsu kodēti komponenti

**Vizualizē:**
```
Developer Change → DDL Trigger → Logging → 
Polling → Validation → Pipeline Trigger → 
Build → Deploy → Mark Processed → Monitoring
```

---

### 2. **Sequence Diagram** (`schema-change-sequence-diagram.mermaid`)
**Mērķis:** Laika secībā parāda precīzu interakciju secību starp komponentēm

**Kad lietot:**
- Debugging problēmām
- Izprast timing un async operācijas
- Detalizēta error scenario analīze
- Performance optimization

**Galvenie elementi:**
- ✅ Participant lifelines (Developer → Monitoring)
- ✅ Sync/Async message flows
- ✅ Activation boxes (kad komponente ir aktīva)
- ✅ Alternative paths (success vs error)
- ✅ Loop mechanics (polling cycle)

**Vizualizē:**
```
Timeline view:
T+0s:   Developer executes DDL
T+0.1s: Trigger fires & logs
T+120s: Timer triggers function
T+121s: Function queries log
T+122s: API call to Azure DevOps
T+123s: Pipeline queued
T+300s: Pipeline completes
T+301s: Mark as processed
```

---

### 3. **Architecture Diagram** (`schema-change-architecture.mermaid`)
**Mērķis:** Sistēmas arhitektūra ar visiem Azure komponentiem un to savienojumiem

**Kad lietot:**
- Infrastructure planning
- Cost estimation
- Security review
- DR/HA design
- Team handoff dokumentācija

**Galvenie elementi:**
- ✅ Azure service boxes (Function, SQL, DevOps, etc.)
- ✅ Data flow arrows
- ✅ Monitoring paths
- ✅ Secret management
- ✅ Legend ar connection types

**Vizualizē:**
```
Azure Cloud Layout:
┌─────────────────────────────────────────┐
│ SQL Environment                         │
│  ├─ Test Database                       │
│  ├─ DDL Trigger                         │
│  └─ SchemaChangeLog                     │
├─────────────────────────────────────────┤
│ Polling Service (Choose One)            │
│  ├─ Azure Function (Python)             │
│  └─ Azure Automation (PowerShell)       │
├─────────────────────────────────────────┤
│ Azure DevOps                            │
│  ├─ Pipeline                            │
│  ├─ Git Repository                      │
│  └─ Artifacts                           │
├─────────────────────────────────────────┤
│ Monitoring                              │
│  ├─ Application Insights                │
│  └─ Alerts                              │
└─────────────────────────────────────────┘
```

---

### 4. **Data Flow Diagram** (`schema-change-data-flow.mermaid`)
**Mērķis:** Precīzi parāda KĀDI dati pārvietojas caur sistēmu

**Kad lietot:**
- Data mapping exercises
- Integration testing
- Troubleshooting data transformation issues
- Compliance/Audit trails

**Galvenie elementi:**
- ✅ Actual data samples katrā posmā
- ✅ XML → Table → JSON → HTTP transformācijas
- ✅ SQL queries ar rezultātiem
- ✅ API requests/responses ar payload
- ✅ Logging data flow

**Vizualizē:**
```
Data transformāciju ķēde:

DDL Statement:
  ALTER TABLE Users ADD Email...

→ EVENTDATA XML:
  <EVENT_INSTANCE>
    <ObjectName>Users</ObjectName>
    <EventType>ALTER_TABLE</EventType>
  </EVENT_INSTANCE>

→ Database Record:
  ChangeId=123, ObjectName='Users', ...

→ JSON Payload:
  {
    "changes": [{
      "object": "dbo.Users",
      "action": "ALTER_TABLE"
    }]
  }

→ HTTP POST:
  POST /pipelines/123/runs
  Body: {...}

→ API Response:
  {"id": "run-456", "state": "inProgress"}

→ Update Query:
  UPDATE SET Processed=1, PipelineRunId='run-456'
```

---

## 🎯 Kā Izvēlēties Pareizo Diagrammu

| Situācija | Izmantojiet | Kāpēc |
|-----------|------------|-------|
| Executive presentation | Process Flow | High-level, viegli saprotams |
| Debugging timing issues | Sequence | Redzēt precīzu interakciju secību |
| Infrastructure planning | Architecture | Redz visus Azure resursus |
| Troubleshooting data problems | Data Flow | Redz precīzus datu formātus |
| New team member training | Process Flow + Architecture | Saprot gan flow, gan komponentes |
| Performance optimization | Sequence | Identificē bottlenecks |
| Security review | Architecture + Data Flow | Redz data paths un secrets |

---

## 🖼️ Kā Skatīt Diagrammas

### Option 1: VS Code (Ieteicams)
```bash
# Install Mermaid extension
code --install-extension bierner.markdown-mermaid

# Open .mermaid file
code schema-change-process-diagram.mermaid
```

### Option 2: Mermaid Live Editor
1. Atvērt https://mermaid.live
2. Copy/paste .mermaid faila saturu
3. Auto-generates diagram

### Option 3: GitHub/Azure DevOps
- Vienkārši commit .mermaid failus
- Tie automātiski renderējas markdown preview

### Option 4: Export as PNG/SVG
```bash
# Using mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Export to PNG
mmdc -i schema-change-process-diagram.mermaid -o process-diagram.png

# Export to SVG
mmdc -i schema-change-process-diagram.mermaid -o process-diagram.svg
```

---

## 🔍 Detalizēta Komponenšu Apraksts

### Process Flow Komponentes

| Component | Apraksts | Atbildība |
|-----------|----------|-----------|
| **Developer** | Cilvēks vai automatizēts process | Izdara schema izmaiņas |
| **DDL Trigger** | SQL Database trigger | Notver DDL events |
| **SchemaChangeLog** | Database tabula | Uzglabā change history |
| **Timer** | Azure Function/Automation schedule | Aktivizē polling |
| **Polling Function** | Azure Function vai Runbook | Query un trigger pipeline |
| **Azure DevOps API** | REST API endpoint | Saņem pipeline trigger |
| **Pipeline** | YAML definēta workflow | Build un deploy DACPAC |
| **Monitoring** | Application Insights | Logs un alerts |

### Sequence Flow Stages

| Stage | Duration | Aktivitātes |
|-------|----------|-------------|
| **DDL Execution** | < 1s | User runs ALTER/CREATE/DROP |
| **Trigger Processing** | < 0.1s | Parse EVENTDATA, Insert log |
| **Waiting** | 2-5 min | Log record waits for polling |
| **Polling Cycle** | 1-2s | Query log, prepare payload |
| **API Call** | 0.5-1s | HTTP POST to Azure DevOps |
| **Pipeline Queue** | 1-5s | Pipeline queued and started |
| **Pipeline Execution** | 2-10 min | Build, deploy, verify |
| **Finalization** | 1s | Update log as processed |

---

## 📊 Metrics un KPIs

### Process Performance

```
Metrics skatāmi no diagrammām:

1. Detection Latency
   - DDL Execute → Log Entry: < 100ms
   - Target: < 500ms

2. Trigger Latency  
   - Log Entry → Pipeline Start: 2-5 min (polling interval)
   - Target: < 5 min

3. Total End-to-End Time
   - DDL Execute → Deployment Complete: 5-15 min
   - Target: < 20 min

4. Success Rate
   - % of changes successfully deployed
   - Target: > 95%

5. Error Recovery Time
   - Failed trigger → Successful retry: 2-5 min (next poll)
   - Target: < 10 min
```

---

## 🚨 Error Scenarios (Redzami Sequence Diagram)

### Common Failures:

1. **SQL Connection Timeout**
   ```
   Polling → SQL: TIMEOUT
   Retry logic: Next polling cycle
   Alert: After 3 consecutive failures
   ```

2. **API Authentication Failure**
   ```
   Function → Azure DevOps: 401 Unauthorized
   Cause: Expired PAT
   Action: Alert admin, changes remain unprocessed
   ```

3. **Pipeline Execution Failure**
   ```
   Pipeline → Deploy: FAILED
   Cause: DACPAC validation error
   Action: Log error, keep Processed=0, retry on next poll
   ```

---

## 🔐 Security Considerations (Architecture Diagram)

### Secret Flow:
```
Key Vault (secrets) →
  Azure Function/Automation (retrieves) →
    SQL Database (authenticates) →
      Azure DevOps API (triggers)
```

### Access Control:
- **SQL Database:** Managed Identity or SQL Auth
- **Azure Function:** System Managed Identity
- **Key Vault:** RBAC for secret access
- **Azure DevOps:** Personal Access Token (PAT)

---

## 📝 Izmantošanas Piemēri

### 1. Onboarding Jauns Developer

**Lietot:** Process Flow + Architecture

```
Step 1: Parādīt Process Flow
  "Šis ir pilnais process no A līdz Z"

Step 2: Parādīt Architecture  
  "Šīs ir visas Azure komponentes kas iesaistītas"

Step 3: Hands-on
  "Tagad dari test izmaiņu un skaties kā process nostrādā"
```

### 2. Troubleshooting Failed Deployment

**Lietot:** Sequence + Data Flow

```
Step 1: Check Sequence Diagram
  Identificē kurā posmā process apstājās

Step 2: Check Data Flow
  Pārbaudi vai dati transformējās pareizi

Step 3: Check Logs
  Salīdzini ar paredzēto flow
```

### 3. Cost Optimization

**Lietot:** Architecture

```
Analyze:
- Function executions (katras 2 min = ~720/day)
- SQL queries (720/day)
- Pipeline runs (depends on changes)
- Storage costs (logs + artifacts)

Optimize:
- Increase polling interval: 2 min → 5 min = 66% cost reduction
- Cleanup old logs: 30 days retention
- Use Consumption plan for Functions
```

---

## 🎓 Learning Path

### Beginner (Saprot "Kas notiek")
1. Lasi Process Flow
2. Skati Architecture
3. Izpildi test scenario

### Intermediate (Saprot "Kā notiek")
1. Lasi Sequence Diagram
2. Izpēti Data Flow transformācijas
3. Debug real issues

### Advanced (Saprot "Kāpēc tā")
1. Modificē komponentes
2. Optimizē performance
3. Extend functionality

---

## 🔄 Diagram Update Process

Ja maini sistēmu, update diagrammas šādā secībā:

1. **Architecture** (pirmais)
   - Jauni/izmainīti Azure resursi

2. **Process Flow** (otrais)
   - Jauni process steps

3. **Sequence** (trešais)
   - Precīza interaction timing

4. **Data Flow** (pēdējais)
   - Datu formātu izmaiņas

---

## 📞 Support

Ja ir jautājumi par diagrammām:
- Architecture questions → DevOps Lead
- Process questions → Team Lead
- Data questions → Database Admin
- All questions → README.md (šis dokuments)

---

## 📌 Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-09 | Initial diagrams | Claude |
| | | - Process Flow | |
| | | - Sequence Diagram | |
| | | - Architecture | |
| | | - Data Flow | |

---

## ✅ Checklist - Vai Saprot Procesu?

- [ ] Varu izskaidrot process flow 9 stages
- [ ] Saprotu kāpēc polling ir 2-5 min
- [ ] Zinu kur atrodas secrets (Key Vault)
- [ ] Varu debug failed deployment
- [ ] Saprotu DDL Trigger lomu
- [ ] Zinu kā darbojas SchemaChangeLog
- [ ] Varu identificēt bottlenecks
- [ ] Saprotu monitoring strategy
- [ ] Zinu error recovery mehānismus
- [ ] Varu explain architecture citiem

Ja visi ✅, tad esi ready strādāt ar šo sistēmu! 🎉
