# Distro própria — Fase 1: ISO live com modo macOS (KDE Plasma)

Data: 2026-11-26
Status: rascunho para aprovação

Nome provisório da distro: **"Brisa"** (placeholder; troca-se em um único lugar, ver "Identidade").

## 1. Intenção e o porquê

O usuário usa macOS e Windows no dia a dia e quer uma distro Linux **leve e bonita**
em que ele se sinta em casa de primeira — **sem curva de aprendizado**. Por isso a
distro terá dois modos completos, alternáveis: **modo macOS** e **modo Windows 11**.
"Completo" significa visual **e** comportamento (atalhos de teclado, posição dos
menus e botões), não só tema.

Esta fase entrega o **modo macOS** numa **ISO live instalável**: o usuário grava a
ISO num pendrive com o balenaEtcher (no Mac), inicia o notebook de teste, usa o
sistema sem instalar e, se gostar, instala pelo ícone "Instalar".

Máquina-alvo de teste: notebook Samsung, Intel Core i3 (geração ainda não informada; o design não depende dela: H.264 forçado e drivers VA-API das duas famílias. Se for 1ª geração (Arrandale), Wayland+vidro pode ficar pesado — verificar no primeiro teste. Modelo a confirmar na
etiqueta), 8 GB RAM, SSD, gráfico Intel HD integrado. Tela provavelmente 1366×768.

## 2. Objetivos

1. ISO x86_64 híbrida, inicializável por pendrive em **UEFI e BIOS legado**.
2. Sessão **live** com login automático direto na área de trabalho modo macOS.
3. **Instalador gráfico** (Calamares) em português, acessível por ícone "Instalar" no dock.
4. Modo macOS fiel (seção 7): barra superior com **menu global**, dock flutuante
   centralizado, botões de janela "semáforo" à esquerda, desfoque, busca estilo
   Spotlight, atalhos estilo Mac.
5. Leve: com o sistema instalado e ocioso, meta **flexível** de ~700 MB de RAM medida no Samsung. **Decidido pelo usuário: em conflito, a fidelidade ao macOS vence** (vidro, animações, Toshy ficam). Cortam-se primeiro serviços invisíveis (indexador, notificadores), nunca o visual ou os atalhos.
6. Programas atuais instaláveis: loja gráfica (Flatpak/Flathub) + pacotes Arch.
7. YouTube em 1080p liso usando decodificação de vídeo pela GPU Intel.
8. ISO gerada **automaticamente no GitHub Actions** a cada push; usuário baixa o arquivo.

## 3. Não-objetivos (desta fase)

- Modo Windows 11 e o alternador de modos (Fase 2; a estrutura já deve prever, ver 7.8).
- Navegador próprio sobre WebKitGTK (projeto futuro separado).
- Chromium compilado sob medida (futuro, se medições justificarem).
- Secure Boot (usuário desativa na BIOS; documentado no guia).
- Testar a ISO no Mac. Nenhuma virtualização será instalada no Mac do usuário.

## 4. Anti-objetivos (falha mesmo que "funcione")

- Parecer "um Linux genérico com tema": menus dentro da janela no modo macOS,
  ícones desencontrados, fontes diferentes entre apps Qt e GTK.
- Exigir terminal para tarefas comuns (instalar app, atualizar, Wi-Fi, trocar modo).
- Redistribuir arquivos da Apple ou da Microsoft (logos, ícones originais, fonte SF Pro,
  papéis de parede oficiais). Tudo deve ser código aberto/licença livre ou próprio.
- Serviços pesados em segundo plano ligados por padrão (indexador Baloo, Akonadi/KDE PIM,
  KDE Connect, telemetria).

## 5. Restrições

- Mac do usuário: Apple M1, 8 GB, sem Docker/VM — **não instalar nada de virtualização**.
  Tem `git` e `brew`. Toda montagem acontece no GitHub Actions.
- Repositório GitHub **público** do usuário (decidido: no plano gratuito, repositório privado não comporta ISO de 2–3 GB nem 30–60 min por build). Só contém configurações e scripts, nada pessoal. O usuário cria a conta/repositório e faz a
  autenticação por conta própria (Claude não digita senhas nem tokens). Nada é enviado
  ao GitHub sem autorização explícita do usuário.
- ISO entregue como **artifact do workflow** (download com login no GitHub, retenção de 90 dias). Quando a ISO tiver menos de 2 GB, também é anexada a um **Release** (limite do GitHub: 2 GB por arquivo).
- Base Arch Linux: não há suporte a Secure Boot de fábrica.
- Licenças: GPL/OFL/CC; sem marcas registradas de terceiros na identidade visual.

## 6. Abordagens consideradas (decidido)

Base da interface — apresentadas ao usuário com esboços dos dois modos:

| | Opção | Fidelidade | RAM ociosa (estim.) | Decisão |
|---|---|---|---|---|
| A | **KDE Plasma 6 enxuto (Wayland)** | Alta: único com menu global funcional no Wayland; vidro, animações, atalhos por modo | ~500–700 MB | **Escolhida pelo usuário** |
| B | XFCE + Plank (X11) | Média: menu global falha em apps novos (GTK4), sem acrílico | ~350–500 MB | Descartada |
| C | labwc + painéis avulsos | Baixa: sem menu global, menu de apps em tela cheia | ~250–350 MB | Descartada |

