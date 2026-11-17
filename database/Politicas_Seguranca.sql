
-- 01. RLS - ATIVACAO NAS 13 TABELAS

ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paciente ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispositivo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compartimento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vinculo_dispositivo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.abastecimento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tratamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispensacao ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerta ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credencial_dispositivo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.acesso_dispositivo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerta_visualizacao ENABLE ROW LEVEL SECURITY;

-- 02. POLITICAS DO PERFIL DE USUARIO
-- Usuario: auth_user_id deve ser o UID da conta logada.
CREATE POLICY usuario_select ON public.usuario FOR SELECT TO authenticated
  USING (auth_user_id = (SELECT auth.uid()));
CREATE POLICY usuario_insert ON public.usuario FOR INSERT TO authenticated
  WITH CHECK (auth_user_id = (SELECT auth.uid()));
CREATE POLICY usuario_update ON public.usuario FOR UPDATE TO authenticated
  USING (auth_user_id = (SELECT auth.uid()))
  WITH CHECK (auth_user_id = (SELECT auth.uid()));

-- 03. IDENTIFICACAO DO USUARIO AUTENTICADO
-- Funcao auxiliar SECURITY DEFINER, sem aceitar IDs arbitrarios como autorizacao.
-- Usa apenas auth.uid() e verifica a propriedade da instalacao.
CREATE FUNCTION public.usuario_atual_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT u.id_usuario FROM public.usuario AS u
  WHERE u.auth_user_id = (SELECT auth.uid())
  LIMIT 1;
$$;
REVOKE ALL ON FUNCTION public.usuario_atual_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.usuario_atual_id() TO authenticated;

