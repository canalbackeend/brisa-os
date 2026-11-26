# Brisa — Fase 1 (ISO live modo macOS) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar no GitHub Actions uma ISO live x86_64 da distro "Brisa" (Arch + KDE Plasma 6 enxuto) que inicia em UEFI e BIOS direto num desktop modo macOS e instala pelo Calamares.

**Architecture:** Perfil archiso derivado de `releng` em `archiso/`; pacotes que não estão nos repositórios oficiais (temas pinados, Calamares, Toshy) são compilados no CI para um repositório pacman local `[brisa]` consumido pelo mkarchiso. Todo o visual/comportamento do modo macOS vive em `modes/macos/` e é aplicado por `brisa-aplicar-modo macos`. O CI valida estaticamente o repositório (bats), monta a ISO e faz um teste de boot em QEMU/KVM (UEFI e BIOS) lendo marcadores gravados na serial por um serviço de autoteste do live.

**Tech Stack:** archiso/mkarchiso, pacman/makepkg, KDE Plasma 6 (Wayland), SDDM, Kvantum, Calamares, Toshy, Chromium, mpv/yt-dlp, Flatpak/Discover, GitHub Actions, QEMU+OVMF, bats-core, shellcheck.

**Spec:** `docs/superpowers/specs/2026-11-26-distro-modo-macos-design.md`

## Global Constraints

- Arquitetura alvo: x86_64. Boot em **UEFI e BIOS legado**. Sem Secure Boot.
- Nome da distro, logo, papel de parede e cores vêm **só** de `branding/` (`branding/brisa.conf` define `BRISA_NAME="Brisa"`, `BRISA_ID="brisa"`). Nenhum outro arquivo escreve "Brisa" literalmente — usa a variável/arquivo gerado.
- Proibido no repositório e na ISO: logos, ícones, fontes (SF Pro/Segoe UI) e papéis de parede da Apple ou da Microsoft.
- Idioma padrão `pt_BR.UTF-8`, teclado `br` (ABNT2), fuso `America/Sao_Paulo`.
- Plasma 6 em **Wayland**; **não** instalar meta-pacotes `plasma` / `kde-applications`, nem KDE PIM/Akonadi, KDE Connect, plasma-welcome, kuserfeedback.
- Baloo desligado; efeitos KWin cubo/wobbly desligados; blur **ligado**.
- Em conflito RAM × fidelidade, **fidelidade ao macOS vence**; cortar primeiro serviços invisíveis.
- Temas MacTahoe (gtk, kde, icon, cursors) **pinados em commit** fixo.
- Sistema instalado **não** referencia o repo `[brisa]` no `pacman.conf`.
- Fonte da interface: Inter 10 pt; monoespaçada JetBrains Mono. Escala 1x.
- ISO: `brisa-AAAA.MM.DD-x86_64.iso` + `.sha256`, artifact do workflow (retenção 90 dias); se < 2 GB, também anexada a um Release.
- Claude não digita senhas/tokens; nada vai ao GitHub sem autorização explícita do usuário.

## Review Focus

1. **Notebook antigo inicia em BIOS legado (sem UEFI)** → a ISO precisa chegar ao desktop igual. Teste: boot QEMU com SeaBIOS além de OVMF (Task 2).
2. **Live sem internet** (Wi-Fi ainda não configurado) → desktop carrega sem travar esperando rede; extensão H.264 apenas falta, sem erro visível; instalação via Calamares funciona offline. Teste: boot QEMU com `-nic none` (Task 4) e Calamares sem módulos que exigem rede (Task 8).
3. **Disco do Samsung com Windows ou outros dados** → nada é apagado sem o usuário escolher "apagar disco" explicitamente; sem particionamento automático silencioso. Teste: bats sobre `calamares/modules/partition.conf` (Task 8).
4. **Tela 1366×768** → barra superior, dock e janela do Calamares cabem inteiras. Teste: screendump QEMU a 1366×768 salvo como artifact para revisão humana + bats sobre `windowSize` do branding Calamares (Tasks 5 e 8).
5. **Primeiro boot do sistema instalado** → sem autologin, sem Calamares, sem ícone "Instalar", usuário criado já no modo macOS. Teste: bats sobre a lista de remoção do `shellprocess` + teste do script `brisa-pos-instalacao` em chroot simulado (Task 8).

---

## File Structure