Porquê A: o objetivo central é zero curva de aprendizado, e só o Plasma entrega os dois
modos de forma fiel. 8 GB de RAM comportam com folga.

Local de montagem da ISO — o usuário escolheu **GitHub Actions** (alternativas: montar no
Mac via OrbStack — recusado, não quer virtualização; montar no próprio Samsung — mais
trabalhoso a cada ajuste).

Base do sistema: **Arch Linux + archiso** (decisão do Claude, aceita pelo usuário):
pacotes sempre atuais e os temas MacTahoe/Calamares disponíveis no AUR.

## 7. Design

### 7.1 Repositório

```
OS/
  .github/workflows/build-iso.yml   # monta a ISO e publica como artifact
  archiso/                          # perfil archiso (derivado de "releng")
    profiledef.sh
    packages.x86_64
    pacman.conf                     # inclui repo local [brisa] com pacotes do AUR
    airootfs/                       # arquivos copiados para o sistema live
    efiboot/ grub/ syslinux/        # menus de boot com a identidade da distro
  aur/                              # lista de pacotes AUR a compilar no CI
  branding/                         # logo, papel de parede, nome — fonte única
  modes/macos/                      # toda a configuração do modo macOS
  calamares/                        # configuração e branding do instalador
  docs/                             # guia do usuário (gravar pendrive, BIOS, instalar)
```

### 7.2 Pipeline de montagem (GitHub Actions)

1. Runner `ubuntu-latest`, container `archlinux:latest` em modo privilegiado.
2. Compila os pacotes AUR listados em `aur/` (usuário não-root dentro do container) e
   monta um repositório pacman local `[brisa]`.
3. Roda `mkarchiso` com o perfil em `archiso/`.
4. Publica `brisa-AAAA.MM.DD-x86_64.iso` + `sha256` como artifact.
5. Disparo: push na branch principal e manual (`workflow_dispatch`).

### 7.3 Sistema base

- Kernel `linux` (padrão Arch), `linux-firmware`, `intel-ucode`.
- Vídeo Intel: `mesa`, `intel-media-driver` **e** `libva-intel-driver` (o certo depende
  da geração do i3; incluir os dois cobre Sandy Bridge até atuais), `libva-utils`.
- Rede: NetworkManager (Wi-Fi pelo applet). Áudio: PipeWire + WirePlumber.
- Bluetooth: bluez (desligado até o usuário ativar).
- Idioma padrão: pt_BR.UTF-8, teclado ABNT2, fuso America/Sao_Paulo (alteráveis no instalador).
- Inicialização: UEFI (systemd-boot/GRUB do archiso) e BIOS (syslinux), ambos com a marca da distro.

### 7.4 Plasma enxuto

- Plasma 6 em Wayland, SDDM com tema da distro, login automático na sessão live.
- Instalar apenas o necessário: `plasma-desktop`, `kwin`, `systemsettings`, `kscreen`,
  `plasma-nm`, `plasma-pa`, `powerdevil`, `bluedevil`, `kde-gtk-config`, `breeze-gtk`,
  `xdg-desktop-portal-kde`, `dolphin`, `konsole`, `ark`, `gwenview`, `okular`, `kate`,
  `spectacle`, `discover` + `flatpak`.
- **Não** instalar: meta-pacotes `plasma`/`kde-applications`, KDE PIM/Akonadi, KDE Connect,
  plasma-welcome, telemetria (kuserfeedback).
- Baloo desativado por padrão; efeitos KWin pesados (cubo, wobbly) desligados.

### 7.5 Programas incluídos

- Navegador: **Chromium** (repo oficial) com `chromium-flags.conf` pré-configurado para
  decodificação por GPU (VA-API) e menor uso de memória. *(Decisão do Claude)* O YouTube é
  **forçado a H.264** (política/extensão estilo h264ify pré-instalada), porque Intel HD
  anteriores à 7ª geração não decodificam VP9/AV1 por hardware e H.264 funciona em todas.

### 7.5.1 Atualizações do sistema instalado *(decisão do Claude)*

Na Fase 1 o sistema instalado **não** aponta para o repositório `[brisa]` (ele só existe
no build). Atualizações vêm dos repositórios oficiais do Arch e do Flathub. Temas,
Toshy e configurações do modo ficam congelados na versão da ISO. Consequência aceita
para a fase de testes: receber a Fase 2 (modo Windows 11) exige reinstalar pela ISO nova.
Um repositório próprio com atualizações fica para depois da Fase 2.
- Vídeo: `mpv` + `yt-dlp`, com atalho "Abrir no player" para links do YouTube.
- Loja: **Discover** com Flathub habilitado (apps gráficos). Atualizações do sistema Arch
  por um atualizador gráfico com ícone na bandeja (escolha do construtor; ex. `arch-update`).
- Instalador: **Calamares** (AUR), só presente na sessão live.

