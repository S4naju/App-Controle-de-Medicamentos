
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Conta do aplicativo
CREATE TABLE public.usuario (
  id_usuario uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  nome varchar(150) NOT NULL,
  data_cadastro timestamptz NOT NULL DEFAULT now()
);

-- 2. Pacientes
CREATE TABLE public.paciente (
  id_paciente uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  nome varchar(150) NOT NULL,
  data_nascimento date,
  data_cadastro timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_paciente, id_usuario)
);

-- 3. Dispositivos
CREATE TABLE public.dispositivo (
  id_dispositivo uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  numero_serie varchar(100) NOT NULL UNIQUE,
  status_conexao varchar(12) NOT NULL DEFAULT 'OFFLINE'
    CHECK (status_conexao IN ('ONLINE','OFFLINE')),
  ultimo_contato timestamptz,
  data_instalacao timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_dispositivo, id_usuario)
);

-- 4. Compartimentos fisicos
CREATE TABLE public.compartimento (
  id_compartimento uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_dispositivo uuid NOT NULL,
  numero_compartimento integer NOT NULL CHECK (numero_compartimento > 0),
  ativo boolean NOT NULL DEFAULT true,
  FOREIGN KEY (id_dispositivo, id_usuario)
    REFERENCES public.dispositivo(id_dispositivo, id_usuario) ON DELETE CASCADE,
  UNIQUE (id_dispositivo, numero_compartimento),
  UNIQUE (id_compartimento, id_usuario)
);

-- 5. Vinculo historico entre paciente e dispositivo
CREATE TABLE public.vinculo_dispositivo (
  id_vinculo uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_paciente uuid NOT NULL,
  id_dispositivo uuid NOT NULL,
  data_inicio timestamptz NOT NULL DEFAULT now(),
  data_fim timestamptz,
  ativo boolean NOT NULL DEFAULT true,
  CHECK (data_fim IS NULL OR data_fim >= data_inicio),
  CHECK (NOT ativo OR data_fim IS NULL),
  FOREIGN KEY (id_paciente)
    REFERENCES public.paciente(id_paciente) ON DELETE CASCADE,
  FOREIGN KEY (id_dispositivo)
    REFERENCES public.dispositivo(id_dispositivo) ON DELETE CASCADE
);
-- Prototipo: um paciente ativo por dispositivo e vice-versa.
CREATE UNIQUE INDEX ux_vinculo_paciente_ativo
  ON public.vinculo_dispositivo(id_paciente) WHERE ativo;
CREATE UNIQUE INDEX ux_vinculo_dispositivo_ativo
  ON public.vinculo_dispositivo(id_dispositivo) WHERE ativo;

-- 6. Medicamentos cadastrados
CREATE TABLE public.medicamento (
  id_medicamento uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_paciente uuid NOT NULL,
  nome varchar(180) NOT NULL,
  dosagem varchar(100),
  instrucoes_armazenamento text,
  data_cadastro timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (id_paciente, id_usuario)
    REFERENCES public.paciente(id_paciente, id_usuario) ON DELETE CASCADE,
  UNIQUE (id_medicamento, id_usuario)
);

-- 7. Abastecimentos e estoque por compartimento
CREATE TABLE public.abastecimento (
  id_abastecimento uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_medicamento uuid NOT NULL,
  id_compartimento uuid NOT NULL,
  quantidade_inicial integer NOT NULL CHECK (quantidade_inicial >= 0),
  quantidade_atual integer NOT NULL CHECK (quantidade_atual >= 0),
  data_abastecimento timestamptz NOT NULL DEFAULT now(),
  data_limite_armazenamento timestamptz,
  ativo boolean NOT NULL DEFAULT true,
  CHECK (quantidade_atual <= quantidade_inicial),
  CHECK (data_limite_armazenamento IS NULL OR
         data_limite_armazenamento >= data_abastecimento),
  FOREIGN KEY (id_medicamento, id_usuario)
    REFERENCES public.medicamento(id_medicamento, id_usuario) ON DELETE CASCADE,
  FOREIGN KEY (id_compartimento, id_usuario)
    REFERENCES public.compartimento(id_compartimento, id_usuario) ON DELETE CASCADE,
  UNIQUE (id_abastecimento, id_usuario)
);
CREATE UNIQUE INDEX ux_abastecimento_ativo_compartimento
  ON public.abastecimento(id_compartimento) WHERE ativo;

-- 8. Tratamento por INTERVALO, nao por horario fixo
CREATE TABLE public.tratamento (
  id_tratamento uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_medicamento uuid NOT NULL,
  intervalo_minutos integer NOT NULL CHECK (intervalo_minutos > 0),
  quantidade_dose integer NOT NULL CHECK (quantidade_dose > 0),
  tolerancia_retirada_minutos integer NOT NULL DEFAULT 10
    CHECK (tolerancia_retirada_minutos > 0),
  data_inicio timestamptz NOT NULL DEFAULT now(),
  data_fim timestamptz,
  primeira_retirada_em timestamptz,
  ultima_retirada_em timestamptz,
  proxima_dose_em timestamptz,
  estado_contagem varchar(25) NOT NULL DEFAULT 'AGUARDANDO_INICIO'
    CHECK (estado_contagem IN (
      'AGUARDANDO_INICIO','AGUARDANDO_RETIRADA','CONTANDO',
      'BLOQUEADO','PAUSADO','FINALIZADO'
    )),
  ativo boolean NOT NULL DEFAULT true,
  CHECK (data_fim IS NULL OR data_fim >= data_inicio),
  FOREIGN KEY (id_medicamento, id_usuario)
    REFERENCES public.medicamento(id_medicamento, id_usuario) ON DELETE CASCADE,
  UNIQUE (id_tratamento, id_usuario)
);
CREATE INDEX ix_tratamento_proxima_dose
  ON public.tratamento(proxima_dose_em) WHERE ativo;

