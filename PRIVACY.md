# Política de Privacidade — Jira Quick Ticket

_Última atualização: 22 de julho de 2026_

A extensão **Jira Quick Ticket** cria tickets no Jira Cloud a partir da página atual do navegador. Esta política descreve quais dados a extensão acessa e o que é feito com eles.

## Resumo

**A extensão não coleta, não armazena em servidores próprios e não compartilha nenhum dado com o desenvolvedor ou com terceiros.** Não há servidores intermediários, telemetria, analytics ou anúncios. Toda a comunicação acontece diretamente entre o seu navegador e o site Jira que você configurar.

## Dados que a extensão acessa

| Dado | Quando | Para quê | Onde fica |
|---|---|---|---|
| E-mail e API token do Atlassian | Informados por você na página de opções | Autenticar as chamadas à API REST do seu Jira | Somente no seu navegador (`chrome.storage.local`); enviados apenas ao site Jira configurado, via HTTPS |
| Título, URL e texto selecionado da página atual | Somente quando você clica no ícone da extensão | Pré-preencher o resumo e a descrição do ticket | Exibidos no popup para edição; enviados ao seu Jira somente se você clicar em "Criar ticket" |
| Lista de projetos e tipos de ticket do seu Jira | Ao abrir o popup (cache de 24 h) | Preencher os seletores de projeto e tipo | Cache local no seu navegador |
| Últimos projeto e tipo usados | Ao criar um ticket | Vir pré-selecionados na próxima vez | Somente no seu navegador |

## Permissões utilizadas

- **`activeTab` + `scripting`** — ler título, URL e texto selecionado **da aba ativa, apenas no momento do clique** no ícone. A extensão não lê sua navegação em segundo plano e não injeta código em páginas fora desse momento.
- **`storage`** — guardar localmente credenciais, preferências e o cache de projetos.
- **Acesso a `https://*.atlassian.net`** — chamar a API REST do Jira Cloud (listar projetos/tipos e criar o ticket). Nenhuma outra origem é contatada.

## O que a extensão NÃO faz

- Não envia dados a servidores do desenvolvedor (não existem);
- Não usa cookies, rastreadores, analytics ou publicidade;
- Não lê histórico de navegação nem monitora páginas em segundo plano;
- Não vende nem transfere dados a terceiros;
- Não usa os dados para nenhuma finalidade além de criar o ticket que você pediu.

## Remoção dos dados

Todos os dados ficam no armazenamento local do navegador. Para removê-los, basta desinstalar a extensão (ou limpar os dados dela em `chrome://extensions`). O API token pode ser revogado a qualquer momento em [id.atlassian.com → Security → API tokens](https://id.atlassian.com/manage-profile/security/api-tokens).

## Contato

Dúvidas ou solicitações: abra uma issue em <https://github.com/dfg-dexterity/jirainsightextension/issues>.

---

## Privacy Policy (English summary)

Jira Quick Ticket creates Jira Cloud issues from the current browser page. The extension **collects no data for the developer and has no servers, telemetry, analytics or ads**. Your Atlassian e-mail and API token are stored only in the browser's `chrome.storage.local` and are sent exclusively to the Jira site you configure, over HTTPS. Page title, URL and selected text are read from the active tab **only when you click the extension icon**, are shown for editing, and are sent to your Jira only if you choose to create the ticket. Uninstalling the extension removes all locally stored data; API tokens can be revoked at any time in your Atlassian account settings. Contact: GitHub issues at the repository above.
