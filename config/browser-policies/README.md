# Browser policies

`setup/post_install.sh` installs these files as browser policies. Keep them as
standard JSON without comments; extension IDs are documented below instead.

`brave-recommended.json` sets Google as Brave's default search engine. This is
a recommended policy, so users can override it in Brave's settings. Existing
user choices take precedence.

## Extensions

| Browser | Extension | ID |
| --- | --- | --- |
| Brave | Surfingkeys | `gfbliohnnapiefjpjlpjnehglfpaknnc` |
| Brave | Google Docs Offline | `ghbmnnjooekpmoecnnnilnnbdlolhkhi` |
| Edge | Surfingkeys | `kgnghhfkloifoabeaobjkgagcecbnppg` |
| Edge | uBlock Origin | `odfafepnkmbhccpbejgmiehpchacaeak` |

Firefox installs Surfingkeys using its named Mozilla download URL,
`surfingkeys_ff`.

In Brave and Edge, `force_installed` installs the extension and prevents its
removal through the browser. `file_url_navigation_allowed` grants access to
local files, allowing Surfingkeys on local pages. `update_url` selects the
extension store used for installation and updates.