```
.github/workflows/build-iso.yml      # validar → AUR/pkgs → mkarchiso → boot test → artifact/release
branding/brisa.conf                  # nome/ID/cores (fonte única)
branding/logo.svg, wallpaper.svg     # arte original
scripts/render-branding.sh           # gera os arquivos derivados (os-release, boot menus, calamares branding)
pkgs/<nome>/PKGBUILD                 # pacotes próprios: brisa-mactahoe-*, brisa-modes, brisa-live
aur/packages.txt                     # pacotes AUR a compilar (um por linha, com commit/versão)
scripts/build-repo.sh                # compila pkgs/ + aur/ → repo local [brisa]
archiso/                             # perfil (profiledef.sh, packages.x86_64, pacman.conf, airootfs/, efiboot/, grub/, syslinux/)
modes/macos/                         # look-and-feel org.brisa.macos, kwinrc, kdeglobals, kvantum, gtk, toshy, chromium
scripts/brisa-aplicar-modo           # aplica um modo ao usuário atual (instalado em /usr/bin)
calamares/                           # settings.conf, modules/*.conf, branding/brisa/
tests/static/*.bats                  # validação estática do repositório
tests/boot/boot-test.sh              # QEMU + leitura de marcadores na serial
docs/guia.md                         # guia do usuário (pt-BR)
```

---

### Task 1: Repositório, branding e validação estática

**Files:**
- Create: `branding/brisa.conf`, `branding/logo.svg`, `branding/wallpaper.svg`, `scripts/render-branding.sh`, `tests/static/branding.bats`, `tests/static/forbidden-assets.bats`, `.gitignore` (inclui `.superpowers/`, `out/`, `work/`)

**Interfaces:**
- Produces: `scripts/render-branding.sh <out_dir>` gera `<out_dir>/os-release`, `<out_dir>/brisa-name.txt`; tasks seguintes adicionam saídas. `branding/brisa.conf` exporta `BRISA_NAME`, `BRISA_ID`, `BRISA_ACCENT` (hex).

- [ ] **Step 1: Testes falhando** — `branding.bats`: `render-branding.sh out` cria `out/os-release` contendo `NAME="Brisa"` e `ID=brisa` e `ID_LIKE=arch`; alterar `BRISA_NAME` num conf temporário muda a saída. `forbidden-assets.bats`: nenhum arquivo do repo casa (case-insensitive) com `SF-Pro|SFNS|segoeui|apple-logo|windows-logo|\.icns$`; nenhum SVG contém o path do logo da Apple/Microsoft (checar pelos nomes de arquivo e por `<title>` contendo "Apple"/"Microsoft"/"Windows").
- [ ] **Step 2:** `bats tests/static` → FAIL.
- [ ] **Step 3:** Implementar `brisa.conf`, arte original simples (◆ em gradiente cônico como nos esboços; papel de parede gradiente roxo→azul→rosa→pêssego) e `render-branding.sh` (bash, `set -euo pipefail`, shellcheck limpo).
- [ ] **Step 4:** `bats tests/static && shellcheck scripts/*.sh` → PASS.
- [ ] **Step 5:** `git init`, commit `feat: branding e validação estática`.
- [ ] **Step 6 (usuário):** Pedir ao usuário que crie no GitHub um repositório **público** vazio (ex. `brisa-os`) e informe a URL. Perguntar se pode instalar o `gh` via `brew` para facilitar a autenticação; o login (`gh auth login` ou credencial do git) é feito **pelo usuário**. Só então `git remote add origin` + `git push` — com autorização explícita do usuário no chat.

### Task 2: Perfil archiso base + CI + teste de boot (console)

**Files:**
- Create: `archiso/` (copiado de `/usr/share/archiso/configs/releng` no container e ajustado), `archiso/airootfs/etc/locale.conf`, `vconsole.conf` (`KEYMAP=br-abnt2`), `localtime` → `America/Sao_Paulo`, `archiso/airootfs/usr/local/bin/brisa-selftest`, `archiso/airootfs/etc/systemd/system/brisa-selftest.service`, `.github/workflows/build-iso.yml`, `tests/boot/boot-test.sh`, `tests/static/profile.bats`

