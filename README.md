# Care Sync - Sistema de Controle e Monitoramento de Medicação

> Aplicação web/mobile (PWA) integrada a um dispensador inteligente (IoT) para gerenciamento de horários, monitoramento de validade e segurança na administração diária de medicamentos.

---

### Sobre o projeto:
Este projeto foi desenvolvido de forma integrada para as disciplinas de *Engenharia de Software* e *Banco de Dados II* no *IFRJ - Campus Niterói*, este sistema conecta uma interface web/mobile a um dispositivo IoT. O desenvolvimento engloba a estruturação da arquitetura, a modelagem e integridade dos dados e o fluxo de integração contínua entre o aplicativo e o hardware.

---

### Objetivo da solução proposta:
Fatores como acidentes e limitações decorrentes da idade podem elevar o risco do uso indevido, esquecimento ou duplicação de doses de medicamentos. O objetivo do *Care Sync* é facilitar a rotina de pessoas que administram medicações diárias — em ambientes domésticos, asilos ou hospitais — garantindo maior segurança e autonomia aos pacientes e tranquilidade aos cuidadores. 

A solução permite armazenar os remédios fora de suas embalagens originais sem comprometer sua integridade, controlando o tempo de permanência no dispensador (limite máximo de 7 dias). O aplicativo realiza o agendamento das doses, sincroniza a liberação de compartimentos mecânicos automatizados (ESP32), valida a retirada e o consumo por meio de um sensor de peso no recipiente de dispensação e de um sensor de detecção da ação do paciente (obs.: arquitetura de sensores sujeita a alterações conforme os testes de hardware), e dispara alertas instantâneos aos responsáveis em caso de não consumo, disponibilizando uma opção de ligação de emergência.

---

### Estrutura do sistema (Visão Geral do Banco de Dados):

O banco de dados relacional é estruturado no PostgreSQL (hospedado no Supabase) e organiza o fluxo de informações da plataforma nos seguintes domínios principais:

- *Controle de Acesso e Perfis*: Gerenciamento de contas de cuidadores responsáveis, pacientes assistidos e seus respectivos níveis de permissão.
- *Hardware e Conectividade*: Registro dos dispensadores físicos (ESP32), mapeamento de compartimentos individuais, status de operação e vínculos com os pacientes.
- *Estoque e Insumos*: Catálogo de medicamentos, controle de abastecimento por compartimento e rastreamento de validade/tempo de armazenamento.
- *Prescrições e Auditoria*: Regras de posologia (intervalos e janelas de tolerância), cronograma de doses e histórico detalhado das dispensações confirmadas pelos sensores.
- *Monitoramento e Notificações*: Logs de eventos do sistema e fila de alertas para atrasos de retirada, reposição de estoque, vencimento ou falhas de hardware.

---

### Funcionalidades:

O sistema permite o gerenciamento completo do ecossistema de medicação, contemplando:

- Cadastrar, editar e excluir usuários, pacientes, medicamentos e tratamentos com intervalos de dosagem
- Vincular cuidadores aos dispositivos físicos e monitorar em tempo real o status de conexão do hardware e o estoque dos compartimentos
- Controlar o tempo de permanência dos medicamentos fora da embalagem original (alerta preventivo antes de ultrapassar 7 dias)
- Validar a permanência e a retirada do medicamento por meio de sensor de peso no recipiente de queda e sensor de detecção de aproximação/ação do paciente (obs.: sujeito a alterações durante a fase de prototipagem)
- Disparar notificações automáticas de confirmação de retirada ou alertas críticos de atraso aos cuidadores, além de disponibilizar acionamento de ligação de emergência
- Consultar o histórico de adesão, alertas e dispensações realizadas

---

### Principais tecnologias previstas:

*Front-end (Aplicação Web/Mobile - PWA):*
- React
- JSX
- HTML5 e CSS3
- JavaScript

*Back-end, Banco de Dados e Integração IoT:*
- C# / .NET Core (API Back-end)
- PostgreSQL (Supabase)
- MQTT (Comunicação com o microcontrolador ESP32)
- C++ (Programação do microcontrolador ESP32)

*Versionamento e Gestão:*
- Git e GitHub (Projects, Issues e Wiki)

---

### Organização geral do repositório:

O projeto está estruturado nos seguintes diretórios:

- docs/ — Documentação técnica, levantamento de requisitos e regras de negócio
- modelos/ — Diagramas de arquitetura (C4), diagrama de classes e modelo lógico do banco de dados
- src/ — Códigos-fonte da aplicação web/mobile (componentes, páginas e serviços)
- database/ — Scripts SQL de criação, relacionamento, rotinas e manipulação do banco de dados
- tests/ — Casos e códigos de teste da aplicação

---

### Links e acompanhamento do projeto:

- *Repositório GitHub:* https://github.com/S4naju/App-Controle-de-Medicamentos
- *Documentação Técnica (Pasta /docs):* [docs/](docs/)
- *Wiki (Documentação e Planejamento):* https://github.com/S4naju/App-Controle-de-Medicamentos/wiki
- *Quadro Kanban (Gestão de Tarefas):* https://github.com/users/S4naju/projects/8/views/1

---

### Observações:

Este projeto representa o desenvolvimento do MVP (Produto Mínimo Viável) da solução *Care Sync*, integrando engenharia de software, banco de dados e automação com microcontrolador (ESP32) para promover autonomia aos pacientes e segurança aos cuidadores.

O desenvolvimento está sendo realizado de forma colaborativa pela equipe *Care Sync Team*, composta por estudantes da Graduação em Engenharia de Computação e do Curso Técnico.

---

### Integrantes da equipe (Care Sync Team):

*Graduação:*
- *Ana Julia Sampaio*
- *Maycon Junior*
- *Raimundo Guilherme*

*Ensino Técnico:*
- *Hugo Lopes*
- *Michel Campos*
- *Murilo Ribeiro*

Disciplinas: *Engenharia de Software* e *Banco de Dados II*  
Instituto Federal do Rio de Janeiro – *Campus Niterói*
