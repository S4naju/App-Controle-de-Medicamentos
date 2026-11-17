BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 0. Usuarios de autenticacao exigidos pela FK usuario.auth_user_id.
INSERT INTO auth.users
  (id, aud, role, email, encrypted_password, email_confirmed_at,
   raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
   is_sso_user, is_anonymous)
SELECT
  ('' || lpad(g::text, 12, '0'))::uuid,
  'authenticated', 'authenticated',
  'demo.usuario' || lpad(g::text, 2, '0') || '@caresync.example',
  crypt('CareSync#2026-' || lpad(g::text, 2, '0'), gen_salt('bf')),
  now(), '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('nome', 'Usuario demonstracao ' || g),
  now() - (g || ' days')::interval, now(), false, false
FROM generate_series(1,20) AS g
ON CONFLICT (id) DO NOTHING;

-- 1. USUARIO (20)
INSERT INTO public.usuario (id_usuario, auth_user_id, nome, data_cadastro)
SELECT
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('00000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  (ARRAY['Mariana Oliveira','Joao Carlos Ferreira','Ana Paula Santos','Roberto Almeida','Luciana Costa','Pedro Henrique Lima','Fernanda Souza','Carlos Eduardo Rocha','Patricia Martins','Jose Augusto Ribeiro','Camila Nunes','Rafael Gomes','Beatriz Carvalho','Antonio Marcos Silva','Juliana Mendes','Paulo Cesar Araujo','Renata Barros','Eduardo Freitas','Sonia Maria Lopes','Marcelo Teixeira'])[g],
  now() - (g * 3 || ' days')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_usuario) DO NOTHING;

-- 2. PACIENTE (20)
INSERT INTO public.paciente (id_paciente, id_usuario, nome, data_nascimento, data_cadastro)
SELECT
  ('20000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  (ARRAY['Maria Oliveira','Joao Ferreira','Ana Santos','Roberto Almeida','Luciana Costa','Pedro Lima','Fernanda Souza','Carlos Rocha','Patricia Martins','Jose Ribeiro','Camila Nunes','Rafael Gomes','Beatriz Carvalho','Antonio Silva','Juliana Mendes','Paulo Araujo','Renata Barros','Eduardo Freitas','Sonia Lopes','Marcelo Teixeira'])[g],
  (DATE '1948-01-01' + (g * 431))::date,
  now() - (g * 2 || ' days')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_paciente) DO NOTHING;

-- 3. DISPOSITIVO (20)
INSERT INTO public.dispositivo (id_dispositivo, id_usuario, numero_serie, status_conexao, ultimo_contato, data_instalacao)
SELECT
  ('30000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  'CS-' || to_char(g, 'FM00000') || '-BR',
  CASE WHEN g % 4 = 0 THEN 'OFFLINE' ELSE 'ONLINE' END,
  CASE WHEN g % 4 = 0 THEN now() - interval '2 days' ELSE now() - (g * 7 || ' minutes')::interval END,
  now() - (g * 5 || ' days')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_dispositivo) DO NOTHING;