**Interfaces:**
- Produces:
  - `brisa-selftest` escreve linhas `BRISA:<chave>=<valor>` em `/dev/ttyS0` **e** no journal. Nesta task: `BRISA:boot=ok`. Tasks seguintes registram verificações adicionais em `/usr/lib/brisa/selftest.d/*.sh` (cada script imprime linhas `BRISA:...`; o runner executa todos em ordem).
  - `tests/boot/boot-test.sh <iso> <uefi|bios> <timeout_s> <chave=valor>...` → exit 0 se todas as linhas esperadas aparecem na serial; salva `out/boot-<fw>.log` e `out/screen-<fw>.png` (screendump via QMP).
  - Workflow jobs: `validate` (bats+shellcheck, ubuntu) → `build` (container `archlinux:latest`, `--privileged`) → `boot-test` (ubuntu com KVM habilitado via regra udev, matriz `uefi`/`bios`) → `publish`.

- [ ] **Step 1: Testes falhando** — `profile.bats`: `profiledef.sh` tem `iso_name` vindo do branding, `arch="x86_64"`, `bootmodes` contém um modo BIOS (`bios.syslinux...`) e um UEFI; `packages.x86_64` não contém `plasma`, `kde-applications`, `akonadi`, `kdeconnect`, `plasma-welcome`, `kuserfeedback`; `locale.conf` = `LANG=pt_BR.UTF-8`.
- [ ] **Step 2:** `bats tests/static/profile.bats` → FAIL.
- [ ] **Step 3:** Montar o perfil; `brisa-selftest.service` (`After=multi-user.target`, só no live); workflow com `workflow_dispatch` e `push` em `main`; boot-test com `qemu-system-x86_64 -enable-kvm -m 4096 -vga virtio -serial file:...`, OVMF para UEFI, padrão SeaBIOS para BIOS; o menu de boot entra na entrada padrão por timeout.
- [ ] **Step 4:** Local: `bats tests/static` PASS. CI (após push autorizado): `build` gera ISO; `boot-test` passa em **uefi e bios** com `boot=ok`.
- [ ] **Step 5:** Commit `feat: perfil archiso base, CI e teste de boot`.

### Task 3: Repositório local `[brisa]` (pacotes próprios + AUR)

**Files:**
- Create: `scripts/build-repo.sh`, `aur/packages.txt`, `pkgs/brisa-mactahoe-gtk/PKGBUILD`, `pkgs/brisa-mactahoe-kde/PKGBUILD`, `pkgs/brisa-mactahoe-icons/PKGBUILD`, `pkgs/brisa-mactahoe-cursors/PKGBUILD`, `tests/static/pkgs.bats`
- Modify: `archiso/pacman.conf` (repo `[brisa]` com `Server = file:///repo` e `SigLevel = Optional TrustAll`), `.github/workflows/build-iso.yml` (passo build-repo antes do mkarchiso; cache do repo por hash de `pkgs/` + `aur/`)

**Interfaces:**
- Produces: `scripts/build-repo.sh <repo_dir>` compila tudo como usuário não-root `builder` e roda `repo-add <repo_dir>/brisa.db.tar.gz`. Pacotes disponíveis para tasks seguintes: `brisa-mactahoe-{gtk,kde,icons,cursors}`, `calamares` (AUR), e — se a Task 6 aprovar — `toshy`.
- Cada PKGBUILD de tema usa `source=("git+https://github.com/vinceliuice/<repo>.git#commit=<sha>")` com SHA real fixado no momento da implementação e instala via o `install.sh` do próprio projeto com `-d "$pkgdir/usr/share/..."`.

- [ ] **Step 1: Testes falhando** — `pkgs.bats`: todo `pkgs/*/PKGBUILD` tem `#commit=` com SHA de 40 hex; nenhum PKGBUILD usa branch sem pin; `aur/packages.txt` contém `calamares`; `archiso/pacman.conf` tem `[brisa]`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implementar PKGBUILDs e `build-repo.sh` (AUR: `git clone https://aur.archlinux.org/<pkg>.git`, checkout do commit listado, `makepkg -s --noconfirm`).
- [ ] **Step 4:** bats PASS; CI: job `build` lista os `.pkg.tar.zst` esperados no repo e o mkarchiso resolve `[brisa]`.
- [ ] **Step 5:** Commit `feat: repo local brisa com temas pinados e calamares`.

### Task 4: Plasma enxuto e sessão live

