# Jira Quick Ticket — app para macOS (barra de menus)

Versão para Mac da extensão Chrome deste repositório: em vez da página do navegador,
ela captura **o aplicativo em primeiro plano, o título da janela ativa e o texto
selecionado** (via API de Acessibilidade do macOS) e cria o ticket no Jira com o
mesmo fluxo — escolha de **projeto** e **tipo**, **apontamento de horas** opcional
e retorno do **número do ticket** com link e botão de copiar.

- App de **barra de menus** (sem ícone no Dock): clique no ícone ▣ ao lado do relógio;
- Swift + SwiftUI puros, **sem dependências externas**;
- Credenciais: URL/e-mail em `UserDefaults`, **API token no Keychain**;
- Mesmos recursos da extensão: cache de projetos por 24 h, últimos projeto/tipo
  memorizados, conversão amigável de horas (`2` → `2h`, `1,5`/`1:30` → `1h 30m`).

## Requisitos

- macOS 13 (Ventura) ou superior;
- Xcode Command Line Tools (`xcode-select --install`) — não precisa do Xcode completo.

## Compilar e rodar

```bash
cd macos

# rodar direto (para testar)
swift run

# ou gerar o aplicativo dist/JiraQuickTicket.app
./make-app.sh
```

Depois arraste `dist/JiraQuickTicket.app` para `/Applications`. Para iniciar com o
sistema: Ajustes do Sistema → Geral → Itens de Início de Sessão → adicione o app.

## Permissão de Acessibilidade (uma vez)

Para ler o **título da janela** e o **texto selecionado** de outros aplicativos, o
macOS exige a permissão de Acessibilidade. Na primeira captura o sistema mostra o
pedido; aceite em **Ajustes do Sistema → Privacidade e Segurança → Acessibilidade**
(ligue a chave do Jira Quick Ticket). Sem a permissão, o app continua funcionando —
captura apenas o nome do aplicativo frontal.

## Configuração (primeira vez)

1. Clique no ícone da barra de menus → engrenagem;
2. Confira a **URL do Jira** (vem `https://dexterityit.atlassian.net`), informe seu
   **e-mail** Atlassian e um **API token**
   ([id.atlassian.com → Security → API tokens](https://id.atlassian.com/manage-profile/security/api-tokens));
3. **Testar conexão** → **Salvar**.

## Uso

1. Na janela sobre a qual quer abrir o ticket (qualquer app: Excel, Teams, SAP GUI,
   navegador…), selecione um texto se quiser e clique no ícone do Jira Quick Ticket;
2. O **Resumo** vem com o título da janela e a **Descrição** com aplicativo, janela e
   texto selecionado — edite à vontade;
3. Escolha **Projeto** e **Tipo**, preencha **Apontar horas** se quiser e clique em
   **Criar ticket**;
4. O número (ex.: `TAD-983`) aparece com **Copiar chave** e **Abrir no Jira**.

## Estrutura

```
macos/
├── Package.swift                     # SwiftPM (macOS 13+, sem dependências)
├── make-app.sh                       # gera dist/JiraQuickTicket.app (assinatura ad-hoc)
└── Sources/JiraQuickTicket/
    ├── main.swift                    # boot do app (.accessory, sem Dock)
    ├── AppDelegate.swift             # NSStatusItem + NSPopover
    ├── FrontWindowTracker.swift      # app frontal + título da janela + seleção (AX)
    ├── JiraClient.swift              # API REST v3, Keychain, texto→ADF, horas
    ├── TicketViewModel.swift         # estado do formulário/criação
    └── Views.swift                   # SwiftUI: formulário, sucesso, configurações
```

## Limitações conhecidas

- Apps sem janela acessível via AX (alguns apps Electron/Java antigos) podem não expor
  o título — o campo fica com o nome do aplicativo;
- Projetos com campos obrigatórios extras retornam o erro do Jira no popover;
- Se o registro de horas estiver desabilitado no projeto, o ticket é criado e o app
  avisa que só o apontamento falhou;
- Código ainda não coberto por build de CI — reporte erros de compilação em uma issue.