-- 4. COMPARTIMENTO (20)
INSERT INTO public.compartimento (id_compartimento, id_usuario, id_dispositivo, numero_compartimento, ativo)
SELECT
  ('40000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('30000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  g, true
FROM generate_series(1,20) AS g
ON CONFLICT (id_compartimento) DO NOTHING;

-- 5. VINCULO_DISPOSITIVO (20)
INSERT INTO public.vinculo_dispositivo (id_vinculo, id_usuario, id_paciente, id_dispositivo, data_inicio, data_fim, ativo)
SELECT
  ('50000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('20000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('30000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  now() - (g * 4 || ' days')::interval, NULL, true
FROM generate_series(1,20) AS g
ON CONFLICT (id_vinculo) DO NOTHING;

-- 6. MEDICAMENTO (20)
INSERT INTO public.medicamento (id_medicamento, id_usuario, id_paciente, nome, dosagem, instrucoes_armazenamento, data_cadastro)
SELECT
  ('60000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('20000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  (ARRAY['Losartana potassica','Metformina','Atenolol','Omeprazol','Sinvastatina','Anlodipino','Hidroclorotiazida','Levotiroxina','Dipirona','Vitamina D','Enalapril','Gliclazida','Pantoprazol','Atorvastatina','Sertralina','Furosemida','AAS','Clonazepam','Prednisona','Cetirizina'])[g],
  (ARRAY['50 mg','850 mg','25 mg','20 mg','20 mg','5 mg','25 mg','50 mcg','500 mg','2000 UI','10 mg','30 mg','40 mg','10 mg','50 mg','40 mg','100 mg','0,5 mg','20 mg','10 mg'])[g],
  CASE WHEN g IN (10,20) THEN 'Manter protegido da luz e umidade; seguir orientacao da embalagem.' ELSE 'Manter em local seco, protegido da luz e em temperatura ambiente, conforme bula.' END,
  now() - (g * 2 || ' days')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_medicamento) DO NOTHING;

-- 7. ABASTECIMENTO (20)
INSERT INTO public.abastecimento (id_abastecimento, id_usuario, id_medicamento, id_compartimento, quantidade_inicial, quantidade_atual, data_abastecimento, data_limite_armazenamento, ativo)
SELECT
  ('70000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('60000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('40000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  30 + (g % 4) * 10,
  8 + (g % 7),
  now() - (g || ' days')::interval,
  now() + ((60 + g) || ' days')::interval,
  true
FROM generate_series(1,20) AS g
ON CONFLICT (id_abastecimento) DO NOTHING;

-- 8. TRATAMENTO (20)
INSERT INTO public.tratamento (id_tratamento, id_usuario, id_medicamento, intervalo_minutos, quantidade_dose, tolerancia_retirada_minutos, data_inicio, data_fim, primeira_retirada_em, ultima_retirada_em, proxima_dose_em, estado_contagem, ativo)
SELECT
  ('80000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('60000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  (ARRAY[360,480,720,1440])[((g-1)%4)+1],
  CASE WHEN g % 5 = 0 THEN 2 ELSE 1 END,
  10,
  now() - (g * 2 || ' days')::interval,
  NULL,
  CASE WHEN g % 5 = 0 THEN NULL ELSE now() - interval '1 day' END,
  CASE WHEN g % 5 = 0 THEN NULL ELSE now() - interval '2 hours' END,
  now() + (g * 15 || ' minutes')::interval,
  CASE WHEN g % 5 = 0 THEN 'AGUARDANDO_INICIO' WHEN g % 4 = 0 THEN 'PAUSADO' ELSE 'CONTANDO' END,
  CASE WHEN g % 4 = 0 THEN false ELSE true END
FROM generate_series(1,20) AS g
ON CONFLICT (id_tratamento) DO NOTHING;

-- 9. DISPENSACAO (20)
INSERT INTO public.dispensacao (id_dispensacao, id_usuario, id_tratamento, id_abastecimento, chave_evento_dispositivo, data_hora_programada, data_hora_liberacao, prazo_retirada, data_hora_retirada, status, quantidade_liberada, retirada_confirmada_sensor)
SELECT
  ('90000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('80000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('70000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  'EVT-CARESYNC-' || to_char(g, 'FM00000'),
  now() - ((g * 2) || ' hours')::interval,
  CASE WHEN g % 6 = 0 THEN NULL ELSE now() - ((g * 2 - 1) || ' hours')::interval END,
  CASE WHEN g % 6 = 0 THEN NULL ELSE now() - ((g * 2 - 1) || ' hours')::interval + interval '15 minutes' END,
  CASE WHEN g % 6 IN (0,1) THEN NULL ELSE now() - ((g * 2 - 1) || ' hours')::interval + (CASE WHEN g % 5 = 0 THEN interval '25 minutes' ELSE interval '5 minutes' END) END,
  CASE WHEN g % 6 = 0 THEN 'PROGRAMADA' WHEN g % 7 = 0 THEN 'FALHA' WHEN g % 6 = 1 THEN 'LIBERADA' WHEN g % 5 = 0 THEN 'RETIRADA_COM_ATRASO' ELSE 'RETIRADA' END,
  CASE WHEN g % 6 = 0 OR g % 7 = 0 THEN 0 ELSE CASE WHEN g % 5 = 0 THEN 2 ELSE 1 END END,
  CASE WHEN g % 6 IN (0,1) OR g % 7 = 0 THEN false ELSE true END
FROM generate_series(1,20) AS g
ON CONFLICT (id_dispensacao) DO NOTHING;

-- 10. ALERTA (20)
INSERT INTO public.alerta (id_alerta, id_usuario, id_dispensacao, id_abastecimento, tipo, mensagem, data_hora)
SELECT
  ('a0000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('90000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('70000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  (ARRAY['ATRASO_RETIRADA','ESTOQUE_BAIXO','FALHA_DISPENSACAO','PRAZO_ARMAZENAMENTO','FALHA_SENSOR','DISPOSITIVO_OFFLINE'])[ ((g-1)%6)+1 ],
  (ARRAY['A retirada da dose ocorreu fora do prazo previsto.','Estoque do compartimento proximo do nivel minimo.','O dispositivo registrou uma falha durante a dispensacao.','Verificar o prazo de armazenamento do medicamento.','Sensor sem confirmacao de leitura; verificar o compartimento.','Dispositivo sem comunicacao recente com o aplicativo.'])[ ((g-1)%6)+1 ],
  now() - (g * 90 || ' minutes')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_alerta) DO NOTHING;

-- 11. CREDENCIAL_DISPOSITIVO (20) - hashes demonstrativos, nao credenciais reais.
INSERT INTO public.credencial_dispositivo (id_dispositivo, senha_vinculo_hash, atualizada_em)
SELECT
  ('30000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  crypt('VinculoDemo#' || lpad(g::text,2,'0'), gen_salt('bf')),
  now() - (g || ' days')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_dispositivo) DO NOTHING;

-- 12. ACESSO_DISPOSITIVO (20)
INSERT INTO public.acesso_dispositivo (id_acesso, id_usuario, id_dispositivo, ativo, data_vinculo)
SELECT
  ('b0000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('30000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  true,
  now() - (g || ' days')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_acesso) DO NOTHING;

-- 13. ALERTA_VISUALIZACAO (20)
INSERT INTO public.alerta_visualizacao (id_alerta, id_usuario, visualizado_em)
SELECT
  ('a0000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  ('10000000-0000-4000-8000-' || lpad(g::text,12,'0'))::uuid,
  now() - (g * 20 || ' minutes')::interval
FROM generate_series(1,20) AS g
ON CONFLICT (id_alerta, id_usuario) DO NOTHING;

COMMIT;

-- CONFERENCIA: deve retornar 20 para cada tabela.
SELECT 'usuario' AS tabela, count(*) AS registros FROM public.usuario
UNION ALL SELECT 'paciente', count(*) FROM public.paciente
UNION ALL SELECT 'dispositivo', count(*) FROM public.dispositivo
UNION ALL SELECT 'compartimento', count(*) FROM public.compartimento
UNION ALL SELECT 'vinculo_dispositivo', count(*) FROM public.vinculo_dispositivo
UNION ALL SELECT 'medicamento', count(*) FROM public.medicamento
UNION ALL SELECT 'abastecimento', count(*) FROM public.abastecimento
UNION ALL SELECT 'tratamento', count(*) FROM public.tratamento
UNION ALL SELECT 'dispensacao', count(*) FROM public.dispensacao
UNION ALL SELECT 'alerta', count(*) FROM public.alerta
UNION ALL SELECT 'credencial_dispositivo', count(*) FROM public.credencial_dispositivo
UNION ALL SELECT 'acesso_dispositivo', count(*) FROM public.acesso_dispositivo
UNION ALL SELECT 'alerta_visualizacao', count(*) FROM public.alerta_visualizacao
ORDER BY tabela;