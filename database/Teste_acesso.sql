-- PERFIL: CUIDADOR (authenticated) = demo.usuario01
-- T01 | AUTORIZADO | Cuidador le os proprios pacientes
-- Esperado: 1 linha (Maria Oliveira)
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
SELECT id_paciente, nome FROM public.paciente;
ROLLBACK;

-- T02 | NAO AUTORIZADO | Cuidador tenta ler pacientes de outros usuarios
-- Esperado: 0 linhas (bloqueado pelo RLS)
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
SELECT count(*) FILTER (WHERE id_usuario <> public.id_usuario_atual()) AS de_outros_usuarios,
       count(*) AS total_visivel
FROM public.paciente;
ROLLBACK;

-- T03 | AUTORIZADO | Cuidador atualiza os proprios medicamentos
-- Esperado: 1 linha atualizada
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
UPDATE public.medicamento SET dosagem = dosagem WHERE id_usuario = public.id_usuario_atual() RETURNING id_medicamento, nome;
ROLLBACK;

-- T04 | NAO AUTORIZADO | Cuidador tenta atualizar medicamentos de outros usuarios
-- Esperado: 0 linhas atualizadas (RLS)
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
WITH u AS (
  UPDATE public.medicamento SET dosagem = dosagem
  WHERE id_usuario <> public.id_usuario_atual() RETURNING 1
)
SELECT count(*) AS linhas_atualizadas FROM u;
ROLLBACK;


-- T05 | NAO AUTORIZADO | Cuidador tenta cadastrar paciente em nome de outro usuario (usuario02)
-- Esperado: ERRO "new row violates row-level security policy"
BEGIN;
SELECT set_config('app.outro_usuario', (SELECT id_usuario::text FROM public.usuario WHERE auth_user_id = '00000000-0000-4000-8000-000000000002'), true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
INSERT INTO public.paciente (id_usuario, nome, data_nascimento)
VALUES (current_setting('app.outro_usuario')::uuid, 'Paciente Teste', DATE '1950-01-01');
ROLLBACK;

-- T06 | NAO AUTORIZADO | Cuidador tenta excluir o proprio paciente
-- Esperado: ERRO "permission denied for table paciente" (DELETE nao concedido)
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
DELETE FROM public.paciente WHERE id_usuario = public.id_usuario_atual();
ROLLBACK;

-- T07 | NAO AUTORIZADO | Cuidador tenta registrar uma dispensacao
-- Esperado: ERRO "permission denied for table dispensacao" (somente leitura)
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
INSERT INTO public.dispensacao (id_usuario, id_tratamento, id_abastecimento, chave_evento_dispositivo, data_hora_programada, status, quantidade_liberada, retirada_confirmada_sensor)
VALUES (gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 'EVT-TESTE-ACESSO', now(), 'PROGRAMADA', 0, false);
ROLLBACK;

-- T08 | NAO AUTORIZADO | Cuidador tenta ler as credenciais dos dispositivos
-- Esperado: ERRO "permission denied for table credencial_dispositivo"
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
SELECT * FROM public.credencial_dispositivo;
ROLLBACK;


-- PERFIL: VISITANTE (anon)
-- T09 | NAO AUTORIZADO | Visitante sem login tenta ler usuarios
-- Esperado: ERRO "permission denied for table usuario"
BEGIN;
SET LOCAL ROLE anon;
SELECT * FROM public.usuario;
ROLLBACK;


-- PERFIL: DISPOSITIVO (caresync_dispositivo)
-- T10 | AUTORIZADO | Dispositivo atualiza status/ultimo contato de um dispositivo
-- Esperado: 1 linha atualizada
BEGIN;
SET LOCAL ROLE caresync_dispositivo;
UPDATE public.dispositivo SET ultimo_contato = ultimo_contato
WHERE id_dispositivo IN (SELECT id_dispositivo FROM public.dispositivo LIMIT 1)
RETURNING id_dispositivo, status_conexao;
ROLLBACK;

-- T11 | AUTORIZADO | Dispositivo atualiza uma dispensacao (ex.: confirmacao de retirada)
-- Esperado: 1 linha atualizada
BEGIN;
SET LOCAL ROLE caresync_dispositivo;
UPDATE public.dispensacao SET status = status
WHERE id_dispensacao IN (SELECT id_dispensacao FROM public.dispensacao LIMIT 1)
RETURNING id_dispensacao, status;
ROLLBACK;

-- T12 | NAO AUTORIZADO | Dispositivo tenta ler dados pessoais dos pacientes
-- Esperado: ERRO "permission denied for table paciente"
BEGIN;
SET LOCAL ROLE caresync_dispositivo;
SELECT * FROM public.paciente;
ROLLBACK;

-- T13 | NAO AUTORIZADO | Dispositivo tenta ler as credenciais dos dispositivos
-- Esperado: ERRO "permission denied for table credencial_dispositivo"
BEGIN;
SET LOCAL ROLE caresync_dispositivo;
SELECT * FROM public.credencial_dispositivo;
ROLLBACK;
