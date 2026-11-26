#!/usr/bin/env bash
# Autoteste: instalador presente e configurado no live.
if command -v calamares >/dev/null && [[ -f /etc/calamares/settings.conf ]]; then
  echo "BRISA:calamares=present"
else
  echo "BRISA:calamares=ausente"
fi
