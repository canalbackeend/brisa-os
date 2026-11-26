# Guia: gravar, testar e instalar a Brisa

Você só precisa do seu Mac, de um pendrive de **8 GB ou mais** (ele será apagado) e do notebook.

## 1. Baixar a ISO

1. Abra o repositório no GitHub.
2. Clique em **Releases** (lado direito da página) e baixe os dois arquivos da versão mais nova:
   `brisa-AAAA.MM.DD-x86_64.iso` e `brisa-AAAA.MM.DD-x86_64.iso.sha256`.
   - Não apareceu em Releases? A ISO passou de 2 GB. Vá em **Actions → Montar ISO**,
     abra a execução mais recente com ✓ verde e baixe o arquivo **iso** em *Artifacts*
     (precisa estar logado no GitHub). Ele vem num `.zip`; dê dois cliques para extrair.

## 2. Conferir se o download veio inteiro

No Terminal do Mac, dentro da pasta Downloads:

```bash
shasum -a 256 brisa-*.iso
```

Compare o código que aparece com o conteúdo do arquivo `.sha256`. Têm que ser iguais.

## 3. Gravar no pendrive com o balenaEtcher

1. Instale o balenaEtcher (balena.io/etcher) no Mac.
2. **Flash from file** → escolha a ISO.
3. **Select target** → escolha o pendrive (confira o tamanho para não escolher outro disco).
4. **Flash!** e aguarde a verificação terminar.

## 4. Preparar o notebook Samsung

1. Desligue o notebook e espete o pendrive.
2. Ligue e aperte **F2** repetidamente para entrar na BIOS (em alguns modelos é **F10** ou **Esc**).
3. Procure **Secure Boot** (geralmente na aba *Boot* ou *Security*) e deixe **Disabled**.
4. Em *Boot Priority*, coloque o pendrive (USB) em primeiro — ou, ao ligar, aperte **F10**
   para escolher o pendrive só desta vez.
5. Salve e saia (geralmente **F10 → Yes**).

## 5. Testar sem instalar (modo live)

- Escolha a primeira opção do menu (**Brisa Live**) ou espere alguns segundos.
- O sistema abre direto na área de trabalho. **Nada é gravado no HD** neste modo.
- Teste Wi-Fi (ícone no canto superior direito), som, brilho, touchpad e o YouTube.
- Para sair, desligue pelo logo no canto superior esquerdo e tire o pendrive.

## 6. Instalar

> ⚠️ Faça backup antes. Se escolher **apagar o disco**, tudo que estiver nele some.

1. No modo live, clique em **Instalar** (último ícone do dock).
2. Siga as telas: idioma e fuso (já vêm com Brasil), teclado (**ABNT2**), disco, seu nome e senha.
3. No disco, escolha **Apagar disco** (só a Brisa no notebook) ou **Particionamento manual**.
   Nada é apagado sem você escolher.
4. Ao final, marque **Reiniciar agora**, tire o pendrive quando a tela apagar.

## 7. Depois de instalar

- **Instalar programas:** abra a **Loja** no dock.
- **Atualizações do sistema:** um ícone na bandeja avisa quando houver atualização.
- **Ver vídeo mais leve:** copie o link do vídeo e abra **Assistir no player**.
