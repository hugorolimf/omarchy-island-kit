.pragma library

// Interface texts of the catalog, Portuguese or English by system language.

var pt = {
  title: "Catálogo",
  installedCount: "INSTALADOS",
  availableCount: "DISPONÍVEIS",
  install: "Instalar",
  installing: "Instalando…",
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
