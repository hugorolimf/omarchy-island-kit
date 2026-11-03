.pragma library

// The catalog comes from the network, so nothing in it is trusted: it is
// rebuilt here with only the known fields, strings of bounded length and
// lists of bounded size, before the shell reads any of it.

var MAX_PLUGINS = 64
var MAX_SECTIONS = 16
var MAX_PACK = 16
var MAX_TAKES_OVER = 8
var MAX_TEXT = 300

function text(v) {
  return typeof v === "string" ? v.slice(0, MAX_TEXT) : ""
}

function id(v) {
  return typeof v === "string" && v.length <= 128 && /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(v) ? v : ""
}

function repo(v) {
  return typeof v === "string" && v.length <= 200 && /^https:\/\/github\.com\/[A-Za-z0-9._-]+\/[A-Za-z0-9._-]+$/.test(v) ? v : ""
}

// The first `max` entries of an array (anything else is an empty list).
function head(v, max) {
  return Array.isArray(v) ? v.slice(0, max) : []
}

function section(s) {
  if (!s || typeof s !== "object" || !id(s.id)) return null
  return { id: id(s.id), pt: text(s.pt), en: text(s.en), hint_pt: text(s.hint_pt), hint_en: text(s.hint_en) }
}

function member(m) {
  if (!m || typeof m !== "object" || !id(m.id)) return null
  return { id: id(m.id), repo: repo(m.repo) }
}

function plugin(p) {
  if (!p || typeof p !== "object" || !id(p.id)) return null
  var out = {
    id: id(p.id), section: id(p.section), name: text(p.name), icon: text(p.icon),
    pt: text(p.pt), en: text(p.en), repo: repo(p.repo),
    status: p.status === "published" ? "published" : "soon",
    self: p.self === true, external: p.external === true,
  }
  var pack = head(p.pack, MAX_PACK).map(member).filter(function(m) { return m !== null })
  if (pack.length > 0) out.pack = pack
  var takes = head(p.takesOver, MAX_TAKES_OVER).map(id).filter(function(t) { return t !== "" })
  if (takes.length > 0) out.takesOver = takes
  return out
}

// A clean catalog, or null when the text is not one.
function parse(textIn) {
  var c = null
  try { c = JSON.parse(String(textIn || "").slice(0, 262144)) } catch (e) { return null }
  if (!c || typeof c !== "object" || !Array.isArray(c.plugins)) return null
  var version = typeof c.version === "number" && isFinite(c.version) ? c.version : 0
  return {
    version: version,
    sections: head(c.sections, MAX_SECTIONS).map(section).filter(function(s) { return s !== null }),
    plugins: head(c.plugins, MAX_PLUGINS).map(plugin).filter(function(p) { return p !== null }),
  }
}
