# Windows Debloat — Guia Reutilizável

Português | [English](README.en.md)

Guia completo e validado para remover bloat, telemetria e apps inúteis do Windows (10/11, Home ou Pro) **sem quebrar** drivers, hardware, jogos ou programas de trabalho — e totalmente reversível (backup CSV + ponto de restauração).

Funciona de **duas formas**:

- **Manual** (sem agente de IA): baixe `debloat.ps1` + `debloat.bat`, clique duas vezes e responda 4 perguntas. Para qualquer pessoa.
- **Com agente de IA**: entregue o `Windows-Debloat-Guia-Reutilizável.md` a um agente de terminal (Hermes Agent, Claude Code, GitHub Copilot CLI, Cline, etc.) e ele executa detectando CPU/GPU e pedindo aprovação antes de cada ação.

## Modo manual (sem agente de IA)

O jeito mais simples para quem não usa agente de IA:

1. Baixe `debloat.ps1` e `debloat.bat` **na mesma pasta**.
2. **Clique duas vezes** em `debloat.bat` (ou clique com o botão direito em `debloat.ps1` → "Executar com PowerShell").
3. Na janela de permissão do Windows (**UAC**), clique em **"Sim"**. Se o Windows Defender/SmartScreen avisar, clique em "Mais informações" → "Executar assim mesmo".
4. Responda às **4 perguntas** com `S` ou `N`:
   - Remover apps de jogo (Xbox app, Solitaire, Game Bar)?
   - Remover o OneDrive?
   - Remover a Microsoft Store?
   - Desligar a atualização automática do Windows?
5. O script cria **backup + ponto de restauração** antes de qualquer mudança, faz a limpeza e mostra um resumo no final.
6. **Reinicie o computador** para concluir.

O que ele faz (sempre): remove apps de bloat (Bing, Clipchamp, GetHelp, FeedbackHub, Widgets, etc.), desativa serviços de telemetria/diagnóstico, desativa o Recall/Copilot/Click-to-Do e limpa o cache do Windows Update. Os itens das 4 perguntas só acontecem se você responder `S`.

Nada é irreversível: o backup fica em `Documentos\windows-debloat-backup\` e há um ponto de restauração "Pre-debloat (manual)".

## Modo com agente de IA

1. Salve `Windows-Debloat-Guia-Reutilizável.md` em algum lugar fácil (Downloads ou Documentos).
2. Abra seu assistente de IA **como Administrador**.
3. Cole o bloco de instruções do topo do guia e siga — ele analisa, mostra um relatório e espera seu "sim" antes de mudar qualquer coisa.

## Resultados (na minha máquina)

ThinkPad · Windows 11 Pro · 32 GB RAM — sessão de 2026-10-18:

- **29 apps** removidos (UWP) — de 125 para 96
- **20 serviços** desativados (telemetria, diagnóstico, Xbox Live cloud, NFC/pagamento/mensagem, host de IA)
- **OneDrive** removido (app + auto-start)
- **2,8 GB** de cache do Windows Update liberados
- Pilha de IA desativada (Recall/Copilot/Click-to-Do) + Copilot desligado + update automático desligado

Estado após o debloat: 203 processos · 114 serviços rodando · 7,6 GB de 31,7 GB de RAM em uso.

## Aviso

Mexer em serviços e apps do sistema tem risco. O guia e o script foram validados em 2 máquinas (ThinkPad Intel/Win11 Pro e desktop AMD + RTX 3060/Win11 Home) e são reversíveis (backup CSV + ponto de restauração), mas use por sua conta e risco. No modo com agente, revise cada item do relatório antes de aprovar.
