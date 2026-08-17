# TI-14-003 — Extensão JIRA Insight (Jira Quick Ticket)

> 🎯 **Objetivo** — Registrar tickets no Jira em segundos, a partir de qualquer página do navegador. A extensão **Jira Quick Ticket** captura a página atual (título, URL e texto selecionado), pergunta o **projeto** e o **tipo de ticket**, cria o ticket via API do Jira e devolve o **número** (ex.: TAD-983) com link direto. Substitui o bookmarklet + webhook Zapier.

**Links:** [Repositório GitHub](https://github.com/dfg-dexterity/jirainsightextension) • [Ticket TAD-983](https://dexterityit.atlassian.net/browse/TAD-983) • [Política de privacidade](https://github.com/dfg-dexterity/jirainsightextension/blob/main/PRIVACY.md)

**Quando é executado:** ad-hoc, sempre que precisar registrar um ticket • **Tempo:** instalação ~10 min; uso < 1 min por ticket

## Como funciona

1. Clique no ícone da extensão em qualquer página do Chrome;
2. Ela captura **título, URL e texto selecionado** e pré-preenche o formulário;
3. Escolha o **projeto** e o **tipo de ticket** — as listas vêm do próprio Jira (cache de 24 h; os últimos usados ficam memorizados);
4. (Opcional) Informe as **horas trabalhadas** — a extensão registra o worklog no ticket recém-criado;
5. Clique em **Criar ticket** → o número volta na hora, com link para abrir no Jira e botão **Copiar chave**.

Vantagens sobre o bookmarklet + Zapier: retorna o número do ticket, permite escolher projeto/tipo (antes fixos em TAD/Tarefa), funciona em páginas com CSP restritivo, mostra os erros reais do Jira e não depende de serviços intermediários — o ticket sai em nome do próprio usuário.

---

## Instruções passo a passo

### 1. Instalação (modo desenvolvedor)

1. Baixe o código: [github.com/dfg-dexterity/jirainsightextension](https://github.com/dfg-dexterity/jirainsightextension) → botão **Code → Download ZIP** → descompacte (ou `git clone`);
2. No Chrome, abra `chrome://extensions`;
3. Ative o **Modo do desenvolvedor** (canto superior direito);
4. Clique em **Carregar sem compactação** e selecione a pasta descompactada (a que contém o `manifest.json`);
5. Fixe a extensão na barra: ícone de quebra-cabeça → alfinete no **Jira Quick Ticket**.

> Quando a extensão for publicada na Chrome Web Store, a instalação passa a ser um clique no link da loja (ver seção Publicação).

### 2. Configuração — primeira vez

![Tela de configurações](https://raw.githubusercontent.com/dfg-dexterity/jirainsightextension/main/store/screenshot-3-opcoes.png)

1. Clique no ícone da extensão → **Configurar credenciais** (ou botão direito no ícone → **Opções**);
2. Confira a **URL do Jira** — já vem preenchida com `https://dexterityit.atlassian.net`;
3. Informe o **e-mail** da sua conta Atlassian;
4. Gere um **API token** em [id.atlassian.com → Security → API tokens](https://id.atlassian.com/manage-profile/security/api-tokens) (**Create API token**, copie e cole no campo);
5. Clique em **Testar conexão** — deve aparecer seu nome;
6. Clique em **Salvar**.

### 3. Uso diário — criar um ticket

![Popup com o formulário preenchido](https://raw.githubusercontent.com/dfg-dexterity/jirainsightextension/main/store/screenshot-1-popup.png)

1. Na página sobre a qual quer abrir o ticket, **selecione um trecho de texto** (opcional) e clique no ícone da extensão;
2. O **Resumo** vem com o título da página e a **Descrição** com título, URL e o trecho selecionado — edite à vontade;
3. Escolha o **Projeto** (dá para filtrar por nome ou chave) e o **Tipo de ticket**;
4. (Opcional) Preencha **Apontar horas** — aceita `1h 30m`, `45m`, `2` (= 2h), `1,5` (= 1h 30m) ou `1:30`;
5. Clique em **Criar ticket**.

O botão **↻ Projetos** força a atualização da lista de projetos quando algo mudou no Jira.
Se o registro de horas estiver desabilitado no projeto, o ticket é criado normalmente e o popup avisa que o apontamento falhou.

![Ticket criado com número e link](https://raw.githubusercontent.com/dfg-dexterity/jirainsightextension/main/store/screenshot-2-sucesso.png)

**Ticket criado!**

- O **número do ticket** (ex.: `TAD-983`) aparece na hora;
- Se você apontou horas, a confirmação mostra o worklog registrado (ex.: "⏱ 1h 30m apontado no ticket");
- Clique no número para **abrir no Jira**, ou use **Copiar chave** para colar no chat/e-mail;
- **Criar outro** volta ao formulário mantendo a página capturada.

Se o projeto exigir campos obrigatórios extras, o erro do Jira aparece no próprio popup — nesse caso, crie o ticket pelo Jira ou ajuste a tela de criação do projeto.

### 4. Segurança e privacidade

- O e-mail e o API token ficam **somente no navegador** (`chrome.storage.local`) e são enviados **apenas ao Jira configurado**, via HTTPS;
- Nada é enviado a servidores próprios ou terceiros — sem telemetria, analytics ou anúncios;
- A extensão só lê a página **no momento do clique** (permissões `activeTab` + `scripting`); não monitora navegação em segundo plano;
- Política completa: [PRIVACY.md](https://github.com/dfg-dexterity/jirainsightextension/blob/main/PRIVACY.md). Para revogar o acesso, exclua o token em id.atlassian.com e desinstale a extensão.

### 5. Publicação na Chrome Web Store

Status: **em preparação** — pacote e materiais prontos no repositório.

1. Materiais: capturas 1280×800 e promo tile em [`store/`](https://github.com/dfg-dexterity/jirainsightextension/tree/main/store); política de privacidade em `PRIVACY.md`; pacote ZIP gerado conforme o README;
2. Criar a conta de desenvolvedor em [chrome.google.com/webstore/devconsole](https://chrome.google.com/webstore/devconsole) (taxa única de US$ 5);
3. **+ Novo item** → enviar o ZIP → preencher a ficha (descrição, categoria Produtividade, capturas, URL da política de privacidade, justificativas de permissões);
4. Visibilidade recomendada: **Não listada** (instala pelo link, não aparece na busca pública);
5. Enviar para revisão (horas a poucos dias). Atualizações: aumentar `version` no `manifest.json`, gerar novo ZIP e reenviar.

---

## Glossário

- **API token** — senha de aplicativo da conta Atlassian, usada no lugar da senha normal para chamadas de API; gerada e revogada em id.atlassian.com;
- **Manifest V3** — formato atual de extensões do Chrome, usado pela extensão (permissões mínimas: `activeTab`, `scripting`, `storage`);
- **Modo do desenvolvedor** — opção de `chrome://extensions` que permite instalar extensões fora da Chrome Web Store ("Carregar sem compactação");
- **TAD** — chave do projeto "ITPR | Tarefas Avulsas" no Jira, destino padrão dos tickets avulsos;
- **Bookmarklet (solução anterior)** — favorito com JavaScript que enviava os dados a um webhook do Zapier; aposentado por esta extensão.

---

## Complemento: app para macOS (barra de menus) — experimental

Além da extensão Chrome, o repositório traz um aplicativo de barra de menus para Mac (pasta `macos/`): em vez da página do navegador, ele captura o **aplicativo em primeiro plano, o título da janela ativa** e o texto selecionado (via permissão de Acessibilidade do macOS) e cria o ticket com o mesmo fluxo — projeto, tipo, apontamento de horas e número do ticket de volta, com token guardado no Keychain.

- Compilar: `cd macos && ./make-app.sh` (requer apenas o Xcode Command Line Tools); o app gerado fica em `macos/dist/JiraQuickTicket.app`;
- Primeira captura pede a permissão em **Ajustes do Sistema → Privacidade e Segurança → Acessibilidade**;
- Instruções completas: [macos/README.md](https://github.com/dfg-dexterity/jirainsightextension/blob/main/macos/README.md).