### 7.6 Modo macOS — visual

| Elemento | Escolha |
|---|---|
| Tema Plasma/cores/decoração de janela | **MacTahoe KDE theme** (vinceliuice), semáforo à esquerda |
| Apps GTK | MacTahoe GTK theme |
| Apps Qt | Kvantum com tema MacTahoe |
| Ícones | MacTahoe icon theme |
| Cursor | MacTahoe cursors |
| Fonte da interface | **Inter** 10 pt (~13 px a 96 dpi); monoespaçada JetBrains Mono |
| Papel de parede | próprio, licença livre (em `branding/`) |
| Escala | 1x; conferir legibilidade em 1366×768 no Samsung |

Layout:
- **Barra superior** (~24 px, translúcida): logo ◆ da distro (menu "Sobre/Ajustes/
  Reiniciar/Desligar", papel do menu Apple), nome do app ativo, **menu global**,
  e à direita bandeja (Wi-Fi, som, bateria), busca e relógio "qui 14:32".
- **Dock inferior** flutuante, centralizado, ícones ~48 px, só ícones, indicador de app
  aberto, separador + lixeira à direita. Fixados: Arquivos, Navegador, Vídeos (mpv),
  Textos, Terminal, Loja, Ajustes, **Instalar** (só no live).
- Sem ícones na área de trabalho.
- Busca estilo Spotlight: KRunner centralizado.

### 7.7 Modo macOS — atalhos

A tecla Super (Windows) faz o papel do ⌘. Implementação: **Toshy** (remapeamento
consciente de aplicativo, compatível com KWin Wayland), pré-instalado no sistema.
Se o Toshy não puder ser pré-instalado de forma confiável na ISO, o construtor deve
parar e reportar antes de adotar alternativa (ex. `keyd` com mapeamento global).

Atalhos mínimos que precisam funcionar:
- Super+C/V/X/Z/A/S/F/T/W/Q (copiar, colar, recortar, desfazer, selecionar tudo,
  salvar, buscar, nova aba, fechar janela/aba, sair do app)
- Super+Espaço: busca (KRunner) · Super+Tab: alternar apps
- Super+Shift+3 / Super+Shift+4: captura de tela inteira / área (Spectacle)
- No terminal, Super+C/V copia/cola (não envia Ctrl+C ao processo)

### 7.8 Preparação para a Fase 2

Toda configuração do modo macOS fica isolada em `modes/macos/` e é aplicada por um
script único (`aplicar-modo macos`). A Fase 2 adiciona `modes/windows11/` e o alternador
(na tela de login e em Ajustes). Nesta fase, a ISO tem apenas o modo macOS.

### 7.9 Instalador (Calamares)

- Português por padrão; marca da distro.
- Particionamento: "apagar disco" e "manual"; sistema de arquivos ext4.
- Copia o sistema live, remove o que é só do live (Calamares, autologin, ícone
  Instalar) e cria o usuário escolhido já no modo macOS.
- Suporta instalar em UEFI e BIOS.

### 7.10 Identidade

Nome, logo ◆, papel de parede e cores ficam em `branding/` e são referenciados por
archiso, SDDM, Calamares, menu de boot e "Sobre". Trocar o nome provisório "Brisa"
deve exigir editar só esse diretório.

### 7.11 Guia do usuário (`docs/`)

Passo a passo curto: baixar a ISO do GitHub, gravar com balenaEtcher, entrar na BIOS
do Samsung (desligar Secure Boot, escolher pendrive), testar no live, instalar.

## 8. Critérios de aceite (verificados no Samsung pelo usuário)

1. Pendrive gravado pelo Etcher inicia o Samsung até a área de trabalho modo macOS sem terminal.
2. Wi-Fi, som, brilho, bateria e touchpad funcionam no live.
3. Menu global aparece no topo para Dolphin, Kate e Konsole.
4. Atalhos da seção 7.7 funcionam em Chromium, Dolphin e Konsole.
5. YouTube 1080p toca sem travar; `vainfo` mostra decodificação H.264 ativa.
6. Instalação pelo ícone "Instalar" conclui e o sistema instalado inicia no modo macOS.
7. Uso de RAM do sistema instalado ocioso é medido (`free -m` após 2 min parado) e registrado; ~700 MB é referência, não reprovação, desde que nada visível do modo macOS tenha sido cortado para atingi-la.

## 9. Deixado para o construtor

- Versões exatas dos pacotes e ordem de compilação do AUR.
- Gerenciador de boot do UEFI dentro do archiso (systemd-boot ou GRUB).
- Atualizador gráfico do sistema (desde que tenha ícone na bandeja e não exija terminal).
- Detalhes de flags do Chromium, desde que VA-API fique ativo.
- Arte do papel de parede e do logo (simples e original).

## 10. Riscos conhecidos

- Toshy pré-instalado em imagem live pode exigir ajustes (instala por usuário).
- Temas MacTahoe evoluem rápido; fixar um commit conhecido para builds reprodutíveis.
- Primeira validação real só acontece no Samsung; cada ciclo de ajuste = novo build no CI
  + regravar pendrive.