-- 04. FUNCOES DE AUTORIZACAO PARA ACESSO COMPARTILHADO
-- O acesso a um dispositivo e decidido pelo vinculo ativo OU pelo proprietario
-- original (para dispositivos existentes, antes da vinculacao inicial).
-- SECURITY DEFINER evita recursao entre RLS de usuario, dispositivo e acesso.
CREATE OR REPLACE FUNCTION public.pode_acessar_dispositivo(p_dispositivo uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.dispositivo d
    WHERE d.id_dispositivo = p_dispositivo
      AND (
        d.id_usuario = (SELECT public.usuario_atual_id())
        OR EXISTS (
          SELECT 1 FROM public.acesso_dispositivo ad
          WHERE ad.id_dispositivo = d.id_dispositivo
            AND ad.id_usuario = (SELECT public.usuario_atual_id())
            AND ad.ativo
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.pode_acessar_paciente(p_paciente uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.paciente p
    WHERE p.id_paciente = p_paciente
      AND (
        p.id_usuario = (SELECT public.usuario_atual_id())
        OR EXISTS (
          SELECT 1 FROM public.vinculo_dispositivo vd
          WHERE vd.id_paciente = p.id_paciente AND vd.ativo
            AND public.pode_acessar_dispositivo(vd.id_dispositivo)
        )
      )
  );
$$;

CREATE OR REPLACE FUNCTION public.pode_acessar_medicamento(p_medicamento uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.medicamento m
    WHERE m.id_medicamento = p_medicamento
      AND public.pode_acessar_paciente(m.id_paciente)
  );
$$;

CREATE OR REPLACE FUNCTION public.pode_acessar_compartimento(p_compartimento uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.compartimento c
    WHERE c.id_compartimento = p_compartimento
      AND public.pode_acessar_dispositivo(c.id_dispositivo)
  );
$$;

CREATE OR REPLACE FUNCTION public.pode_acessar_tratamento(p_tratamento uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.tratamento t
    WHERE t.id_tratamento = p_tratamento
      AND public.pode_acessar_medicamento(t.id_medicamento)
  );
$$;

CREATE OR REPLACE FUNCTION public.pode_acessar_abastecimento(p_abastecimento uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.abastecimento a
    WHERE a.id_abastecimento = p_abastecimento
      AND public.pode_acessar_medicamento(a.id_medicamento)
      AND public.pode_acessar_compartimento(a.id_compartimento)
  );
$$;

CREATE OR REPLACE FUNCTION public.pode_acessar_dispensacao(p_dispensacao uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.dispensacao d
    WHERE d.id_dispensacao = p_dispensacao
      AND public.pode_acessar_tratamento(d.id_tratamento)
  );
$$;

CREATE OR REPLACE FUNCTION public.pode_acessar_alerta(p_alerta uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.alerta a
    WHERE a.id_alerta = p_alerta
      AND (
        (a.id_dispensacao IS NOT NULL AND public.pode_acessar_dispensacao(a.id_dispensacao))
        OR (a.id_abastecimento IS NOT NULL AND public.pode_acessar_abastecimento(a.id_abastecimento))
        OR (a.id_dispensacao IS NULL AND a.id_abastecimento IS NULL
            AND a.id_usuario = (SELECT public.usuario_atual_id()))
      )
  );
$$;


-- 05. PRIVILEGIOS DAS FUNCOES (REVOKE / GRANT)
-- Somente usuarios autenticados podem executar as funcoes de autorizacao.
REVOKE ALL ON FUNCTION public.pode_acessar_dispositivo(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pode_acessar_paciente(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pode_acessar_medicamento(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pode_acessar_compartimento(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pode_acessar_tratamento(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pode_acessar_abastecimento(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pode_acessar_dispensacao(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.pode_acessar_alerta(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.pode_acessar_dispositivo(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_acessar_paciente(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_acessar_medicamento(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_acessar_compartimento(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_acessar_tratamento(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_acessar_abastecimento(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_acessar_dispensacao(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pode_acessar_alerta(uuid) TO authenticated;


-- 06. POLITICAS RLS FINAIS DE COMPARTILHAMENTO
-- Vinculacao nao pode ser autoatribuida pelo cliente.
-- Somente o backend confiavel, apos validar a senha, insere ou reativa acessos.
CREATE POLICY acesso_dispositivo_select ON public.acesso_dispositivo
  FOR SELECT TO authenticated
  USING (id_usuario = (SELECT public.usuario_atual_id())
         OR public.pode_acessar_dispositivo(id_dispositivo));

-- Acesso aos registros do dispositivo: mesma capacidade de ler e editar.
DROP POLICY IF EXISTS dispositivo_proprietario ON public.dispositivo;
CREATE POLICY dispositivo_select_compartilhado ON public.dispositivo
  FOR SELECT TO authenticated USING (public.pode_acessar_dispositivo(id_dispositivo));
CREATE POLICY dispositivo_insert_autor ON public.dispositivo
  FOR INSERT TO authenticated WITH CHECK (id_usuario = (SELECT public.usuario_atual_id()));
CREATE POLICY dispositivo_update_compartilhado ON public.dispositivo
  FOR UPDATE TO authenticated
  USING (public.pode_acessar_dispositivo(id_dispositivo))
  WITH CHECK (public.pode_acessar_dispositivo(id_dispositivo));
-- Exclusao do dispositivo exige fluxo backend explicito, para evitar cascata acidental.

DROP POLICY IF EXISTS paciente_proprietario ON public.paciente;
CREATE POLICY paciente_select_compartilhado ON public.paciente
  FOR SELECT TO authenticated USING (public.pode_acessar_paciente(id_paciente));
CREATE POLICY paciente_insert_autor ON public.paciente
  FOR INSERT TO authenticated WITH CHECK (id_usuario = (SELECT public.usuario_atual_id()));
CREATE POLICY paciente_update_compartilhado ON public.paciente
  FOR UPDATE TO authenticated
  USING (public.pode_acessar_paciente(id_paciente))
  WITH CHECK (public.pode_acessar_paciente(id_paciente));
-- Exclusao de paciente fica restrita ao backend (cascata sobre historicos).

DROP POLICY IF EXISTS vinculo_dispositivo_proprietario ON public.vinculo_dispositivo;
CREATE POLICY vinculo_select_compartilhado ON public.vinculo_dispositivo
  FOR SELECT TO authenticated USING (public.pode_acessar_dispositivo(id_dispositivo));
CREATE POLICY vinculo_insert_compartilhado ON public.vinculo_dispositivo
  FOR INSERT TO authenticated WITH CHECK (
    public.pode_acessar_dispositivo(id_dispositivo)
    AND public.pode_acessar_paciente(id_paciente)
    AND id_usuario = (SELECT d.id_usuario FROM public.dispositivo d
                      WHERE d.id_dispositivo = vinculo_dispositivo.id_dispositivo)
  );
CREATE POLICY vinculo_update_compartilhado ON public.vinculo_dispositivo
  FOR UPDATE TO authenticated
  USING (public.pode_acessar_dispositivo(id_dispositivo))
  WITH CHECK (public.pode_acessar_dispositivo(id_dispositivo));

DROP POLICY IF EXISTS compartimento_proprietario ON public.compartimento;
CREATE POLICY compartimento_select_compartilhado ON public.compartimento
  FOR SELECT TO authenticated USING (public.pode_acessar_dispositivo(id_dispositivo));
CREATE POLICY compartimento_insert_compartilhado ON public.compartimento
  FOR INSERT TO authenticated WITH CHECK (
    public.pode_acessar_dispositivo(id_dispositivo)
    AND id_usuario = (SELECT d.id_usuario FROM public.dispositivo d
                      WHERE d.id_dispositivo = compartimento.id_dispositivo)
  );
CREATE POLICY compartimento_update_compartilhado ON public.compartimento
  FOR UPDATE TO authenticated
  USING (public.pode_acessar_dispositivo(id_dispositivo))
  WITH CHECK (public.pode_acessar_dispositivo(id_dispositivo));
CREATE POLICY compartimento_delete_compartilhado ON public.compartimento
  FOR DELETE TO authenticated USING (public.pode_acessar_dispositivo(id_dispositivo));

DROP POLICY IF EXISTS medicamento_proprietario ON public.medicamento;
CREATE POLICY medicamento_select_compartilhado ON public.medicamento
  FOR SELECT TO authenticated USING (public.pode_acessar_paciente(id_paciente));
CREATE POLICY medicamento_insert_compartilhado ON public.medicamento
  FOR INSERT TO authenticated WITH CHECK (
    public.pode_acessar_paciente(id_paciente)
    AND id_usuario = (SELECT p.id_usuario FROM public.paciente p
                      WHERE p.id_paciente = medicamento.id_paciente)
  );
CREATE POLICY medicamento_update_compartilhado ON public.medicamento
  FOR UPDATE TO authenticated
  USING (public.pode_acessar_paciente(id_paciente))
  WITH CHECK (public.pode_acessar_paciente(id_paciente));
CREATE POLICY medicamento_delete_compartilhado ON public.medicamento
  FOR DELETE TO authenticated USING (public.pode_acessar_paciente(id_paciente));

DROP POLICY IF EXISTS abastecimento_proprietario ON public.abastecimento;
CREATE POLICY abastecimento_select_compartilhado ON public.abastecimento
  FOR SELECT TO authenticated USING (
    public.pode_acessar_medicamento(id_medicamento)
    AND public.pode_acessar_compartimento(id_compartimento));
CREATE POLICY abastecimento_insert_compartilhado ON public.abastecimento
  FOR INSERT TO authenticated WITH CHECK (
    public.pode_acessar_medicamento(id_medicamento)
    AND public.pode_acessar_compartimento(id_compartimento)
    AND id_usuario = (SELECT m.id_usuario FROM public.medicamento m
                      WHERE m.id_medicamento = abastecimento.id_medicamento)
  );
CREATE POLICY abastecimento_update_compartilhado ON public.abastecimento
  FOR UPDATE TO authenticated
  USING (public.pode_acessar_medicamento(id_medicamento)
         AND public.pode_acessar_compartimento(id_compartimento))
  WITH CHECK (public.pode_acessar_medicamento(id_medicamento)
              AND public.pode_acessar_compartimento(id_compartimento));
CREATE POLICY abastecimento_delete_compartilhado ON public.abastecimento
  FOR DELETE TO authenticated USING (
    public.pode_acessar_medicamento(id_medicamento)
    AND public.pode_acessar_compartimento(id_compartimento));

DROP POLICY IF EXISTS tratamento_proprietario ON public.tratamento;
CREATE POLICY tratamento_select_compartilhado ON public.tratamento
  FOR SELECT TO authenticated USING (public.pode_acessar_medicamento(id_medicamento));
CREATE POLICY tratamento_insert_compartilhado ON public.tratamento
  FOR INSERT TO authenticated WITH CHECK (
    public.pode_acessar_medicamento(id_medicamento)
    AND id_usuario = (SELECT m.id_usuario FROM public.medicamento m
                      WHERE m.id_medicamento = tratamento.id_medicamento)
  );
CREATE POLICY tratamento_update_compartilhado ON public.tratamento
  FOR UPDATE TO authenticated
  USING (public.pode_acessar_medicamento(id_medicamento))
  WITH CHECK (public.pode_acessar_medicamento(id_medicamento));
CREATE POLICY tratamento_delete_compartilhado ON public.tratamento
  FOR DELETE TO authenticated USING (public.pode_acessar_medicamento(id_medicamento));

-- Historico e alertas: somente leitura para o app; escrita continua no backend.
DROP POLICY IF EXISTS dispensacao_leitura ON public.dispensacao;
CREATE POLICY dispensacao_leitura_compartilhada ON public.dispensacao
  FOR SELECT TO authenticated USING (public.pode_acessar_tratamento(id_tratamento));
DROP POLICY IF EXISTS alerta_leitura ON public.alerta;
DROP POLICY IF EXISTS alerta_marcar_lido ON public.alerta;
CREATE POLICY alerta_leitura_compartilhada ON public.alerta
  FOR SELECT TO authenticated USING (public.pode_acessar_alerta(id_alerta));

CREATE POLICY alerta_visualizacao_select ON public.alerta_visualizacao
  FOR SELECT TO authenticated USING (
    id_usuario = (SELECT public.usuario_atual_id())
    AND public.pode_acessar_alerta(id_alerta));
CREATE POLICY alerta_visualizacao_insert ON public.alerta_visualizacao
  FOR INSERT TO authenticated WITH CHECK (
    id_usuario = (SELECT public.usuario_atual_id())
    AND public.pode_acessar_alerta(id_alerta));
CREATE POLICY alerta_visualizacao_update ON public.alerta_visualizacao
  FOR UPDATE TO authenticated
  USING (id_usuario = (SELECT public.usuario_atual_id())
         AND public.pode_acessar_alerta(id_alerta))
  WITH CHECK (id_usuario = (SELECT public.usuario_atual_id())
              AND public.pode_acessar_alerta(id_alerta));
CREATE POLICY alerta_visualizacao_delete ON public.alerta_visualizacao
  FOR DELETE TO authenticated USING (
    id_usuario = (SELECT public.usuario_atual_id())
    AND public.pode_acessar_alerta(id_alerta));


-- 07. PROTECAO DE CREDENCIAIS DO DISPOSITIVO
-- A tabela public.credencial_dispositivo foi criada no script de estrutura.
-- O trecho abaixo impede o acesso direto dos papeis anon e authenticated.
ALTER TABLE public.credencial_dispositivo ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.credencial_dispositivo FROM anon, authenticated;


-- 08. TRIGGERS E FUNCOES DE INTEGRIDADE / TITULARIDADE
-- A coluna id_usuario e parte das chaves estrangeiras legadas e nao pode ser
-- trocada pelo frontend: todos editam o conteudo, mas nao alteram titularidade.
CREATE OR REPLACE FUNCTION public.bloquear_troca_titularidade()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF current_user = 'authenticated' AND NEW.id_usuario IS DISTINCT FROM OLD.id_usuario THEN
    RAISE EXCEPTION 'Titularidade so pode ser transferida pelo backend confiavel';
  END IF;
  RETURN NEW;
END;
$$;
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'paciente','dispositivo','compartimento','vinculo_dispositivo',
    'medicamento','abastecimento','tratamento'
  ] LOOP
    EXECUTE format(
      'CREATE TRIGGER %I BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.bloquear_troca_titularidade()',
      'trg_bloquear_titularidade_' || t, t
    );
  END LOOP;
END $$;

-- Impede apagar o proprietario original enquanto existirem dispositivos seus.
-- Excluir conta com dispositivo exige primeiro transferir titularidade pelo backend.
CREATE OR REPLACE FUNCTION public.proteger_proprietario_dispositivo()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.dispositivo d WHERE d.id_usuario = OLD.id_usuario) THEN
    RAISE EXCEPTION 'Transfira a titularidade dos dispositivos antes de excluir esta conta';
  END IF;
  RETURN OLD;
END;
$$;
CREATE TRIGGER trg_proteger_proprietario_dispositivo
BEFORE DELETE ON public.usuario FOR EACH ROW
EXECUTE FUNCTION public.proteger_proprietario_dispositivo();


-- 09. PRIVILEGIOS DE TABELAS COMPARTILHADAS
-- Garantir que as novas tabelas estejam disponiveis ao app sob RLS.
GRANT SELECT ON public.acesso_dispositivo TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.alerta_visualizacao TO authenticated;
-- Nao conceder INSERT/UPDATE/DELETE em acesso_dispositivo ao app.


-- 10. RESTRICOES DE INTEGRIDADE DEFINIDAS NO ESQUEMA
-- As regras abaixo fazem parte das instrucoes CREATE TABLE/CREATE INDEX
-- do script original e sao apresentadas aqui como referencia documental.

-- PK: id_usuario, id_paciente, id_dispositivo, id_compartimento,
--     id_vinculo, id_medicamento, id_abastecimento, id_tratamento,
--     id_dispensacao, id_alerta, id_acesso; PK composta em alerta_visualizacao;
--     id_dispositivo e PK/FK em credencial_dispositivo.
-- FK: relacionamentos entre usuarios, pacientes, dispositivos,
--     compartimentos, medicamentos, tratamentos, dispensacoes e alertas.
-- UNIQUE: auth_user_id; numero_serie; dispositivo+numero_compartimento;
--     usuario+dispositivo em acesso_dispositivo; chaves de idempotencia;
--     indices parciais de vinculos/abastecimentos ativos.
-- CHECK: status de dispositivo, numero de compartimento positivo,
--     estoque nao negativo e nao superior ao inicial, intervalo e dose
--     positivos, estados validos de tratamento e dispensacao,
--     consistencia de datas de liberacao e retirada.
--
-- Exemplos LITERAIS do codigo original (somente referencia):
-- quantidade_atual integer NOT NULL CHECK (quantidade_atual >= 0)
-- CHECK (quantidade_atual <= quantidade_inicial)
-- numero_compartimento integer NOT NULL CHECK (numero_compartimento > 0)
-- status_conexao varchar(12) NOT NULL DEFAULT 'OFFLINE'
--   CHECK (status_conexao IN ('ONLINE','OFFLINE'))
-- UNIQUE (id_usuario, id_dispositivo)
--
-- Indices unicos parciais presentes no SQL original:
-- CREATE UNIQUE INDEX ux_vinculo_paciente_ativo
--   ON public.vinculo_dispositivo(id_paciente) WHERE ativo;
-- CREATE UNIQUE INDEX ux_vinculo_dispositivo_ativo
--   ON public.vinculo_dispositivo(id_dispositivo) WHERE ativo;
-- CREATE UNIQUE INDEX ux_abastecimento_ativo_compartimento
--   ON public.abastecimento(id_compartimento) WHERE ativo;