**Files:**
- Modify: `archiso/packages.x86_64` (lista da spec §7.3–7.4: `linux linux-firmware intel-ucode mesa intel-media-driver libva-intel-driver libva-utils networkmanager pipewire pipewire-pulse wireplumber bluez bluez-utils plasma-desktop kwin systemsettings kscreen plasma-nm plasma-pa powerdevil bluedevil kde-gtk-config breeze-gtk xdg-desktop-portal-kde dolphin konsole ark gwenview okular kate spectacle sddm inter-font ttf-jetbrains-mono noto-fonts noto-fonts-emoji`)
- Create: `archiso/airootfs/etc/sddm.conf.d/10-brisa-live.conf` (autologin usuário `live`, sessão `plasma` Wayland), `archiso/airootfs/etc/skel/.config/baloofilerc` (`Indexing-Enabled=false`), criação do usuário `live` sem senha + sudo sem senha (só no live, via `customize_airootfs`/`sysusers`), `archiso/airootfs/usr/lib/brisa/selftest.d/10-plasma.sh`, `tests/static/live.bats`

**Interfaces:**
- Produces: selftest `BRISA:plasma=ok` quando `plasmashell` roda para `live` em sessão Wayland (`XDG_SESSION_TYPE=wayland` no environ do processo); `BRISA:baloo=off`; `BRISA:ram_mb=<n>` (`free -m`, 120 s após o login).

- [ ] **Step 1: Testes falhando** — `live.bats`: autologin `User=live` e `Session=plasma`; baloofilerc desliga indexação; lista de pacotes contém `libva-intel-driver` e `intel-media-driver`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implementar; `NetworkManager` e `sddm` habilitados; bluetooth instalado e não habilitado.
- [ ] **Step 4:** CI boot-test (uefi e bios) espera `plasma=ok baloo=off`; rodar também uma vez com `-nic none` (Review Focus 2) esperando `plasma=ok`. Registrar `ram_mb` no resumo do job.
- [ ] **Step 5:** Commit `feat: plasma enxuto com sessão live wayland`.

### Task 5: Modo macOS — visual e layout

**Files:**
- Create: `modes/macos/look-and-feel/org.brisa.macos/` (`metadata.json`, `contents/defaults`, `contents/layouts/org.kde.plasma.desktop-layout.js`), `modes/macos/config/{kdeglobals,kwinrc,kcminputrc,kvantum.kvconfig,gtk-3.0/settings.ini,gtk-4.0/settings.ini}`, `scripts/brisa-aplicar-modo`, `pkgs/brisa-modes/PKGBUILD` (instala `modes/` em `/usr/share/brisa/modes/` e o script em `/usr/bin/`), `archiso/airootfs/usr/lib/brisa/selftest.d/20-macos.sh`, `tests/static/macos.bats`
- Modify: `archiso/packages.x86_64` (+ `brisa-modes brisa-mactahoe-gtk brisa-mactahoe-kde brisa-mactahoe-icons brisa-mactahoe-cursors kvantum`), autostart do live chamando `brisa-aplicar-modo macos` no primeiro login (marca em `~/.config/brisa/modo`)

**Interfaces:**
- Consumes: pacotes de tema da Task 3; branding (wallpaper, logo) da Task 1.
- Produces: `brisa-aplicar-modo <macos> [--sem-reiniciar-shell]` → exit 0, grava `~/.config/brisa/modo=macos`; idempotente. Fase 2 adicionará `windows11` com o mesmo contrato.

Valores fixados pela spec §7.6:
- Barra superior ~24 px, translúcida: logo da distro (menu Sobre/Ajustes/Reiniciar/Desligar), título do app ativo, **widget Global Menu** (`org.kde.plasma.appmenu`), espaçador, bandeja, busca, relógio no formato `ddd HH:mm`.
- Dock inferior flutuante, centralizado, ícones 48 px, `org.kde.plasma.icontasks`, separador + lixeira à direita. Fixados em ordem: Arquivos (dolphin), Navegador (chromium), Vídeos (mpv), Textos (kate), Terminal (konsole), Loja (discover), Ajustes (systemsettings), Instalar (só se `/run/archiso` existe).
- Decoração Aurorae MacTahoe com botões à esquerda (`ButtonsOnLeft=XIA`, `ButtonsOnRight=`); Kvantum MacTahoe; ícones/cursor MacTahoe; fontes Inter 10 / JetBrains Mono 10; blur ligado; cubo/wobbly desligados; sem ícones na área de trabalho; KRunner centralizado.

