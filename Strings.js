.pragma library

// Interface texts of the catalog, Portuguese or English by system language.

var pt = {
  title: "Catálogo",
  installedCount: "INSTALADOS",
  availableCount: "DISPONÍVEIS",
  install: "Instalar",
  installing: "Instalando…",
  update: "Atualizar",
  updating: "Atualizando…",
  updateAll: "Atualizar tudo",
  updateTo: "Nova versão no GitHub:",
  updateReady: "Há novidades no GitHub",
  selfUpdateHint: "reinicia a barra",
  selfUpdateFailed: "Não deu para atualizar o Island Kit",
  localChanges: "ALTERADO AQUI",
  localChangesHint: "Há novidades no GitHub, mas este plugin tem alterações locais",
  checking: "Conferindo o GitHub…",
  checkFailed: "Não deu para conferir tudo no GitHub.",
  upToDate: "Tudo em dia com o GitHub.",
  removing: "Removendo…",
  installed: "Instalado",
  disabled: "Desativado",
  enable: "Ativar",
  soon: "Em breve",
  view: "Ver",
  installAll: "Instalar tudo",
  thisPlugin: "Este plugin",
  remove: "Remover do sistema",
  confirmRemove: "Clique de novo para remover",
  failed: "Não deu certo: ",
  nothingFor: "Nada encontrado para",
  restartHint: "Alguns plugins só aparecem depois de reiniciar o shell.",
  restart: "Reiniciar",
  offline: "Sem conexão: mostrando a lista que veio com o Kit.",
  footer: "Os plugins Island usam este Kit; os Glass funcionam sozinhos. Os Extras abrem a página de instalação."
}

var en = {
  title: "Catalog",
  installedCount: "INSTALLED",
  availableCount: "AVAILABLE",
  install: "Install",
  installing: "Installing…",
  update: "Update",
  updating: "Updating…",
  updateAll: "Update all",
  updateTo: "New version on GitHub:",
  updateReady: "New changes on GitHub",
  selfUpdateHint: "restarts the bar",
  selfUpdateFailed: "Couldn't update Island Kit",
  localChanges: "CHANGED HERE",
  localChangesHint: "New changes on GitHub, but this plugin has local changes",
  checking: "Checking GitHub…",
  checkFailed: "Couldn't check everything on GitHub.",
  upToDate: "Everything matches GitHub.",
  removing: "Removing…",
  installed: "Installed",
  disabled: "Disabled",
  enable: "Enable",
  soon: "Soon",
  view: "View",
  installAll: "Install all",
  thisPlugin: "This plugin",
  remove: "Remove from the system",
  confirmRemove: "Click again to remove",
  failed: "Didn't work: ",
  nothingFor: "Nothing found for",
  restartHint: "Some plugins only show up after restarting the shell.",
  restart: "Restart",
  offline: "Offline: showing the list that came with the Kit.",
  footer: "Island plugins use this Kit; Glass ones work on their own. Extras open their install page."
}

function forLocale(name) {
  return String(name || "").indexOf("pt") === 0 ? pt : en
}
