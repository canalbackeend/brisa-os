# Checklist de aceite — Fase 1 (modo macOS)

Faça no notebook Samsung, com o pendrive gravado (veja `docs/guia.md`). Anote ✓ ou ✗ e o que viu.

| # | O que testar | Como | Resultado |
|---|---|---|---|
| 0 | Modelo do processador | etiqueta do notebook, ou no live: Terminal → `lscpu \| grep "Model name"` | |
| 1 | Inicia até a área de trabalho modo macOS, sem terminal | ligar pelo pendrive | |
| 2 | Wi-Fi, som, brilho, bateria, touchpad | ícones da barra superior / teclas Fn | |
| 3 | Menu do app no topo da tela | abrir Arquivos (Dolphin), Kate e Terminal | |
| 4 | Atalhos estilo Mac | *pendente — depende da decisão sobre o Toshy* | |
| 5 | YouTube 1080p liso | Chromium → vídeo em 1080p; Terminal → `vainfo \| grep -i h264` deve listar perfis H264 | |
| 6 | Instalação conclui e o sistema instalado inicia no modo macOS | ícone **Instalar** | |
| 7 | Memória com o sistema instalado parado | Terminal → esperar 2 min → `free -m` (coluna *usado*) | ___ MB |
| 8 | Sistema instalado sem sobras do live | não há ícone Instalar; pede senha no login | |
| 9 | Dual boot (se houver Windows) | menu do GRUB mostra o Windows | |