- [ ] **Step 1: Testes falhando** — `macos.bats`: layout.js cria painel `top` com `org.kde.plasma.appmenu` e painel `bottom` floating com `icontasks`; `kwinrc` tem `ButtonsOnLeft` contendo `X`, `blurEnabled=true`, `wobblywindowsEnabled=false`; `kdeglobals` fonte `Inter,10`; `brisa-aplicar-modo` rejeita modo desconhecido com exit ≠ 0 e mensagem em português.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implementar look-and-feel e script (`plasma-apply-lookandfeel -a org.brisa.macos --resetLayout`, `kwriteconfig6`, `qdbus6 org.kde.KWin /KWin reconfigure`).
- [ ] **Step 4:** bats PASS; CI boot-test espera `macos_appmenu=ok macos_dock=ok macos_buttons_left=ok` (20-macos.sh lê `plasma-org.kde.plasma.desktop-appletsrc` e `kwinrc` do `live`); boot em **1366×768** (`-device virtio-vga,xres=1366,yres=768`) e screendump salvo como artifact `screen-macos-1366x768.png` para revisão humana (Review Focus 4).
- [ ] **Step 5:** Commit `feat: modo macOS visual`.

### Task 6: Modo macOS — atalhos (Toshy) — **ponto de parada**

**Files:**
- Create: `aur/packages.txt` (+ toshy, se viável) ou `pkgs/brisa-toshy/PKGBUILD`, `modes/macos/toshy/` (config), `archiso/airootfs/usr/lib/brisa/selftest.d/30-atalhos.sh`, `tests/static/atalhos.bats`

**Interfaces:**
- Consumes: `brisa-aplicar-modo macos` (Task 5) passa a habilitar o serviço de usuário do Toshy.
- Produces: `BRISA:toshy=running` no selftest.

- [ ] **Step 1: Spike** — Verificar se o Toshy pode ser empacotado para instalação **sistêmica** (sem o instalador por usuário em `~/.config/toshy`) e rodar com KWin Wayland no live. Se não for viável em até um ciclo de CI: **parar e reportar ao usuário** antes de adotar `keyd` (regra da spec §7.7).
- [ ] **Step 2: Teste falhando** — `atalhos.bats`: config do modo mapeia Super+{C,V,X,Z,A,S,F,T,W,Q} para os equivalentes Ctrl; Super+Espaço → KRunner; Super+Tab → alternador; Super+Shift+3 / Super+Shift+4 → Spectacle tela inteira / região; Konsole: Super+C/V → Ctrl+Shift+C/V.
- [ ] **Step 3:** Implementar config e serviço.
- [ ] **Step 4:** bats PASS; CI selftest `toshy=running`. Verificação funcional dos atalhos fica para o aceite no Samsung (spec §8.4).
- [ ] **Step 5:** Commit `feat: atalhos estilo macOS`.

### Task 7: Programas — navegador, vídeo, loja, atualizador

**Files:**
- Create: `archiso/airootfs/etc/chromium-flags.conf` (VA-API: `--enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL` — conferir nomes vigentes da versão do Chromium no build; `--ozone-platform-hint=auto`), `archiso/airootfs/etc/chromium/policies/managed/brisa.json` (instalação forçada de extensão que força H.264 no YouTube, ex. enhanced-h264ify, via `ExtensionInstallForcelist`), `archiso/airootfs/usr/share/applications/brisa-assistir-no-player.desktop` + `/usr/bin/brisa-assistir-no-player` (lê URL da área de transferência, valida que é http(s), abre `mpv`), configuração Flathub, `tests/static/apps.bats`
- Modify: `archiso/packages.x86_64` (+ `chromium mpv yt-dlp discover flatpak`; **não** instalar `packagekit-qt6` — Discover só com backend Flatpak), `aur/packages.txt` (+ atualizador gráfico com ícone na bandeja, ex. `arch-update`)

**Interfaces:**
- Produces: `brisa-assistir-no-player [url]` — sem argumento usa a área de transferência; URL inválida → notificação em português e exit 1.

