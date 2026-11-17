BEGIN;

-- 1. Papel do dispositivo (sem login direto; assumido pelo backend)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'caresync_dispositivo') THEN
    CREATE ROLE caresync_dispositivo NOLOGIN;
  END IF;
END $$;
-- Permite ao usuario administrador (SQL Editor) assumir o papel nos testes de acesso
GRANT caresync_dispositivo TO postgres;

-- 2. Parte do zero: remove privilegios padrao e libera apenas o uso do schema
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated, caresync_dispositivo;
GRANT USAGE ON SCHEMA public TO anon, authenticated, caresync_dispositivo;

-- 3. Funcao auxiliar: id_usuario (uuid) do usuario logado
CREATE OR REPLACE FUNCTION public.id_usuario_atual()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT id_usuario FROM public.usuario WHERE auth_user_id = auth.uid();
$$;
REVOKE ALL ON FUNCTION public.id_usuario_atual() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.id_usuario_atual() TO authenticated;

-- 4. Privilegios do CUIDADOR (authenticated)
GRANT SELECT, UPDATE (nome)  ON public.usuario              TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.paciente             TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.dispositivo          TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.compartimento        TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.vinculo_dispositivo  TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.medicamento          TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.abastecimento        TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.tratamento           TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.acesso_dispositivo   TO authenticated;
GRANT SELECT                 ON public.dispensacao          TO authenticated;  -- historico: somente leitura
GRANT SELECT                 ON public.alerta               TO authenticated;  -- gerado pelo sistema
GRANT SELECT, INSERT         ON public.alerta_visualizacao  TO authenticated;
-- credencial_dispositivo: nenhum privilegio para authenticated
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 5. Privilegios do DISPOSITIVO
GRANT SELECT ON public.dispositivo, public.compartimento, public.medicamento,
                public.abastecimento, public.tratamento TO caresync_dispositivo;
GRANT UPDATE (status_conexao, ultimo_contato) ON public.dispositivo   TO caresync_dispositivo;
GRANT UPDATE (quantidade_atual)               ON public.abastecimento TO caresync_dispositivo;
GRANT UPDATE (primeira_retirada_em, ultima_retirada_em, proxima_dose_em, estado_contagem)
                                              ON public.tratamento    TO caresync_dispositivo;
GRANT SELECT, INSERT, UPDATE                  ON public.dispensacao   TO caresync_dispositivo;
GRANT SELECT, INSERT                          ON public.alerta        TO caresync_dispositivo;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO caresync_dispositivo;
-- credencial_dispositivo e verificada por funcao no backend (service_role), nao lida diretamente

-- 6. RLS: cada cuidador ve e altera apenas os proprios dados
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'usuario','paciente','dispositivo','compartimento','vinculo_dispositivo',
    'medicamento','abastecimento','tratamento','dispensacao','alerta',
    'acesso_dispositivo','alerta_visualizacao'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS p_cuidador_%1$s ON public.%1$I', t);
    EXECUTE format(
      'CREATE POLICY p_cuidador_%1$s ON public.%1$I FOR ALL TO authenticated
         USING (id_usuario = public.id_usuario_atual())
         WITH CHECK (id_usuario = public.id_usuario_atual())', t);
  END LOOP;

  -- dispositivo: acesso as linhas necessarias a operacao
  FOREACH t IN ARRAY ARRAY[
    'dispositivo','compartimento','medicamento','abastecimento',
    'tratamento','dispensacao','alerta'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS p_dispositivo_%1$s ON public.%1$I', t);
    EXECUTE format(
      'CREATE POLICY p_dispositivo_%1$s ON public.%1$I FOR ALL TO caresync_dispositivo
         USING (true) WITH CHECK (true)', t);
  END LOOP;
END $$;

-- credencial_dispositivo: RLS ligada e sem politica = negado para todos, exceto service_role
ALTER TABLE public.credencial_dispositivo ENABLE ROW LEVEL SECURITY;

COMMIT;

-- CONFERENCIA (opcional): privilegios concedidos por perfil
-- SELECT grantee, table_name, string_agg(privilege_type, ', ') AS privilegios
-- FROM information_schema.role_table_grants
-- WHERE table_schema = 'public'
--   AND grantee IN ('anon','authenticated','caresync_dispositivo')
-- GROUP BY grantee, table_name ORDER BY grantee, table_name;
