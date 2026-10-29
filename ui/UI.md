# hugo.ui — componentes "anatomy" dos painéis

Cópia de `/usr/share/omarchy/shell/Ui/` (o `qs.Ui` do Omarchy) com o visual
anatomy. A API é a mesma (propriedades, sinais, funções), então um painel do
Omarchy funciona trocando só o import. **Não tem `manifest.json` de propósito**:
é uma biblioteca, não um plugin.

- Fonte de trabalho: `~/.local/share/hugo-bar/hugo.ui/` (edite lá e copie
  pronto; cada gravação em `~/.config/omarchy/plugins` recarrega o shell).
- Tokens: `Anatomy.qml` (cores, raios, fontes, curva `Anatomy.ease`) e ícones
  em traço `Anatomy.icons.*`, desenhados com `AnatomyIcon { path: ... }`.
- `AnatomyLift` = sombra "lift" do protótipo; `BorderGeometry.js` é cópia local
  do Commons (o import relativo `../Commons` não funciona daqui).
- Piloto pronto: `hugo.monitor` (Tela).

## Converter outro painel (ex.: som = `omarchy.audio`)

1. Copiar o painel original para a fonte de trabalho:
   `cp -a /usr/share/omarchy/shell/plugins/panels/audio ~/.local/share/hugo-bar/hugo.audio`
   (`chmod -R u+w` na cópia). Se o painel tiver serviço/pasta extra, copie tudo.
2. No(s) `.qml`: trocar `import qs.Ui` por `import "../hugo.ui"`
   (arquivos em subpastas: `"../../hugo.ui"`).
3. Trocar `moduleName: "omarchy.audio"` por `moduleName: "hugo.audio"`.
   **Não mexer** em `ipcTarget` nem no `target:` dos `IpcHandler`
   (`omarchy.audio`): atalhos e scripts continuam chamando o id antigo.
4. Traduzir TODO texto visível para pt-BR (títulos, cabeçalhos em caixa alta,
   estados, dicas, mensagens em `Model.js`). Não traduzir chaves/ids internos.
5. Visual (opcional, mas é o que deixa igual à Tela):
   - textos soltos: `color: root.bar.foreground` → `Anatomy.strong`
     (corrido `Anatomy.text`, legenda `Anatomy.muted`); `font.family:
     root.bar.fontFamily` → `Anatomy.sans` (números e rótulos: `Anatomy.mono`);
     `font.bold: true` → `font.weight: Font.DemiBold`/`Medium`.
   - ícones Nerd Font do cabeçalho/linhas → `AnatomyIcon` (adicione o caminho
     em `Anatomy.icons` se faltar; grade 24, mesmo traço do hugo.bar).
   - remover `fill:` / `currentFill:` passados a `CursorSurface` (os padrões
     já são os do anatomy: branco 5% no cursor, azul translúcido no atual).
   - `font.pixelSize` só aceita inteiro (use `Math.round`).
6. `manifest.json`: `id` `hugo.audio`, `name`/`barWidget.displayName` em
   português, e **manter** `"omarchy": { "clonedFrom": "omarchy.audio" }` —
   é o que roteia o IPC antigo para o clone e libera o `summon` do OSD.
7. `omarchy plugin validate ~/.local/share/hugo-bar/hugo.audio`, depois
   copiar para `~/.config/omarchy/plugins/hugo.audio` de uma vez.
8. `~/.config/omarchy/shell.json` (backup antes): trocar no layout
   `"id": "omarchy.audio"` por `"hugo.audio"`, mantendo `group`. Avisar quem
   cuida do `hugo.bar` para mapear o novo id (ícone, dica e valor ao vivo).
9. `omarchy-restart-shell`, abrir por IPC (`omarchy-shell omarchy.audio open`),
   capturar com `grim`, fechar, olhar `qs log -p /usr/share/omarchy/shell | grep hugo`
   e a CPU do quickshell.

Reverter um painel: voltar o id no `shell.json` (ou restaurar o backup) e
apagar a pasta `hugo.<nome>` em `~/.config/omarchy/plugins`.
