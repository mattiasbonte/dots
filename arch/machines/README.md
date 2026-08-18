# Per-machine quirks

Optional. `first-boot.sh` sources `machines/$(hostname).sh` when present —
AFTER the shared capability/class layers, so quirks override, never
duplicate. One file per machine, only for things detection can't infer
(that one udev rule, that firmware workaround). `paci`/`pari` + the
failure collector are available inside.
