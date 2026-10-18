# Windows Debloat — Guia Reutilizável

Guia completo e validado para remover bloat, telemetria e apps inúteis do Windows (10/11, Home ou Pro) **sem quebrar** drivers, hardware, jogos ou programas de trabalho — e totalmente reversível.

Funciona com qualquer agente de IA que tenha acesso a um terminal elevado (Hermes Agent, Claude Code, GitHub Copilot CLI, Cline, etc.). O guia é autocontido: detecta CPU/GPU, pede aprovação antes de cada ação destrutiva e cria backup/rollback antes de tudo.

## Como usar

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

Mexer em serviços e apps do sistema tem risco. O guia foi validado em 2 máquinas (ThinkPad Intel/Win11 Pro e desktop AMD + RTX 3060/Win11 Home) e é reversível (backup CSV + ponto de restauração), mas use por sua conta e risco. Revise cada item do relatório antes de aprovar.