-- 9. Historico de liberacao e RETIRADA detectada pelo sensor
CREATE TABLE public.dispensacao (
  id_dispensacao uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_tratamento uuid NOT NULL,
  id_abastecimento uuid,
  chave_evento_dispositivo varchar(120), -- idempotencia para MQTT/reenvios
  data_hora_programada timestamptz NOT NULL,
  data_hora_liberacao timestamptz,
  prazo_retirada timestamptz,
  data_hora_retirada timestamptz,
  status varchar(25) NOT NULL DEFAULT 'PROGRAMADA'
    CHECK (status IN (
      'PROGRAMADA','LIBERADA','ATRASADA','RETIRADA',
      'RETIRADA_COM_ATRASO','FALHA','CANCELADA'
    )),
  quantidade_liberada integer NOT NULL DEFAULT 0
    CHECK (quantidade_liberada >= 0),
  retirada_confirmada_sensor boolean NOT NULL DEFAULT false,
  CHECK (NOT retirada_confirmada_sensor OR data_hora_retirada IS NOT NULL),
  CHECK (data_hora_retirada IS NULL OR data_hora_liberacao IS NOT NULL),
  CHECK (prazo_retirada IS NULL OR data_hora_liberacao IS NOT NULL),
  CHECK (data_hora_retirada IS NULL OR
         data_hora_retirada >= data_hora_liberacao),
  FOREIGN KEY (id_tratamento, id_usuario)
    REFERENCES public.tratamento(id_tratamento, id_usuario) ON DELETE CASCADE,
  FOREIGN KEY (id_abastecimento, id_usuario)
    REFERENCES public.abastecimento(id_abastecimento, id_usuario),
  UNIQUE (id_dispensacao, id_usuario),
  UNIQUE (id_tratamento, data_hora_programada),
  UNIQUE (id_usuario, chave_evento_dispositivo)
);
CREATE INDEX ix_dispensacao_prazo_pendente
  ON public.dispensacao(prazo_retirada)
  WHERE status = 'LIBERADA';
CREATE INDEX ix_dispensacao_tratamento_historico
  ON public.dispensacao(id_tratamento, data_hora_programada DESC);

-- 10. Alertas do aplicativo
CREATE TABLE public.alerta (
  id_alerta uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_dispensacao uuid,
  id_abastecimento uuid,
  tipo varchar(35) NOT NULL CHECK (tipo IN (
    'ATRASO_RETIRADA','ESTOQUE_BAIXO','FALHA_DISPENSACAO',
    'PRAZO_ARMAZENAMENTO','FALHA_SENSOR','DISPOSITIVO_OFFLINE'
  )),
  mensagem text NOT NULL,
  data_hora timestamptz NOT NULL DEFAULT now(),
  FOREIGN KEY (id_dispensacao, id_usuario)
    REFERENCES public.dispensacao(id_dispensacao, id_usuario) ON DELETE CASCADE,
  FOREIGN KEY (id_abastecimento, id_usuario)
    REFERENCES public.abastecimento(id_abastecimento, id_usuario) ON DELETE CASCADE
);
CREATE INDEX ix_alerta_usuario_data ON public.alerta(id_usuario, data_hora DESC);

CREATE TABLE public.credencial_dispositivo (
  id_dispositivo uuid PRIMARY KEY REFERENCES public.dispositivo(id_dispositivo) ON DELETE CASCADE,
  senha_vinculo_hash text NOT NULL,
  atualizada_em timestamptz NOT NULL DEFAULT now()
);
REVOKE ALL ON TABLE public.credencial_dispositivo FROM anon, authenticated;

CREATE TABLE public.acesso_dispositivo (
  id_acesso uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  id_dispositivo uuid NOT NULL REFERENCES public.dispositivo(id_dispositivo) ON DELETE CASCADE,
  ativo boolean NOT NULL DEFAULT true,
  data_vinculo timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_usuario, id_dispositivo)
);
CREATE INDEX ix_acesso_dispositivo_dispositivo ON public.acesso_dispositivo(id_dispositivo) WHERE ativo;
CREATE INDEX ix_acesso_dispositivo_usuario ON public.acesso_dispositivo(id_usuario) WHERE ativo;

-- Cada usuario marca individualmente os alertas visualizados.
CREATE TABLE public.alerta_visualizacao (
  id_alerta uuid NOT NULL REFERENCES public.alerta(id_alerta) ON DELETE CASCADE,
  id_usuario uuid NOT NULL REFERENCES public.usuario(id_usuario) ON DELETE CASCADE,
  visualizado_em timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (id_alerta, id_usuario)
);

COMMIT;