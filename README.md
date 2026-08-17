# Jira Quick Ticket — extensão Chrome

Extensão (Manifest V3) que cria tickets no Jira a partir da página atual do navegador:

1. Clique no ícone da extensão em qualquer página;
2. Ela captura **título, URL e texto selecionado** e pré-preenche o formulário;
3. Você escolhe o **projeto** e o **tipo de ticket** (listas carregadas do próprio Jira);
4. (Opcional) Informe as **horas trabalhadas** — viram worklog no ticket recém-criado;
5. Ao criar, ela mostra o **número do ticket** (ex.: `TAD-123`) com link direto e botão de copiar.

Substitui o bookmarklet que enviava os dados para um webhook do Zapier.

## Por que é melhor que o bookmarklet + Zapier

| | Bookmarklet + Zapier | Extensão |
|---|---|---|
| Retorna o número do ticket | ❌ (fire-and-forget) | ✅ com link e copiar |
| Escolher projeto | ❌ fixo (`TAD`) | ✅ qualquer projeto onde você pode criar |
| Escolher tipo de ticket | ❌ fixo (`Tarefa`) | ✅ tipos reais do projeto escolhido |
| Editar resumo/descrição antes de enviar | prompt simples | formulário completo |
| Funciona em páginas com CSP restritivo | ❌ (form/iframe bloqueados) | ✅ (o popup roda fora da página) |
| Dependências externas | Zapier (webhook público) | nenhuma — fala direto com a API do Jira |
| Erros visíveis (campo obrigatório, permissão…) | ❌ silencioso | ✅ mensagem do Jira no popup |

## Instalação (modo desenvolvedor)

1. Baixe este repositório (**Code → Download ZIP** e descompacte) ou clone com git;
2. Abra `chrome://extensions` no Chrome;
3. Ative **Modo do desenvolvedor** (canto superior direito);
4. Clique em **Carregar sem compactação** e selecione a pasta do repositório (a que contém o `manifest.json`);
5. (Opcional) Fixe a extensão na barra pelo ícone de quebra-cabeça.

Para distribuir ao time sem a Chrome Web Store: compartilhe a pasta (ou o repositório) e cada
pessoa carrega sem compactação — ou publique na Web Store como extensão privada/não listada
(conta de desenvolvedor, taxa única de US$ 5).

## Configuração

1. Clique com o botão direito no ícone da extensão → **Opções** (ou clique na engrenagem do popup);
2. Informe:
   - **URL do Jira** — já vem `https://dexterityit.atlassian.net`;
   - **E-mail** da sua conta Atlassian;
   - **API token** — gere em [id.atlassian.com → Security → API tokens](https://id.atlassian.com/manage-profile/security/api-tokens);
3. Use **Testar conexão** e depois **Salvar**.

Segurança: o token fica somente no `chrome.storage.local` do seu navegador e é enviado
apenas para o site Jira configurado (`host_permissions` restrito a `*.atlassian.net`).
O ticket é criado em seu nome (relator = você), diferente do webhook que criava tudo
com um usuário de integração.

## Uso

- O **resumo** vem pré-preenchido com o título da página (editável);
- A **descrição** traz título, URL e o trecho selecionado na página, se houver;
- Os últimos **projeto e tipo usados** ficam memorizados como padrão;
- **Apontar horas (opcional)**: aceita `1h 30m`, `45m`, `2` (= 2h), `1,5` (= 1h 30m) ou `1:30`;
  o apontamento é registrado como worklog no ticket logo após a criação;
- A lista de projetos é cacheada por 24 h — o botão **↻ Projetos** força a atualização;
- Após criar, use **Copiar chave** ou clique no número para abrir o ticket no Jira.

## Estrutura

```
jirainsightextension/
├── manifest.json        # Manifest V3 (permissions: activeTab, scripting, storage)
├── popup.html/.js       # formulário de criação do ticket
├── options.html/.js     # credenciais (URL, e-mail, API token)
├── jira.js              # cliente da API REST do Jira Cloud (v3) + conversão texto→ADF
├── styles.css
└── icons/               # PNGs gerados por icons/generate.mjs (node icons/generate.mjs)
```

## App para macOS (barra de menus)

Em [`macos/`](macos/README.md) há a versão para Mac: em vez da página do navegador, ela captura
o **aplicativo em primeiro plano e o título da janela ativa** (e o texto selecionado, via
permissão de Acessibilidade) e cria o ticket com o mesmo fluxo — projeto, tipo, apontamento de
horas e número do ticket de volta. Swift puro, sem dependências: `swift run` para testar ou
`./make-app.sh` para gerar o `.app`; detalhes no README da pasta.

## Publicação na Chrome Web Store

Material pronto em [`store/`](store/) (capturas 1280×800 e promo tile 440×280) e política de
privacidade em [`PRIVACY.md`](PRIVACY.md) — a URL pública desse arquivo serve como
"privacy policy URL" na ficha da loja.

1. Gere o pacote (ZIP com o `manifest.json` na raiz, só os arquivos de runtime):

   ```bash
   zip -r jira-quick-ticket-v1.0.0.zip manifest.json popup.html popup.js \
     options.html options.js jira.js styles.css \
     icons/icon16.png icons/icon32.png icons/icon48.png icons/icon128.png
   ```

2. Crie a conta de desenvolvedor em <https://chrome.google.com/webstore/devconsole>
   (taxa única de US$ 5) e use **+ Novo item** → envie o ZIP;
3. Preencha a ficha (idioma pt-BR, categoria Produtividade), suba as capturas de `store/`,
   informe a URL da política de privacidade, justifique as permissões e preencha as
   práticas de privacidade (nenhum dado é coletado pelo desenvolvedor);
4. Visibilidade: **Não listada** (instalável pelo link, fora da busca) é o ideal para uso
   interno; **Pública** também é possível;
5. Envie para revisão (algumas horas a poucos dias). Para atualizar: aumente `version`
   no `manifest.json`, gere novo ZIP e reenvie.

## Limitações conhecidas

- Projetos cujo tipo de ticket exige **campos obrigatórios extras** (além de resumo/descrição)
  retornam o erro do Jira no popup — crie por lá ou ajuste a tela de criação do projeto;
- Se o **registro de horas** estiver desabilitado no projeto, o ticket é criado normalmente
  e o popup avisa que o apontamento falhou;
- Sites Jira com **domínio próprio** (fora de `*.atlassian.net`) exigem ajustar
  `host_permissions` no `manifest.json`;
- Em páginas restritas (`chrome://…`, Chrome Web Store) a extensão funciona,
  mas sem capturar título/seleção da página.