- [ ] **Step 1: Testes falhando** — `apps.bats`: política JSON válida (`jq`) e contém o ID da extensão; `chromium-flags.conf` contém VA-API; `brisa-assistir-no-player "ftp://x"` → exit 1; com `mpv` falso no PATH, `brisa-assistir-no-player https://youtu.be/abc` chama `mpv https://youtu.be/abc`; remote `flathub` configurado no airootfs.
- [ ] **Step 2:** FAIL. **Step 3:** Implementar. **Step 4:** bats PASS; CI boot ok.
- [ ] **Step 5:** Commit `feat: navegador, player, loja e atualizador`.

### Task 8: Instalador Calamares e limpeza pós-instalação

**Files:**
- Create: `calamares/settings.conf`, `calamares/modules/{welcome,locale,keyboard,partition,users,unpackfs,fstab,bootloader,shellprocess-limpeza}.conf`, `calamares/branding/brisa/` (gerado por `render-branding.sh`, `windowSize: 800px,520px`), `scripts/brisa-pos-instalacao` (roda no alvo via shellprocess), `archiso/airootfs/usr/share/applications/brisa-instalar.desktop`, `tests/static/calamares.bats`, `tests/static/pos-instalacao.bats`
- Modify: `scripts/render-branding.sh` (gera branding do Calamares), `archiso/packages.x86_64` (+ `calamares`)

**Interfaces:**
- Consumes: `brisa-aplicar-modo` (Task 5) — `brisa-pos-instalacao` deixa um autostart de primeiro login que aplica `macos` ao novo usuário.
- Produces: `brisa-pos-instalacao <root>` remove do alvo: pacote `calamares`, `brisa-instalar.desktop`, `10-brisa-live.conf` do SDDM, usuário `live`, sudo sem senha, `brisa-selftest.service`, e a seção `[brisa]` do `pacman.conf`; idempotente.

- [ ] **Step 1: Testes falhando** — `calamares.bats`: `partition.conf` não tem modo de apagar automático/sem confirmação e oferece `erase` e `manual` (Review Focus 3); nenhum módulo exige rede (`welcome.conf` sem `internet` em `required`) (Review Focus 2); defaults `pt_BR`, `br`, `America/Sao_Paulo`; filesystem padrão `ext4`; bootloader cobre EFI e BIOS; `windowSize` ≤ 1366×768 (Review Focus 4). `pos-instalacao.bats`: rodar o script sobre uma árvore falsa em `$BATS_TMPDIR` que contém todos os itens live → todos removidos, `pacman.conf` sem `[brisa]`, rodar duas vezes não falha (Review Focus 5).
- [ ] **Step 2:** FAIL. **Step 3:** Implementar. **Step 4:** bats PASS; CI boot ok e selftest `calamares=present` no live.
- [ ] **Step 5:** Commit `feat: instalador calamares com limpeza do live`.

### Task 9: Menus de boot com marca, publicação e guia

**Files:**
- Modify: `scripts/render-branding.sh` (gera tema SDDM da distro — Breeze com papel de parede e logo do branding, usado no sistema instalado —, `syslinux/splash.png`, títulos de entrada em `syslinux/*.cfg`, `efiboot/loader/entries/*.conf`, `grub/*.cfg` com o nome da distro), `.github/workflows/build-iso.yml` (job `publish`: artifact sempre; Release `v<data>` com ISO+sha256 só se `stat -c%s` < 2147483648)
- Create: `docs/guia.md`, `tests/static/bootmenu.bats`

- [ ] **Step 1: Testes falhando** — `bootmenu.bats`: nenhum arquivo de boot contém "Arch Linux install medium" como título visível; todos usam o nome do branding. 
- [ ] **Step 2:** FAIL. **Step 3:** Implementar; `docs/guia.md` em pt-BR: baixar a ISO (Actions/Release), conferir sha256 no Mac (`shasum -a 256`), gravar com balenaEtcher, entrar no menu de boot/BIOS do Samsung (F2 para BIOS, F10 para boot — confirmar no aceite), desligar Secure Boot, testar no live, instalar.
- [ ] **Step 4:** bats PASS; CI completo verde; ISO baixável.
- [ ] **Step 5:** Commit `feat: menus de boot, publicação e guia`.

### Task 10: Aceite no Samsung (usuário)

- [ ] Usuário grava a ISO e percorre a spec §8 itens 1–7; Claude fornece um checklist em `docs/aceite-fase1.md` com onde anotar cada resultado (incluindo `vainfo`, `free -m` e o modelo do i3).
- [ ] Problemas viram novas tasks; ISO nova a cada correção.
