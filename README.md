Care Sync - App de Controle e Monitoramento de Medicação 

>Interface web/mobile para controle, agendamento e segurança na administração de medicamentos integrados ao dispensador inteligente.

---

##Objetivo da Solução

O uso indevido ou o esquecimento de medicamentos representa um risco elevado à saúde, sobretudo para idosos ou pessoas com limitações motoras e cognitivas em ambientes domésticos, asilos e hospitais. 

Esta aplicação atua como a central de controle e monitoramento do sistema de dispensação de remédios. Ela permite que cuidadores, familiares ou profissionais de saúde configurem rotinas de dosagem, acompanhem a adesão do paciente em tempo real, monitorem o tempo de armazenamento dos fármacos fora da embalagem e recebam alertas críticos de segurança com suporte a chamadas de emergência.

---

##Principais Funcionalidades do App

* **Agendamento e Monitoramento de Doses:** Cadastro de horários, dosagens e instruções específicas para cada medicamento.
* **Comunicação com o Hardware:** Envio de comandos para acionamento remoto e sincronização de horários com os compartimentos mecânicos.
* **Validação por Identificação (RFID/Pulseira):** Confirmação de consumo vinculada ao registro de leitura da pulseira de identificação do paciente.
* **Controle de Validade no Compartimento (Limite de 7 Dias):** Rastreamento do tempo de permanência de cada dose fora da embalagem original, alertando caso atinja o limite máximo recomendado para preservar a integridade química do fármaco.
* **Sistema Escalonado de Alertas:**
  * Notificação imediata ao cuidador em caso de não consumo no horário estipulado.
  * Acionamento direto de **Ligação de Emergência** caso o responsável não consiga contato com o paciente.

---

##Integrantes da Equipe

* **Ana Julia Sampaio**
* **Maycon Júnior Moraes** 
* **Raimundo Guilherme Alves**

---

##Tecnologias Previstas

* **Linguagens e Estruturação:** JavaScript, JSX, CSS3, HTML5
* **Interface:** Estrutura baseada em componentes reutilizáveis (biblioteca/framework frontend em definição pela equipe)
* **Backend & Banco de Dados (BaaS):** Supabase (PostgreSQL, Autenticação e APIs em tempo real)
* **Comunicação com Hardware / IoT:** Integração via REST APIs / WebSockets
* **Versionamento & Gestão:** Git, GitHub, GitHub Projects / Issues
---

##Estrutura do Repositório

```text
├── docs/ # Documentação técnica e demais documentos do projeto
├── modelos/ # Diagramas e modelos de arquitetura, classes e banco de dados
├── src/ # Códigos-fonte da aplicação
├── database/ # Scripts relacionados ao banco de dados
├── tests/ # Códigos e artefatos relacionados aos testes
├── .gitignore # Arquivos e diretórios ignorados pelo Git
└── README.md # Informações gerais e guia do projeto
